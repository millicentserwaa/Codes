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
    switch (profile.strokeRiskLevel) {
      case 'Low':
        return 'Your current risk factors suggest a low probability '
            'of stroke. Continue maintaining a healthy lifestyle.';
      case 'Moderate':
        return 'Your risk factors suggest a moderate probability of '
            'stroke. Consult your healthcare provider for guidance.';
      case 'High':
        return 'Your risk factors suggest a high probability of stroke. '
            'Please consult a healthcare provider as soon as possible.';
      default:
        return '';
    }
  }

  // ── AF Burden from measurement history ───────────────────
  static double getAFBurden(List<Measurement> measurements) {
    if (measurements.isEmpty) return 0.0;
    final afCount = measurements
        .where((m) => m.afPrediction == 1)
        .length;
    return (afCount / measurements.length) * 100;
  }

  // ── Trend analysis ───────────────────────────────────────
  static String getHeartRateTrend(List<Measurement> measurements) {
    if (measurements.length < 2) return 'Not enough data';

    final recent = measurements.take(5).toList();
    final older = measurements.skip(5).take(5).toList();

    if (older.isEmpty) return 'Not enough data';

    final recentAvg = recent
            .map((m) => m.heartRate)
            .reduce((a, b) => a + b) /
        recent.length;

    final olderAvg = older
            .map((m) => m.heartRate)
            .reduce((a, b) => a + b) /
        older.length;

    final diff = recentAvg - olderAvg;

    if (diff > 5) return 'Increasing';
    if (diff < -5) return 'Decreasing';
    return 'Stable';
  }

  // ── Recommendations based on profile and measurements ────
  static List<String> getRecommendations(
    UserProfile profile,
    List<Measurement> measurements,
  ) {
    final List<String> recommendations = [];
    final afBurden = getAFBurden(measurements);
    final score = profile.strokeRiskScore;

    // AF burden recommendations
    if (afBurden > 50) {
      recommendations.add(
        'More than half of your recent readings show irregular rhythm. '
        'Please consult a doctor (cardiologist) promptly.',
      );
    } else if (afBurden > 20) {
      recommendations.add(
        'Some of your readings show irregular rhythm. '
        'Monitor closely and inform your doctor.',
      );
    }

    // Stroke risk recommendations
    if (score >= 2) {
      recommendations.add(
        'Your CHA\u2082DS\u2082-VASc score of $score indicates high stroke risk. '
        'Anticoagulation therapy may be appropriate — consult your doctor.',
      );
    } else if (score == 1) {
      recommendations.add(
        'Your CHA\u2082DS\u2082-VASc score of $score indicates moderate risk. '
        'Discuss stroke prevention options with your healthcare provider.',
      );
    }

    // Condition-specific recommendations
    if (profile.hasHypertension) {
      recommendations.add(
        'Monitor your blood pressure regularly. '
        'Keeping it under control reduces AF and stroke risk.',
      );
    }

    if (profile.hasDiabetes) {
      recommendations.add(
        'Maintain good blood sugar control to reduce cardiovascular risk.',
      );
    }

    if (profile.age >= 65) {
      recommendations.add(
        'Age is a significant risk factor for AF and stroke. '
        'Regular cardiac screening is recommended.',
      );
    }

    // Heart rate recommendations
    final latest = measurements.isEmpty ? null : measurements.first;
    if (latest != null) {
      if (latest.heartRate > 100) {
        recommendations.add(
          'Your most recent heart rate of ${latest.heartRate.toStringAsFixed(0)} BPM '
          'is elevated. Rest and monitor. Seek care if it persists.',
        );
      } else if (latest.heartRate < 60) {
        recommendations.add(
          'Your most recent heart rate of ${latest.heartRate.toStringAsFixed(0)} BPM '
          'is low. If you feel dizzy or unwell, seek medical attention.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Your readings look good. Keep up your healthy habits and '
        'continue monitoring regularly.',
      );
    }

    return recommendations;
  }
}