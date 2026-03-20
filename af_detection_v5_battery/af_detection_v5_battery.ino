/*
 * AF Detection System v5.2
 * Added: battery status LED, voltage divider ADC, TP4056 CHRG monitoring
 * Fixed: calibration now learns from actual signal, not hardcoded values
 * Added: 5-minute wait between measurements
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>
#include "af_detection_esp32.h"

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

// ── PIN CONFIGURATION ─────────────────────────────────────
#define ECG_PIN       34
#define LO_PLUS_PIN   26
#define LO_MINUS_PIN  27

// AF result LEDs (existing)
#define GREEN_LED     25
#define RED_LED       33
#define BLUE_LED      32

// Battery status LED — use yellow/orange if available
#define BATT_LED      4

// Battery voltage divider — connect midpoint here
// Wire: Battery(+) -- R1(100kΩ) -- GPIO35 -- R2(100kΩ) -- GND
#define BATT_ADC_PIN  35

// TP4056 CHRG pin — goes LOW when charging, HIGH/float when done
// Wire: TP4056 CHRG pin -- GPIO13
#define CHRG_PIN      13

// ── WINDOW / DETECTION PARAMETERS ────────────────────────
#define WINDOW_SIZE      30
#define MIN_RR_INTERVAL  300
#define MAX_RR_INTERVAL  2000

#define THRESHOLD_RATIO  0.5f
#define BASELINE_ALPHA   0.005f
#define PEAK_ALPHA       0.05f
#define MIN_AMPLITUDE    100
#define CALIBRATION_MS   5000
#define WAIT_BETWEEN_MS  300000  // 5 minutes between measurements

// Battery thresholds
#define BATT_LOW_PERCENT  20      // Red slow-blink below this
#define BATT_CHECK_MS     30000   // Check battery every 30 seconds

// ── DATA STRUCTURE ────────────────────────────────────────
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

// ── GLOBAL STATE ──────────────────────────────────────────
int   rrIntervals[WINDOW_SIZE];
int   rrIndex    = 0;
int   validBeats = 0;
float currentBPM = 0;
float avgBPM     = 0;
unsigned long lastBlink = 0;
bool  blueState  = false;

// Adaptive threshold state — initialised to 0 so calibration learns from actual signal
float adaptiveBaseline  = 0.0f;
float adaptivePeak      = 0.0f;
float adaptiveThreshold = 0.0f;
unsigned long lastPeakTime = 0;
int   lastValue    = 0;
bool  peakDetected = false;

// Battery state
unsigned long lastBattCheck = 0;
bool battLedState = false;
unsigned long lastBattBlink = 0;
float batteryPercent = 100.0f;
bool isCharging = false;

void sendAllReadings();

// ── BATTERY FUNCTIONS ─────────────────────────────────────

// Read battery voltage via voltage divider and convert to percentage
float readBatteryPercent() {
  // Average 10 readings to reduce ADC noise
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(BATT_ADC_PIN);
    delay(2);
  }
  float raw = sum / 10.0f;

  // x2 because equal resistor divider halves the voltage
  float voltage = (raw / 4095.0f) * 3.3f * 2.0f;

  // Map 3.2V (0%) to 4.2V (100%)
  float percent = ((voltage - 3.2f) / (4.2f - 3.2f)) * 100.0f;
  percent = constrain(percent, 0.0f, 100.0f);

  Serial.print("Battery voltage: "); Serial.print(voltage, 2);
  Serial.print("V | Level: ");       Serial.print(percent, 0);
  Serial.println("%");

  return percent;
}

// Check TP4056 CHRG pin — LOW = charging, HIGH = full/not charging
bool checkCharging() {
  return (digitalRead(CHRG_PIN) == LOW);
}

// Update battery LED based on current state
// Charging  → solid ON
// Low (<20%) → slow blink (1 second interval)
// Normal    → OFF
void updateBatteryLed() {
  isCharging     = checkCharging();
  batteryPercent = readBatteryPercent();

  if (isCharging) {
    // Solid on while charging
    digitalWrite(BATT_LED, HIGH);
    Serial.println("Battery: CHARGING");
  } else if (batteryPercent < BATT_LOW_PERCENT) {
    // Slow blink for low battery — handled in loop
    Serial.println("Battery: LOW");
  } else {
    // Normal — LED off
    digitalWrite(BATT_LED, LOW);
    Serial.println("Battery: OK");
  }
}

// Call this in the main loop to handle slow blink without blocking
void handleBatteryLedLoop() {
  if (isCharging) {
    digitalWrite(BATT_LED, HIGH);
    return;
  }

  if (batteryPercent < BATT_LOW_PERCENT) {
    // Slow blink — 1 second on, 1 second off
    if (millis() - lastBattBlink > 1000) {
      battLedState = !battLedState;
      digitalWrite(BATT_LED, battLedState);
      lastBattBlink = millis();
    }
  } else {
    digitalWrite(BATT_LED, LOW);
  }
}

// ── BLE CALLBACKS ─────────────────────────────────────────
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

// ── BLE DATA TRANSFER ─────────────────────────────────────
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

// ── AF RESULT LEDs ────────────────────────────────────────
void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  LOW);
  // Note: BATT_LED is NOT turned off here — battery state is independent
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

// ── FEATURE EXTRACTION ───────────────────────────────────
void calculateFeatures(int* rr_intervals, int count, float* features) {
  if (count < 5) return;

  float rr[WINDOW_SIZE];
  for (int i = 0; i < count; i++) rr[i] = (float)rr_intervals[i];

  float sum = 0;
  for (int i = 0; i < count; i++) sum += rr[i];
  float mean_rr = sum / count;

  float diffs[WINDOW_SIZE];
  int   dc = count - 1;
  for (int i = 0; i < dc; i++)
    diffs[i] = fabsf(rr[i+1] - rr[i]);

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

  float mean_diff = diff_sum / dc;
  float var = 0;
  for (int i = 0; i < dc; i++) {
    float d = diffs[i] - mean_diff;
    var += d * d;
  }
  float sdsd = sqrtf(var / dc);

  float tpr = compute_tpr(rr, count);

  features[0] = mean_rr;
  features[1] = pRR20;
  features[2] = pRR6_25;
  features[3] = pRR30;
  features[4] = pRR50;
  features[5] = sdsd;
  features[6] = tpr;
}

// ── AF PREDICTION ─────────────────────────────────────────
int predictAF(float* features, int* confidence) {
  Eloquent::ML::Port::RandomForest clf;

  uint8_t votes[2] = {0};
  int prediction = clf.predictWithVotes(features, votes);

  *confidence = (int)((float)votes[prediction] / 3.0f * 100.0f);

  Serial.print("  Votes    : Normal="); Serial.print(votes[0]);
  Serial.print(" | AF=");              Serial.print(votes[1]);
  Serial.print(" | Confidence: ");     Serial.print(*confidence);
  Serial.println("%");
  Serial.print("  Result   : "); Serial.println(prediction == 1 ? "POSSIBLE AF" : "NORMAL");

  return prediction;
}

// ── FLASH STORAGE ─────────────────────────────────────────
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
  Serial.println("AF Detection System v5.1");
  Serial.println("Random Forest Edition");
  Serial.println("Trained: MIT-BIH AF Database");
  Serial.println("================================\n");

  // AF result LEDs
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED,   OUTPUT);
  pinMode(BLUE_LED,  OUTPUT);

  // Battery LED
  pinMode(BATT_LED, OUTPUT);
  digitalWrite(BATT_LED, LOW);

  // Battery ADC pin (input only — no pinMode needed for GPIO35)
  // TP4056 CHRG pin
  pinMode(CHRG_PIN, INPUT_PULLUP);

  // LED test
  Serial.println("Testing LEDs...");
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   HIGH); delay(300); digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  HIGH); delay(300); digitalWrite(BLUE_LED,  LOW);
  digitalWrite(BATT_LED,  HIGH); delay(300); digitalWrite(BATT_LED,  LOW);
  Serial.println("LEDs OK\n");

  // Initial battery check
  Serial.println("Checking battery...");
  updateBatteryLed();

  // Flash storage
  preferences.begin("af-storage", false);
  int storedCount = preferences.getInt("count", 0);
  Serial.print("Stored readings: ");
  Serial.println(storedCount);
  printStoredReadings();

  // BLE init
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
  Serial.println("BLE Ready! Device: AF_Monitor\n");

  // ECG pins
  pinMode(ECG_PIN,      INPUT);
  pinMode(LO_PLUS_PIN,  INPUT);
  pinMode(LO_MINUS_PIN, INPUT);

  // Calibration — seed from first real ADC sample then let it adapt
  Serial.println("================================");
  Serial.println("Calibrating adaptive threshold");
  Serial.println("Place fingers on electrodes now");
  Serial.println("Hold still for 5 seconds...");
  Serial.println("================================");

  // Seed baseline and peak from the first real sample so we don't
  // start from a hardcoded guess that may be far from the actual signal
  int firstSample = analogRead(ECG_PIN);
  adaptiveBaseline  = (float)firstSample;
  adaptivePeak      = (float)firstSample;
  adaptiveThreshold = (float)firstSample;

  unsigned long calStart    = millis();
  unsigned long calEnd      = calStart + CALIBRATION_MS;
  bool          calBlink    = false;
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

  lastBattCheck = millis();
}

// ── LOOP ──────────────────────────────────────────────────
void loop() {
  // BLE reconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Battery check every 30 seconds
  if (millis() - lastBattCheck > BATT_CHECK_MS) {
    updateBatteryLed();
    lastBattCheck = millis();
  }

  // Battery LED blink handler (non-blocking)
  handleBatteryLedLoop();

  // Lead-off detection
  bool leadsOff = digitalRead(LO_PLUS_PIN) || digitalRead(LO_MINUS_PIN);
  if (leadsOff) {
    showError();
    // Reset to current signal level rather than hardcoded guess
    int sample        = analogRead(ECG_PIN);
    adaptiveBaseline  = (float)sample;
    adaptivePeak      = (float)sample;
    adaptiveThreshold = (float)sample;
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

  // Analysis after 30 beats
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();

    Serial.println("\n================================");
    Serial.println("30 beats collected — Analysing...");
    Serial.println("================================");

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

    // ── 5-MINUTE WAIT ──────────────────────────────────────
    // Device idles for 5 minutes before accepting a new measurement.
    // Blue LED slow-blinks during wait. Battery LED continues normally.
    Serial.println("Waiting 5 minutes before next measurement...");
    Serial.println("(Blue slow-blink = idle/waiting)");

    validBeats = 0;
    rrIndex    = 0;
    lastPeakTime = 0;
    peakDetected = false;

    unsigned long waitStart = millis();
    unsigned long lastWaitBlink = 0;
    bool waitBlink = false;

    while (millis() - waitStart < WAIT_BETWEEN_MS) {
      // Keep BLE alive
      if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        oldDeviceConnected = deviceConnected;
      }
      if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
      }

      // Battery LED
      if (millis() - lastBattCheck > BATT_CHECK_MS) {
        updateBatteryLed();
        lastBattCheck = millis();
      }
      handleBatteryLedLoop();

      // Blue slow blink during wait
      if (millis() - lastWaitBlink > 1000) {
        waitBlink = !waitBlink;
        digitalWrite(BLUE_LED, waitBlink);
        lastWaitBlink = millis();
      }

      // Print countdown every 30 seconds
      unsigned long elapsed = millis() - waitStart;
      unsigned long remaining = (WAIT_BETWEEN_MS - elapsed) / 1000;
      static unsigned long lastCountdown = 0;
      if (millis() - lastCountdown > 30000) {
        Serial.print("Next measurement in: ");
        Serial.print(remaining);
        Serial.println("s");
        lastCountdown = millis();
      }

      delay(100);
    }

    // Wait done — ready for next measurement
    digitalWrite(BLUE_LED, LOW);
    Serial.println("\n================================");
    Serial.println("Ready for next measurement");
    Serial.println("Place fingers on electrodes");
    Serial.println("================================\n");

  }  // end if validBeats >= WINDOW_SIZE

  delay(4);
}
