/*
 * AF Detection System v5.2
 * Trained: MIT-BIH Atrial Fibrillation (AF) Database
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>
#include "af_detection_esp32.h"

Preferences preferences;

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_READ      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_UUID_CONTROL   "beb5483e-36e1-4688-b7f5-ea07361b26a9"

BLEServer*         pServer                = NULL;
BLECharacteristic* pReadCharacteristic    = NULL;
BLECharacteristic* pControlCharacteristic = NULL;
bool deviceConnected    = false;
bool oldDeviceConnected = false;

// Pin configuration
#define ECG_PIN       34
#define LO_PLUS_PIN   26
#define LO_MINUS_PIN  27
#define GREEN_LED     25
#define RED_LED       33
#define BLUE_LED      32

// Detection parameters
#define WINDOW_SIZE      30
#define MIN_RR_INTERVAL  300
#define MAX_RR_INTERVAL  2000
#define THRESHOLD_RATIO  0.5f
#define BASELINE_ALPHA   0.005f
#define PEAK_ALPHA       0.05f
#define MIN_AMPLITUDE    100
#define CALIBRATION_MS   5000
#define WAIT_BETWEEN_MS  300000

struct AFReading {
  unsigned long timestamp;
  float mean_rr;
  float pRR20;
  float pRR6_25;
  float pRR30;
  float pRR50;
  float sdsd;
  float tpr;
  float mean_hr;
  uint8_t af_prediction;
  uint8_t confidence;
};

// Global state
int   rrIntervals[WINDOW_SIZE];
int   rrIndex    = 0;
int   validBeats = 0;
float currentBPM = 0;
float avgBPM     = 0;
unsigned long lastBlink = 0;
bool  blueState  = false;

float         adaptiveBaseline  = 0.0f;
float         adaptivePeak      = 0.0f;
float         adaptiveThreshold = 0.0f;
unsigned long lastPeakTime      = 0;
int           lastValue         = 0;
bool          peakDetected      = false;

void sendAllReadings();

// ── BLE ───────────────────────────────────────────────────

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer)    { deviceConnected = true;  Serial.println("Phone connected."); }
  void onDisconnect(BLEServer* pServer) { deviceConnected = false; Serial.println("Phone disconnected."); }
};

class ControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    if (value.length() > 0) {
      Serial.print("BLE command: "); Serial.println(value);
      if (value == "GET_DATA") {
        sendAllReadings();
      } else if (value == "CLEAR_DATA") {
        preferences.clear();
        pReadCharacteristic->setValue("CLEARED");
        pReadCharacteristic->notify();
        Serial.println("Data cleared.");
      } else if (value == "GET_COUNT") {
        int count = preferences.getInt("count", 0);
        String s  = "COUNT:" + String(count);
        pReadCharacteristic->setValue(s.c_str());
        pReadCharacteristic->notify();
      }
    }
  }
};

void sendAllReadings() {
  int total = preferences.getInt("count", 0);
  Serial.print("Sending "); Serial.print(total); Serial.println(" readings...");
  for (int i = 0; i < total; i++) {
    char key[20];
    sprintf(key, "r%d", i);
    AFReading reading;
    preferences.getBytes(key, &reading, sizeof(AFReading));
    String s = String(reading.timestamp)     + "," +
               String(reading.mean_hr,   1)  + "," +
               String(reading.af_prediction) + "," +
               String(reading.confidence);
    pReadCharacteristic->setValue(s.c_str());
    pReadCharacteristic->notify();
    delay(50);
  }
  pReadCharacteristic->setValue("END");
  pReadCharacteristic->notify();
  Serial.println("All readings sent.");
}

// ── LEDs ──────────────────────────────────────────────────

void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  LOW);
}

void showNormalResult() {
  allLedsOff();
  digitalWrite(GREEN_LED, HIGH);
  delay(5000);
  allLedsOff();
}

void showAFResult() {
  allLedsOff();
  for (int i = 0; i < 10; i++) {
    for (int b = 0;   b < 255; b += 5) { analogWrite(RED_LED, b); delay(10); }
    for (int b = 255; b > 0;   b -= 5) { analogWrite(RED_LED, b); delay(10); }
  }
  allLedsOff();
}

void showProcessing() {
  if (millis() - lastBlink > 200)  { blueState = !blueState; digitalWrite(BLUE_LED, blueState); lastBlink = millis(); }
}

void showIdle() {
  if (millis() - lastBlink > 1000) { blueState = !blueState; digitalWrite(BLUE_LED, blueState); lastBlink = millis(); }
}

void showError() {
  allLedsOff();
  for (int i = 0; i < 3; i++) {
    digitalWrite(GREEN_LED, HIGH); digitalWrite(RED_LED, HIGH); digitalWrite(BLUE_LED, HIGH);
    delay(100); allLedsOff(); delay(100);
  }
}

// FEATURE EXTRACTION 
void calculateFeatures(int* rr_intervals, int count, float* features) {
  if (count < 5) return;
  float rr[WINDOW_SIZE];
  for (int i = 0; i < count; i++) rr[i] = (float)rr_intervals[i];

  float sum = 0;
  for (int i = 0; i < count; i++) sum += rr[i];

  float diffs[WINDOW_SIZE];
  int   dc = count - 1;
  for (int i = 0; i < dc; i++) diffs[i] = fabsf(rr[i+1] - rr[i]);

  int   cnt6=0, cnt20=0, cnt30=0, cnt50=0;
  float diff_sum = 0;
  for (int i = 0; i < dc; i++) {
    if (diffs[i] > 6.25f)  cnt6++;
    if (diffs[i] > 20.0f)  cnt20++;
    if (diffs[i] > 30.0f)  cnt30++;
    if (diffs[i] > 50.0f)  cnt50++;
    diff_sum += diffs[i];
  }

  float mean_diff = diff_sum / dc;
  float var = 0;
  for (int i = 0; i < dc; i++) { float d = diffs[i] - mean_diff; var += d * d; }

  features[0] = sum / count;
  features[1] = (100.0f * cnt20) / dc;
  features[2] = (100.0f * cnt6)  / dc;
  features[3] = (100.0f * cnt30) / dc;
  features[4] = (100.0f * cnt50) / dc;
  features[5] = sqrtf(var / dc);
  features[6] = compute_tpr(rr, count);
}

// AF PREDICTION

int predictAF(float* features, int* confidence) {
  Eloquent::ML::Port::RandomForest clf;
  uint8_t votes[2] = {0};
  int prediction = clf.predictWithVotes(features, votes);
  *confidence = (int)((float)votes[prediction] / 3.0f * 100.0f);
  Serial.print("  Votes: Normal="); Serial.print(votes[0]);
  Serial.print(" | AF=");           Serial.print(votes[1]);
  Serial.print(" | Confidence: ");  Serial.print(*confidence); Serial.println("%");
  Serial.print("  Result: "); Serial.println(prediction == 1 ? "POSSIBLE AF" : "NORMAL");
  return prediction;
}

// STORAGE 

void storeReading(float* features, int prediction, int confidence) {
  AFReading reading;
  reading.timestamp     = millis() / 1000;
  reading.mean_rr       = features[0];
  reading.pRR20         = features[1];
  reading.pRR6_25       = features[2];
  reading.pRR30         = features[3];
  reading.pRR50         = features[4];
  reading.sdsd          = features[5];
  reading.tpr           = features[6];
  reading.mean_hr       = (features[0] > 0) ? 60000.0f / features[0] : 0;
  reading.af_prediction = prediction;
  reading.confidence    = confidence;

  int count = preferences.getInt("count", 0);
  char key[20];
  sprintf(key, "r%d", count);
  preferences.putBytes(key, &reading, sizeof(AFReading));
  preferences.putInt("count", count + 1);
  Serial.print("Stored reading #"); Serial.println(count + 1);
}

void printStoredReadings() {
  int count = preferences.getInt("count", 0);
  if (count == 0) { Serial.println("No stored readings."); return; }
  Serial.println("========================================");
  Serial.println("STORED READINGS");
  Serial.print("Total: "); Serial.println(count);
  for (int i = 0; i < count; i++) {
    char key[20]; sprintf(key, "r%d", i);
    AFReading r;
    preferences.getBytes(key, &r, sizeof(AFReading));
    Serial.print("Reading #"); Serial.println(i + 1);
    Serial.print("  Timestamp : "); Serial.println(r.timestamp);
    Serial.print("  Mean RR   : "); Serial.print(r.mean_rr, 2);  Serial.println(" ms");
    Serial.print("  Mean HR   : "); Serial.print(r.mean_hr, 1);  Serial.println(" BPM");
    Serial.print("  pRR20     : "); Serial.print(r.pRR20, 1);    Serial.println("%");
    Serial.print("  pRR6.25   : "); Serial.print(r.pRR6_25, 1);  Serial.println("%");
    Serial.print("  pRR30     : "); Serial.print(r.pRR30, 1);    Serial.println("%");
    Serial.print("  pRR50     : "); Serial.print(r.pRR50, 1);    Serial.println("%");
    Serial.print("  SDSD      : "); Serial.print(r.sdsd, 2);     Serial.println(" ms");
    Serial.print("  TPR       : "); Serial.println(r.tpr, 4);
    Serial.print("  Result    : "); Serial.println(r.af_prediction == 1 ? "POSSIBLE AF" : "NORMAL");
    Serial.print("  Confidence: "); Serial.print(r.confidence);  Serial.println("%");
  }
  Serial.println("========================================");
}

// R-PEAK DETECTION 
void detectRPeak(int currentValue, unsigned long currentTime) {
  float fval = (float)currentValue;

  adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * (fval - adaptiveBaseline);
  if (fval > adaptiveThreshold)
    adaptivePeak = adaptivePeak + PEAK_ALPHA * (fval - adaptivePeak);

  float amplitude   = adaptivePeak - adaptiveBaseline;
  adaptiveThreshold = adaptiveBaseline + THRESHOLD_RATIO * amplitude;

  if (amplitude < MIN_AMPLITUDE) { peakDetected = false; lastValue = currentValue; return; }

  if ((float)lastValue < adaptiveThreshold &&
      fval >= adaptiveThreshold &&
      !peakDetected) {
    if (lastPeakTime > 0) {
      int rrInterval = currentTime - lastPeakTime;
      if (rrInterval >= MIN_RR_INTERVAL && rrInterval <= MAX_RR_INTERVAL) {
        rrIntervals[rrIndex] = rrInterval;
        rrIndex = (rrIndex + 1) % WINDOW_SIZE;
        if (validBeats < WINDOW_SIZE) validBeats++;
        currentBPM = 60000.0f / rrInterval;
        float s = 0;
        for (int i = 0; i < validBeats; i++) s += rrIntervals[i];
        avgBPM = 60000.0f / (s / validBeats);
        Serial.print("Beat "); Serial.print(validBeats); Serial.print("/30");
        Serial.print(" | RR: "); Serial.print(rrInterval); Serial.print(" ms");
        Serial.print(" | BPM: "); Serial.print(currentBPM, 1);
        Serial.print(" | Avg: "); Serial.print(avgBPM, 1);
        Serial.print(" | Thr: "); Serial.println((int)adaptiveThreshold);
      }
    }
    lastPeakTime = currentTime;
    peakDetected = true;
  }

  if (fval < adaptiveThreshold - 0.2f * amplitude) peakDetected = false;
  lastValue = currentValue;
}

// CALIBRATION 
void calibrateWithContactCheck() {
  Serial.println("================================");
  Serial.println("Place fingers on electrodes.");
  Serial.println("================================");

  int firstSample   = analogRead(ECG_PIN);
  adaptiveBaseline  = (float)firstSample;
  adaptivePeak      = (float)firstSample;
  adaptiveThreshold = (float)firstSample;
  lastPeakTime      = 0;
  peakDetected      = false;
  lastValue         = firstSample;

  // Phase 1: wait for finger contact — slow blue blink
  Serial.println("Waiting for electrode contact...");
  bool waitBlink      = false;
  unsigned long lastWaitBlink = 0;

  while (true) {
    int v = analogRead(ECG_PIN);
    adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * ((float)v - adaptiveBaseline);
    if ((float)v > adaptivePeak) {
      adaptivePeak = (float)v;
    } else {
      adaptivePeak = adaptivePeak * 0.999f;
    }
    adaptiveThreshold = adaptiveBaseline + THRESHOLD_RATIO * (adaptivePeak - adaptiveBaseline);

    if (millis() - lastWaitBlink > 1000) {
      waitBlink = !waitBlink;
      digitalWrite(BLUE_LED, waitBlink);
      lastWaitBlink = millis();
    }

    if ((adaptivePeak - adaptiveBaseline) >= MIN_AMPLITUDE) {
      Serial.println("Electrode contact detected.");
      break;
    }
    delay(4);
  }

  // Phase 2: contact confirmed — 5-second calibration, fast blue blink
  Serial.println("Hold still — calibrating for 5 seconds...");
  unsigned long calEnd      = millis() + CALIBRATION_MS;
  bool          calBlink    = false;
  unsigned long lastCalBlink = 0;

  while (millis() < calEnd) {
    if (millis() - lastCalBlink > 200) {
      calBlink = !calBlink;
      digitalWrite(BLUE_LED, calBlink);
      lastCalBlink = millis();
    }
    int v = analogRead(ECG_PIN);
    adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * ((float)v - adaptiveBaseline);
    if ((float)v > adaptivePeak) {
      adaptivePeak = (float)v;
    } else {
      adaptivePeak = adaptivePeak * 0.999f;
    }
    adaptiveThreshold = adaptiveBaseline + THRESHOLD_RATIO * (adaptivePeak - adaptiveBaseline);
    delay(4);
  }

  digitalWrite(BLUE_LED, LOW);
  Serial.print("Baseline  : "); Serial.println((int)adaptiveBaseline);
  Serial.print("Peak est  : "); Serial.println((int)adaptivePeak);
  Serial.print("Amplitude : "); Serial.println((int)(adaptivePeak - adaptiveBaseline));
  Serial.print("Threshold : "); Serial.println((int)adaptiveThreshold);

  if ((adaptivePeak - adaptiveBaseline) < MIN_AMPLITUDE) {
    Serial.println("WARNING: Low signal amplitude. Check electrodes.");
    showError();
  } else {
    Serial.println("Signal quality: OK");
  }

  Serial.println("================================");
  Serial.println("Measurement starting...");
  Serial.println("================================");
}

// ── SETUP ─────────────────────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("================================");
  Serial.println("AF Detection System v5.2");
  Serial.println("Trained: MIT-BIH AF Database");
  Serial.println("================================");

  pinMode(GREEN_LED,    OUTPUT);
  pinMode(RED_LED,      OUTPUT);
  pinMode(BLUE_LED,     OUTPUT);
  pinMode(ECG_PIN,      INPUT);
  pinMode(LO_PLUS_PIN,  INPUT);
  pinMode(LO_MINUS_PIN, INPUT);

  // LED startup test
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   HIGH); delay(300); digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  HIGH); delay(300); digitalWrite(BLUE_LED,  LOW);
  Serial.println("LEDs OK.");

  preferences.begin("af-storage", false);
  Serial.print("Stored readings: "); Serial.println(preferences.getInt("count", 0));
  printStoredReadings();

  Serial.println("Initialising BLE...");
  BLEDevice::init("AF_Monitor");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pReadCharacteristic = pService->createCharacteristic(
    CHAR_UUID_READ,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pReadCharacteristic->addDescriptor(new BLE2902());

  pControlCharacteristic = pService->createCharacteristic(
    CHAR_UUID_CONTROL,
    BLECharacteristic::PROPERTY_WRITE
  );
  pControlCharacteristic->setCallbacks(new ControlCallbacks());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("BLE ready. Device name: AF_Monitor");

  calibrateWithContactCheck();
}

// ── LOOP ──────────────────────────────────────────────────

void loop() {
  // BLE reconnection handler
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Lead-off detection
  if (digitalRead(LO_PLUS_PIN) || digitalRead(LO_MINUS_PIN)) {
    showError();
    validBeats   = 0;
    rrIndex      = 0;
    Serial.println("Electrodes disconnected — resetting.");
    delay(1000);
    return;
  }

  int ecgValue        = analogRead(ECG_PIN);
  unsigned long nowMs = millis();

  validBeats > 0 ? showProcessing() : showIdle();

  detectRPeak(ecgValue, nowMs);

  // Analysis after 30 valid beats
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();

    Serial.println("================================");
    Serial.println("30 beats collected — Analysing...");
    Serial.println("================================");

    float features[7];
    calculateFeatures(rrIntervals, WINDOW_SIZE, features);

    Serial.println("HRV Features:");
    Serial.print("  Mean RR : "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  HR      : "); Serial.print(60000.0f / features[0], 1); Serial.println(" BPM");
    Serial.print("  pRR20   : "); Serial.print(features[1], 1); Serial.println("%");
    Serial.print("  pRR6.25 : "); Serial.print(features[2], 1); Serial.println("%");
    Serial.print("  pRR30   : "); Serial.print(features[3], 1); Serial.println("%");
    Serial.print("  pRR50   : "); Serial.print(features[4], 1); Serial.println("%");
    Serial.print("  SDSD    : "); Serial.print(features[5], 2); Serial.println(" ms");
    Serial.print("  TPR     : "); Serial.print(features[6], 4); Serial.println();

    int confidence;
    int prediction = predictAF(features, &confidence);

    Serial.println("================================");
    if (prediction == 1) {
      Serial.println("RHYTHM: Possible AF Detected");
      Serial.println("Consult a healthcare professional.");
      showAFResult();
    } else {
      Serial.println("RHYTHM: Normal Sinus Rhythm");
      showNormalResult();
    }
    Serial.println("================================");

    storeReading(features, prediction, confidence);

    // 5-minute wait before next measurement
    Serial.println("Waiting 5 minutes before next measurement...");

    validBeats   = 0;
    rrIndex      = 0;
    lastPeakTime = 0;
    peakDetected = false;

    unsigned long waitStart     = millis();
    unsigned long lastWaitBlink = 0;
    unsigned long lastCountdown = 0;
    bool          waitBlink     = false;

    while (millis() - waitStart < WAIT_BETWEEN_MS) {
      if (!deviceConnected && oldDeviceConnected) {
        delay(500); pServer->startAdvertising(); oldDeviceConnected = deviceConnected;
      }
      if (deviceConnected && !oldDeviceConnected) oldDeviceConnected = deviceConnected;

      if (millis() - lastWaitBlink > 1000) {
        waitBlink = !waitBlink;
        digitalWrite(BLUE_LED, waitBlink);
        lastWaitBlink = millis();
      }

      unsigned long remaining = (WAIT_BETWEEN_MS - (millis() - waitStart)) / 1000;
      if (millis() - lastCountdown > 30000) {
        Serial.print("Next measurement in: "); Serial.print(remaining); Serial.println("s");
        lastCountdown = millis();
      }

      delay(100);
    }

    digitalWrite(BLUE_LED, LOW);
    calibrateWithContactCheck();
  }

  delay(4);
}