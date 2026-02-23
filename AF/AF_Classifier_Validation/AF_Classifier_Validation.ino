/*
 * AF Detection System v5.0 - Classifier Validation Test
 */

#include <math.h>

// ── LED Pins ──
#define GREEN_LED 25
#define RED_LED   33
#define BLUE_LED  32

#define CV_THRESHOLD     0.15f
#define RMSSD_THRESHOLD  40.0f
#define PNN50_THRESHOLD  43.0f
#define WINDOW_SIZE      30

// ── LED Functions ──
void allLedsOff() {
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  LOW);
}

void showNormalResult() {
  allLedsOff();
  digitalWrite(GREEN_LED, HIGH);
  Serial.println("  LED: GREEN ON (Normal)");
  delay(3000);
  allLedsOff();
}

void showAFResult() {
  allLedsOff();
  Serial.println("  LED: RED PULSING (Possible AF)");
  for (int i = 0; i < 5; i++) {
    for (int b = 0;   b < 255; b += 5) { analogWrite(RED_LED, b); delay(10); }
    for (int b = 255; b > 0;   b -= 5) { analogWrite(RED_LED, b); delay(10); }
  }
  allLedsOff();
}

// Feature Extraction
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
  float std_rr  = sqrt(variance / count);
  float cv      = std_rr / mean_rr;
  float mean_hr = 60000.0f / mean_rr;

  float sum_sq = 0;
  int   dc = 0, pnn50c = 0;
  for (int i = 0; i < count - 1; i++) {
    int diff = rr_intervals[i + 1] - rr_intervals[i];
    sum_sq += (float)diff * diff;
    if (abs(diff) > 50) pnn50c++;
    dc++;
  }

  features[0] = mean_rr;
  features[1] = std_rr;
  features[2] = cv;
  features[3] = mean_hr;
  features[4] = sqrt(sum_sq / dc);
  features[5] = (float)pnn50c / dc * 100.0f;
}

// Classifier 
int predictAF(float* features, int* confidence) {
  int af_score = 0;
  if (features[2] > CV_THRESHOLD)    af_score += 2;
  if (features[4] > RMSSD_THRESHOLD) af_score += 2;
  if (features[5] > PNN50_THRESHOLD) af_score += 1;
  *confidence = (af_score * 100) / 5;
  return (af_score >= 3) ? 1 : 0;
}

// ── Run one test ──
void runTest(const char* title, const char* basis,
             int* rr, int count, int expected) {

  Serial.println("\n--------------------------------------------");
  Serial.println(title);
  Serial.println(basis);
  Serial.println("--------------------------------------------");

  // Blue blink = processing
  for (int i = 0; i < 6; i++) {
    digitalWrite(BLUE_LED, HIGH); delay(200);
    digitalWrite(BLUE_LED, LOW);  delay(200);
  }

  float features[6];
  calculateFeatures(rr, count, features);

  // Print all features with threshold comparisons
  Serial.print("  Mean RR : "); Serial.print(features[0], 1); Serial.println(" ms");
  Serial.print("  Mean HR : "); Serial.print(features[3], 1); Serial.println(" BPM");

  Serial.print("  CV      : "); Serial.print(features[2], 4);
  Serial.println(features[2] > CV_THRESHOLD    ? "  > 0.15 [FLAG]" : "  < 0.15 [OK]");

  Serial.print("  RMSSD   : "); Serial.print(features[4], 2);
  Serial.println(features[4] > RMSSD_THRESHOLD ? " ms  > 40ms [FLAG]" : " ms  < 40ms [OK]");

  Serial.print("  pNN50   : "); Serial.print(features[5], 1);
  Serial.println(features[5] > PNN50_THRESHOLD ? "%   > 43% [FLAG]" : "%   < 43% [OK]");

  int confidence, result;
  result = predictAF(features, &confidence);

  Serial.print("  Score   : ");
  int score = 0;
  if (features[2] > CV_THRESHOLD)    score += 2;
  if (features[4] > RMSSD_THRESHOLD) score += 2;
  if (features[5] > PNN50_THRESHOLD) score += 1;
  Serial.print(score); Serial.print(" / 5  (");
  Serial.print(confidence); Serial.println("% confidence)");

  Serial.print("  Result  : ");
  Serial.println(result == 1 ? "POSSIBLE AF" : "NORMAL");

  // LED output
  if (result == 1) showAFResult();
  else             showNormalResult();

  // Pass/fail
  Serial.print("  Expected: ");
  Serial.print(expected == 1 ? "POSSIBLE AF" : "NORMAL");
  Serial.print("  -->  ");
  if (result == expected) Serial.println("PASS");
  else                    Serial.println("FAIL  <-- review thresholds");

  delay(1000);
}

// Generate 30 RR intervals from a pattern 
void fillRR(int* out, int count,
            int* pattern, int plen) {
  for (int i = 0; i < count; i++) {
    out[i] = pattern[i % plen];
  }
}

void runValidationTests() {
  Serial.println("\n============================================");
  Serial.println("  AF CLASSIFIER VALIDATION  v5.0");
  Serial.println("  30-beat windows, updated thresholds");
  Serial.println("============================================");

  int passed = 0;
  int rr[WINDOW_SIZE]; // reused for each test

  // ── TEST 1: Normal Sinus Rhythm (~70 BPM) ────────────
  // Regular intervals, minimal variation
  // Expected: CV small, RMSSD low, pNN50 near 0
  // Expected result: NORMAL, score 0/5
  // Physiological basis: healthy adult resting rhythm
  {
    int pattern[] = {857, 855, 860, 856, 858, 857, 854,
                     861, 857, 858, 856, 859, 857, 855,
                     860, 857, 856, 858, 857, 859, 855,
                     861, 857, 858, 856, 857, 860, 855,
                     858, 857};
    fillRR(rr, WINDOW_SIZE, pattern, 30);
    runTest(
      "TEST 1: Normal Sinus Rhythm",
      "  ~70 BPM, tight intervals (854-861 ms)",
      rr, WINDOW_SIZE, 0
    );
    // manually check pass after call
  }

  // ── TEST 2: Atrial Fibrillation Pattern 
  // Chaotic, highly irregular RR intervals
  // Expected: CV >> 0.15, RMSSD >> 40ms, pNN50 >> 43%
  // Expected result: POSSIBLE AF, score 5/5
  {
    int pattern[] = {620, 1050, 580, 1180, 710, 990, 640,
                     1100, 590, 1020, 670, 1150, 600, 960,
                     730, 1080, 560, 1200, 690, 1010, 650,
                     1130, 580, 970, 720, 1060, 610, 1090,
                     640, 1020};
    fillRR(rr, WINDOW_SIZE, pattern, 30);
    runTest(
      "TEST 2: Atrial Fibrillation Pattern",
      "  Chaotic intervals (560-1200 ms)",
      rr, WINDOW_SIZE, 1
    );
  }

  // ── TEST 3: Respiratory Sinus Arrhythmia ─────────────
  // Mild, rhythmic variability from breathing
  // Intervals cycle gently 780-830ms (~73-77 BPM)
  // Expected: CV borderline, RMSSD < 40ms, pNN50 < 43%
  // Expected result: NORMAL (benign variation, not AF)
  // Critical test: validates SPECIFICITY of classifier
  {
    int pattern[] = {780, 800, 820, 830, 820, 800, 780,
                     800, 820, 830, 820, 800, 780, 800,
                     820, 830, 820, 800, 780, 800, 820,
                     830, 820, 800, 780, 800, 820, 830,
                     820, 800};
    fillRR(rr, WINDOW_SIZE, pattern, 30);
    runTest(
      "TEST 3: Respiratory Sinus Arrhythmia",
      "  Gentle cyclic variation (780-830 ms)",
      rr, WINDOW_SIZE, 0
    );
  }

  // ── TEST 4: Sinus Tachycardia (~125 BPM) ─────────────
  // Fast but completely regular (exercise/stress response)
  // Expected: very low CV, RMSSD near 0, pNN50 = 0%
  // Expected result: NORMAL (high HR ≠ AF)
  // Critical test: confirms high HR alone does NOT trigger flag
  {
    int pattern[] = {480, 482, 479, 481, 480, 483, 478,
                     481, 480, 482, 479, 481, 480, 482,
                     478, 481, 480, 483, 479, 481, 480,
                     482, 479, 481, 480, 482, 478, 481,
                     480, 482};
    fillRR(rr, WINDOW_SIZE, pattern, 30);
    runTest(
      "TEST 4: Sinus Tachycardia (Fast + Regular)",
      "  ~125 BPM, tight intervals (478-483 ms)",
      rr, WINDOW_SIZE, 0
    );
  }

  // ── TEST 5: BORDERLINE CASE — Frequent Ectopic Beats ──
  // Occasional premature beats causing large RR jumps
  // Pattern: mostly regular 850ms with every 5th beat early
  // at ~600ms followed by compensatory pause at ~1100ms
  // This tests whether the classifier correctly flags
  // significant ectopy, which can precede AF
  // Expected result: POSSIBLE AF (CV and RMSSD elevated)
  {
    int pattern[] = {850, 850, 850, 850, 600,
                     1100, 850, 850, 850, 600,
                     1100, 850, 850, 850, 600,
                     1100, 850, 850, 850, 600,
                     1100, 850, 850, 850, 600,
                     1100, 850, 850, 850, 850};
    fillRR(rr, WINDOW_SIZE, pattern, 30);
    runTest(
      "TEST 5: Frequent Ectopic Beats (Borderline)",
      "  Regular 850ms with premature beats every 5th ",
      rr, WINDOW_SIZE, 1
    );
  }

  // SUMMARY 
  Serial.println("\n============================================");
  Serial.println("  VALIDATION COMPLETE");
  Serial.println("============================================\n");
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED,   OUTPUT);
  pinMode(BLUE_LED,  OUTPUT);

  // LED self-test
  Serial.println("LED self-test");
  digitalWrite(GREEN_LED, HIGH); delay(300); digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED,   HIGH); delay(300); digitalWrite(RED_LED,   LOW);
  digitalWrite(BLUE_LED,  HIGH); delay(300); digitalWrite(BLUE_LED,  LOW);
  Serial.println("LEDs OK\n");

  runValidationTests();
}

void loop() {
  delay(10000);
}