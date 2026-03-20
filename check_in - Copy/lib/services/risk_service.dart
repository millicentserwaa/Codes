import '../models/measurement.dart';
import '../models/user_profile.dart';

class RiskService {
  // ── CHA2DS2-VASc Stroke Risk ─────────────────────────────
  static String getRiskLevel(UserProfile profile) {
    return profile.strokeRiskLevel;
  }

  static int getRiskScore(UserProfile profile) {
    return profile.strokeRiskScore;
  }

  // ── Risk description for UI ──────────────────────────────
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

  // ── AF Burden from measurement history (rolling window) ──
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

  // ── Urgency engine ───────────────────────────────────────
  // Combines AF burden + CHA2DS2-VASc score into a single urgency level.
  // Grounded in ESC 2024 guidelines and Circulation 2019 AF burden thresholds.
  static String getUrgencyLevel(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final afBurden = getAFBurden(measurements);
    final score = profile.strokeRiskScore;

    // Prior stroke always high urgency regardless of burden
    if (profile.hasPriorStroke) return 'High';

    // High AF burden alone is high urgency
    if (afBurden > 30) return 'High';

    // Moderate burden + elevated risk score = high urgency
    if (afBurden > 10 && score >= 2) return 'High';

    // Either moderate burden or elevated score = moderate urgency
    if (afBurden > 10 || score >= 2) return 'Moderate';

    return 'Low';
  }

  // ── Urgency action message ───────────────────────────────
  static String getUrgencyMessage(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final name = profile.name.split(' ').first;
    final urgency = getUrgencyLevel(profile, measurements);

    switch (urgency) {
      case 'High':
        return '$name, based on your readings and risk factors, '
            'we strongly recommend you see a doctor or visit a clinic this week. '
            'Bring this report with you.';
      case 'Moderate':
        return '$name, your readings and risk factors suggest you should '
            'discuss your heart health with a healthcare provider soon. '
            'You can share this report at your next visit.';
      default:
        return '$name, your readings look reassuring. '
            'Keep monitoring daily and see a doctor if anything changes.';
    }
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

  // ── Recommendations ──────────────────────────────────────
  static List<String> getRecommendations(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final List<String> recommendations = [];
    final afBurden = getAFBurden(measurements);
    final score = profile.strokeRiskScore;
    final name = profile.name.split(' ').first;

    // AF burden recommendations
    if (afBurden > 50) {
      recommendations.add(
        '$name, more than half of your recent readings show an irregular heartbeat. '
        'Please see a doctor or cardiologist as soon as possible.',
      );
    } else if (afBurden > 20) {
      recommendations.add(
        '$name, some of your recent readings show an irregular heartbeat. '
        'Keep monitoring and let your doctor know at your next visit.',
      );
    }

    // Stroke risk recommendations
    if (score >= 2) {
      recommendations.add(
        '$name, your CHA\u2082DS\u2082-VASc score of $score means your risk of stroke is high. '
        'Please speak to your doctor about treatment options as soon as you can.',
      );
    } else if (score == 1) {
      recommendations.add(
        '$name, your CHA\u2082DS\u2082-VASc score of $score suggests a moderate stroke risk. '
        'It is worth discussing this with your healthcare provider.',
      );
    }

    // Condition-specific recommendations
    if (profile.hasHypertension) {
      recommendations.add(
        '$name, since you have hypertension, checking your blood pressure regularly '
        'is very important. Keeping it under control protects your heart.',
      );
    }

    if (profile.hasDiabetes) {
      recommendations.add(
        '$name, managing your blood sugar well is one of the best things '
        'you can do to protect your heart and reduce stroke risk.',
      );
    }

    if (profile.hasPriorStroke) {
      recommendations.add(
        '$name, because you have had a stroke or TIA before, '
        'please make sure you are attending your follow-up appointments '
        'and taking any prescribed medication consistently.',
      );
    }

    if (profile.hasHeartFailure) {
      recommendations.add(
        '$name, with a history of heart failure, any new irregular '
        'rhythm readings should be reported to your doctor promptly.',
      );
    }

    if (profile.hasVascularDisease) {
      recommendations.add(
        '$name, with a history of vascular disease your risk of both '
        'AF and stroke is elevated. Regular monitoring and medication '
        'compliance are especially important for you.',
      );
    }

    if (profile.age >= 65) {
      recommendations.add(
        '$name, at your age regular heart screening is especially important. '
        'Try to take a reading at least once a day.',
      );
    }

    // Heart rate recommendations
    final latest = measurements.isEmpty ? null : measurements.first;
    if (latest != null) {
      if (latest.heartRate > 100) {
        recommendations.add(
          '$name, your most recent heart rate was '
          '${latest.heartRate.toStringAsFixed(0)} BPM which is higher than normal. '
          'Rest and take another reading. If it stays high or you feel unwell, '
          'please seek medical attention.',
        );
      } else if (latest.heartRate < 60) {
        recommendations.add(
          '$name, your most recent heart rate was '
          '${latest.heartRate.toStringAsFixed(0)} BPM which is lower than normal. '
          'If you feel dizzy or weak, please see a doctor.',
        );
      }
    }

    // Monitoring consistency nudge
    final consistency = getMonitoringConsistency(measurements);
    if (consistency == 'Poor' || consistency == 'Fair') {
      final last7Count = measurements
          .where(
            (m) => m.timestamp.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          )
          .length;
      recommendations.add(
        '$name, you have only taken $last7Count reading${last7Count == 1 ? '' : 's'} '
        'in the last 7 days. Try to measure daily for the most accurate picture '
        'of your heart health.',
      );
    }

    // Default — all clear
    if (recommendations.isEmpty) {
      recommendations.add(
        '$name, your readings look good — keep it up! '
        'Continue taking daily readings so you can spot any changes early.',
      );
    }

    return recommendations;
  }
}
