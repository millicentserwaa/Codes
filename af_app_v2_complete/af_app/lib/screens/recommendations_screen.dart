import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';
import '../services/stroke_algorithm.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/tts_service.dart';

class RecommendationsScreen extends StatelessWidget {
  final Measurement measurement;
  final StrokeScoreResult scoreResult;
  final PatientProfile profile;

  const RecommendationsScreen({
    super.key,
    required this.measurement,
    required this.scoreResult,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final recs = StrokeAlgorithm.getRecommendations(
      result: scoreResult,
      profile: profile,
      afResult: measurement.afResult,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: TtsService.instance.stateNotifier,
            builder: (context, _, __) {
              final buffer = StringBuffer();
              for (final r in recs) {
                buffer.write('${r.title}. ${r.body} ');
              }
              final text = buffer.toString();
              final playing = TtsService.instance.isPlaying &&
                  TtsService.instance.currentText == text;
              final paused = playing && TtsService.instance.isPaused;
              final icon =
                  paused ? Icons.play_arrow_rounded : Icons.volume_up_rounded;
              return IconButton(
                icon: Icon(icon),
                onPressed: () {
                  TtsService.instance.togglePlayPause(text);
                },
                tooltip: paused ? 'Resume' : 'Read all',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withBlue(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personalised for you',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AfResultBadge(result: measurement.afResult, large: true),
                    const SizedBox(width: 10),
                    StrokeRiskChip(
                        risk: scoreResult.risk,
                        score: scoreResult.totalScore,
                        large: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Group urgent first
          ...recs.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _RecCard(rec: r),
              )),

          const SizedBox(height: 16),

          // Emergency numbers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.emergency_rounded,
                      color: AppTheme.danger, size: 18),
                  SizedBox(width: 8),
                  Text('Emergency Numbers — Ghana',
                      style: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 12),
                _emergencyLine('Ambulance / GNEMS', '193'),
                _emergencyLine('Police', '191'),
                _emergencyLine('General Emergency', '112'),
                const SizedBox(height: 8),
                Text(
                  'If you experience sudden weakness, numbness, slurred speech, severe headache, or vision loss — call immediately.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _emergencyLine(String name, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          Text(number,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.danger)),
        ],
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  final Recommendation rec;
  const _RecCard({required this.rec});

  Color get _borderColor {
    switch (rec.priority) {
      case RecommendationPriority.urgent:
        return AppTheme.danger;
      case RecommendationPriority.warning:
        return AppTheme.warning;
      case RecommendationPriority.info:
        return AppTheme.border;
    }
  }

  Color get _bgColor {
    switch (rec.priority) {
      case RecommendationPriority.urgent:
        return AppTheme.danger.withOpacity(0.05);
      case RecommendationPriority.warning:
        return AppTheme.warning.withOpacity(0.05);
      case RecommendationPriority.info:
        return AppTheme.card;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(rec.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 14)),
                    ),
                    ReadAloudIcon(text: '${rec.title}. ${rec.body}'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(rec.body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
