
import '../models/measurement.dart';
import '../models/user_profile.dart';

enum CombinedRiskState {
  lowBurdenLowScore, // Green  — reassuring
  lowBurdenHighScore, // Amber  — risk factors elevated, no AF yet
  highBurdenLowScore, // Orange — rhythm concern, low clinical risk
  highBurdenHighScore, // Red    — urgent
}

class RiskService {
  // ── CHA2DS2-VASc helpers ─────────────────────────────────
  static String getRiskLevel(UserProfile profile) => profile.strokeRiskLevel;
  static int getRiskScore(UserProfile profile) => profile.strokeRiskScore;

  // ── Risk description for score card ─────────────────────
  static String getRiskDescription(UserProfile profile) {
    final name = profile.name.split(' ').first;
    switch (profile.strokeRiskLevel) {
      case 'Low':
        return '$name, your current risk factors suggest a low probability of stroke. '
            'Keep maintaining a healthy lifestyle.';
      case 'Moderate':
        return '$name, your risk factors suggest a moderate probability of stroke. '
            'Please consult your healthcare provider for guidance.';
      case 'High':
        return '$name, your risk factors suggest a high probability of stroke. '
            'Please consult a healthcare provider as soon as possible.';
      default:
        return '';
    }
  }

  // ── AF Burden (rolling 30-day window) ────────────────────
  static double getAFBurden(List<Measurement> measurements, {int days = 30}) {
    if (measurements.isEmpty) return 0.0;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = measurements
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
    if (recent.isEmpty) return 0.0;
    final afCount = recent.where((m) => m.afPrediction == 1).length;
    return (afCount / recent.length) * 100;
  }

  // ── Heart rate trend ─────────────────────────────────────
  static String getHeartRateTrend(List<Measurement> measurements) {
    if (measurements.length < 2) return 'Not enough data';
    final recent = measurements.take(5).toList();
    final older = measurements.skip(5).take(5).toList();
    if (older.isEmpty) return 'Not enough data';
    final recentAvg =
        recent.map((m) => m.heartRate).reduce((a, b) => a + b) / recent.length;
    final olderAvg =
        older.map((m) => m.heartRate).reduce((a, b) => a + b) / older.length;
    final diff = recentAvg - olderAvg;
    if (diff > 5) return 'Increasing';
    if (diff < -5) return 'Decreasing';
    return 'Stable';
  }

  // ── Monitoring consistency ───────────────────────────────
  static String getMonitoringConsistency(List<Measurement> measurements) {
    if (measurements.isEmpty) return 'No readings yet';
    final last7Days = measurements
        .where(
          (m) => m.timestamp.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
        .length;
    if (last7Days >= 6) return 'Excellent';
    if (last7Days >= 4) return 'Good';
    if (last7Days >= 2) return 'Fair';
    return 'Poor';
  }

  // ── Combined state classifier ────────────────────────────
  // Grounded in:
  // - Botto et al. (2009) / Stroke (2011): AF burden threshold for stroke risk
  // - Circulation (2019): AF duration × CHA2DS2-VASc interaction
  // - ESC 2020 AF Guidelines: anticoagulation thresholds
  static CombinedRiskState getCombinedState(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final afBurden = getAFBurden(measurements);
    final isHighScore = _isHighChaScore(profile);
    final isHighBurden = afBurden >= 20.0;

    if (!isHighBurden && !isHighScore)
      return CombinedRiskState.lowBurdenLowScore;
    if (!isHighBurden && isHighScore)
      return CombinedRiskState.lowBurdenHighScore;
    if (isHighBurden && !isHighScore)
      return CombinedRiskState.highBurdenLowScore;
    return CombinedRiskState.highBurdenHighScore;
  }

  /// High score: ≥2 for males, ≥3 for females (ESC 2020 anticoagulation threshold)
  static bool _isHighChaScore(UserProfile profile) {
    final score = profile.strokeRiskScore;
    return profile.gender == 'Female' ? score >= 3 : score >= 2;
  }

  // ── One-sentence banner text ─────────────────────────────
  static String getCombinedInterpretation(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final state = getCombinedState(profile, measurements);
    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return 'Your heart rhythm appears regular and your stroke risk factors are currently low — keep monitoring regularly.';
      case CombinedRiskState.lowBurdenHighScore:
        return 'No irregular rhythm detected yet, but your clinical risk factors are elevated — more frequent screening and a doctor visit are recommended.';
      case CombinedRiskState.highBurdenLowScore:
        return 'Irregular rhythm detected frequently — even with low clinical risk factors, this needs medical review soon.';
      case CombinedRiskState.highBurdenHighScore:
        return 'High irregular rhythm burden combined with elevated stroke risk factors — seek clinical review urgently.';
    }
  }

  // ── State label ──────────────────────────────────────────
  static String getCombinedStateLabel(CombinedRiskState state) {
    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return 'Low Combined Risk';
      case CombinedRiskState.lowBurdenHighScore:
        return 'Elevated Clinical Risk';
      case CombinedRiskState.highBurdenLowScore:
        return 'Rhythm Concern';
      case CombinedRiskState.highBurdenHighScore:
        return 'High Combined Risk';
    }
  }

  // ── Actions per state ────────────────────────────────────
  static List<String> getActions(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final state = getCombinedState(profile, measurements);
    final name = profile.name.split(' ').first;

    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return [
          'Rescreen with CheckIn everyday.',
          'Keep up with regular blood pressure checks.',
          'If you feel palpitations, dizziness, or shortness of breath before your next scheduled session, test immediately.',
        ];

      case CombinedRiskState.lowBurdenHighScore:
        return [
          '$name, discuss these results with a doctor or community health worker and show them your PDF report.',
          'Ask your doctor whether you need a Holter monitor or longer ECG recording to rule out paroxysmal AF — it can occur in short episodes that a single session may miss.',
          'Rescreen everyday to keep monitoring.',
          'Ensure your blood pressure and blood sugar are being actively managed with medication if prescribed.',
        ];

      case CombinedRiskState.highBurdenLowScore:
        return [
          '$name, visit a doctor or clinic as soon as possible and bring your CheckIn PDF report.',
          'A 12-lead ECG or Holter monitor recording is needed to confirm whether the irregular rhythm is true AF.',
          'Do not wait for symptoms — AF is frequently silent.',
          'Stop screening at home until you have seen a doctor — professional evaluation is now the priority.',
        ];

      case CombinedRiskState.highBurdenHighScore:
        return [
          '$name, seek medical care urgently. Do not delay — show your CheckIn PDF report to the doctor.',
          'A 12-lead ECG is needed immediately to confirm AF.',
          'If AF is confirmed, your doctor may discuss anticoagulation therapy (blood thinners) to reduce stroke risk. Per ESC 2020 guidelines, this is recommended for confirmed AF patients with a CHA\u2082DS\u2082-VASc score \u22652 in males or \u22653 in females.',
          'Continue monitoring with CheckIn to track AF burden over time and share updated reports at each clinical visit.',
        ];
    }
  }

  // ── Lifestyle tips per state ─────────────────────────────
  static List<String> getLifestyleTips(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final state = getCombinedState(profile, measurements);

    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return [
          'Reduce salt intake — high salt raises blood pressure which is a key AF trigger.',
          'Aim for at least 30 minutes of moderate activity like walking most days of the week.',
          'Limit alcohol — even moderate drinking can trigger irregular heart rhythm.',
          'Maintain a healthy weight — obesity significantly increases AF risk.',
          'If you smoke, stopping is the single most impactful change you can make for heart health.',
        ];

      case CombinedRiskState.lowBurdenHighScore:
        return [
          'Take your blood pressure or diabetes medications consistently — missing doses significantly raises stroke risk.',
          'Follow a low-salt, low-sugar diet — both hypertension and diabetes are directly worsened by diet.',
          'Avoid heavy physical exertion without medical clearance.',
          'Know the warning signs of stroke: sudden face drooping, arm weakness, difficulty speaking. Seek emergency care immediately if they occur.',
        ];

      case CombinedRiskState.highBurdenLowScore:
        return [
          'Reduce or eliminate caffeine and alcohol — both are common AF triggers, especially at high burden levels.',
          'Avoid high-stress situations and get adequate sleep — stress and sleep deprivation are documented AF triggers.',
          'Do not take new herbal or traditional medicines without telling your doctor — some can affect heart rhythm.',
          'Avoid strenuous exercise until AF is confirmed or ruled out by a clinician.',
        ];

      case CombinedRiskState.highBurdenHighScore:
        return [
          'Take all prescribed medications for blood pressure, diabetes, and heart conditions without skipping doses.',
          'Strictly limit salt and sugar — both directly worsen the underlying risk factors contributing to your score.',
          'Avoid alcohol completely — it is a direct AF trigger and raises blood pressure.',
          'Rest adequately — aim for 7 to 8 hours of sleep per night.',
          'Do not travel far from medical facilities until you have been seen by a doctor and a management plan is in place.',
          'Know the signs of stroke and keep the number of a nearby clinic or emergency contact accessible at all times.',
        ];
    }
  }

  // ── Legacy method kept for TTS compatibility ─────────────
  static List<String> getRecommendations(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    return [
      ...getActions(profile, measurements),
      ...getLifestyleTips(profile, measurements),
    ];
  }

  // ── Legacy urgency (kept for any other callers) ──────────
  static String getUrgencyLevel(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final state = getCombinedState(profile, measurements);
    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return 'Low';
      case CombinedRiskState.lowBurdenHighScore:
        return 'Moderate';
      case CombinedRiskState.highBurdenLowScore:
        return 'Moderate';
      case CombinedRiskState.highBurdenHighScore:
        return 'High';
    }
  }

  static String getUrgencyMessage(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final name = profile.name.split(' ').first;
    final urgency = getUrgencyLevel(profile, measurements);
    switch (urgency) {
      case 'High':
        return '$name, based on your readings and risk factors, we strongly recommend '
            'you see a doctor or visit a clinic this week. Bring this report with you.';
      case 'Moderate':
        return '$name, your readings and risk factors suggest you should discuss your '
            'heart health with a healthcare provider soon.';
      default:
        return '$name, your readings look reassuring. Keep monitoring and see a doctor '
            'if anything changes.';
    }
  }
}
