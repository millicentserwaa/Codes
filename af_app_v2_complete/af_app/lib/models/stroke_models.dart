
// ── StrokeRisk enum ────────────────────────────────────────────
enum StrokeRisk { low, lowModerate, high }

extension StrokeRiskExtension on StrokeRisk {
  String get label {
    switch (this) {
      case StrokeRisk.low:
        return 'Low Risk';
      case StrokeRisk.lowModerate:
        return 'Low-Moderate';
      case StrokeRisk.high:
        return 'High Risk';
    }
  }

  String get advice {
    switch (this) {
      case StrokeRisk.low:
        return 'Your CHA₂DS₂-VASc score is 0, indicating low stroke risk. '
            'Continue regular monitoring and maintain a healthy lifestyle.';
      case StrokeRisk.lowModerate:
        return 'Your CHA₂DS₂-VASc score is 1. Anticoagulation may be '
            'considered depending on sex and full clinical picture. '
            'Discuss with your doctor.';
      case StrokeRisk.high:
        return 'Your CHA₂DS₂-VASc score is ≥ 2, indicating high stroke risk. '
            'Anticoagulation therapy is recommended. '
            'Please consult your doctor promptly.';
    }
  }
}

// ── ScoringFactor ──────────────────────────────────────────────
class ScoringFactor {
  final String name;
  final int points;
  final bool? triggered; // null = not assessed / data unavailable
  final String source;
  final String reference; // academic citation

  const ScoringFactor({
    required this.name,
    required this.points,
    required this.triggered,
    required this.source,
    required this.reference,
  });
}

// ── StrokeScoreResult ──────────────────────────────────────────
class StrokeScoreResult {
  final int totalScore;
  final int maxScore;
  final StrokeRisk risk;
  final List<ScoringFactor> chadFactors; // standard CHA₂DS₂-VASc factors
  final List<ScoringFactor> hrvFactors;  // device HRV assessment flags
  final int hrvFlagsTriggered;
  final bool afDetected;

  const StrokeScoreResult({
    required this.totalScore,
    required this.maxScore,
    required this.risk,
    required this.chadFactors,
    required this.hrvFactors,
    required this.hrvFlagsTriggered,
    required this.afDetected,
  });

  /// Combined list for UI screens that display all factors together
  List<ScoringFactor> get factors => [...chadFactors, ...hrvFactors];
}

// ── RecommendationPriority ─────────────────────────────────────
enum RecommendationPriority { urgent, warning, info }

// ── Recommendation ─────────────────────────────────────────────
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