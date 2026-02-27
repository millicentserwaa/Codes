// import '../models/patient_profile.dart';
// import '../models/stroke_models.dart';

// class StrokeAlgorithm {
//   static StrokeScoreResult calculate({
//     required PatientProfile profile,
//     required double pRR50,
//     required double sdsd,
//     required int afResultIndex,   // ← int not AfResult (avoids circular import)
//     int? systolicBP,
//   }) {
//     final chadFactors = <ScoringFactor>[];
//     final hrvFactors = <ScoringFactor>[];
//     int total = 0;

//     //  STANDARD CHA₂DS₂-VASc FACTORS
//     if (profile.age >= 75) {
//       chadFactors.add(const ScoringFactor(
//         name: 'Age ≥ 75 years (A₂)', points: 2, triggered: true,
//         source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//       ));
//       total += 2;
//     } else if (profile.age >= 65) {
//       chadFactors.add(const ScoringFactor(
//         name: 'Age 65–74 years (A)', points: 1, triggered: true,
//         source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//       ));
//       total += 1;
//     } else {
//       chadFactors.add(const ScoringFactor(
//         name: 'Age < 65 years', points: 0, triggered: false,
//         source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//       ));
//     }

//     // Female sex +1
//     final isFemale = profile.sex == 'Female';
//     chadFactors.add(ScoringFactor(
//       name: 'Female sex (Sc)', points: 1, triggered: isFemale,
//       source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//     ));
//     if (isFemale) total += 1;

//     // Hypertension +1
//     chadFactors.add(ScoringFactor(
//       name: 'Hypertension (H)', points: 1, triggered: profile.hasHypertension,
//       source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//     ));
//     if (profile.hasHypertension) total += 1;

//     // Diabetes +1
//     chadFactors.add(ScoringFactor(
//       name: 'Diabetes mellitus (D)', points: 1, triggered: profile.hasDiabetes,
//       source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//     ));
//     if (profile.hasDiabetes) total += 1;

//     // Prior stroke/TIA +2
//     chadFactors.add(ScoringFactor(
//       name: 'Prior Stroke or TIA (S₂)', points: 2, triggered: profile.hasPriorStrokeTIA,
//       source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
//     ));
//     if (profile.hasPriorStrokeTIA) total += 2;

//     // DEVICE HRV ASSESSMENT
//     final bp = systolicBP ?? profile.systolicBP;
//     final bpTriggered = bp != null && bp >= 140;
//     hrvFactors.add(ScoringFactor(
//       name: 'Elevated Blood Pressure ≥ 140 mmHg', points: 0,
//       triggered: bp != null ? bpTriggered : null,
//       source: bp != null ? 'Blood pressure reading' : 'Not recorded',
//       reference: 'JNC 8. JAMA. 2014;311(5):507-520',
//     ));

//     // pRR50 < 3%
//     final lowPRR50 = pRR50 < 3.0;
//     hrvFactors.add(ScoringFactor(
//       name: 'Reduced Autonomic Modulation (pRR50 < 3%)', points: 0,
//       triggered: lowPRR50, source: 'Device HRV analysis',
//       reference: 'Liao et al. Stroke. 1997;28(10):1944-1950',
//     ));

//     // SDSD > 50ms
//     final highSdsd = sdsd > 50.0;
//     hrvFactors.add(ScoringFactor(
//       name: 'Excessive Beat-to-Beat Irregularity (SDSD > 50ms)', points: 0,
//       triggered: highSdsd, source: 'Device HRV analysis',
//       reference: 'Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065',
//     ));

//     final hrvFlagsTriggered = [bpTriggered, lowPRR50, highSdsd].where((f) => f).length;

//     // Risk category — standard CHA₂DS₂-VASc thresholds
//     StrokeRisk risk;
//     if (total == 0) {
//       risk = StrokeRisk.low;
//     } else if (total == 1) {
//       risk = StrokeRisk.lowModerate;
//     } else {
//       risk = StrokeRisk.high;
//     }

//     return StrokeScoreResult(
//       totalScore: total,
//       maxScore: 7,
//       risk: risk,
//       chadFactors: chadFactors,
//       hrvFactors: hrvFactors,
//       hrvFlagsTriggered: hrvFlagsTriggered,
//       afDetected: afResultIndex == 1,  // 1 = possibleAF
//     );
//   }

//   static List<Recommendation> getRecommendations({
//     required StrokeScoreResult result,
//     required PatientProfile profile,
//     required int afResultIndex,   // ← int not AfResult
//     required double pRR50,
//     required double sdsd,
//   }) {
//     final recs = <Recommendation>[];

//     if (afResultIndex == 1) {
//       recs.add(const Recommendation(
//         icon: '🏥', title: 'Possible AF Detected — Seek Medical Evaluation',
//         body: 'A possible atrial fibrillation result was detected. '
//             'Please visit a clinic or hospital for a 12-lead ECG to '
//             'confirm. Do not delay if you feel palpitations, '
//             'dizziness, or chest discomfort.',
//         priority: RecommendationPriority.urgent,
//       ));
//     }

//     if (result.risk == StrokeRisk.high) {
//       recs.add(const Recommendation(
//         icon: '⚠️', title: 'High Stroke Risk — See a Doctor',
//         body: 'Your CHA₂DS₂-VASc score indicates high stroke risk. '
//             'Anticoagulation therapy is recommended — discuss with '
//             'your doctor immediately. If you experience sudden '
//             'weakness, speech difficulties, or vision changes, '
//             'call emergency services immediately.',
//         priority: RecommendationPriority.urgent,
//       ));
//     }

//     if (result.risk == StrokeRisk.lowModerate) {
//       recs.add(const Recommendation(
//         icon: '📊', title: 'Low-Moderate Stroke Risk',
//         body: 'Your CHA₂DS₂-VASc score is 1. Anticoagulation may be '
//             'considered depending on your full clinical picture. '
//             'Discuss with your doctor, especially if AF was detected.',
//         priority: RecommendationPriority.warning,
//       ));
//     }

//     if (profile.hasPriorStrokeTIA) {
//       recs.add(const Recommendation(
//         icon: '🧠', title: 'Prior Stroke History — Stay Vigilant',
//         body: 'Your history of stroke or TIA significantly increases '
//             'recurrence risk. Ensure you are on appropriate '
//             'anticoagulation therapy and attend all follow-up appointments.',
//         priority: RecommendationPriority.urgent,
//       ));
//     }

//     if (result.hrvFlagsTriggered >= 2) {
//       recs.add(const Recommendation(
//         icon: '💓', title: 'Multiple HRV Risk Indicators Detected',
//         body: 'Your device measurements flagged multiple cardiac '
//             'risk indicators. While these do not directly modify '
//             'your CHA₂DS₂-VASc score, they suggest increased '
//             'cardiovascular risk. Share this report with your doctor.',
//         priority: RecommendationPriority.warning,
//       ));
//     } else if (pRR50 < 3.0) {
//       recs.add(const Recommendation(
//         icon: '💓', title: 'Reduced Heart Rate Variability',
//         body: 'Your pRR50 is below 3%, indicating reduced autonomic '
//             'nervous system activity. Regular aerobic exercise '
//             'can improve autonomic function over time.',
//         priority: RecommendationPriority.warning,
//       ));
//     } else if (sdsd > 50.0) {
//       recs.add(const Recommendation(
//         icon: '📈', title: 'Irregular Beat-to-Beat Pattern',
//         body: 'Your SDSD exceeds 50ms, indicating significant '
//             'beat-to-beat variability. Combined with other risk '
//             'factors, medical evaluation is advisable.',
//         priority: RecommendationPriority.warning,
//       ));
//     }

//     if (profile.systolicBP != null && profile.systolicBP! >= 140) {
//       recs.add(const Recommendation(
//         icon: '💊', title: 'Manage Your Blood Pressure',
//         body: 'Your recorded blood pressure is elevated (≥ 140 mmHg). '
//             'Reduce salt intake, limit alcohol, exercise regularly, '
//             'and take any prescribed antihypertensive medication. '
//             'Target BP < 130/80 mmHg per JNC 8 guidelines.',
//         priority: RecommendationPriority.warning,
//       ));
//     }

//     if (profile.hasHypertension) {
//       recs.add(const Recommendation(
//         icon: '📋', title: 'Blood Pressure Check',
//         body: 'Monitor your blood pressure at least twice a week '
//             'and keep a record to share with your doctor.',
//         priority: RecommendationPriority.warning,
//       ));
//     }

//     if (profile.hasDiabetes) {
//       recs.add(const Recommendation(
//         icon: '🩸', title: 'Blood Sugar Management',
//         body: 'Good blood sugar control reduces your stroke risk. '
//             'Take your medication as prescribed and monitor your glucose regularly.',
//         priority: RecommendationPriority.warning,
//       ));
//     }

//     recs.add(const Recommendation(
//       icon: '🚶', title: 'Stay Active',
//       body: 'Aim for at least 30 minutes of moderate exercise on most '
//           'days. Physical activity strengthens your heart, improves '
//           'autonomic function, and reduces AF and stroke risk.',
//       priority: RecommendationPriority.info,
//     ));

//     recs.add(const Recommendation(
//       icon: '🚭', title: 'Avoid Smoking and Limit Alcohol',
//       body: 'Smoking and heavy alcohol consumption significantly increase the risk of AF and stroke.',
//       priority: RecommendationPriority.info,
//     ));

//     recs.add(const Recommendation(
//       icon: '😴', title: 'Sleep and Stress',
//       body: 'Poor sleep and chronic stress are associated with increased AF episodes. Aim for 7–9 hours of sleep.',
//       priority: RecommendationPriority.info,
//     ));

//     recs.add(const Recommendation(
//       icon: '🔄', title: 'Continue Regular Monitoring',
//       body: 'Use the AF-Screen device at the same time each day. Aim for at least 3 readings per week.',
//       priority: RecommendationPriority.info,
//     ));

//     recs.sort((a, b) => a.priority.index.compareTo(b.priority.index));
//     return recs;
//   }
// }


import '../models/patient_profile.dart';
import '../models/stroke_models.dart';

// ── WHY we import stroke_models and NOT measurement.dart ──────────
// measurement.dart needs StrokeRisk, which lives in stroke_models.dart.
// If stroke_algorithm.dart imported measurement.dart, that would be circular:
//   stroke_algorithm → measurement → stroke_algorithm  ← CRASH
// Solution: shared types live in stroke_models.dart (no app imports).
// Both measurement.dart and stroke_algorithm.dart import stroke_models.dart safely.
//
// AfResult (defined in measurement.dart) is passed as int afResultIndex
// to avoid importing measurement.dart here.
//   0 = AfResult.normal
//   1 = AfResult.possibleAF
//   2 = AfResult.inconclusive

class StrokeAlgorithm {
  static StrokeScoreResult calculate({
    required PatientProfile profile,
    required double pRR50,
    required double sdsd,
    required int afResultIndex,   // ← int not AfResult (avoids circular import)
    int? systolicBP,
  }) {
    final chadFactors = <ScoringFactor>[];
    final hrvFactors = <ScoringFactor>[];
    int total = 0;

    // ════════════════════════════════════════════════════════
    // PART 1 — STANDARD CHA₂DS₂-VASc FACTORS
    // ════════════════════════════════════════════════════════

    // Age: A₂ ≥75 = +2 | A 65–74 = +1
    // Ref: Lip GYH et al. Chest. 2010;137(2):263-272
    if (profile.age >= 75) {
      chadFactors.add(const ScoringFactor(
        name: 'Age ≥ 75 years (A₂)', points: 2, triggered: true,
        source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
      ));
      total += 2;
    } else if (profile.age >= 65) {
      chadFactors.add(const ScoringFactor(
        name: 'Age 65–74 years (A)', points: 1, triggered: true,
        source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
      ));
      total += 1;
    } else {
      chadFactors.add(const ScoringFactor(
        name: 'Age < 65 years', points: 0, triggered: false,
        source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
      ));
    }

    // Female sex +1
    final isFemale = profile.sex == 'Female';
    chadFactors.add(ScoringFactor(
      name: 'Female sex (Sc)', points: 1, triggered: isFemale,
      source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
    ));
    if (isFemale) total += 1;

    // Hypertension +1
    chadFactors.add(ScoringFactor(
      name: 'Hypertension (H)', points: 1, triggered: profile.hasHypertension,
      source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
    ));
    if (profile.hasHypertension) total += 1;

    // Diabetes +1
    chadFactors.add(ScoringFactor(
      name: 'Diabetes mellitus (D)', points: 1, triggered: profile.hasDiabetes,
      source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
    ));
    if (profile.hasDiabetes) total += 1;

    // Prior stroke/TIA +2
    chadFactors.add(ScoringFactor(
      name: 'Prior Stroke or TIA (S₂)', points: 2, triggered: profile.hasPriorStrokeTIA,
      source: 'Patient profile', reference: 'Lip GYH et al. Chest. 2010;137(2):263-272',
    ));
    if (profile.hasPriorStrokeTIA) total += 2;

    // ════════════════════════════════════════════════════════
    // PART 2 — DEVICE HRV ASSESSMENT (informational only)
    // ════════════════════════════════════════════════════════

    // BP ≥ 140 mmHg
    // Ref: JNC 8. JAMA. 2014;311(5):507-520
    final bp = systolicBP ?? profile.systolicBP;
    final bpTriggered = bp != null && bp >= 140;
    hrvFactors.add(ScoringFactor(
      name: 'Elevated Blood Pressure ≥ 140 mmHg', points: 0,
      triggered: bp != null ? bpTriggered : null,
      source: bp != null ? 'Blood pressure reading' : 'Not recorded',
      reference: 'JNC 8. JAMA. 2014;311(5):507-520',
    ));

    // pRR50 < 3%
    // Ref: Liao et al. Stroke. 1997;28(10):1944-1950
    final lowPRR50 = pRR50 < 3.0;
    hrvFactors.add(ScoringFactor(
      name: 'Reduced Autonomic Modulation (pRR50 < 3%)', points: 0,
      triggered: lowPRR50, source: 'Device HRV analysis',
      reference: 'Liao et al. Stroke. 1997;28(10):1944-1950',
    ));

    // SDSD > 50ms
    // Ref: Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065
    final highSdsd = sdsd > 50.0;
    hrvFactors.add(ScoringFactor(
      name: 'Excessive Beat-to-Beat Irregularity (SDSD > 50ms)', points: 0,
      triggered: highSdsd, source: 'Device HRV analysis',
      reference: 'Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065',
    ));

    final hrvFlagsTriggered = [bpTriggered, lowPRR50, highSdsd].where((f) => f).length;

    // Risk category — standard CHA₂DS₂-VASc thresholds
    // Ref: ESC Guidelines on AF. Eur Heart J. 2020;42(5):373-498
    StrokeRisk risk;
    if (total == 0) {
      risk = StrokeRisk.low;
    } else if (total == 1) {
      risk = StrokeRisk.lowModerate;
    } else {
      risk = StrokeRisk.high;
    }

    return StrokeScoreResult(
      totalScore: total,
      maxScore: 7,
      risk: risk,
      chadFactors: chadFactors,
      hrvFactors: hrvFactors,
      hrvFlagsTriggered: hrvFlagsTriggered,
      afDetected: afResultIndex == 1,  // 1 = possibleAF
    );
  }

  static List<Recommendation> getRecommendations({
    required StrokeScoreResult result,
    required PatientProfile profile,
    required int afResultIndex,   // ← int not AfResult
    required double pRR50,
    required double sdsd,
  }) {
    final recs = <Recommendation>[];

    if (afResultIndex == 1) {
      recs.add(const Recommendation(
        icon: 'hospital', title: 'Possible AF Detected — Seek Medical Evaluation',
        body: 'A possible atrial fibrillation result was detected. '
            'Please visit a clinic or hospital for a 12-lead ECG to '
            'confirm. Do not delay if you feel palpitations, '
            'dizziness, or chest discomfort.',
        priority: RecommendationPriority.urgent,
      ));
    }

    if (result.risk == StrokeRisk.high) {
      recs.add(const Recommendation(
        icon: 'warning', title: 'High Stroke Risk — See a Doctor',
        body: 'Your CHA₂DS₂-VASc score indicates high stroke risk. '
            'Anticoagulation therapy is recommended — discuss with '
            'your doctor immediately. If you experience sudden '
            'weakness, speech difficulties, or vision changes, '
            'call emergency services immediately.',
        priority: RecommendationPriority.urgent,
      ));
    }

    if (result.risk == StrokeRisk.lowModerate) {
      recs.add(const Recommendation(
        icon: 'chart', title: 'Low-Moderate Stroke Risk',
        body: 'Your CHA₂DS₂-VASc score is 1. Anticoagulation may be '
            'considered depending on your full clinical picture. '
            'Discuss with your doctor, especially if AF was detected.',
        priority: RecommendationPriority.warning,
      ));
    }

    if (profile.hasPriorStrokeTIA) {
      recs.add(const Recommendation(
        icon: 'brain', title: 'Prior Stroke History — Stay Vigilant',
        body: 'Your history of stroke or TIA significantly increases '
            'recurrence risk. Ensure you are on appropriate '
            'anticoagulation therapy and attend all follow-up appointments.',
        priority: RecommendationPriority.urgent,
      ));
    }

    if (result.hrvFlagsTriggered >= 2) {
      recs.add(const Recommendation(
        icon: 'heart', title: 'Multiple HRV Risk Indicators Detected',
        body: 'Your device measurements flagged multiple cardiac '
            'risk indicators. While these do not directly modify '
            'your CHA₂DS₂-VASc score, they suggest increased '
            'cardiovascular risk. Share this report with your doctor.',
        priority: RecommendationPriority.warning,
      ));
    } else if (pRR50 < 3.0) {
      recs.add(const Recommendation(
        icon: 'heart', title: 'Reduced Heart Rate Variability',
        body: 'Your pRR50 is below 3%, indicating reduced autonomic '
            'nervous system activity. Regular aerobic exercise '
            'can improve autonomic function over time.',
        priority: RecommendationPriority.warning,
      ));
    } else if (sdsd > 50.0) {
      recs.add(const Recommendation(
        icon: 'trending', title: 'Irregular Beat-to-Beat Pattern',
        body: 'Your SDSD exceeds 50ms, indicating significant '
            'beat-to-beat variability. Combined with other risk '
            'factors, medical evaluation is advisable.',
        priority: RecommendationPriority.warning,
      ));
    }

    if (profile.systolicBP != null && profile.systolicBP! >= 140) {
      recs.add(const Recommendation(
        icon: 'pill', title: 'Manage Your Blood Pressure',
        body: 'Your recorded blood pressure is elevated (≥ 140 mmHg). '
            'Reduce salt intake, limit alcohol, exercise regularly, '
            'and take any prescribed antihypertensive medication. '
            'Target BP < 130/80 mmHg per JNC 8 guidelines.',
        priority: RecommendationPriority.warning,
      ));
    }

    if (profile.hasHypertension) {
      recs.add(const Recommendation(
        icon: 'clipboard', title: 'Blood Pressure Check',
        body: 'Monitor your blood pressure at least twice a week '
            'and keep a record to share with your doctor.',
        priority: RecommendationPriority.warning,
      ));
    }

    if (profile.hasDiabetes) {
      recs.add(const Recommendation(
        icon: '🩸', title: 'Blood Sugar Management',
        body: 'Good blood sugar control reduces your stroke risk. '
            'Take your medication as prescribed and monitor your glucose regularly.',
        priority: RecommendationPriority.warning,
      ));
    }

    recs.add(const Recommendation(
      icon: 'walk', title: 'Stay Active',
      body: 'Aim for at least 30 minutes of moderate exercise on most '
          'days. Physical activity strengthens your heart, improves '
          'autonomic function, and reduces AF and stroke risk.',
      priority: RecommendationPriority.info,
    ));

    recs.add(const Recommendation(
      icon: 'no_smoking', title: 'Avoid Smoking and Limit Alcohol',
      body: 'Smoking and heavy alcohol consumption significantly increase the risk of AF and stroke.',
      priority: RecommendationPriority.info,
    ));

    recs.add(const Recommendation(
      icon: 'sleep', title: 'Sleep and Stress',
      body: 'Poor sleep and chronic stress are associated with increased AF episodes. Aim for 7–9 hours of sleep.',
      priority: RecommendationPriority.info,
    ));

    recs.add(const Recommendation(
      icon: 'monitor', title: 'Continue Regular Monitoring',
      body: 'Use the AF-Screen device at the same time each day. Aim for at least 3 readings per week.',
      priority: RecommendationPriority.info,
    ));

    recs.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return recs;
  }
}