/*
 * AF Detection System v5.0
 * Clinically-Informed Parameter Edition
 *
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

Preferences preferences;

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_READ      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_UUID_CONTROL   "beb5483e-36e1-4688-b7f5-ea07361b26a9"

BLEServer*         pServer              = NULL;
BLECharacteristic* pReadCharacteristic  = NULL;
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

// 30 beats = ~25-30 seconds at resting HR
// Minimum validated window for RR-interval AF screening
// Reference: Taoum et al., Physiol. Meas. (2019)
#define WINDOW_SIZE      30

// Physiological RR bounds 
//Reference https://pubmed.ncbi.nlm.nih.gov/8598068/
// 300ms = 200 BPM | 2000ms = 30 BPM
#define MIN_RR_INTERVAL  300
#define MAX_RR_INTERVAL  2000

// CLASSIFICATION THRESHOLDS
// CV > 0.15: primary AF discriminator
// Reference: https://www.mdpi.com/2077-0383/11/14/4004
#define CV_THRESHOLD     0.15f

// RMSSD > 40ms: conservative margin above 34.5ms ROC cutoff
// Ref: https://www.medrxiv.org/content/10.1101/2023.08.29.23294803v1.full
#define RMSSD_THRESHOLD  40.0f

// pNN50 > 43%: matches 43.5% ROC-derived cutoff
// Ref: https://www.medrxiv.org/content/10.1101/2023.08.29.23294803v1.full
#define PNN50_THRESHOLD  43.0f

// ADAPTIVE THRESHOLD PARAMETERS
// Threshold sits at midpoint between baseline and peak
// Raise toward 0.6 if false peaks appear on your signal
#define THRESHOLD_RATIO  0.5f

// Baseline EMA: very slow — only tracks slow wander
// Peak EMA: faster — tracks signal amplitude changes
#define BASELINE_ALPHA   0.005f
#define PEAK_ALPHA       0.05f

// Minimum peak-to-baseline amplitude to enable detection
// Prevents false triggers when no electrode is connected
#define MIN_AMPLITUDE    100

// Calibration duration (ms)
// 5 seconds captures ~5-6 full cardiac cycles at 70 BPM
// ensuring EMA is stably initialised before detection starts
#define CALIBRATION_MS   5000

// DATA STRUCTURE
struct AFReading {
  unsigned long timestamp;
  float mean_rr;
  float std_rr;
  float cv;
  float mean_hr;
  float rmssd;
  float pnn50;
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

// Forward declaration
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
        Serial.print("Sent count: "); Serial.println(count);
      }
    }
  }
};


// BLE DATA TRANSFER
void sendAllReadings() {
  int total = preferences.getInt("count", 0);
  Serial.print("Sending "); Serial.print(total); Serial.println(" readings...");

  for (int i = 0; i < total; i++) {
    char key[20];
    sprintf(key, "r%d", i);
    AFReading reading;
    preferences.getBytes(key, &reading, sizeof(AFReading));

    String s = String(reading.timestamp)      + "," +
               String(reading.mean_hr,   1)   + "," +
               String(reading.af_prediction)  + "," +
               String(reading.confidence);

    pReadCharacteristic->setValue(s.c_str());
    pReadCharacteristic->notify();
    delay(50);

    if ((i + 1) % 10 == 0) {
      Serial.print("  Sent "); Serial.print(i + 1);
      Serial.print("/"); Serial.println(total);
    }
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
// Features: Mean RR, Std RR, CV, Mean HR, RMSSD, pNN50
void calculateFeatures(int* rr_intervals, int count, float* features) {
  if (count < 5) return;

  // Mean RR
  float sum = 0;
  for (int i = 0; i < count; i++) sum += rr_intervals[i];
  float mean_rr = sum / count;

  // Standard deviation RR
  float variance = 0;
  for (int i = 0; i < count; i++) {
    float diff = rr_intervals[i] - mean_rr;
    variance += diff * diff;
  }
  float std_rr  = sqrt(variance / count);

  // CV and Mean HR
  float cv      = std_rr / mean_rr;
  float mean_hr = 60000.0f / mean_rr;

  // RMSSD and pNN50
  // pNN50 threshold: 50ms per established HRV convention
  float sum_sq   = 0;
  int   dc       = 0;
  int   pnn50c   = 0;

  for (int i = 0; i < count - 1; i++) {
    int diff = rr_intervals[i + 1] - rr_intervals[i];
    sum_sq += (float)diff * diff;
    if (abs(diff) > 50) pnn50c++;
    dc++;
  }

  float rmssd = sqrt(sum_sq / dc);
  float pnn50 = (float)pnn50c / dc * 100.0f;

  features[0] = mean_rr;
  features[1] = std_rr;
  features[2] = cv;
  features[3] = mean_hr;
  features[4] = rmssd;
  features[5] = pnn50;
}

// CLASSIFIER

int predictAF(float* features, int* confidence) {
  float cv    = features[2];
  float rmssd = features[4];
  float pnn50 = features[5];

  int af_score = 0;

  if (cv    > CV_THRESHOLD)    af_score += 2;  // strongest discriminator
  if (rmssd > RMSSD_THRESHOLD) af_score += 2;  // high beat-to-beat variation
  if (pnn50 > PNN50_THRESHOLD) af_score += 1;  // frequent large RR changes

  *confidence = (af_score * 100) / 5;

  Serial.print("  AF Score : "); Serial.print(af_score);
  Serial.print(" / 5  ("); Serial.print(*confidence); Serial.println("%)");

  Serial.print("  CV       : "); Serial.print(cv, 4);
  Serial.print(cv > CV_THRESHOLD ? "  > 0.15 [FLAG]" : "  < 0.15 [OK]");
  Serial.println();

  Serial.print("  RMSSD    : "); Serial.print(rmssd, 2);
  Serial.print(rmssd > RMSSD_THRESHOLD ? "ms  > 40ms [FLAG]" : "ms  < 40ms [OK]");
  Serial.println();

  Serial.print("  pNN50    : "); Serial.print(pnn50, 1);
  Serial.print(pnn50 > PNN50_THRESHOLD ? "%   > 43% [FLAG]" : "%   < 43% [OK]");
  Serial.println();

  return (af_score >= 3) ? 1 : 0;
}


// FLASH STORAGE
void storeReading(float* features, int prediction, int confidence) {
  AFReading reading;
  reading.timestamp     = millis();
  reading.mean_rr       = features[0];
  reading.std_rr        = features[1];
  reading.cv            = features[2];
  reading.mean_hr       = features[3];
  reading.rmssd         = features[4];
  reading.pnn50         = features[5];
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
    Serial.print("  Std RR    : "); Serial.print(r.std_rr, 2);   Serial.println(" ms");
    Serial.print("  CV        : "); Serial.println(r.cv, 4);
    Serial.print("  Mean HR   : "); Serial.print(r.mean_hr, 1);  Serial.println(" BPM");
    Serial.print("  RMSSD     : "); Serial.print(r.rmssd, 2);    Serial.println(" ms");
    Serial.print("  pNN50     : "); Serial.print(r.pnn50, 1);    Serial.println(" %");
    Serial.print("  Result    : "); Serial.println(r.af_prediction == 1 ? "POSSIBLE AF" : "NORMAL");
    Serial.print("  Confidence: "); Serial.print(r.confidence);  Serial.println("%");
    Serial.println("----------------------------------------");
  }
  Serial.println("========================================\n");
}

// ADAPTIVE THRESHOLD R-PEAK DETECTION
void detectRPeak(int currentValue, unsigned long currentTime) {

  float fval = (float)currentValue;

  // Update baseline — always runs, very slow
  adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * (fval - adaptiveBaseline);

  // Update peak — only when signal is above current threshold
  if (fval > adaptiveThreshold) {
    adaptivePeak = adaptivePeak + PEAK_ALPHA * (fval - adaptivePeak);
  }

  // Recompute threshold
  float amplitude   = adaptivePeak - adaptiveBaseline;
  adaptiveThreshold = adaptiveBaseline + THRESHOLD_RATIO * amplitude;

  // Amplitude guard — suspend if signal too flat (no electrode)
  if (amplitude < MIN_AMPLITUDE) {
    peakDetected = false;
    lastValue    = currentValue;
    return;
  }

  // Rising edge detection
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
        float sum  = 0;
        for (int i = 0; i < validBeats; i++) sum += rrIntervals[i];
        avgBPM = 60000.0f / (sum / validBeats);

        Serial.print("Beat ");   Serial.print(validBeats);
        Serial.print("/");       Serial.print(WINDOW_SIZE);
        Serial.print(" | RR: "); Serial.print(rrInterval);
        Serial.print(" ms | BPM: "); Serial.print(currentBPM, 1);
        Serial.print(" | Avg: "); Serial.print(avgBPM, 1);
        Serial.print(" | Thr: "); Serial.println((int)adaptiveThreshold);
      }
    }
    lastPeakTime = currentTime;
    peakDetected = true;
  }

  // Refractory reset — must fall 20% below threshold
  if (fval < adaptiveThreshold - 0.2f * amplitude) {
    peakDetected = false;
  }

  lastValue = currentValue;
}

// ─────────────────────────────────────────────────────────
// SETUP
// ─────────────────────────────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n================================");
  Serial.println("AF Detection System v5.0");
  Serial.println("================================");
  // Serial.println("Window : 30 beats (~30 seconds)");
  // Serial.println("RMSSD  : >40ms threshold");
  // Serial.println("pNN50  : >43% threshold");
  // Serial.println("CV     : >0.15 threshold");
  // Serial.println("================================\n");

  // LEDs
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED,   OUTPUT);
  pinMode(BLUE_LED,  OUTPUT);

  Serial.println("Testing LEDs ");
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   HIGH); delay(300); digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  HIGH); delay(300); digitalWrite(BLUE_LED,  LOW);
  Serial.println("LEDs OK\n");

  // Flash storage
  preferences.begin("af-storage", false);
  int storedCount = preferences.getInt("count", 0);
  Serial.print("Stored readings: "); Serial.println(storedCount);
  printStoredReadings();

  // BLE
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

  // ECG pins
  pinMode(ECG_PIN,      INPUT);
  pinMode(LO_PLUS_PIN,  INPUT);
  pinMode(LO_MINUS_PIN, INPUT);

  // ADAPTIVE THRESHOLD CALIBRATION
  

  Serial.println("================================");
  Serial.println("Calibrating adaptive threshold");
  Serial.println("Place fingers on electrodes now");
  Serial.println("Hold still for 5 seconds ");
  Serial.println("================================");

  unsigned long calStart = millis();
  unsigned long calEnd   = calStart + CALIBRATION_MS;
  bool calBlink = false;
  unsigned long lastCalBlink = 0;

  while (millis() < calEnd) {
    // Slow blue blink during calibration
    if (millis() - lastCalBlink > 500) {
      calBlink = !calBlink;
      digitalWrite(BLUE_LED, calBlink);
      lastCalBlink = millis();
    }

    int v = analogRead(ECG_PIN);

    // Update baseline EMA
    adaptiveBaseline = adaptiveBaseline + BASELINE_ALPHA * (v - adaptiveBaseline);

    // Update peak estimate — track running max with slow decay
    if ((float)v > adaptivePeak) {
      adaptivePeak = (float)v;
    } else {
      adaptivePeak = adaptivePeak * 0.999f;
    }

    // Recompute threshold
    adaptiveThreshold = adaptiveBaseline +
                        THRESHOLD_RATIO * (adaptivePeak - adaptiveBaseline);

    delay(4);
  }

  digitalWrite(BLUE_LED, LOW);

  unsigned long elapsed = millis() - calStart;
  Serial.print("Calibration complete (");
  Serial.print(elapsed);
  Serial.println(" ms)");
  Serial.print("  Baseline  : "); Serial.println((int)adaptiveBaseline);
  Serial.print("  Peak est  : "); Serial.println((int)adaptivePeak);
  Serial.print("  Amplitude : "); Serial.println((int)(adaptivePeak - adaptiveBaseline));
  Serial.print("  Threshold : "); Serial.println((int)adaptiveThreshold);

  if ((adaptivePeak - adaptiveBaseline) < MIN_AMPLITUDE) {
    Serial.println("  WARNING: Low signal amplitude detected.");
    Serial.println("  Check electrode contact and retry.");
    showError();
  } else {
    Serial.println("  Signal quality: OK");
  }

  Serial.println("================================");
  Serial.println("Measurement starting ");
  Serial.print("Collecting "); Serial.print(WINDOW_SIZE);
  Serial.println(" beats before analysis.");
  Serial.println("================================\n");
}

// ─────────────────────────────────────────────────────────
// LOOP
// ─────────────────────────────────────────────────────────

void loop() {
  // BLE reconnection handling
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Lead-off detection
  bool leadsOff = digitalRead(LO_PLUS_PIN) || digitalRead(LO_MINUS_PIN);

  if (leadsOff) {
    showError();
    // Reset adaptive state — will re-calibrate on next stable contact
    adaptiveBaseline  = 1800.0f;
    adaptivePeak      = 2000.0f;
    adaptiveThreshold = 1900.0f;
    validBeats = 0;
    rrIndex    = 0;
    Serial.println("Electrodes disconnected - threshold reset");
    delay(1000);
    return;
  }

  int ecgValue        = analogRead(ECG_PIN);
  unsigned long nowMs = millis();

  // LED feedback during data collection
  if (validBeats < WINDOW_SIZE) {
    validBeats > 0 ? showProcessing() : showIdle();
  }

  detectRPeak(ecgValue, nowMs);

  // Analysis triggered after WINDOW_SIZE (30) beats collected
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();

    Serial.println("\n================================");
    Serial.println("30 beats collected — Analysing...........");
    Serial.println("================================");

    float features[6];
    calculateFeatures(rrIntervals, WINDOW_SIZE, features);

    Serial.println("\nHRV Features:");
    Serial.print("  Mean RR : "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  Std RR  : "); Serial.print(features[1], 2); Serial.println(" ms");
    Serial.print("  CV      : "); Serial.println(features[2], 4);
    Serial.print("  Mean HR : "); Serial.print(features[3], 1); Serial.println(" BPM");
    Serial.print("  RMSSD   : "); Serial.print(features[4], 2); Serial.println(" ms");
    Serial.print("  pNN50   : "); Serial.print(features[5], 1); Serial.println(" %");
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

    // Reset for next measurement
    validBeats = 0;
    rrIndex    = 0;
    delay(5000);
  }

  delay(4);
}