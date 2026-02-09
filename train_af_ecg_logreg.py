import numpy as np
import wfdb
from scipy.signal import butter, filtfilt, find_peaks
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

# ---------------------------
# 1) ECG filtering
# ---------------------------
def butter_filter(x, fs, ftype, cutoff, order):
    nyq = 0.5 * fs
    if isinstance(cutoff, (list, tuple)):
        Wn = [c / nyq for c in cutoff]
    else:
        Wn = cutoff / nyq
    b, a = butter(order, Wn, btype=ftype)
    return filtfilt(b, a, x)

def preprocess_ecg(ecg, fs):
    # Baseline removal: HPF 0.5 Hz (2nd order)
    y = butter_filter(ecg, fs, "highpass", 0.5, order=2)
    # Noise suppression: LPF 40 Hz (4th order)
    y = butter_filter(y, fs, "lowpass", 40.0, order=4)
    # normalize
    y = (y - np.mean(y)) / (np.std(y) + 1e-8)
    return y

# ---------------------------
# 2) R-peak detection + features
# ---------------------------
def rpeaks_and_rr(ecg_filt, fs):
    # Simple peak detection constraints
    # distance: at least 200 ms between peaks
    min_dist = int(0.2 * fs)
    # adaptive height threshold
    height = 0.5 * np.max(ecg_filt)
    peaks, _ = find_peaks(ecg_filt, height=height, distance=min_dist)
    if len(peaks) < 5:
        return None
    rr = np.diff(peaks) / fs  # seconds
    # reject unrealistic RR
    rr = rr[(rr > 0.25) & (rr < 2.0)]  # 30–240 bpm range
    if len(rr) < 5:
        return None
    return rr

def hrv_features(rr):
    # rr in seconds
    rr_ms = rr * 1000.0
    mean_rr = np.mean(rr)              # seconds
    sdnn = np.std(rr_ms, ddof=1)       # ms
    diff_rr = np.diff(rr_ms)
    rmssd = np.sqrt(np.mean(diff_rr**2)) if len(diff_rr) > 0 else 0.0  # ms
    pnn50 = (np.sum(np.abs(diff_rr) > 50.0) / max(len(diff_rr), 1)) * 100.0  # %
    # coefficient of variation (optional but helps)
    cvrr = (np.std(rr) / (np.mean(rr) + 1e-8))
    return np.array([mean_rr, sdnn, rmssd, pnn50, cvrr], dtype=float)

# ---------------------------
# 3) Windowing helper
# ---------------------------
def sliding_windows(sig, fs, win_s=30, step_s=15):
    win = int(win_s * fs)
    step = int(step_s * fs)
    n = len(sig)
    for start in range(0, n - win + 1, step):
        yield start, start + win

# ---------------------------
# 4) AFDB: use rhythm annotation to label windows
# ---------------------------
def load_afdb_windows(record_name, win_s=30, step_s=15):
    rec = wfdb.rdrecord(record_name, pn_dir="afdb")
    fs = int(rec.fs)
    ecg = rec.p_signal[:, 0].astype(float)

    # AFDB rhythm annotations are typically in 'atr' or 'qrs' depending on record.
    # We'll try 'atr' first.
    ann = wfdb.rdann(record_name, "atr", pn_dir="afdb")

    # ann.aux_note contains rhythm labels like '(AFIB', '(N', etc. with sample indices.
    # We'll convert these into labeled intervals.
    samples = np.array(ann.sample)
    notes = np.array(ann.aux_note)

    # Build intervals: [samples[i], samples[i+1]) with label notes[i]
    intervals = []
    for i in range(len(samples) - 1):
        label = notes[i].strip()
        s0, s1 = int(samples[i]), int(samples[i + 1])
        intervals.append((s0, s1, label))

    def interval_label(s0, s1):
        # Decide label for a window using 90% rule
        length = s1 - s0
        if length <= 0:
            return None

        af_count = 0
        n_count = 0
        covered = 0

        for a0, a1, lab in intervals:
            # overlap
            o0 = max(s0, a0)
            o1 = min(s1, a1)
            if o1 <= o0:
                continue
            ol = o1 - o0
            covered += ol
            if "AFIB" in lab or "AF" in lab:
                af_count += ol
            if "(N" in lab or "N" == lab:
                n_count += ol

        if covered == 0:
            return None

        if af_count / length >= 0.90:
            return 1
        if n_count / length >= 0.90:
            return 0
        return None

    X, y = [], []
    ecg_f = preprocess_ecg(ecg, fs)

    for s0, s1 in sliding_windows(ecg_f, fs, win_s, step_s):
        lab = interval_label(s0, s1)
        if lab is None:
            continue
        rr = rpeaks_and_rr(ecg_f[s0:s1], fs)
        if rr is None:
            continue
        feats = hrv_features(rr)
        X.append(feats)
        y.append(lab)

    return np.array(X), np.array(y)

# ---------------------------
# 5) MIT-BIH: take "mostly normal" records as Non-AF only
# ---------------------------
def load_mitdb_nonaf_windows(record_name, win_s=30, step_s=15):
    rec = wfdb.rdrecord(record_name, pn_dir="mitdb")
    fs = int(rec.fs)
    ecg = rec.p_signal[:, 0].astype(float)

    ecg_f = preprocess_ecg(ecg, fs)

    X, y = [], []
    for s0, s1 in sliding_windows(ecg_f, fs, win_s, step_s):
        rr = rpeaks_and_rr(ecg_f[s0:s1], fs)
        if rr is None:
            continue
        feats = hrv_features(rr)
        X.append(feats)
        y.append(0)  # Non-AF
    return np.array(X), np.array(y)

# ---------------------------
# 6) Train + evaluate
# ---------------------------
def main():
    # Start small so you see results fast, then expand.
    afdb_records = ["04015", "04043", "04048", "04126", "04746"]
    mitdb_records = ["100", "101", "103", "105", "106", "108", "109"]

    X_list, y_list = [], []

    print("Loading AFDB...")
    for r in afdb_records:
        try:
            Xr, yr = load_afdb_windows(r)
            if len(yr) > 0:
                X_list.append(Xr)
                y_list.append(yr)
                print(f"  {r}: {len(yr)} windows (AF={np.sum(yr==1)}, N={np.sum(yr==0)})")
            else:
                print(f"  {r}: 0 usable windows")
        except Exception as e:
            print(f"  {r}: failed ({e})")

    print("\nLoading MIT-BIH (Non-AF only)...")
    for r in mitdb_records:
        try:
            Xr, yr = load_mitdb_nonaf_windows(r)
            if len(yr) > 0:
                X_list.append(Xr)
                y_list.append(yr)
                print(f"  {r}: {len(yr)} windows (Non-AF)")
            else:
                print(f"  {r}: 0 usable windows")
        except Exception as e:
            print(f"  {r}: failed ({e})")

    X = np.vstack(X_list)
    y = np.concatenate(y_list)

    print("\nDataset summary:")
    print("  Total windows:", len(y))
    print("  AF windows:", int(np.sum(y == 1)))
    print("  Non-AF windows:", int(np.sum(y == 0)))

    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y
    )

    # Standardize
    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s = scaler.transform(X_test)

    # Logistic regression (balanced)
    clf = LogisticRegression(class_weight="balanced", max_iter=1000)
    clf.fit(X_train_s, y_train)

    # Predict
    y_pred = clf.predict(X_test_s)
    y_prob = clf.predict_proba(X_test_s)[:, 1]

    print("\nConfusion Matrix:")
    print(confusion_matrix(y_test, y_pred))

    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, digits=3))

    try:
        auc = roc_auc_score(y_test, y_prob)
        print("ROC-AUC:", round(auc, 4))
    except Exception:
        pass

    # Print weights for ESP32 deployment later
    print("\nModel weights (for ESP32 later):")
    print("  Features: [MeanRR(s), SDNN(ms), RMSSD(ms), pNN50(%), CVRR]")
    print("  w =", clf.coef_[0])
    print("  b =", clf.intercept_[0])

    print("\nScaler params (store for ESP32 later):")
    print("  mean =", scaler.mean_)
    print("  std  =", np.sqrt(scaler.var_))

if __name__ == "__main__":
    main()
