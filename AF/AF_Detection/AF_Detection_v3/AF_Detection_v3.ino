/*
 * AF Detection System v2.1
 * With Flash Storage + LED Indicators
 */

#include <Preferences.h>

Preferences preferences;

// Pin configuration
#define ECG_PIN 34
#define LO_PLUS_PIN 26
#define LO_MINUS_PIN 27

// LED Pins
#define GREEN_LED 25   // Normal rhythm
#define RED_LED 33     // Possible AF
#define BLUE_LED 32    // Processing/Status

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

// LED control variables
unsigned long lastBlink = 0;
bool blueState = false;

// LED Functions
void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(BLUE_LED, LOW);
}

void showNormalResult() {
  allLedsOff();
  digitalWrite(GREEN_LED, HIGH);
  Serial.println("💚 LED: GREEN ON (Normal Rhythm)");
  delay(5000);  // Keep green on for 5 seconds
  allLedsOff();
}

void showAFResult() {
  allLedsOff();
  Serial.println("❤️ LED: RED PULSING (Possible AF)");
  
  // Pulse red LED for 5 seconds
  for (int i = 0; i < 10; i++) {
    // Fade in
    for (int brightness = 0; brightness < 255; brightness += 5) {
      analogWrite(RED_LED, brightness);
      delay(10);
    }
    // Fade out
    for (int brightness = 255; brightness > 0; brightness -= 5) {
      analogWrite(RED_LED, brightness);
      delay(10);
    }
  }
  
  allLedsOff();
}

void showProcessing() {
  // Fast blink blue LED
  if (millis() - lastBlink > 200) {
    blueState = !blueState;
    digitalWrite(BLUE_LED, blueState);
    lastBlink = millis();
  }
}

void showIdle() {
  // Slow blink blue LED
  if (millis() - lastBlink > 1000) {
    blueState = !blueState;
    digitalWrite(BLUE_LED, blueState);
    lastBlink = millis();
  }
}

void showError() {
  // Quick flash all LEDs
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
  Serial.println("% confidence)");
  
  return (af_score >= 3) ? 1 : 0;
}

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
  
  Serial.print("✓ Stored reading #");
  Serial.print(readingCount + 1);
  Serial.println(" to Flash");
}

void printStoredReadings() {
  int totalReadings = preferences.getInt("count", 0);
  
  Serial.println("\n================================");
  Serial.println("STORED READINGS:");
  Serial.println("================================");
  Serial.print("Total: ");
  Serial.println(totalReadings);
  
  for (int i = 0; i < totalReadings; i++) {
    char key[20];
    sprintf(key, "r%d", i);
    
    AFReading reading;
    preferences.getBytes(key, &reading, sizeof(AFReading));
    
    Serial.print("#");
    Serial.print(i + 1);
    Serial.print(" | Time: ");
    Serial.print(reading.timestamp / 1000);
    Serial.print("s | HR: ");
    Serial.print(reading.mean_hr, 1);
    Serial.print(" BPM | AF: ");
    Serial.print(reading.af_prediction ? "YES" : "NO");
    Serial.print(" (");
    Serial.print(reading.confidence);
    Serial.println("%)");
  }
  Serial.println("================================\n");
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
  Serial.println("AF Detection System v2.1");
  Serial.println("With LED Indicators");
  Serial.println("================================\n");
  
  // Initialize LED pins
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BLUE_LED, OUTPUT);
  
  // Test LEDs
  Serial.println("Testing LEDs...");
  digitalWrite(GREEN_LED, HIGH);
  delay(500);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, HIGH);
  delay(500);
  digitalWrite(RED_LED, LOW);
  digitalWrite(BLUE_LED, HIGH);
  delay(500);
  digitalWrite(BLUE_LED, LOW);
  Serial.println("✓ LED test complete\n");
  
  // Initialize Flash storage
  preferences.begin("af-storage", false);
  
  int storedCount = preferences.getInt("count", 0);
  Serial.print("Previous readings: ");
  Serial.println(storedCount);
  
  pinMode(ECG_PIN, INPUT);
  pinMode(LO_PLUS_PIN, INPUT);
  pinMode(LO_MINUS_PIN, INPUT);
  
  Serial.println("\nCommands:");
  Serial.println("  'view' - See stored readings");
  Serial.println("  'clear' - Erase all data");
  Serial.println("\nLED Indicators:");
  Serial.println("  🔵 BLUE - Processing");
  Serial.println("  💚 GREEN - Normal Rhythm");
  Serial.println("  ❤️ RED - Possible AF");
  Serial.println("\nSystem ready!\n");
}

void loop() {
  // Check for serial commands
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command == "view") {
      printStoredReadings();
    } else if (command == "clear") {
      preferences.clear();
      Serial.println("✓ All data cleared");
    }
  }
  
  bool leadsOff = digitalRead(LO_PLUS_PIN) == 1 || digitalRead(LO_MINUS_PIN) == 1;
  
  if (leadsOff) {
    showError();
    Serial.println("! Electrodes disconnected");
    delay(1000);
    return;
  }
  
  int ecgValue = analogRead(ECG_PIN);
  unsigned long currentTime = millis();
  
  // Show status based on beat collection
  if (validBeats < WINDOW_SIZE) {
    if (validBeats > 0) {
      showProcessing();  // Collecting beats
    } else {
      showIdle();  // Waiting for first beat
    }
  }
  
  detectRPeak(ecgValue, currentTime);
  
  if (validBeats >= WINDOW_SIZE) {
    allLedsOff();
    
    Serial.println("\n================================");
    Serial.println("Analyzing Heart Rhythm...");
    Serial.println("================================");
    
    float features[6];
    calculateFeatures(rrIntervals, validBeats, features);
    
    Serial.println("\nHRV Metrics:");
    Serial.print("  Mean RR:  "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  Std RR:   "); Serial.print(features[1], 2); Serial.println(" ms");
    Serial.print("  CV:       "); Serial.println(features[2], 4);
    Serial.print("  Mean HR:  "); Serial.print(features[3], 1); Serial.println(" BPM");
    Serial.print("  RMSSD:    "); Serial.print(features[4], 2); Serial.println(" ms");
    Serial.print("  pNN50:    "); Serial.print(features[5], 1); Serial.println(" %");
    
    Serial.println("\nRunning Classification...");
    int confidence;
    int prediction = predictAF(features, &confidence);
    
    Serial.println("\n================================");
    Serial.println("RESULT:");
    Serial.println("================================");
    
    if (prediction == 1) {
      Serial.println("⚠ RHYTHM: Possible AF");
      Serial.println("RECOMMENDATION: Seek evaluation");
      showAFResult();  // Red LED pulsing
    } else {
      Serial.println("✓ RHYTHM: Normal");
      Serial.println("No concerns detected");
      showNormalResult();  // Green LED solid
    }
    Serial.println("================================\n");
    
    storeReading(features, prediction, confidence);
    
    validBeats = 0;
    rrIndex = 0;
    delay(5000);  // Wait 5 seconds before next measurement
  }
  
  delay(4);
}
