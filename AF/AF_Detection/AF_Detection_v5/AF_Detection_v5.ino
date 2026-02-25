/*
 * AF Detection System v5.0
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>
#include "af_detection_v5.h"   

Preferences preferences;

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_READ      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_UUID_CONTROL   "beb5483e-36e1-4688-b7f5-ea07361b26a9"

BLEServer*         pServer               = NULL;
BLECharacteristic* pReadCharacteristic   = NULL;
BLECharacteristic* pControlCharacteristic = NULL;
bool deviceConnected    = false;
bool oldDeviceConnected = false;

// Pin configuration
#define ECG_PIN      34
#define LO_PLUS_PIN  26
#define LO_MINUS_PIN 27

// LED Pins
#define GREEN_LED 25
#define RED_LED   33
#define BLUE_LED  32

// Window size — 30 beats matches training window
#define WINDOW_SIZE      30
#define MIN_RR_INTERVAL  300
#define MAX_RR_INTERVAL  2000

// ADAPTIVE THRESHOLD PARAMETERS
#define THRESHOLD_RATIO  0.5f
#define BASELINE_ALPHA   0.005f
#define PEAK_ALPHA       0.05f
#define MIN_AMPLITUDE    100
#define CALIBRATION_MS   5000

// DATA STRUCTURE
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

// GLOBAL STATE
int   rrIntervals[WINDOW_SIZE];
int   rrIndex    = 0;
int   validBeats = 0;
float currentBPM = 0;
float avgBPM     = 0;
unsigned long lastBlink = 0;
bool  blueState  = false;

// Adaptive threshold state
float adaptiveBaseline  = 1800.0f;
float adaptivePeak      = 2000.0f;
float adaptiveThreshold = 1900.0f;
unsigned long lastPeakTime = 0;
int   lastValue    = 0;
bool  peakDetected = false;


void sendAllReadings();

// BLE CALLBACKS
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Phone connected!");
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Phone disconnected!");
  }
};

class ControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    if (value.length() > 0) {
      Serial.print("Received command: "); Serial.println(value);
      if (value == "GET_DATA")  sendAllReadings();
      else if (value == "CLEAR_DATA") {
        preferences.clear();
        pReadCharacteristic->setValue("CLEARED");
        pReadCharacteristic->notify();
        Serial.println("Data cleared via BLE");
      } else if (value == "GET_COUNT") {
        int count = preferences.getInt("count", 0);
        String s  = "COUNT:" + String(count);
        pReadCharacteristic->setValue(s.c_str());
        pReadCharacteristic->notify();
      }
    }
  }
};

// BLE DATA TRANSFER
void sendAllReadings() {
  int total = preferences.getInt("count", 0);
  Serial.print("Sending "); Serial.print(total);
  Serial.println(" readings...");

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
  Serial.println("All readings sent!");
}

// LED FUNCTIONS 
void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  LOW);
}

void showNormalResult() {
  allLedsOff();
  digitalWrite(GREEN_LED, HIGH);
  Serial.println("LED: GREEN ON (Normal)");
  delay(5000);
  allLedsOff();
}

void showAFResult() {
  allLedsOff();
  Serial.println("LED: RED PULSING (Possible AF)");
  for (int i = 0; i < 10; i++) {
    for (int b = 0;   b < 255; b += 5) { analogWrite(RED_LED, b); delay(10); }
    for (int b = 255; b > 0;   b -= 5) { analogWrite(RED_LED, b); delay(10); }
  }
  allLedsOff();
}

void showProcessing() {
  if (millis() - lastBlink > 200) {
    blueState = !blueState;
    digitalWrite(BLUE_LED, blueState);
    lastBlink = millis();
  }
}

void showIdle() {
  if (millis() - lastBlink > 1000) {
    blueState = !blueState;
    digitalWrite(BLUE_LED, blueState);
    lastBlink = millis();
  }
}

void showError() {
  allLedsOff();
  for (int i = 0; i < 3; i++) {
    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(RED_LED,   HIGH);
    digitalWrite(BLUE_LED,  HIGH);
    delay(100);
    allLedsOff();
    delay(100);
  }
}

// FEATURE EXTRACTION 
void calculateFeatures(int* rr_intervals, int count, float* features) {
  if (count < 5) return;

  // Convert to float array for TPR computation
  float rr[WINDOW_SIZE];
  for (int i = 0; i < count; i++) rr[i] = (float)rr_intervals[i];

  // mean_rr
  float sum = 0;
  for (int i = 0; i < count; i++) sum += rr[i];
  float mean_rr = sum / count;

  // Successive absolute differences
  float diffs[WINDOW_SIZE];
  int   dc = count - 1;
  for (int i = 0; i < dc; i++)
    diffs[i] = fabsf(rr[i+1] - rr[i]);

  // pRRx features
  int cnt6 = 0, cnt20 = 0, cnt30 = 0, cnt50 = 0;
  float sum_sq   = 0;
  float diff_sum = 0;

  for (int i = 0; i < dc; i++) {
    if (diffs[i] > 6.25f)  cnt6++;
    if (diffs[i] > 20.0f)  cnt20++;
    if (diffs[i] > 30.0f)  cnt30++;
    if (diffs[i] > 50.0f)  cnt50++;
    diff_sum += diffs[i];
  }

  float pRR20   = (100.0f * cnt20) / dc;   
  float pRR6_25 = (100.0f * cnt6)  / dc;   
  float pRR30   = (100.0f * cnt30) / dc;   
  float pRR50   = (100.0f * cnt50) / dc;   

  // SDSD — SD of successive differences
  float mean_diff = diff_sum / dc;
  float var = 0;
  for (int i = 0; i < dc; i++) {
    float d = diffs[i] - mean_diff;
    var += d * d;
  }
  float sdsd = sqrtf(var / dc);

  // TPR
  float tpr = compute_tpr(rr, count);

  features[0] = mean_rr;
  features[1] = pRR20;
  features[2] = pRR6_25;
  features[3] = pRR30;
  features[4] = pRR50;
  features[5] = sdsd;
  features[6] = tpr;
}

// UPDATED CLASSIFIER 
int predictAF(float* features, int* confidence) {
  Eloquent::ML::Port::RandomForest clf;
  int prediction = clf.predict(features);

  // Confidence based on validated model accuracy
  *confidence = (prediction == 1) ? 92 : 84;

  // Debug output
  Serial.print("  mean_rr : "); Serial.print(features[0], 2); Serial.println(" ms");
  Serial.print("  pRR20   : "); Serial.print(features[1], 1); Serial.println("%");
  Serial.print("  pRR6.25 : "); Serial.print(features[2], 1); Serial.println("%");
  Serial.print("  pRR30   : "); Serial.print(features[3], 1); Serial.println("%");
  Serial.print("  pRR50   : "); Serial.print(features[4], 1); Serial.println("%");
  Serial.print("  sdsd    : "); Serial.print(features[5], 2); Serial.println(" ms");
  Serial.print("  tpr     : "); Serial.print(features[6], 4); Serial.println();
  Serial.print("  Result  : "); Serial.println(prediction == 1 ? "POSSIBLE AF" : "NORMAL");
  Serial.print("  Conf    : "); Serial.print(*confidence); Serial.println("%");

  return prediction;
}

// FLASH STORAGE
void storeReading(float* features, int prediction, int confidence) {
  AFReading reading;
  reading.timestamp     = millis();
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

  Serial.println("\n========================================");
  Serial.println("STORED READINGS FROM FLASH");
  Serial.println("========================================");
  Serial.print("Total: "); Serial.println(count);

  for (int i = 0; i < count; i++) {
    char key[20];
    sprintf(key, "r%d", i);
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
  Serial.println("========================================\n");
}

// ── ADAPTIVE THRESHOLD R-PEAK DETECTION ──────────────────
void detectRPeak(int currentValue, unsigned long currentTime) {
  float fval = (float)currentValue;

  adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * (fval - adaptiveBaseline);

  if (fval > adaptiveThreshold)
    adaptivePeak = adaptivePeak + PEAK_ALPHA * (fval - adaptivePeak);

  float amplitude   = adaptivePeak - adaptiveBaseline;
  adaptiveThreshold = adaptiveBaseline + THRESHOLD_RATIO * amplitude;

  if (amplitude < MIN_AMPLITUDE) {
    peakDetected = false;
    lastValue    = currentValue;
    return;
  }

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

        Serial.print("Beat ");    Serial.print(validBeats);
        Serial.print("/");        Serial.print(WINDOW_SIZE);
        Serial.print(" | RR: ");  Serial.print(rrInterval);
        Serial.print(" ms | BPM: "); Serial.print(currentBPM, 1);
        Serial.print(" | Avg: "); Serial.print(avgBPM, 1);
        Serial.print(" | Thr: "); Serial.println((int)adaptiveThreshold);
      }
    }
    lastPeakTime = currentTime;
    peakDetected = true;
  }

  if (fval < adaptiveThreshold - 0.2f * amplitude)
    peakDetected = false;

  lastValue = currentValue;
}

// ── SETUP ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n================================");
  Serial.println("AF Detection System ");
  Serial.println("Random Forest Edition");
  Serial.println("Trained: MIT-BIH AF Database");
  Serial.println("================================\n");

  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED,   OUTPUT);
  pinMode(BLUE_LED,  OUTPUT);

  Serial.println("Testing LEDs ");
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   HIGH); delay(300); digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  HIGH); delay(300); digitalWrite(BLUE_LED,  LOW);
  Serial.println("LEDs OK\n");

  preferences.begin("af-storage", false);
  int storedCount = preferences.getInt("count", 0);
  Serial.print("Stored readings: "); Serial.println(storedCount);
  printStoredReadings();

  Serial.println("Initialising BLE ");
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
  Serial.println("BLE Ready! Device: AF_Monitor\n");

  pinMode(ECG_PIN,      INPUT);
  pinMode(LO_PLUS_PIN,  INPUT);
  pinMode(LO_MINUS_PIN, INPUT);

  Serial.println("================================");
  Serial.println("Calibrating adaptive threshold");
  Serial.println("Place fingers on electrodes now");
  Serial.println("Hold still for 5 seconds...");
  Serial.println("================================");

  unsigned long calStart = millis();
  unsigned long calEnd   = calStart + CALIBRATION_MS;
  bool calBlink = false;
  unsigned long lastCalBlink = 0;

  while (millis() < calEnd) {
    if (millis() - lastCalBlink > 500) {
      calBlink = !calBlink;
      digitalWrite(BLUE_LED, calBlink);
      lastCalBlink = millis();
    }
    int v = analogRead(ECG_PIN);
    adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * (v - adaptiveBaseline);
    if ((float)v > adaptivePeak) {
      adaptivePeak = (float)v;
    } else {
      adaptivePeak = adaptivePeak * 0.999f;
    }
    adaptiveThreshold = adaptiveBaseline +
                        THRESHOLD_RATIO * (adaptivePeak - adaptiveBaseline);
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
  Serial.println("================================\n");
}

// ── LOOP ──────────────────────────────────────────────────
void loop() {
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  bool leadsOff = digitalRead(LO_PLUS_PIN) || digitalRead(LO_MINUS_PIN);
  if (leadsOff) {
    showError();
    adaptiveBaseline  = 1800.0f;
    adaptivePeak      = 2000.0f;
    adaptiveThreshold = 1900.0f;
    validBeats = 0;
    rrIndex    = 0;
    Serial.println("Electrodes disconnected - reset");
    delay(1000);
    return;
  }

  int ecgValue        = analogRead(ECG_PIN);
  unsigned long nowMs = millis();

  if (validBeats < WINDOW_SIZE) {
    validBeats > 0 ? showProcessing() : showIdle();
  }

  detectRPeak(ecgValue, nowMs);

  // Analysis triggered after 30 beats
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();

    Serial.println("\n================================");
    Serial.println("30 beats collected — Analysing...");
    Serial.println("================================");

    // 7 features now
    float features[7];
    calculateFeatures(rrIntervals, WINDOW_SIZE, features);

    Serial.println("\nHRV Features:");
    Serial.print("  Mean RR : "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  HR      : "); Serial.print(60000.0f/features[0], 1); Serial.println(" BPM");
    Serial.print("  pRR20   : "); Serial.print(features[1], 1); Serial.println("%");
    Serial.print("  pRR6.25 : "); Serial.print(features[2], 1); Serial.println("%");
    Serial.print("  pRR30   : "); Serial.print(features[3], 1); Serial.println("%");
    Serial.print("  pRR50   : "); Serial.print(features[4], 1); Serial.println("%");
    Serial.print("  SDSD    : "); Serial.print(features[5], 2); Serial.println(" ms");
    Serial.print("  TPR     : "); Serial.print(features[6], 4); Serial.println();
    Serial.println();

    int confidence;
    int prediction = predictAF(features, &confidence);

    Serial.println("\n================================");
    Serial.println("RESULT:");
    Serial.println("================================");

    if (prediction == 1) {
      Serial.println("RHYTHM: Possible AF Detected");
      Serial.println("Consult a healthcare professional.");
      showAFResult();
    } else {
      Serial.println("RHYTHM: Normal Sinus Rhythm");
      showNormalResult();
    }

    Serial.println("================================\n");

    storeReading(features, prediction, confidence);

    validBeats = 0;
    rrIndex    = 0;
    delay(5000);
  }

  delay(4);
}