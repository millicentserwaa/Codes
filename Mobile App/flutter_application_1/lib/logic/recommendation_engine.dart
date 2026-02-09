import '../models/user_profile.dart';
import '../models/session_record.dart';

enum ConcernLevel { low, moderate, high }

class Recommendation {
  final ConcernLevel level;
  final String title;
  final List<String> reasons;
  final List<String> actions;

  Recommendation({
    required this.level,
    required this.title,
    required this.reasons,
    required this.actions,
  });
}

class RecommendationEngine {
  /// Main entrypoint
  static Recommendation generate({
    required UserProfile profile,
    required List<SessionRecord> sessionsNewestFirst,
  }) {
    if (sessionsNewestFirst.isEmpty) {
      return Recommendation(
        level: ConcernLevel.low,
        title: 'No sessions yet',
        reasons: const ['No screening records are available.'],
        actions: const ['Add at least one screening session to view guidance.'],
      );
    }

    // Use a recent window (last N sessions)
    final recent = sessionsNewestFirst.take(10).toList();

    final notOkCount = recent.where((s) => s.afResult == AfResult.notOk).length;
    final inconclusiveCount =
        recent.where((s) => s.afResult == AfResult.inconclusive).length;

    final double inconclusiveRate =
        recent.isEmpty ? 0 : inconclusiveCount / recent.length;

    final avgConfidence = _avg(recent.map((s) => s.confidence.toDouble()));
    final avgQuality = _avg(recent.map((s) => s.signalQuality.toDouble()));

    // Optional physiological indicators (only use if present)
    final spo2Values = recent
        .where((s) => s.spo2 != null && (s.spo2Confidence ?? 0) >= 60)
        .map((s) => s.spo2!)
        .toList();

    final avgSpo2 = spo2Values.isEmpty ? null : _avg(spo2Values);

    // Risk factor weighting (simple, explainable)
    int riskPoints = 0;
    if (profile.hasHypertension) riskPoints += 1;
    if (profile.hasDiabetes) riskPoints += 1;
    if (profile.ageGroup == AgeGroup.from40to59) riskPoints += 1;
    if (profile.ageGroup == AgeGroup.above60) riskPoints += 2;

    // --- Integrity gating: if too many inconclusive/low quality, downgrade certainty ---
    final bool integrityWeak =
        inconclusiveRate >= 0.4 || avgConfidence < 60 || avgQuality < 60;

    // --- Decision logic (conservative) ---
    // Base concern from AF flags
    ConcernLevel level;
    final reasons = <String>[];
    final actions = <String>[];

    if (notOkCount >= 2) {
      level = ConcernLevel.high;
      reasons.add('Multiple sessions flagged irregular rhythm (NOT OK).');
    } else if (notOkCount == 1) {
      level = ConcernLevel.moderate;
      reasons.add('One session flagged irregular rhythm (NOT OK).');
    } else {
      level = ConcernLevel.low;
      reasons.add('No recent sessions flagged irregular rhythm.');
    }

    // Adjust concern upward if risk factors are high
    if (riskPoints >= 3 && level == ConcernLevel.moderate) {
      level = ConcernLevel.high;
      reasons.add('User risk factors increase concern (hypertension/diabetes/age).');
    } else if (riskPoints >= 3 && level == ConcernLevel.low) {
      level = ConcernLevel.moderate;
      reasons.add('User risk factors warrant closer follow-up (hypertension/diabetes/age).');
    }

    // Add SpO2 supporting note (not a stroke predictor, just a screening indicator)
    if (avgSpo2 != null && avgSpo2 < 92) {
      reasons.add('Average SpO₂ in recent reliable sessions is low (<92%).');
      if (level == ConcernLevel.low) level = ConcernLevel.moderate;
    }

    // Integrity note
    if (integrityWeak) {
      reasons.add('Several sessions had low confidence or were inconclusive.');
      actions.addAll([
        'Repeat screening with steady finger contact and minimal movement.',
        'Ensure fingers are warm and relaxed during measurement.',
      ]);

      // If integrity is weak, don’t escalate beyond moderate unless we have repeated NOT OK
      if (level == ConcernLevel.high && notOkCount < 2) {
        level = ConcernLevel.moderate;
        reasons.add('Concern level limited due to weak signal integrity.');
      }
    }

    // Actions based on final level
    switch (level) {
      case ConcernLevel.low:
        actions.addAll([
          'Continue periodic screening (e.g., weekly or during routine checks).',
          'Repeat if symptoms occur (palpitations, dizziness, chest discomfort).',
        ]);
        break;

      case ConcernLevel.moderate:
        actions.addAll([
          'Repeat screening within 24–48 hours to confirm.',
          'If repeated NOT OK occurs, seek clinical evaluation (ECG confirmation).',
        ]);
        break;

      case ConcernLevel.high:
        actions.addAll([
          'Seek clinical evaluation soon for confirmatory assessment (12-lead ECG or clinician review).',
          'If symptoms are severe or sudden (fainting, chest pain, stroke-like symptoms), seek urgent care.',
        ]);
        break;
    }

    final title = _titleFor(level);

    return Recommendation(
      level: level,
      title: title,
      reasons: reasons,
      actions: actions,
    );
  }

  static String _titleFor(ConcernLevel level) {
    switch (level) {
      case ConcernLevel.low:
        return 'Low concern based on recent screenings';
      case ConcernLevel.moderate:
        return 'Moderate concern — repeat and monitor closely';
      case ConcernLevel.high:
        return 'High concern — clinical follow-up recommended';
    }
  }

  static double _avg(Iterable<double> xs) {
    final list = xs.toList();
    if (list.isEmpty) return 0;
    final sum = list.reduce((a, b) => a + b);
    return sum / list.length;
  }
}
