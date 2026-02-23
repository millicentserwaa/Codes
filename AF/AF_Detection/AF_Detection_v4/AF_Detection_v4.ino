/*
 * AF Detection System v3.0
 * With Flash Storage + LED Indicators + BLE Transfer
 */

#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

Preferences preferences;

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_READ      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_UUID_CONTROL   "beb5483e-36e1-4688-b7f5-ea07361b26a9"

BLEServer* pServer = NULL;
BLECharacteristic* pReadCharacteristic = NULL;
BLECharacteristic* pControlCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Pin configuration
#define ECG_PIN 34
#define LO_PLUS_PIN 26
#define LO_MINUS_PIN 27

// LED Pins
#define GREEN_LED 25
#define RED_LED 33
#define BLUE_LED 32

// Algorithm parameters
#define THRESHOLD 2000
#define MIN_RR_INTERVAL 300
#define MAX_RR_INTERVAL 2000
#define WINDOW_SIZE 10

// Data structure
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

// Global variables
int rrIntervals[WINDOW_SIZE];
int rrIndex = 0;
int validBeats = 0;
unsigned long lastPeakTime = 0;
int lastValue = 0;
bool peakDetected = false;
float currentBPM = 0;
float avgBPM = 0;
unsigned long lastBlink = 0;
bool blueState = false;

// Forward declaration
void sendAllReadings();

// BLE Server Callbacks
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println(" Phone connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println(" Phone disconnected!");
    }
};

// BLE Control Callback
class ControlCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      
      if (value.length() > 0) {
        Serial.print(" Received command: ");
        Serial.println(value);
        
        if (value == "GET_DATA") {
          sendAllReadings();
        } else if (value == "CLEAR_DATA") {
          preferences.clear();
          Serial.println(" Data cleared via BLE");
          pReadCharacteristic->setValue("CLEARED");
          pReadCharacteristic->notify();
        } else if (value == "GET_COUNT") {
          int count = preferences.getInt("count", 0);
          String countStr = "COUNT:" + String(count);
          pReadCharacteristic->setValue(countStr.c_str());
          pReadCharacteristic->notify();
          Serial.print(" Sent count: ");
          Serial.println(count);
        }
      }
    }
};

void sendAllReadings() {
  int totalReadings = preferences.getInt("count", 0);
  
  Serial.print(" Sending ");
  Serial.print(totalReadings);
  Serial.println(" readings ");
  
  for (int i = 0; i < totalReadings; i++) {
    char key[20];
    sprintf(key, "r%d", i);
    
    AFReading reading;
    preferences.getBytes(key, &reading, sizeof(AFReading));
    
    String dataStr = String(reading.timestamp) + "," +
                     String(reading.mean_hr, 1) + "," +
                     String(reading.af_prediction) + "," +
                     String(reading.confidence);
    
    pReadCharacteristic->setValue(dataStr.c_str());
    pReadCharacteristic->notify();
    
    delay(50);
    
    if ((i + 1) % 10 == 0) {
      Serial.print("  Sent ");
      Serial.print(i + 1);
      Serial.print("/");
      Serial.println(totalReadings);
    }
  }
  
  pReadCharacteristic->setValue("END");
  pReadCharacteristic->notify();
  
  Serial.println(" All readings sent!");
}

// LED Functions
void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(BLUE_LED, LOW);
}

void showNormalResult() {
  allLedsOff();
  digitalWrite(GREEN_LED, HIGH);
  Serial.println(" LED: GREEN ON");
  delay(5000);
  allLedsOff();
}

void showAFResult() {
  allLedsOff();
  Serial.println(" LED: RED PULSING");
  
  for (int i = 0; i < 10; i++) {
    for (int brightness = 0; brightness < 255; brightness += 5) {
      analogWrite(RED_LED, brightness);
      delay(10);
    }
    for (int brightness = 255; brightness > 0; brightness -= 5) {
      analogWrite(RED_LED, brightness);
      delay(10);
    }
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
    digitalWrite(RED_LED, HIGH);
    digitalWrite(BLUE_LED, HIGH);
    delay(100);
    allLedsOff();
    delay(100);
  }
}

void calculateFeatures(int* rr_intervals, int count, float* features) {
  if (count < 5) return;
  
  float sum = 0;
  for (int i = 0; i < count; i++) sum += rr_intervals[i];
  float mean_rr = sum / count;
  
  float variance = 0;
  for (int i = 0; i < count; i++) {
    float diff = rr_intervals[i] - mean_rr;
    variance += diff * diff;
  }
  float std_rr = sqrt(variance / count);
  
  float cv = std_rr / mean_rr;
  float mean_hr = 60000.0 / mean_rr;
  
  float sum_squared_diffs = 0;
  int diff_count = 0;
  int pnn50_count = 0;
  
  for (int i = 0; i < count - 1; i++) {
    int diff = rr_intervals[i+1] - rr_intervals[i];
    sum_squared_diffs += diff * diff;
    if (abs(diff) > 50) pnn50_count++;
    diff_count++;
  }
  
  float rmssd = sqrt(sum_squared_diffs / diff_count);
  float pnn50 = (float)pnn50_count / diff_count * 100.0;
  
  features[0] = mean_rr;
  features[1] = std_rr;
  features[2] = cv;
  features[3] = mean_hr;
  features[4] = rmssd;
  features[5] = pnn50;
}

int predictAF(float* features, int* confidence) {
  float cv = features[2];
  float rmssd = features[4];
  float pnn50 = features[5];
  
  int af_score = 0;
  
  if (cv > 0.15) af_score += 2;
  if (rmssd > 80.0) af_score += 2;
  if (pnn50 > 50.0) af_score += 1;
  
  *confidence = (af_score * 100) / 5;
  
  Serial.print("AF Risk Score: ");
  Serial.print(af_score);
  Serial.print(" / 5 (");
  Serial.print(*confidence);
  Serial.println("%)");
  
  return (af_score >= 3) ? 1 : 0;
}

//Storing the Data
void storeReading(float* features, int prediction, int confidence) {
  AFReading reading;
  reading.timestamp = millis();
  reading.mean_rr = features[0];
  reading.std_rr = features[1];
  reading.cv = features[2];
  reading.mean_hr = features[3];
  reading.rmssd = features[4];
  reading.pnn50 = features[5];
  reading.af_prediction = prediction;
  reading.confidence = confidence;
  
  int readingCount = preferences.getInt("count", 0);
  
  char key[20];
  sprintf(key, "r%d", readingCount);
  preferences.putBytes(key, &reading, sizeof(AFReading));
  
  preferences.putInt("count", readingCount + 1);
  
  Serial.print(" Stored reading #");
  Serial.println(readingCount + 1);
}

//Printing the stored data in serial monitor 
void printStoredReadings() {
  int count = preferences.getInt("count", 0);
  
  if (count == 0) {
    Serial.println("No stored readings found.");
    return;
  }
  
  Serial.println("\n========================================");
  Serial.println("STORED READINGS FROM FLASH");
  Serial.println("========================================");
  Serial.print("Total readings: ");
  Serial.println(count);
  //Serial.println("----------------------------------------");
  
  for (int i = 0; i < count; i++) {
    char key[20];
    sprintf(key, "r%d", i);
    
    AFReading reading;
    preferences.getBytes(key, &reading, sizeof(AFReading));
    
    Serial.print("Reading #"); Serial.println(i + 1);
    Serial.print("  Timestamp (ms): "); Serial.println(reading.timestamp);
    Serial.print("  Mean RR:        "); Serial.print(reading.mean_rr, 2); Serial.println(" ms");
    Serial.print("  Std RR:         "); Serial.print(reading.std_rr, 2); Serial.println(" ms");
    Serial.print("  CV:             "); Serial.println(reading.cv, 4);
    Serial.print("  Mean HR:        "); Serial.print(reading.mean_hr, 1); Serial.println(" BPM");
    Serial.print("  RMSSD:          "); Serial.print(reading.rmssd, 2); Serial.println(" ms");
    Serial.print("  pNN50:          "); Serial.print(reading.pnn50, 1); Serial.println(" %");
    Serial.print("  Prediction:     "); Serial.println(reading.af_prediction == 1 ? "POSSIBLE AF" : "NORMAL");
    Serial.print("  Confidence:     "); Serial.print(reading.confidence); Serial.println("%");
    Serial.println("----------------------------------------");
  }
  Serial.println("========================================\n");
}


void detectRPeak(int currentValue, unsigned long currentTime) {
  if (lastValue < THRESHOLD && currentValue >= THRESHOLD && !peakDetected) {
    if (lastPeakTime > 0) {
      int rrInterval = currentTime - lastPeakTime;
      
      if (rrInterval >= MIN_RR_INTERVAL && rrInterval <= MAX_RR_INTERVAL) {
        rrIntervals[rrIndex] = rrInterval;
        rrIndex = (rrIndex + 1) % WINDOW_SIZE;
        if (validBeats < WINDOW_SIZE) validBeats++;
        
        currentBPM = 60000.0 / rrInterval;
        
        if (validBeats > 0) {
          float sum = 0;
          for (int i = 0; i < validBeats; i++) {
            sum += rrIntervals[i];
          }
          avgBPM = 60000.0 / (sum / validBeats);
        }
        
        Serial.print("Beat | RR: ");
        Serial.print(rrInterval);
        Serial.print(" ms | BPM: ");
        Serial.print(currentBPM, 1);
        Serial.print(" | Avg: ");
        Serial.println(avgBPM, 1);
      }
    }
    lastPeakTime = currentTime;
    peakDetected = true;
  }
  
  if (currentValue < THRESHOLD - 200) {
    peakDetected = false;
  }
  lastValue = currentValue;
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n================================");
  Serial.println("AF Detection System v3.0");
  Serial.println("With BLE Transfer");
  Serial.println("================================\n");
  
  // Initialize LEDs
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BLUE_LED, OUTPUT);
  
  Serial.println("Testing LEDs ");
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, HIGH); delay(300); digitalWrite(RED_LED, LOW);
  digitalWrite(BLUE_LED, HIGH); delay(300); digitalWrite(BLUE_LED, LOW);
  Serial.println(" LEDs OK\n");
  
  // Initialize Flash
  preferences.begin("af-storage", false);
  int storedCount = preferences.getInt("count", 0);
  Serial.print("Stored readings: ");
  Serial.println(storedCount);
  printStoredReadings();
  
  // Initialize BLE
  Serial.println("\nInitializing BLE ");
  BLEDevice::init("AF_Monitor");
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pReadCharacteristic = pService->createCharacteristic(
                          CHAR_UUID_READ,
                          BLECharacteristic::PROPERTY_READ |
                          BLECharacteristic::PROPERTY_NOTIFY
                        );
  pReadCharacteristic->addDescriptor(new BLE2902());
  
  pControlCharacteristic = pService->createCharacteristic(
                            CHAR_UUID_CONTROL,
                            BLECharacteristic::PROPERTY_WRITE
                          );
  pControlCharacteristic->setCallbacks(new ControlCallbacks());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println(" BLE Ready!");
  Serial.println(" Device name: AF_Monitor");
  Serial.println(" Waiting for phone connection \n");
  
  pinMode(ECG_PIN, INPUT);
  pinMode(LO_PLUS_PIN, INPUT);
  pinMode(LO_MINUS_PIN, INPUT);
  
  Serial.println("System ready!\n");
}

void loop() {
  // Handle BLE connection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println(" Advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  // ECG monitoring
  bool leadsOff = digitalRead(LO_PLUS_PIN) == 1 || digitalRead(LO_MINUS_PIN) == 1;
  
  if (leadsOff) {
    showError();
    Serial.println(" Electrodes disconnected!");
    delay(1000);
    return;
  }
  
  int ecgValue = analogRead(ECG_PIN);
  unsigned long currentTime = millis();
  
  if (validBeats < WINDOW_SIZE) {
    if (validBeats > 0) {
      showProcessing();
    } else {
      showIdle();
    }
  }
  
  detectRPeak(ecgValue, currentTime);
  
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();
    
    Serial.println("\n================================");
    Serial.println("Analyzing ");
    Serial.println("================================");
    
    float features[6];
    calculateFeatures(rrIntervals, validBeats, features);
    
    Serial.println("\nHRV Metrics:");
    Serial.print("  Mean RR: "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  CV: "); Serial.println(features[2], 4);
    Serial.print("  Mean HR: "); Serial.print(features[3], 1); Serial.println(" BPM");
    Serial.print("  RMSSD: "); Serial.print(features[4], 2); Serial.println(" ms");
    
    int confidence;
    int prediction = predictAF(features, &confidence);
    
    Serial.println("\n================================");
    Serial.println("RESULT:");
    Serial.println("================================");
    
    if (prediction == 1) {
      Serial.println(" RHYTHM: Possible AF");
      showAFResult();
    } else {
      Serial.println(" RHYTHM: Normal");
      showNormalResult();
    }
    Serial.println("================================\n");
    
    storeReading(features, prediction, confidence);
    
    validBeats = 0;
    rrIndex = 0;
    delay(5000);
  }
  
  delay(4);
}