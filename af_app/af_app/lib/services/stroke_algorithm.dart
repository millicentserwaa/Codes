import '../models/measurement.dart';
import '../models/patient_profile.dart';

/// Modified CHA₂DS₂-VASc stroke risk algorithm.
///
/// Standard CHA₂DS₂-VASc factors:
///   C — Congestive heart failure       (not assessed, excluded)
///   H — Hypertension                   +1
///   A₂ — Age ≥ 75                      +2  (age 65–74 = +1)
///   D — Diabetes mellitus              +1
///   S₂ — Prior Stroke / TIA           +2
///   V — Vascular disease               (not assessed, excluded)
///   A — AF detected                    +1  (added: device result)
///   Sc — Sex category female           +1  (standard, included)
///
/// Extended with device HRV data:
///   HRV-CV — CV ≥ 0.15                +1
///   HRV-RMSSD — RMSSD ≥ 80 ms        +1
///   BP — Systolic BP ≥ 140 mmHg       +1
///
/// Max possible score: 12
/// Risk categories:
///   0   → Low
///   1–3 → Moderate
///   ≥4  → High

class StrokeAlgorithm {
  static StrokeScoreResult calculate({
    required PatientProfile profile,
    required double cv,
    required double rmssd,
    required AfResult afResult,
    int? systolicBP,
  }) {
    final factors = <ScoringFactor>[];
    int total = 0;

    // ── AF detected ──────────────────────────────────────────
    if (afResult == AfResult.possibleAF) {
      factors.add(ScoringFactor(
        name: 'Atrial Fibrillation Detected',
        points: 1,
        triggered: true,
        source: 'Device measurement',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Atrial Fibrillation Detected',
        points: 1,
        triggered: false,
        source: 'Device measurement',
      ));
    }

    // ── Age ───────────────────────────────────────────────────
    if (profile.age >= 75) {
      factors.add(ScoringFactor(
        name: 'Age ≥ 75 years',
        points: 2,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 2;
    } else if (profile.age >= 65) {
      factors.add(ScoringFactor(
        name: 'Age 65–74 years',
        points: 1,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Age < 65 years',
        points: 0,
        triggered: false,
        source: 'Patient profile',
      ));
    }

    // ── Sex (female = +1, standard CHA₂DS₂-VASc) ─────────────
    if (profile.sex == 'Female') {
      factors.add(ScoringFactor(
        name: 'Female sex',
        points: 1,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Female sex',
        points: 1,
        triggered: false,
        source: 'Patient profile',
      ));
    }

    // ── Hypertension ─────────────────────────────────────────
    if (profile.hasHypertension) {
      factors.add(ScoringFactor(
        name: 'Hypertension',
        points: 1,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Hypertension',
        points: 1,
        triggered: false,
        source: 'Patient profile',
      ));
    }

    // ── Diabetes ──────────────────────────────────────────────
    if (profile.hasDiabetes) {
      factors.add(ScoringFactor(
        name: 'Diabetes mellitus',
        points: 1,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Diabetes mellitus',
        points: 1,
        triggered: false,
        source: 'Patient profile',
      ));
    }

    // ── Prior stroke / TIA ────────────────────────────────────
    if (profile.hasPriorStrokeTIA) {
      factors.add(ScoringFactor(
        name: 'Prior Stroke or TIA',
        points: 2,
        triggered: true,
        source: 'Patient profile',
      ));
      total += 2;
    } else {
      factors.add(ScoringFactor(
        name: 'Prior Stroke or TIA',
        points: 2,
        triggered: false,
        source: 'Patient profile',
      ));
    }

    // ── Systolic BP ≥ 140 mmHg ────────────────────────────────
    final bp = systolicBP ?? profile.systolicBP;
    if (bp != null && bp >= 140) {
      factors.add(ScoringFactor(
        name: 'Elevated Blood Pressure ≥ 140 mmHg',
        points: 1,
        triggered: true,
        source: 'Blood pressure reading',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Elevated Blood Pressure ≥ 140 mmHg',
        points: 1,
        triggered: bp != null ? false : null,
        source: bp != null ? 'Blood pressure reading' : 'Not recorded',
      ));
    }

    // ── HRV: CV ≥ 0.15 ───────────────────────────────────────
    if (cv >= 0.15) {
      factors.add(ScoringFactor(
        name: 'Elevated HRV — High Irregularity (CV ≥ 0.15)',
        points: 1,
        triggered: true,
        source: 'Device HRV analysis',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Elevated HRV — High Irregularity (CV ≥ 0.15)',
        points: 1,
        triggered: false,
        source: 'Device HRV analysis',
      ));
    }

    // ── HRV: RMSSD ≥ 80 ms ───────────────────────────────────
    if (rmssd >= 80) {
      factors.add(ScoringFactor(
        name: 'Elevated HRV — Beat-to-Beat Variation (RMSSD ≥ 80 ms)',
        points: 1,
        triggered: true,
        source: 'Device HRV analysis',
      ));
      total += 1;
    } else {
      factors.add(ScoringFactor(
        name: 'Elevated HRV — Beat-to-Beat Variation (RMSSD ≥ 80 ms)',
        points: 1,
        triggered: false,
        source: 'Device HRV analysis',
      ));
    }

    // ── Risk category ─────────────────────────────────────────
    StrokeRisk risk;
    if (total == 0) {
      risk = StrokeRisk.low;
    } else if (total <= 3) {
      risk = StrokeRisk.moderate;
    } else {
      risk = StrokeRisk.high;
    }

    return StrokeScoreResult(
      totalScore: total,
      maxScore: 12,
      risk: risk,
      factors: factors,
    );
  }

  /// Generate personalised recommendations based on result + profile
  static List<Recommendation> getRecommendations({
    required StrokeScoreResult result,
    required PatientProfile profile,
    required AfResult afResult,
  }) {
    final recs = <Recommendation>[];

    // Always-present
    recs.add(const Recommendation(
      icon: '🔄',
      title: 'Continue Regular Monitoring',
      body: 'Use the AF-Screen device at the same time each day for consistent results. Aim for at least 3 readings per week.',
      priority: RecommendationPriority.info,
    ));

    // AF detected
    if (afResult == AfResult.possibleAF) {
      recs.add(const Recommendation(
        icon: '🏥',
        title: 'Seek Medical Evaluation',
        body: 'A possible atrial fibrillation result was detected. Please visit a clinic or hospital for a 12-lead ECG to confirm. Do not delay if you feel palpitations, dizziness, or chest discomfort.',
        priority: RecommendationPriority.urgent,
      ));
    }

    // High stroke risk
    if (result.risk == StrokeRisk.high) {
      recs.add(const Recommendation(
        icon: '⚠️',
        title: 'High Stroke Risk — See a Doctor',
        body: 'Your combined risk score is elevated. Share this app report with your doctor. If you experience sudden weakness, speech difficulties, or vision changes, call emergency services immediately.',
        priority: RecommendationPriority.urgent,
      ));
    }

    // BP
    if (profile.systolicBP != null && profile.systolicBP! >= 140) {
      recs.add(const Recommendation(
        icon: '💊',
        title: 'Manage Your Blood Pressure',
        body: 'Your recorded blood pressure is elevated (≥ 140 mmHg). Reduce salt intake, limit alcohol, exercise regularly, and take any prescribed antihypertensive medication consistently.',
        priority: RecommendationPriority.warning,
      ));
    }

    // Hypertension
    if (profile.hasHypertension) {
      recs.add(const Recommendation(
        icon: '📋',
        title: 'Blood Pressure Check',
        body: 'As someone with hypertension, monitor your blood pressure at least twice a week and keep a record to share with your doctor at each visit.',
        priority: RecommendationPriority.warning,
      ));
    }

    // Diabetes
    if (profile.hasDiabetes) {
      recs.add(const Recommendation(
        icon: '🩸',
        title: 'Blood Sugar Management',
        body: 'Good blood sugar control reduces your stroke risk. Take your medication as prescribed, follow a low-sugar diet, and monitor your glucose regularly.',
        priority: RecommendationPriority.warning,
      ));
    }

    // Lifestyle — always
    recs.add(const Recommendation(
      icon: '🚶',
      title: 'Stay Active',
      body: 'Aim for at least 30 minutes of moderate exercise (walking, swimming, cycling) on most days. Physical activity strengthens your heart and reduces AF and stroke risk.',
      priority: RecommendationPriority.info,
    ));

    recs.add(const Recommendation(
      icon: '🚭',
      title: 'Avoid Smoking and Limit Alcohol',
      body: 'Smoking and heavy alcohol consumption significantly increase the risk of AF and stroke. Seek support to quit smoking if needed.',
      priority: RecommendationPriority.info,
    ));

    recs.add(const Recommendation(
      icon: '😴',
      title: 'Sleep and Stress',
      body: 'Poor sleep and chronic stress are associated with increased AF episodes. Aim for 7–9 hours of sleep and practise stress-reduction techniques such as deep breathing.',
      priority: RecommendationPriority.info,
    ));

    // Sort: urgent first
    recs.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return recs;
  }
}

// ── Data classes ──────────────────────────────────────────────

class StrokeScoreResult {
  final int totalScore;
  final int maxScore;
  final StrokeRisk risk;
  final List<ScoringFactor> factors;

  const StrokeScoreResult({
    required this.totalScore,
    required this.maxScore,
    required this.risk,
    required this.factors,
  });
}

class ScoringFactor {
  final String name;
  final int points;
  final bool? triggered; // null = not assessed
  final String source;

  const ScoringFactor({
    required this.name,
    required this.points,
    required this.triggered,
    required this.source,
  });
}

enum RecommendationPriority { urgent, warning, info }

class Recommendation {
  final String icon;
  final String title;
  final String body;
  final RecommendationPriority priority;

  const Recommendation({
    required this.icon,
    required this.title,
    required this.body,
    required this.priority,
  });
}
