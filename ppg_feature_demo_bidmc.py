import os
import numpy as np
import wfdb
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, find_peaks

os.makedirs("figures", exist_ok=True)

def bandpass(x, fs, low=0.5, high=8.0, order=4):
    nyq = 0.5 * fs
    b, a = butter(order, [low/nyq, high/nyq], btype="bandpass")
    return filtfilt(b, a, x)

# 1) Pick a valid record
records = wfdb.get_record_list("bidmc")
record_id = records[0]  # e.g., "bidmc01"
print("Using record:", record_id)

# 2) Load record
rec = wfdb.rdrecord(record_id, pn_dir="bidmc")
fs = float(rec.fs)
print("Sampling frequency (Hz):", fs)
print("Signals available (raw):", rec.sig_name)

# 3) Clean signal names (remove commas/spaces)
sig_raw = rec.sig_name
sig_clean = [s.replace(",", "").strip() for s in sig_raw]
print("Signals available (clean):", sig_clean)

def find_channel(candidates):
    """Return (index, name_clean, name_raw) if found."""
    for cand in candidates:
        for i, s in enumerate(sig_clean):
            if s.upper() == cand.upper():
                return i, s, sig_raw[i]
    return None, None, None

# 4) Find PPG + SpO2 channels
ppg_candidates = ["PLETH", "PPG", "PLETHY", "PLETH1", "PLETH2"]
ppg_idx, ppg_name_clean, ppg_name_raw = find_channel(ppg_candidates)
if ppg_idx is None:
    raise ValueError(f"No PPG-like channel found. Available(clean): {sig_clean}")

spo2_candidates = ["SPO2", "SpO2", "SaO2", "SO2"]
spo2_idx, spo2_name_clean, spo2_name_raw = find_channel(spo2_candidates)

print("Using PPG channel:", ppg_name_clean, "(raw:", ppg_name_raw, ")")
print("Using SpO2 channel:", spo2_name_clean if spo2_idx is not None else "None")

ppg = rec.p_signal[:, ppg_idx].astype(float)
spo2 = rec.p_signal[:, spo2_idx].astype(float) if spo2_idx is not None else None

# 5) Take a 30-second segment
win_s = 30
N = int(win_s * fs)
seg_ppg = ppg[:N]
seg_spo2 = spo2[:N] if spo2 is not None else None

# 6) Filter PPG
ppg_f = bandpass(seg_ppg, fs)

# 7) Peak detection
min_dist = int(0.3 * fs)  # >=300 ms
peaks, _ = find_peaks(ppg_f, distance=min_dist, prominence=np.std(ppg_f) * 0.5)

# 8) Compute PPG interval features
if len(peaks) >= 5:
    pp = np.diff(peaks) / fs
    pp_ms = pp * 1000.0
    meanpp = float(np.mean(pp))
    sdpp = float(np.std(pp_ms, ddof=1))
    cvpp = float(np.std(pp) / (np.mean(pp) + 1e-8))

    print("\nPPG Features (30s window):")
    print("  MeanPP (s):", round(meanpp, 4))
    print("  SDPP (ms):", round(sdpp, 2))
    print("  CVPP:", round(cvpp, 4))
else:
    print("\nNot enough peaks detected for PP interval features. Try another record.")

# 9) Plot raw vs filtered PPG
plt.figure()
plt.plot(seg_ppg, label="Raw PPG")
plt.plot(ppg_f, label="Filtered PPG")
plt.title(f"PPG Before and After Bandpass Filtering ({record_id}, 30s)")
plt.xlabel("Samples")
plt.ylabel("Amplitude")
plt.legend()
plt.savefig("figures/ppg_raw_vs_filtered.png", dpi=300, bbox_inches="tight")
plt.close()

# 10) Plot peaks
plt.figure()
plt.plot(ppg_f, label="Filtered PPG")
if len(peaks) > 0:
    plt.plot(peaks, ppg_f[peaks], "rx", label="Detected Peaks")
plt.title(f"PPG Peak Detection ({record_id}, 30s)")
plt.xlabel("Samples")
plt.ylabel("Amplitude")
plt.legend()
plt.savefig("figures/ppg_peak_detection.png", dpi=300, bbox_inches="tight")
plt.close()

# 11) Plot SpO2 (if present)
if seg_spo2 is not None:
    plt.figure()
    plt.plot(seg_spo2)
    plt.title(f"SpO₂ Trend Over 30s Window ({record_id})")
    plt.xlabel("Samples")
    plt.ylabel("SpO₂ (%)")
    plt.savefig("figures/spo2_trend.png", dpi=300, bbox_inches="tight")
    plt.close()
    print("\nSaved SpO₂ trend plot.")
else:
    print("\nSpO₂ channel not found in this record, so no SpO₂ plot saved.")

print("\nSaved plots to: figures/")
print(" - figures/ppg_raw_vs_filtered.png")
print(" - figures/ppg_peak_detection.png")
if seg_spo2 is not None:
    print(" - figures/spo2_trend.png")
