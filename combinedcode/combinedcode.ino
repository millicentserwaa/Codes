#include <Wire.h>
#include "MAX30105.h"        // SparkFun MAX3010x library
#include "heartRate.h"       // comes with the library
#include <math.h>

// ---------------------------
// USER SETTINGS (EDIT THESE)
// ---------------------------

// AD8232 pins
const int ECG_ADC_PIN = 1;     // <-- CHANGE to your ADC pin (ESP32 ADC1 recommended)
const int ECG_LO_PLUS = 4;     // <-- optional lead-off detect
const int ECG_LO_MINUS = 5;    // <-- optional lead-off detect

// I2C pins (edit for your board if needed)
const int I2C_SDA = 8;         // <-- CHANGE if needed
const int I2C_SCL = 9;         // <-- CHANGE if needed

// Sampling
const int ECG_FS = 250;        // ECG sampling frequency (Hz)
const int PPG_FS = 100;        // PPG effective sample rate (we’ll read often; library handles timing)

// Window
const int WINDOW_SEC = 30;     // feature window length
const int MIN_BEATS = 20;      // minimum detected beats/pulses in window for reliability

// ECG R-peak detection
const float ECG_THRESH = 0.6f;           // threshold on normalized-ish signal (tune during testing)
const int ECG_REFRACT_MS = 200;          // 200ms refractory

// PPG irregularity threshold (start values; tune with data)
const float SDPP_IRREG_MS = 80.0f;       // if SD of PP intervals > 80ms => irregular (screening flag)

// ---------------------------
// YOUR TRAINED MODEL (ECG) - paste from your results
// Features: [MeanRR(s), SDNN(ms), RMSSD(ms), pNN50(%), CVRR]
// StandardScaler: z = (x - mean) / std
// Logistic: p = sigmoid(b + w·z)
// ---------------------------

const float W[5] = {
  -3.07118542f,
   3.10996797f,
  -1.29916497f,
   3.82940862f,
  -2.14630831f
};

const float BIAS = -3.62379168f;

const float SCALER_MEAN[5] = {
  0.792958057f,
  109.017824f,
  149.397852f,
  29.5833242f,
  0.13553955f
};

const float SCALER_STD[5] = {
  0.177314201f,
  117.591401f,
  171.118881f,
  33.0004090f,
  0.137570090f
};

// ---------------------------
// Globals
// ---------------------------
MAX30105 ppg;

unsigned long lastECGSampleUs = 0;
unsigned long lastDecisionMs = 0;

float ecgDC = 0.0f;           // DC removal (simple IIR)
float ecgHP = 0.0f;           // high-passed
float ecgPrev = 0.0f;

unsigned long lastRpeakMs = 0;
unsigned long lastPPpeakMs = 0;

// store RR and PP intervals for one window (max beats)
const int MAX_INTERVALS = 400;  // enough for 30s at high HR
float rr_ms[MAX_INTERVALS];
int rr_count = 0;

float pp_ms[MAX_INTERVALS];
int pp_count = 0;

// pNN50 needs successive differences
float rr_diff_ms[MAX_INTERVALS];
int rr_diff_count = 0;

// ---------------------------
// Helpers
// ---------------------------
static inline float sigmoidf(float x) {
  // prevent overflow
  if (x > 20.0f) return 1.0f;
  if (x < -20.0f) return 0.0f;
  return 1.0f / (1.0f + expf(-x));
}

float mean(const float* a, int n) {
  if (n <= 0) return NAN;
  double s = 0;
  for (int i = 0; i < n; i++) s += a[i];
  return (float)(s / n);
}

float stdev(const float* a, int n) {
  if (n < 2) return NAN;
  float m = mean(a, n);
  double s = 0;
  for (int i = 0; i < n; i++) {
    double d = (double)a[i] - m;
    s += d * d;
  }
  return (float)sqrt(s / (n - 1));
}

float rmssd_from_diffs(const float* diffs, int n) {
  if (n <= 0) return NAN;
  double s = 0;
  for (int i = 0; i < n; i++) s += (double)diffs[i] * diffs[i];
  return (float)sqrt(s / n);
}

float compute_pnn50(const float* diffs, int n) {
  if (n <= 0) return NAN;
  int c = 0;
  for (int i = 0; i < n; i++) if (fabs(diffs[i]) > 50.0f) c++;
  return 100.0f * ((float)c / (float)n);
}

void resetWindow() {
  rr_count = 0;
  rr_diff_count = 0;
  pp_count = 0;
}

bool leadOff() {
  // If you didn’t wire LO+/LO-, just return false.
  int lop = digitalRead(ECG_LO_PLUS);
  int lom = digitalRead(ECG_LO_MINUS);
  return (lop == 1 || lom == 1);
}

// ---------------------------
// ECG sampling + R-peak detection
// ---------------------------
void sampleECG() {
  // basic lead-off check
  if (leadOff()) return;

  int raw = analogRead(ECG_ADC_PIN);
  float x = (float)raw;

  // Simple DC removal (IIR): ecgDC tracks slow changes
  ecgDC = 0.995f * ecgDC + 0.005f * x;
  ecgHP = x - ecgDC;

  // crude normalization (not perfect, but ok for peak detection)
  // If peaks are too low/high, adjust ECG_THRESH.
  float s = ecgHP;

  // R-peak detection: threshold crossing with refractory period
  unsigned long nowMs = millis();
  if ((nowMs - lastRpeakMs) > (unsigned long)ECG_REFRACT_MS) {
    // detect rising threshold crossing
    if (ecgPrev < ECG_THRESH && s >= ECG_THRESH) {
      // R-peak detected
      if (lastRpeakMs != 0) {
        float rr = (float)(nowMs - lastRpeakMs);  // ms
        if (rr > 250.0f && rr < 2000.0f && rr_count < MAX_INTERVALS) { // 30-240 bpm
          rr_ms[rr_count++] = rr;
          // diff for pNN50/RMSSD (needs previous RR)
          if (rr_count >= 2 && rr_diff_count < MAX_INTERVALS) {
            rr_diff_ms[rr_diff_count++] = rr_ms[rr_count - 1] - rr_ms[rr_count - 2];
          }
        }
      }
      lastRpeakMs = nowMs;
    }
  }

  ecgPrev = s;
}

// ---------------------------
// PPG sampling + pulse detection
// ---------------------------
void samplePPG() {
  // Read IR signal
  long ir = ppg.getIR();

  // Use library helper to detect beats from IR
  bool beat = checkForBeat(ir);

  if (beat) {
    unsigned long nowMs = millis();
    if (lastPPpeakMs != 0) {
      float pp = (float)(nowMs - lastPPpeakMs); // ms
      if (pp > 250.0f && pp < 2000.0f && pp_count < MAX_INTERVALS) {
        pp_ms[pp_count++] = pp;
      }
    }
    lastPPpeakMs = nowMs;
  }
}

// ---------------------------
// Feature computation + AF screening
// ---------------------------
void decideAndPrint() {
  // basic reliability checks
  if (rr_count < MIN_BEATS) {
    Serial.println("ECG: Not enough R-peaks for reliable HRV window.");
    resetWindow();
    return;
  }

  // ECG features
  float meanRR_s = mean(rr_ms, rr_count) / 1000.0f;
  float sdnn_ms = stdev(rr_ms, rr_count);
  float rmssd_ms = rmssd_from_diffs(rr_diff_ms, rr_diff_count);
  float pnn50 = compute_pnn50(rr_diff_ms, rr_diff_count);

  float rr_mean_ms = mean(rr_ms, rr_count);
  float cvrr = (sdnn_ms / (rr_mean_ms + 1e-6f)); // dimensionless

  // Guard against NAN
  if (!isfinite(meanRR_s) || !isfinite(sdnn_ms) || !isfinite(rmssd_ms) || !isfinite(pnn50) || !isfinite(cvrr)) {
    Serial.println("ECG: Feature computation failed (NaN).");
    resetWindow();
    return;
  }

  // Standardize features
  float x[5] = { meanRR_s, sdnn_ms, rmssd_ms, pnn50, cvrr };
  float z[5];
  for (int i = 0; i < 5; i++) z[i] = (x[i] - SCALER_MEAN[i]) / (SCALER_STD[i] + 1e-8f);

  // Logistic regression score
  float score = BIAS;
  for (int i = 0; i < 5; i++) score += W[i] * z[i];
  float pAF = sigmoidf(score);

  // Screening threshold (start at 0.40 to favor sensitivity)
  const float THRESH = 0.40f;
  bool ecgAF = (pAF >= THRESH);

  // PPG irregularity flag
  bool ppgIrreg = false;
  float sdpp_ms = NAN, meanpp_ms = NAN;
  if (pp_count >= MIN_BEATS) {
    meanpp_ms = mean(pp_ms, pp_count);
    sdpp_ms = stdev(pp_ms, pp_count);
    if (isfinite(sdpp_ms) && sdpp_ms > SDPP_IRREG_MS) ppgIrreg = true;
  }

  // Combine decision (defendable multimodal screening)
  String decision;
  if (ecgAF && ppgIrreg) decision = "AF Screening: POSITIVE (High confidence)";
  else if (ecgAF && !ppgIrreg) decision = "AF Screening: POSITIVE (Low confidence - repeat measurement)";
  else if (!ecgAF && ppgIrreg) decision = "AF Screening: NEGATIVE (PPG irregular - likely motion/noise, repeat)";
  else decision = "AF Screening: NEGATIVE";

  // Print summary (you can later send this via BLE)
  Serial.println("----- 30s Window Result -----");
  Serial.print("ECG Features: MeanRR(s)="); Serial.print(meanRR_s, 4);
  Serial.print(" SDNN(ms)="); Serial.print(sdnn_ms, 2);
  Serial.print(" RMSSD(ms)="); Serial.print(rmssd_ms, 2);
  Serial.print(" pNN50(%)="); Serial.print(pnn50, 2);
  Serial.print(" CVRR="); Serial.println(cvrr, 4);

  Serial.print("ECG Model: score="); Serial.print(score, 4);
  Serial.print(" p(AF)="); Serial.print(pAF, 4);
  Serial.print(" ecgAF="); Serial.println(ecgAF ? "YES" : "NO");

  if (pp_count >= MIN_BEATS) {
    Serial.print("PPG Features: MeanPP(ms)="); Serial.print(meanpp_ms, 2);
    Serial.print(" SDPP(ms)="); Serial.print(sdpp_ms, 2);
    Serial.print(" ppgIrreg="); Serial.println(ppgIrreg ? "YES" : "NO");
  } else {
    Serial.println("PPG: Not enough pulse peaks for reliability in this window.");
  }

  Serial.println(decision);
  Serial.println("----------------------------");

  resetWindow();
}

// ---------------------------
// Setup / Loop
// ---------------------------
void setup() {
  Serial.begin(115200);

  pinMode(ECG_LO_PLUS, INPUT);
  pinMode(ECG_LO_MINUS, INPUT);

  // ADC settings (ESP32)
  analogReadResolution(12); // 0..4095

  // I2C + MAX30102 init
  Wire.begin(I2C_SDA, I2C_SCL);

  if (!ppg.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1) delay(10);
  }

  // Recommended config: adjust if readings are weak/strong
  ppg.setup();                // default settings
  ppg.setPulseAmplitudeRed(0x1F);
  ppg.setPulseAmplitudeIR(0x1F);
  ppg.setPulseAmplitudeGreen(0); // not used

  resetWindow();
  lastDecisionMs = millis();
}

void loop() {
  // ECG sampling at fixed rate
  unsigned long nowUs = micros();
  unsigned long periodUs = 1000000UL / (unsigned long)ECG_FS;
  if (nowUs - lastECGSampleUs >= periodUs) {
    lastECGSampleUs += periodUs;
    sampleECG();
  }

  // PPG sampling (read often; library handles timing)
  samplePPG();

  // Every WINDOW_SEC, compute result
  unsigned long nowMs = millis();
  if (nowMs - lastDecisionMs >= (unsigned long)WINDOW_SEC * 1000UL) {
    lastDecisionMs += (unsigned long)WINDOW_SEC * 1000UL;
    decideAndPrint();
  }
}
