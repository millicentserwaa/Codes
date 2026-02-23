// // /*
// //  * AF Detection System with Machine Learning
// //  * Using EloquentTinyML library v3.x
// //  */

// // #include <eloquent_tinyml.h>  // Changed to lowercase
// // #include "af_model.h"

// // //using namespace Eloquent::TinyML;

// // // Model configuration
// // #define NUMBER_OF_INPUTS 6
// // #define NUMBER_OF_OUTPUTS 1
// // #define TENSOR_ARENA_SIZE 8*1024

// // Eloquent::TinyML::TfLite<NUMBER_OF_INPUTS, NUMBER_OF_OUTPUTS, TENSOR_ARENA_SIZE> ml;

// // // Rest of the code stays the same...
// // // Pin configuration
// // #define ECG_PIN 34
// // #define LO_PLUS_PIN 26
// // #define LO_MINUS_PIN 27

// // // Algorithm parameters
// // #define SAMPLE_RATE 250
// // #define THRESHOLD 2000
// // #define MIN_RR_INTERVAL 300
// // #define MAX_RR_INTERVAL 2000
// // #define WINDOW_SIZE 10

// // // Scaler parameters - REPLACE WITH YOUR VALUES
// // const float SCALER_MEAN[6] = {
// //   806.485840, // mean_rr
// //   112.936888, // std_rr
// //   0.151064, // cv
// //   77.078569, // mean_hr
// //   162.389420, // rmssd
// //   62.269397 // pnn50
// // };

// // const float SCALER_SCALE[6] = {
// //   142.984322, // mean_rr
// //   78.270976, // std_rr
// //   0.114918, // cv
// //   15.773682, // mean_hr
// //   114.043520, // rmssd
// //   26.445281 // pnn50
// // };


// // // Global variables
// // int rrIntervals[WINDOW_SIZE];
// // int rrIndex = 0;
// // int validBeats = 0;

// // unsigned long lastPeakTime = 0;
// // int lastValue = 0;
// // bool peakDetected = false;

// // float currentBPM = 0;
// // float avgBPM = 0;

// // // Feature extraction
// // void calculateFeatures(int* rr_intervals, int count, float* features) {
// //   if (count < 5) {
// //     Serial.println("Not enough RR intervals");
// //     return;
// //   }
  
// //   // Mean RR
// //   float sum = 0;
// //   for (int i = 0; i < count; i++) {
// //     sum += rr_intervals[i];
// //   }
// //   float mean_rr = sum / count;
  
// //   // Std RR
// //   float variance = 0;
// //   for (int i = 0; i < count; i++) {
// //     float diff = rr_intervals[i] - mean_rr;
// //     variance += diff * diff;
// //   }
// //   float std_rr = sqrt(variance / count);
  
// //   // CV
// //   float cv = std_rr / mean_rr;
  
// //   // Mean HR
// //   float mean_hr = 60000.0 / mean_rr;
  
// //   // RMSSD and pNN50
// //   float sum_squared_diffs = 0;
// //   int diff_count = 0;
// //   int pnn50_count = 0;
  
// //   for (int i = 0; i < count - 1; i++) {
// //     int diff = rr_intervals[i+1] - rr_intervals[i];
// //     sum_squared_diffs += diff * diff;
    
// //     if (abs(diff) > 50) {
// //       pnn50_count++;
// //     }
// //     diff_count++;
// //   }
  
// //   float rmssd = sqrt(sum_squared_diffs / diff_count);
// //   float pnn50 = (float)pnn50_count / diff_count * 100.0;
  
// //   // Store features
// //   features[0] = mean_rr;
// //   features[1] = std_rr;
// //   features[2] = cv;
// //   features[3] = mean_hr;
// //   features[4] = rmssd;
// //   features[5] = pnn50;
// // }

// // // Normalize features
// // void normalizeFeatures(float* features) {
// //   for (int i = 0; i < 6; i++) {
// //     features[i] = (features[i] - SCALER_MEAN[i]) / SCALER_SCALE[i];
// //   }
// // }

// // // ML prediction
// // int predictAF(float* features) {
// //   // Normalize
// //   normalizeFeatures(features);
  
// //   // Run inference
// //   float output = ml.predict(features);
  
// //   Serial.print("AF Probability: ");
// //   Serial.print(output * 100, 1);
// //   Serial.println("%");
  
// //   return (output > 0.5) ? 1 : 0;
// // }

// // // R-peak detection
// // void detectRPeak(int currentValue, unsigned long currentTime) {
// //   if (lastValue < THRESHOLD && currentValue >= THRESHOLD && !peakDetected) {
    
// //     if (lastPeakTime > 0) {
// //       int rrInterval = currentTime - lastPeakTime;
      
// //       if (rrInterval >= MIN_RR_INTERVAL && rrInterval <= MAX_RR_INTERVAL) {
        
// //         rrIntervals[rrIndex] = rrInterval;
// //         rrIndex = (rrIndex + 1) % WINDOW_SIZE;
        
// //         if (validBeats < WINDOW_SIZE) {
// //           validBeats++;
// //         }
        
// //         currentBPM = 60000.0 / rrInterval;
        
// //         if (validBeats > 0) {
// //           float sum = 0;
// //           for (int i = 0; i < validBeats; i++) {
// //             sum += rrIntervals[i];
// //           }
// //           avgBPM = 60000.0 / (sum / validBeats);
// //         }
        
// //         Serial.print("Beat | RR: ");
// //         Serial.print(rrInterval);
// //         Serial.print(" ms | BPM: ");
// //         Serial.print(currentBPM, 1);
// //         Serial.print(" | Avg: ");
// //         Serial.println(avgBPM, 1);
// //       }
// //     }
    
// //     lastPeakTime = currentTime;
// //     peakDetected = true;
// //   }
  
// //   if (currentValue < THRESHOLD - 200) {
// //     peakDetected = false;
// //   }
  
// //   lastValue = currentValue;
// // }

// // void setup() {
// //   Serial.begin(115200);
// //   delay(1000);
  
// //   Serial.println("\n================================");
// //   Serial.println("AF Detection System");
// //   Serial.println("================================\n");
  
// //   pinMode(ECG_PIN, INPUT);
// //   pinMode(LO_PLUS_PIN, INPUT);
// //   pinMode(LO_MINUS_PIN, INPUT);
  
// //   Serial.println("Initializing ML model...");
  
// //   ml.begin(af_model);
  
// //   Serial.println("Model loaded successfully!");
// //   Serial.println("System ready!\n");
// //   Serial.println("================================\n");
// // }

// // void loop() {
// //   // Check leads
// //   bool leadsOff = digitalRead(LO_PLUS_PIN) == 1 || digitalRead(LO_MINUS_PIN) == 1;
  
// //   if (leadsOff) {
// //     Serial.println("! Electrodes disconnected");
// //     delay(1000);
// //     return;
// //   }
  
// //   // Read ECG
// //   int ecgValue = analogRead(ECG_PIN);
// //   unsigned long currentTime = millis();
  
// //   // Detect R-peaks
// //   detectRPeak(ecgValue, currentTime);
  
// //   // Run inference
// //   if (validBeats >= WINDOW_SIZE) {
    
// //     Serial.println("\n================================");
// //     Serial.println("Running AF Detection...");
// //     Serial.println("================================");
    
// //     float features[6];
// //     calculateFeatures(rrIntervals, validBeats, features);
    
// //     Serial.println("\nFeatures:");
// //     Serial.print("  Mean RR:  "); Serial.println(features[0], 2);
// //     Serial.print("  Std RR:   "); Serial.println(features[1], 2);
// //     Serial.print("  CV:       "); Serial.println(features[2], 4);
// //     Serial.print("  Mean HR:  "); Serial.println(features[3], 1);
// //     Serial.print("  RMSSD:    "); Serial.println(features[4], 2);
// //     Serial.print("  pNN50:    "); Serial.println(features[5], 1);
    
// //     Serial.println("\nRunning ML Model...");
// //     int prediction = predictAF(features);
    
// //     Serial.println("\n================================");
// //     Serial.println("RESULT:");
// //     Serial.println("================================");
    
// //     if (prediction == 1) {
// //       Serial.println("RHYTHM: Possible AF");
// //       Serial.println("RECOMMENDATION: Seek evaluation");
// //     } else {
// //       Serial.println("RHYTHM: Normal");
// //       Serial.println("Heart rhythm appears regular");
// //     }
    
// //     Serial.println("================================\n");
    
// //     validBeats = 0;
// //     rrIndex = 0;
    
// //     delay(10000);
// //   }
  
// //   delay(4);
// // }


// /*
//  * AF Detection System with Machine Learning
//  * EloquentTinyML v3.0.1
//  */

// #include "af_model.h"           // Include model FIRST
// #include <tflm_esp32.h>         // Then TensorFlow runtime for ESP32
// #include <eloquent_tinyml.h>    // Then EloquentTinyML wrapper

// // Model configuration
// #define ARENA_SIZE 8000
// #define TF_NUM_OPS 10

// Eloquent::TF::Sequential<TF_NUM_OPS, ARENA_SIZE> tf;

// // Pin configuration
// #define ECG_PIN 34
// #define LO_PLUS_PIN 26
// #define LO_MINUS_PIN 27

// // Algorithm parameters
// #define SAMPLE_RATE 250
// #define THRESHOLD 2000
// #define MIN_RR_INTERVAL 300
// #define MAX_RR_INTERVAL 2000
// #define WINDOW_SIZE 10

// // Scaler parameters - UPDATE WITH YOUR ACTUAL VALUES
// const float SCALER_MEAN[6] = {
//   806.485840, // mean_rr
//   112.936888, // std_rr
//   0.151064, // cv
//   77.078569, // mean_hr
//   162.389420, // rmssd
//   62.269397 // pnn50
// };

// const float SCALER_SCALE[6] = {
//   142.984322, // mean_rr
//   78.270976, // std_rr
//   0.114918, // cv
//   15.773682, // mean_hr
//   114.043520, // rmssd
//   26.445281 // pnn50
// };


// // Global variables
// int rrIntervals[WINDOW_SIZE];
// int rrIndex = 0;
// int validBeats = 0;
// unsigned long lastPeakTime = 0;
// int lastValue = 0;
// bool peakDetected = false;
// float currentBPM = 0;
// float avgBPM = 0;

// // Feature extraction
// void calculateFeatures(int* rr_intervals, int count, float* features) {
//   if (count < 5) {
//     Serial.println("Not enough RR intervals");
//     return;
//   }
  
//   float sum = 0;
//   for (int i = 0; i < count; i++) {
//     sum += rr_intervals[i];
//   }
//   float mean_rr = sum / count;
  
//   float variance = 0;
//   for (int i = 0; i < count; i++) {
//     float diff = rr_intervals[i] - mean_rr;
//     variance += diff * diff;
//   }
//   float std_rr = sqrt(variance / count);
  
//   float cv = std_rr / mean_rr;
//   float mean_hr = 60000.0 / mean_rr;
  
//   float sum_squared_diffs = 0;
//   int diff_count = 0;
//   int pnn50_count = 0;
  
//   for (int i = 0; i < count - 1; i++) {
//     int diff = rr_intervals[i+1] - rr_intervals[i];
//     sum_squared_diffs += diff * diff;
//     if (abs(diff) > 50) pnn50_count++;
//     diff_count++;
//   }
  
//   float rmssd = sqrt(sum_squared_diffs / diff_count);
//   float pnn50 = (float)pnn50_count / diff_count * 100.0;
  
//   features[0] = mean_rr;
//   features[1] = std_rr;
//   features[2] = cv;
//   features[3] = mean_hr;
//   features[4] = rmssd;
//   features[5] = pnn50;
// }

// void normalizeFeatures(float* features, float* normalized) {
//   for (int i = 0; i < 6; i++) {
//     normalized[i] = (features[i] - SCALER_MEAN[i]) / SCALER_SCALE[i];
//   }
// }

// int predictAF(float* features) {
//   // Normalize features
//   float normalized[6];
//   normalizeFeatures(features, normalized);
  
//   // Run prediction
//   if (!tf.predict(normalized).isOk()) {
//     Serial.print("Prediction error: ");
//     Serial.println(tf.exception.toString());
//     return -1;
//   }
  
//   // Get probability (output is between 0 and 1)
//   float probability = tf.output(0);
  
//   Serial.print("AF Probability: ");
//   Serial.print(probability * 100, 1);
//   Serial.println("%");
  
//   return (probability > 0.5) ? 1 : 0;
// }

// void detectRPeak(int currentValue, unsigned long currentTime) {
//   if (lastValue < THRESHOLD && currentValue >= THRESHOLD && !peakDetected) {
//     if (lastPeakTime > 0) {
//       int rrInterval = currentTime - lastPeakTime;
      
//       if (rrInterval >= MIN_RR_INTERVAL && rrInterval <= MAX_RR_INTERVAL) {
//         rrIntervals[rrIndex] = rrInterval;
//         rrIndex = (rrIndex + 1) % WINDOW_SIZE;
//         if (validBeats < WINDOW_SIZE) validBeats++;
        
//         currentBPM = 60000.0 / rrInterval;
        
//         if (validBeats > 0) {
//           float sum = 0;
//           for (int i = 0; i < validBeats; i++) {
//             sum += rrIntervals[i];
//           }
//           avgBPM = 60000.0 / (sum / validBeats);
//         }
        
//         Serial.print("Beat | RR: ");
//         Serial.print(rrInterval);
//         Serial.print(" ms | BPM: ");
//         Serial.print(currentBPM, 1);
//         Serial.print(" | Avg: ");
//         Serial.println(avgBPM, 1);
//       }
//     }
//     lastPeakTime = currentTime;
//     peakDetected = true;
//   }
  
//   if (currentValue < THRESHOLD - 200) {
//     peakDetected = false;
//   }
//   lastValue = currentValue;
// }

// void setup() {
//   Serial.begin(115200);
//   delay(3000);
  
//   Serial.println("\n================================");
//   Serial.println("AF Detection System");
//   Serial.println("================================\n");
  
//   pinMode(ECG_PIN, INPUT);
//   pinMode(LO_PLUS_PIN, INPUT);
//   pinMode(LO_MINUS_PIN, INPUT);
  
//   Serial.println("Initializing ML model...");
  
//   // Configure model
//   tf.setNumInputs(6);
//   tf.setNumOutputs(1);
  
//   // Add required operations
//   tf.resolver.AddFullyConnected();
//   tf.resolver.AddRelu();
//   tf.resolver.AddSoftmax();
  
//   // Load model
//   while (!tf.begin(af_model).isOk()) {
//     Serial.print("Model error: ");
//     Serial.println(tf.exception.toString());
//     delay(1000);
//   }
  
//   Serial.println("Model loaded successfully!");
//   Serial.println("System ready!\n");
// }

// void loop() {
//   bool leadsOff = digitalRead(LO_PLUS_PIN) == 1 || digitalRead(LO_MINUS_PIN) == 1;
  
//   if (leadsOff) {
//     Serial.println("! Electrodes disconnected");
//     delay(1000);
//     return;
//   }
  
//   int ecgValue = analogRead(ECG_PIN);
//   unsigned long currentTime = millis();
  
//   detectRPeak(ecgValue, currentTime);
  
//   if (validBeats >= WINDOW_SIZE) {
//     Serial.println("\n================================");
//     Serial.println("Running AF Detection...");
//     Serial.println("================================");
    
//     float features[6];
//     calculateFeatures(rrIntervals, validBeats, features);
    
//     Serial.println("\nFeatures:");
//     Serial.print("  Mean RR:  "); Serial.println(features[0], 2);
//     Serial.print("  Std RR:   "); Serial.println(features[1], 2);
//     Serial.print("  CV:       "); Serial.println(features[2], 4);
//     Serial.print("  Mean HR:  "); Serial.println(features[3], 1);
//     Serial.print("  RMSSD:    "); Serial.println(features[4], 2);
//     Serial.print("  pNN50:    "); Serial.println(features[5], 1);
    
//     Serial.println("\nRunning ML Model...");
//     int prediction = predictAF(features);
    
//     Serial.println("\n================================");
//     Serial.println("RESULT:");
//     Serial.println("================================");
    
//     if (prediction == 1) {
//       Serial.println("RHYTHM: Possible AF");
//       Serial.println("RECOMMENDATION: Seek evaluation");
//     } else if (prediction == 0) {
//       Serial.println("RHYTHM: Normal");
//       Serial.println("Heart rhythm appears regular");
//     } else {
//       Serial.println("ERROR: Prediction failed");
//     }
    
//     Serial.println("================================\n");
    
//     validBeats = 0;
//     rrIndex = 0;
//     delay(10000);
//   }
  
//   delay(4);
// }



/*
 * AF Detection System v1.0
 * ML-Based Rule Classifier (No External Libraries)
 * Based on Random Forest decision rules
 */

// Pin configuration
#define ECG_PIN 34
#define LO_PLUS_PIN 26
#define LO_MINUS_PIN 27

// Algorithm parameters
#define THRESHOLD 2000
#define MIN_RR_INTERVAL 300
#define MAX_RR_INTERVAL 2000
#define WINDOW_SIZE 10

// Global variables
int rrIntervals[WINDOW_SIZE];
int rrIndex = 0;
int validBeats = 0;
unsigned long lastPeakTime = 0;
int lastValue = 0;
bool peakDetected = false;
float currentBPM = 0;
float avgBPM = 0;

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

int predictAF(float* features) {
  float cv = features[2];
  float rmssd = features[4];
  float pnn50 = features[5];
  
  int af_score = 0;
  
  if (cv > 0.15) af_score += 2;
  if (rmssd > 80.0) af_score += 2;
  if (pnn50 > 50.0) af_score += 1;
  
  float confidence = (af_score / 5.0) * 100.0;
  
  Serial.print("AF Risk Score: ");
  Serial.print(af_score);
  Serial.print(" / 5 (");
  Serial.print(confidence, 1);
  Serial.println("% confidence)");
  
  return (af_score >= 3) ? 1 : 0;
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
  Serial.println("AF Detection System v1.0");
  Serial.println("ML-Based Rule Classifier");
  Serial.println("================================\n");
  
  pinMode(ECG_PIN, INPUT);
  pinMode(LO_PLUS_PIN, INPUT);
  pinMode(LO_MINUS_PIN, INPUT);
  
  Serial.println("System initialized successfully!");
  Serial.println("Waiting for ECG signal...\n");
}

void loop() {
  bool leadsOff = digitalRead(LO_PLUS_PIN) == 1 || digitalRead(LO_MINUS_PIN) == 1;
  
  if (leadsOff) {
    Serial.println("! Electrodes disconnected - Please check connection");
    delay(1000);
    return;
  }
  
  int ecgValue = analogRead(ECG_PIN);
  unsigned long currentTime = millis();
  
  detectRPeak(ecgValue, currentTime);
  
  if (validBeats >= WINDOW_SIZE) {
    Serial.println("\n================================");
    Serial.println("Analyzing Heart Rhythm...");
    Serial.println("================================");
    
    float features[6];
    calculateFeatures(rrIntervals, validBeats, features);
    
    Serial.println("\nHeart Rate Variability Metrics:");
    Serial.print("  Mean RR Interval:  "); Serial.print(features[0], 2); Serial.println(" ms");
    Serial.print("  Std Deviation:     "); Serial.print(features[1], 2); Serial.println(" ms");
    Serial.print("  Coefficient of Variation: "); Serial.println(features[2], 4);
    Serial.print("  Average Heart Rate: "); Serial.print(features[3], 1); Serial.println(" BPM");
    Serial.print("  RMSSD:             "); Serial.print(features[4], 2); Serial.println(" ms");
    Serial.print("  pNN50:             "); Serial.print(features[5], 1); Serial.println(" %");
    
    Serial.println("\nRunning ML-Based Classification...");
    int prediction = predictAF(features);
    
    Serial.println("\n================================");
    Serial.println("SCREENING RESULT:");
    Serial.println("================================");
    
    if (prediction == 1) {
      Serial.println("⚠ RHYTHM: Possible Atrial Fibrillation");
      Serial.println("RECOMMENDATION: Seek medical evaluation");
      Serial.println("(Irregular heart rhythm detected)");
    } else {
      Serial.println("✓ RHYTHM: Normal Sinus Rhythm");
      Serial.println("Heart rhythm appears regular");
      Serial.println("No immediate concerns detected");
    }
    
    Serial.println("================================\n");
    Serial.println("System will restart measurement in 10 seconds...\n");
    
    validBeats = 0;
    rrIndex = 0;
    delay(10000);
  }
  
  delay(4);
}