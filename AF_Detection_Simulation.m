%% ========================================================
%  AF Detection System v5.0 - MATLAB Simulation
%  Finger-Based ECG Atrial Fibrillation Screening Device
%
%  Simulates the complete signal processing pipeline:
%    1. ECG waveform generation (4 clinical test cases)
%    2. Adaptive threshold R-peak detection
%    3. RR interval extraction
%    4. HRV feature calculation (CV, RMSSD, pNN50)
%    5. Rule-based AF classification
%
%  Clinically-informed parameters:
%    Window : 30 beats  [Taoum et al., Physiol. Meas. 2019]
%    CV     : > 0.15    [Bus et al., J. Clin. Med. 2022]
%    RMSSD  : > 40 ms   [medRxiv oHCM cohort, n=1112, 2023]
%    pNN50  : > 43%     [medRxiv oHCM cohort, n=1112, 2023]
%
%  Author  : Capstone Project - AF Detection System
%  Date    : February 2026
% =========================================================

clc; clear; close all;

%% ── GLOBAL PARAMETERS ────────────────────────────────────

Fs          = 250;          % Sampling frequency (Hz) - ESP32 ADC rate
WINDOW_SIZE = 30;           % Beats per analysis window
MIN_RR      = 300;          % ms - minimum valid RR (200 BPM)
MAX_RR      = 2000;         % ms - maximum valid RR (30 BPM)

% Classification thresholds (evidence-based)
CV_THRESH    = 0.15;        % Bus et al. 2022
RMSSD_THRESH = 40.0;        % medRxiv oHCM 2023
PNN50_THRESH = 43.0;        % medRxiv oHCM 2023

% Adaptive threshold parameters
THRESHOLD_RATIO = 0.5;      % midpoint between baseline and peak
BASELINE_ALPHA  = 0.005;    % slow EMA for baseline tracking
PEAK_ALPHA      = 0.05;     % faster EMA for peak tracking
MIN_AMPLITUDE   = 100;      % minimum ADC swing to enable detection

% Signal characteristics (from observed ESP32 ADC output)
ADC_BASELINE = 1640;        % resting signal level
ADC_PEAK     = 1960;        % R-wave peak level
RISE_MS      = 80;          % QRS upstroke duration
FALL_MS      = 120;         % QRS downstroke duration

%% ── DEFINE 4 TEST CASES ──────────────────────────────────

% Each test case defines a sequence of RR intervals in ms
% representing a specific cardiac rhythm pattern.

testCases(1).name        = 'Normal Sinus Rhythm (~70 BPM)';
testCases(1).shortname   = 'Normal Sinus';
testCases(1).expected    = 'NORMAL';
testCases(1).color       = [0.18 0.55 0.34];   % green
testCases(1).description = 'Regular intervals 854-861ms, healthy resting adult';
testCases(1).reference   = 'Task Force ESC/NASPE (1996)';
testCases(1).rrPattern   = [857 855 860 856 858 857 854 861 857 858 ...
                             856 859 857 855 860 857 856 858 857 859 ...
                             855 861 857 858 856 857 860 855 858 857];

testCases(2).name        = 'Atrial Fibrillation Pattern';
testCases(2).shortname   = 'AF Pattern';
testCases(2).expected    = 'POSSIBLE AF';
testCases(2).color       = [0.85 0.20 0.20];   % red
testCases(2).description = 'Chaotic intervals 560-1200ms, AV node irregularity';
testCases(2).reference   = 'MIT-BIH AF Database (PhysioNet)';
testCases(2).rrPattern   = [620 1050 580 1180 710 990 640 1100 590 1020 ...
                             670 1150 600 960 730 1080 560 1200 690 1010 ...
                             650 1130 580 970 720 1060 610 1090 640 1020];

testCases(3).name        = 'Respiratory Sinus Arrhythmia (~75 BPM)';
testCases(3).shortname   = 'Sinus Arrhythmia';
testCases(3).expected    = 'NORMAL';
testCases(3).color       = [0.18 0.45 0.75];   % blue
testCases(3).description = 'Mild rhythmic variation 780-830ms from breathing';
testCases(3).reference   = 'Task Force ESC/NASPE (1996)';
testCases(3).rrPattern   = [780 800 820 830 820 800 780 800 820 830 ...
                             820 800 780 800 820 830 820 800 780 800 ...
                             820 830 820 800 780 800 820 830 820 800];

testCases(4).name        = 'Sinus Tachycardia (~125 BPM)';
testCases(4).shortname   = 'Sinus Tachycardia';
testCases(4).expected    = 'NORMAL';
testCases(4).color       = [0.85 0.55 0.10];   % orange
testCases(4).description = 'Fast but regular intervals 478-483ms (exercise/stress)';
testCases(4).reference   = 'Bus et al., J. Clin. Med. 2022';
testCases(4).rrPattern   = [480 482 479 481 480 483 478 481 480 482 ...
                             479 481 480 482 478 481 480 483 479 481 ...
                             480 482 479 481 480 482 478 481 480 482];

nTests = length(testCases);

%% ── HELPER FUNCTIONS ─────────────────────────────────────

% Generate simulated ADC signal from RR interval sequence
function [signal, timeVec, peakTimes] = generateECGSignal(rrPattern, ...
    Fs, baseline, peakVal, riseMs, fallMs)

    signal    = [];
    timeVec   = [];
    peakTimes = [];
    tCurrent  = 0;

    riseN = round(riseMs / 1000 * Fs);
    fallN = round(fallMs / 1000 * Fs);

    for b = 1:length(rrPattern)
        beatN = round(rrPattern(b) / 1000 * Fs);
        flatN = max(1, beatN - riseN - fallN);

        % Rise phase
        riseVec = linspace(baseline, peakVal, riseN);
        % Fall phase
        fallVec = linspace(peakVal, baseline, fallN);
        % Flat phase
        flatVec = baseline * ones(1, flatN);

        beat = [riseVec, fallVec, flatVec];

        % Record time of peak (at end of rise phase)
        peakTimes(end+1) = tCurrent + riseMs/1000;

        tBeat = tCurrent + (0:length(beat)-1) / Fs;
        signal  = [signal,  beat];
        timeVec = [timeVec, tBeat];
        tCurrent = tCurrent + length(beat)/Fs;
    end
end

% Adaptive threshold detection on signal
function [rrIntervals, peakIdxs, threshVec] = ...
    adaptiveDetect(signal, Fs, baseline, peakVal, ...
                   threshRatio, baseAlpha, peakAlpha, ...
                   minAmp, minRR, maxRR)

    adaptBaseline  = baseline;
    adaptPeak      = peakVal;
    adaptThreshold = baseline + threshRatio * (peakVal - baseline);

    lastPeakIdx = -1;
    lastVal     = signal(1);
    peakDet     = false;

    rrIntervals = [];
    peakIdxs    = [];
    threshVec   = zeros(1, length(signal));

    for i = 1:length(signal)
        v = signal(i);

        % Update baseline EMA
        adaptBaseline = adaptBaseline + baseAlpha * (v - adaptBaseline);

        % Update peak EMA only when above threshold
        if v > adaptThreshold
            adaptPeak = adaptPeak + peakAlpha * (v - adaptPeak);
        end

        % Recompute threshold
        amplitude      = adaptPeak - adaptBaseline;
        adaptThreshold = adaptBaseline + threshRatio * amplitude;
        threshVec(i)   = adaptThreshold;

        % Amplitude guard
        if amplitude < minAmp
            peakDet = false;
            lastVal = v;
            continue;
        end

        % Rising edge detection
        if lastVal < adaptThreshold && v >= adaptThreshold && ~peakDet
            if lastPeakIdx > 0
                rrMs = (i - lastPeakIdx) / Fs * 1000;
                if rrMs >= minRR && rrMs <= maxRR
                    rrIntervals(end+1) = rrMs;
                    peakIdxs(end+1)    = i;
                end
            end
            lastPeakIdx = i;
            peakDet     = true;
        end

        % Refractory reset
        if v < adaptThreshold - 0.2 * amplitude
            peakDet = false;
        end

        lastVal = v;
    end
end

% Calculate HRV features from RR intervals
function features = calculateFeatures(rr)
    mean_rr = mean(rr);
    std_rr  = std(rr, 1);         % population std (matches ESP32 code)
    cv      = std_rr / mean_rr;
    mean_hr = 60000 / mean_rr;

    diffs   = diff(rr);
    rmssd   = sqrt(mean(diffs.^2));
    pnn50   = sum(abs(diffs) > 50) / length(diffs) * 100;

    features.mean_rr = mean_rr;
    features.std_rr  = std_rr;
    features.cv      = cv;
    features.mean_hr = mean_hr;
    features.rmssd   = rmssd;
    features.pnn50   = pnn50;
end

% Classify AF from features
function [result, score, confidence] = classifyAF(features, ...
    cvThr, rmssdThr, pnn50Thr)

    score = 0;
    if features.cv    > cvThr    ; score = score + 2; end
    if features.rmssd > rmssdThr ; score = score + 2; end
    if features.pnn50 > pnn50Thr ; score = score + 1; end

    confidence = score / 5 * 100;
    result     = score >= 3;
end

%% ── RUN ALL 4 TEST CASES ─────────────────────────────────

results = struct();

for t = 1:nTests
    tc = testCases(t);

    % Generate ADC signal
    [sig, tvec, ~] = generateECGSignal(tc.rrPattern, Fs, ...
        ADC_BASELINE, ADC_PEAK, RISE_MS, FALL_MS);

    % Add mild Gaussian noise (realistic ADC noise ~±15 ADC units)
    rng(t);  % fixed seed per test for reproducibility
    noise = 15 * randn(size(sig));
    sig   = sig + noise;

    % Run adaptive threshold detection
    [rrDet, pkIdx, threshVec] = adaptiveDetect(sig, Fs, ...
        ADC_BASELINE, ADC_PEAK, THRESHOLD_RATIO, ...
        BASELINE_ALPHA, PEAK_ALPHA, MIN_AMPLITUDE, MIN_RR, MAX_RR);

    % Use detected RR intervals (up to WINDOW_SIZE)
    if length(rrDet) >= WINDOW_SIZE
        rrUsed = rrDet(1:WINDOW_SIZE);
    else
        rrUsed = rrDet;
    end

    % Calculate features
    if length(rrUsed) >= 5
        feat = calculateFeatures(rrUsed);
    else
        feat = struct('mean_rr',0,'std_rr',0,'cv',0,...
                      'mean_hr',0,'rmssd',0,'pnn50',0);
    end

    % Classify
    [afResult, afScore, afConf] = classifyAF(feat, ...
        CV_THRESH, RMSSD_THRESH, PNN50_THRESH);

    % Store
    results(t).tc        = tc;
    results(t).sig       = sig;
    results(t).tvec      = tvec;
    results(t).threshVec = threshVec;
    results(t).pkIdx     = pkIdx;
    results(t).rrDet     = rrDet;
    results(t).rrUsed    = rrUsed;
    results(t).feat      = feat;
    results(t).afResult  = afResult;
    results(t).afScore   = afScore;
    results(t).afConf    = afConf;
    results(t).pass      = (afResult == strcmp(tc.expected, 'POSSIBLE AF'));
end

%% ── FIGURE 1: ECG WAVEFORMS WITH ADAPTIVE THRESHOLD ─────
% Shows the raw simulated signal, the moving adaptive threshold,
% and the detected R-peaks for each test case

figure('Name','Figure 1 - ECG Waveforms & Adaptive Threshold',...
       'Position',[50 50 1400 900],'Color','white');

for t = 1:nTests
    r  = results(t);
    tc = r.tc;

    subplot(4, 1, t);
    hold on;

    % Plot ECG signal
    plot(r.tvec, r.sig, 'Color', [0.3 0.3 0.3], ...
         'LineWidth', 0.8, 'DisplayName', 'ECG Signal');

    % Plot adaptive threshold
    plot(r.tvec, r.threshVec, '--', 'Color', [0.85 0.65 0.10], ...
         'LineWidth', 1.5, 'DisplayName', 'Adaptive Threshold');

    % Plot detected R-peaks
    if ~isempty(r.pkIdx)
        plot(r.tvec(r.pkIdx), r.sig(r.pkIdx), 'v', ...
             'Color', tc.color, 'MarkerFaceColor', tc.color, ...
             'MarkerSize', 7, 'DisplayName', 'Detected R-peaks');
    end

    % Result annotation box
    if r.afResult
        resultStr = 'POSSIBLE AF';
        boxColor  = [1.0 0.85 0.85];
        txtColor  = [0.75 0.10 0.10];
    else
        resultStr = 'NORMAL';
        boxColor  = [0.85 1.0 0.88];
        txtColor  = [0.10 0.50 0.20];
    end

    xlims = xlim;
    ylims = [1500, 2050];
    ylim(ylims);

    text(r.tvec(end)*0.02, 2020, ...
         sprintf('[%s]  Score: %d/5  Conf: %d%%', ...
                 resultStr, r.afScore, round(r.afConf)), ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', txtColor, ...
         'BackgroundColor', boxColor, 'EdgeColor', txtColor);

    title(sprintf('Test %d: %s', t, tc.name), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', tc.color);
    xlabel('Time (s)', 'FontSize', 9);
    ylabel('ADC Value', 'FontSize', 9);
    legend('Location', 'northeast', 'FontSize', 8);
    grid on; box on;
    set(gca, 'FontSize', 9, 'GridAlpha', 0.3);
    hold off;
end

sgtitle({'Figure 1: Simulated ECG Signals with Adaptive Threshold Detection', ...
         'ESP32 ADC scale (0-4095) | Fs = 250 Hz | Baseline \approx1640 | Peak \approx1960'}, ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── FIGURE 2: RR INTERVAL TACHOGRAMS ─────────────────────
% Tachogram = plot of RR interval vs beat number
% This is how cardiologists visually inspect HRV
% Normal rhythm = flat line; AF = chaotic scatter

figure('Name','Figure 2 - RR Interval Tachograms',...
       'Position',[50 50 1400 900],'Color','white');

for t = 1:nTests
    r  = results(t);
    tc = r.tc;

    subplot(2, 2, t);
    hold on;

    beatNums = 1:length(r.rrUsed);

    % Stem plot for tachogram
    stem(beatNums, r.rrUsed, 'Color', tc.color, ...
         'MarkerFaceColor', tc.color, 'MarkerSize', 4, ...
         'LineWidth', 1.2);

    % Mean RR line
    yline(r.feat.mean_rr, '--k', sprintf('Mean: %.0f ms', r.feat.mean_rr), ...
          'LineWidth', 1.5, 'FontSize', 9, 'LabelHorizontalAlignment', 'left');

    % Result box
    if r.afResult
        annotStr = sprintf('POSSIBLE AF\nScore: %d/5', r.afScore);
        bgc = [1.0 0.88 0.88];
    else
        annotStr = sprintf('NORMAL\nScore: %d/5', r.afScore);
        bgc = [0.88 1.0 0.90];
    end

    text(length(r.rrUsed)*0.65, max(r.rrUsed)*0.95, annotStr, ...
         'FontSize', 10, 'FontWeight', 'bold', ...
         'BackgroundColor', bgc, 'EdgeColor', tc.color, ...
         'HorizontalAlignment', 'center');

    title(sprintf('Test %d: %s', t, tc.shortname), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', tc.color);
    xlabel('Beat Number', 'FontSize', 9);
    ylabel('RR Interval (ms)', 'FontSize', 9);
    xlim([0, length(r.rrUsed)+1]);
    grid on; box on;
    set(gca, 'FontSize', 9, 'GridAlpha', 0.3);
    hold off;
end

sgtitle({'Figure 2: RR Interval Tachograms (Beat-to-Beat Variability)', ...
         '30-beat analysis windows | Flat = regular | Scattered = irregular'}, ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── FIGURE 3: HRV FEATURE COMPARISON ────────────────────
% Bar charts comparing CV, RMSSD, and pNN50 across all 4
% test cases with threshold lines clearly visible

figure('Name','Figure 3 - HRV Feature Comparison',...
       'Position',[50 50 1400 600],'Color','white');

% Extract feature values
cvVals    = arrayfun(@(r) r.feat.cv,    results);
rmssdVals = arrayfun(@(r) r.feat.rmssd, results);
pnn50Vals = arrayfun(@(r) r.feat.pnn50, results);
names     = {testCases.shortname};
colors    = cat(1, testCases.color);

% ── CV plot ──
subplot(1, 3, 1);
b1 = bar(cvVals, 'FaceColor', 'flat');
for i = 1:nTests; b1.CData(i,:) = colors(i,:); end
yline(CV_THRESH, '--r', sprintf('Threshold = %.2f', CV_THRESH), ...
      'LineWidth', 2, 'FontSize', 10, 'FontWeight', 'bold');
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15, 'FontSize', 9);
ylabel('CV (dimensionless)', 'FontSize', 10);
title('Coefficient of Variation (CV)', 'FontSize', 11, 'FontWeight', 'bold');
grid on; box on;
% Value labels
for i = 1:nTests
    text(i, cvVals(i) + 0.005, sprintf('%.4f', cvVals(i)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

% ── RMSSD plot ──
subplot(1, 3, 2);
b2 = bar(rmssdVals, 'FaceColor', 'flat');
for i = 1:nTests; b2.CData(i,:) = colors(i,:); end
yline(RMSSD_THRESH, '--r', sprintf('Threshold = %.0f ms', RMSSD_THRESH), ...
      'LineWidth', 2, 'FontSize', 10, 'FontWeight', 'bold');
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15, 'FontSize', 9);
ylabel('RMSSD (ms)', 'FontSize', 10);
title('Root Mean Square of Successive Differences', 'FontSize', 11, 'FontWeight', 'bold');
grid on; box on;
for i = 1:nTests
    text(i, rmssdVals(i) + 1, sprintf('%.1f', rmssdVals(i)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

% ── pNN50 plot ──
subplot(1, 3, 3);
b3 = bar(pnn50Vals, 'FaceColor', 'flat');
for i = 1:nTests; b3.CData(i,:) = colors(i,:); end
yline(PNN50_THRESH, '--r', sprintf('Threshold = %.0f%%', PNN50_THRESH), ...
      'LineWidth', 2, 'FontSize', 10, 'FontWeight', 'bold');
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 15, 'FontSize', 9);
ylabel('pNN50 (%)', 'FontSize', 10);
title('Percentage of Successive Differences > 50ms', 'FontSize', 11, 'FontWeight', 'bold');
grid on; box on;
for i = 1:nTests
    text(i, pnn50Vals(i) + 0.5, sprintf('%.1f%%', pnn50Vals(i)), ...
         'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

sgtitle({'Figure 3: HRV Feature Values vs Clinical Thresholds', ...
         'Red dashed line = classification threshold | Bars above threshold contribute to AF score'}, ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── FIGURE 4: CLASSIFIER DECISION DASHBOARD ─────────────
% Full summary panel showing scoring breakdown and result
% for each test case — matches what is shown on ESP32 serial

figure('Name','Figure 4 - AF Classifier Decision Dashboard',...
       'Position',[50 50 1400 750],'Color','white');

for t = 1:nTests
    r  = results(t);
    tc = r.tc;
    f  = r.feat;

    subplot(2, 2, t);
    hold on; axis off;

    % Background colour by result
    if r.afResult
        bgRect = [1.0 0.92 0.92];
        resultLabel = 'POSSIBLE AF DETECTED';
        resultColor = [0.75 0.10 0.10];
    else
        bgRect = [0.92 1.0 0.94];
        resultLabel = 'NORMAL SINUS RHYTHM';
        resultColor = [0.10 0.50 0.20];
    end

    % Draw background
    rectangle('Position',[0 0 10 10], 'FaceColor', bgRect, ...
              'EdgeColor', tc.color, 'LineWidth', 2);

    % Title
    text(5, 9.3, sprintf('TEST %d: %s', t, upper(tc.shortname)), ...
         'HorizontalAlignment','center','FontSize',11,...
         'FontWeight','bold','Color',tc.color);

    % Feature rows with flag indicators
    rowY   = [7.8, 6.8, 5.8];
    labels = {'CV', 'RMSSD', 'pNN50'};
    vals   = [f.cv, f.rmssd, f.pnn50];
    thrs   = [CV_THRESH, RMSSD_THRESH, PNN50_THRESH];
    units  = {'', ' ms', '%'};
    pts    = [2, 2, 1];

    for i = 1:3
        flagged = vals(i) > thrs(i);
        if flagged
            rowColor = [0.75 0.10 0.10];
            flagStr  = sprintf('+%d pts  [FLAG]', pts(i));
        else
            rowColor = [0.10 0.10 0.10];
            flagStr  = '0 pts   [OK]';
        end
        text(1, rowY(i), sprintf('%s:', labels{i}), ...
             'FontSize', 10, 'Color', [0.3 0.3 0.3]);
        text(3.5, rowY(i), sprintf('%.4g%s', vals(i), units{i}), ...
             'FontSize', 10, 'FontWeight', 'bold', 'Color', rowColor);
        text(6.5, rowY(i), sprintf('> %.4g%s ?', thrs(i), units{i}), ...
             'FontSize', 9, 'Color', [0.4 0.4 0.4]);
        text(8.2, rowY(i), flagStr, ...
             'FontSize', 9, 'FontWeight', 'bold', 'Color', rowColor);
    end

    % Divider line
    plot([0.5 9.5], [5.2 5.2], '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    % Score bar
    scoreBarW = (r.afScore / 5) * 7;
    rectangle('Position',[1.5 4.2 7 0.6], 'FaceColor',[0.88 0.88 0.88], ...
              'EdgeColor',[0.6 0.6 0.6]);
    if r.afScore > 0
        rectangle('Position',[1.5 4.2 scoreBarW 0.6], ...
                  'FaceColor', resultColor, 'EdgeColor', resultColor);
    end
    text(5, 3.7, sprintf('Score: %d / 5  (%d%% confidence)', ...
         r.afScore, round(r.afConf)), ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.3 0.3 0.3]);

    % Result
    text(5, 2.7, resultLabel, 'HorizontalAlignment','center', ...
         'FontSize', 13, 'FontWeight', 'bold', 'Color', resultColor);

    % Pass/fail
    passStr = 'PASS ✓';
    if ~r.pass; passStr = 'FAIL ✗'; end
    text(5, 1.8, sprintf('Expected: %s  |  %s', tc.expected, passStr), ...
         'HorizontalAlignment','center','FontSize',9,'Color',[0.3 0.3 0.3]);

    % Reference
    text(5, 0.8, sprintf('Ref: %s', tc.reference), ...
         'HorizontalAlignment','center','FontSize',8,'Color',[0.5 0.5 0.5],...
         'FontAngle','italic');

    xlim([0 10]); ylim([0 10]);
    hold off;
end

sgtitle({'Figure 4: AF Classifier Decision Dashboard', ...
         'Rule-based scoring | CV(x2) + RMSSD(x2) + pNN50(x1) | Threshold: Score ≥ 3/5'}, ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── FIGURE 5: ADAPTIVE THRESHOLD TRACKING ───────────────
% Zoomed view of Test 1 (normal) vs Test 2 (AF)
% showing how the threshold moves with the signal
% This is the key figure showing WHY adaptive > fixed

figure('Name','Figure 5 - Adaptive vs Fixed Threshold Comparison',...
       'Position',[50 50 1400 700],'Color','white');

FIXED_THRESHOLD = 2000; % old production value

for t = [1, 2]
    r  = results(t);
    tc = r.tc;

    % Show only first 10 seconds
    showSecs  = 10;
    showIdx   = r.tvec <= showSecs;
    tShow     = r.tvec(showIdx);
    sShow     = r.sig(showIdx);
    thrShow   = r.threshVec(showIdx);

    % Fixed threshold would miss peaks if signal below 2000
    fixedHits = sum(r.sig(r.pkIdx) >= FIXED_THRESHOLD & ...
                    r.tvec(r.pkIdx) <= showSecs);
    adaptHits = sum(r.tvec(r.pkIdx) <= showSecs);

    subplot(2, 1, t - 0);
    hold on;

    % Signal
    plot(tShow, sShow, 'Color',[0.3 0.3 0.3], 'LineWidth', 0.8, ...
         'DisplayName','ECG Signal');

    % Fixed threshold
    yline(FIXED_THRESHOLD, ':', 'Color',[0.7 0.2 0.2], 'LineWidth', 2, ...
          'DisplayName', sprintf('Fixed Threshold = %d (old v3.0)', FIXED_THRESHOLD));

    % Adaptive threshold
    plot(tShow, thrShow, '--', 'Color',[0.85 0.65 0.10], 'LineWidth', 2, ...
         'DisplayName', 'Adaptive Threshold (v5.0)');

    % Detected peaks
    pkInRange = r.pkIdx(r.tvec(r.pkIdx) <= showSecs);
    if ~isempty(pkInRange)
        plot(r.tvec(pkInRange), r.sig(pkInRange), 'v', ...
             'Color', tc.color, 'MarkerFaceColor', tc.color, ...
             'MarkerSize', 8, 'DisplayName', 'Detected R-peaks');
    end

    ylim([1500, 2100]);
    title(sprintf('Test %d: %s | Adaptive peaks detected: %d | Fixed would detect: %d', ...
                  t, tc.name, adaptHits, fixedHits), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', tc.color);
    xlabel('Time (s)', 'FontSize', 10);
    ylabel('ADC Value', 'FontSize', 10);
    legend('Location','northeast','FontSize', 9);
    grid on; box on;
    set(gca,'FontSize', 9,'GridAlpha', 0.3);
    hold off;
end

sgtitle({'Figure 5: Adaptive Threshold vs Fixed Threshold Comparison', ...
         'Observed signal peaks ~1960 — fixed threshold of 2000 would detect ZERO beats'}, ...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── PRINT RESULTS SUMMARY TO CONSOLE ────────────────────

fprintf('\n============================================================\n');
fprintf('  AF DETECTION SYSTEM v5.0 - MATLAB SIMULATION RESULTS\n');
fprintf('  Window: %d beats | CV>%.2f | RMSSD>%.0fms | pNN50>%.0f%%\n', ...
        WINDOW_SIZE, CV_THRESH, RMSSD_THRESH, PNN50_THRESH);
fprintf('============================================================\n\n');

allPass = true;

for t = 1:nTests
    r  = results(t);
    tc = r.tc;
    f  = r.feat;

    fprintf('TEST %d: %s\n', t, tc.name);
    fprintf('  Description : %s\n', tc.description);
    fprintf('  Reference   : %s\n', tc.reference);
    fprintf('  Beats used  : %d\n', length(r.rrUsed));
    fprintf('  Mean RR     : %.1f ms\n', f.mean_rr);
    fprintf('  Mean HR     : %.1f BPM\n', f.mean_hr);
    fprintf('  Std RR      : %.2f ms\n', f.std_rr);
    fprintf('  CV          : %.4f  %s\n', f.cv, ...
            ternary(f.cv > CV_THRESH, '> 0.15 [FLAG +2]', '< 0.15 [OK]'));
    fprintf('  RMSSD       : %.2f ms  %s\n', f.rmssd, ...
            ternary(f.rmssd > RMSSD_THRESH, '> 40ms [FLAG +2]', '< 40ms [OK]'));
    fprintf('  pNN50       : %.1f%%  %s\n', f.pnn50, ...
            ternary(f.pnn50 > PNN50_THRESH, '> 43%% [FLAG +1]', '< 43%% [OK]'));
    fprintf('  AF Score    : %d / 5  (%d%% confidence)\n', ...
            r.afScore, round(r.afConf));

    if r.afResult
        fprintf('  RESULT      : ** POSSIBLE AF DETECTED **\n');
    else
        fprintf('  RESULT      : Normal Sinus Rhythm\n');
    end

    fprintf('  Expected    : %s\n', tc.expected);
    if r.pass
        fprintf('  Outcome     : PASS\n');
    else
        fprintf('  Outcome     : FAIL  <-- review thresholds\n');
        allPass = false;
    end
    fprintf('\n');
end

fprintf('============================================================\n');
if allPass
    fprintf('  ALL TESTS PASSED\n');
    fprintf('  Classifier correctly distinguishes all 4 rhythm types.\n');
else
    fprintf('  ONE OR MORE TESTS FAILED - review threshold values.\n');
end
fprintf('============================================================\n\n');

%% ── HELPER: ternary operator ─────────────────────────────
function out = ternary(cond, a, b)
    if cond; out = a; else; out = b; end
end
