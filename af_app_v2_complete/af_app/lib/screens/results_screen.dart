// import 'package:flutter/material.dart';
// import '../models/measurement.dart';
// import '../services/storage_service.dart';
// import 'dart:math' as math;
// import '../services/stroke_algorithm.dart';
// import '../models/stroke_models.dart';
// import '../theme/app_theme.dart';
// import '../widgets/shared_widgets.dart';
// //import '../services/tts_service.dart';
// import 'recommendations_screen.dart';

// class ResultsScreen extends StatelessWidget {
//   final Measurement measurement;

//   const ResultsScreen({super.key, required this.measurement});

//   @override
//   Widget build(BuildContext context) {
//     final profile = StorageService.getProfile();
//     final scoreResult = profile != null
//         ? StrokeAlgorithm.calculate(
//             profile: profile,
//             pRR50: measurement.pnn50,
//             sdsd: measurement.rmssd / math.sqrt(2),
//             afResultIndex: measurement.afResultIndex,
//             systolicBP: measurement.systolicBP,
//           )
//         : null;

//     return Scaffold(
//       backgroundColor: AppTheme.surface,
//       appBar: AppBar(
//         title: const Text('Analysis Results'),
//         actions: [
//           if (profile != null)
//             TextButton.icon(
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => RecommendationsScreen(
//                     measurement: measurement,
//                     scoreResult: scoreResult!,
//                     profile: profile,
//                   ),
//                 ),
//               ),
//               icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
//               label: const Text('Recommendations'),
//             ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           // ── Timestamp ──────────────────────────────────────
//           Text(
//             _formatDateTime(measurement.timestamp),
//             style: Theme.of(context)
//                 .textTheme
//                 .bodyMedium
//                 ?.copyWith(color: AppTheme.textSecondary),
//           ),
//           const SizedBox(height: 20),

//           // ── AF Result Banner ───────────────────────────────
//           _AfBanner(result: measurement.afResult, score: measurement.afScore),
//           const SizedBox(height: 20),

//           // ── HRV Values ─────────────────────────────────────
//           const SectionHeader(title: 'HRV Analysis'),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: HrvTile(
//                   label: 'COEFFICIENT OF VARIATION',
//                   value: measurement.cv.toStringAsFixed(3),
//                   unit: '',
//                   subtitle: measurement.cv >= 0.15
//                       ? '⚠ Above threshold (0.15)'
//                       : '✓ Within normal range',
//                   highlight: measurement.cv >= 0.15 ? AppTheme.warning : null,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: HrvTile(
//                   label: 'RMSSD',
//                   value: measurement.rmssd.toStringAsFixed(0),
//                   unit: 'ms',
//                   subtitle: measurement.rmssd >= 80
//                       ? '⚠ Above threshold (80 ms)'
//                       : '✓ Within normal range',
//                   highlight: measurement.rmssd >= 80 ? AppTheme.warning : null,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: HrvTile(
//                   label: 'pNN50',
//                   value: measurement.pnn50.toStringAsFixed(1),
//                   unit: '%',
//                   subtitle: measurement.pnn50 >= 50
//                       ? '⚠ Above threshold (50%)'
//                       : '✓ Within normal range',
//                   highlight: measurement.pnn50 >= 50 ? AppTheme.warning : null,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: HrvTile(
//                   label: 'HEART RATE',
//                   value: measurement.heartRate.toStringAsFixed(0),
//                   unit: 'bpm',
//                   subtitle:
//                       'Mean RR: ${measurement.meanRR.toStringAsFixed(0)} ms',
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 24),

//           // ── Stroke Risk ────────────────────────────────────
//           if (scoreResult != null) ...[
//             const SectionHeader(title: 'Stroke Risk Assessment'),
//             const SizedBox(height: 12),
//             _StrokeScoreCard(result: scoreResult),
//             const SizedBox(height: 12),
//             _StrokeFactorList(factors: scoreResult.factors),
//           ] else ...[
//             _NoProfileWarning(context: context),
//           ],

//           const SizedBox(height: 24),

//           // ── AF Description ─────────────────────────────────
//           _InfoCard(
//             icon: Icons.info_outline_rounded,
//             title: 'About This Result',
//             body: measurement.afResult.description,
//             color: _afColor(measurement.afResult),
//           ),

//           if (scoreResult != null) ...[
//             const SizedBox(height: 12),
//             _InfoCard(
//               icon: Icons.medical_information_outlined,
//               title: 'About Stroke Risk',
//               body: scoreResult.risk.advice,
//               color: _riskColor(scoreResult.risk),
//             ),
//           ],

//           const SizedBox(height: 32),

//           // ── Disclaimer ─────────────────────────────────────
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: AppTheme.border.withOpacity(0.5),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(children: [
//               Expanded(
//                 child: Text(
//                   '⚕️  This device is a screening tool only. Results are not a clinical diagnosis. Always consult a qualified healthcare professional before making any medical decisions.',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
//                 ),
//               ),
//               const ReadAloudIcon(
//                 text:
//                     'This device is a screening tool only. Results are not a clinical diagnosis. Always consult a qualified healthcare professional before making any medical decisions.',
//               ),
//             ]),
//           ),

//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   String _formatDateTime(DateTime dt) {
//     final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     final months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}  '
//         '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//   }

//   Color _afColor(AfResult r) {
//     switch (r) {
//       case AfResult.normal:
//         return AppTheme.afNormal;
//       case AfResult.possibleAF:
//         return AppTheme.afPossible;
//       case AfResult.inconclusive:
//         return AppTheme.afInconclusive;
//     }
//   }

//   Color _riskColor(StrokeRisk r) {
//     switch (r) {
//       case StrokeRisk.low:
//         return AppTheme.riskLow;
//       case StrokeRisk.lowModerate:
//         return AppTheme.riskModerate;
//       case StrokeRisk.high:
//         return AppTheme.riskHigh;
//     }
//   }
// }

// // ── AF Banner ──────────────────────────────────────────────────
// class _AfBanner extends StatelessWidget {
//   final AfResult result;
//   final int score;

//   const _AfBanner({required this.result, required this.score});

//   Color get _color {
//     switch (result) {
//       case AfResult.normal:
//         return AppTheme.afNormal;
//       case AfResult.possibleAF:
//         return AppTheme.afPossible;
//       case AfResult.inconclusive:
//         return AppTheme.afInconclusive;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: _color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               color: _color.withOpacity(0.15),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               result == AfResult.normal
//                   ? Icons.favorite_rounded
//                   : result == AfResult.possibleAF
//                       ? Icons.warning_rounded
//                       : Icons.help_rounded,
//               color: _color,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('AF Screening',
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyMedium
//                         ?.copyWith(color: AppTheme.textSecondary)),
//                 const SizedBox(height: 4),
//                 AfResultBadge(result: result, large: true),
//                 const SizedBox(height: 6),
//                 Text(
//                   'AF Score: $score / 5',
//                   style: TextStyle(
//                       fontSize: 12, fontWeight: FontWeight.w500, color: _color),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Stroke Score Card ──────────────────────────────────────────
// class _StrokeScoreCard extends StatelessWidget {
//   final StrokeScoreResult result;

//   const _StrokeScoreCard({required this.result});

//   Color get _color {
//     switch (result.risk) {
//       case StrokeRisk.low:
//         return AppTheme.riskLow;
//       case StrokeRisk.lowModerate:
//         return AppTheme.riskModerate;
//       case StrokeRisk.high:
//         return AppTheme.riskHigh;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pct = result.totalScore / result.maxScore;

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppTheme.card,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppTheme.border),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Modified CHA₂DS₂-VASc Score',
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodyMedium
//                           ?.copyWith(fontSize: 11)),
//                   const SizedBox(height: 6),
//                   StrokeRiskChip(
//                       risk: result.risk, score: result.totalScore, large: true),
//                 ],
//               ),
//               // Score circle
//               Container(
//                 width: 70,
//                 height: 70,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: _color, width: 3),
//                   color: _color.withOpacity(0.08),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       '${result.totalScore}',
//                       style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.w800,
//                           color: _color),
//                     ),
//                     Text('/ ${result.maxScore}',
//                         style: TextStyle(
//                             fontSize: 10, color: _color.withOpacity(0.7))),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Progress bar
//           ClipRRect(
//             borderRadius: BorderRadius.circular(100),
//             child: LinearProgressIndicator(
//               value: pct,
//               minHeight: 8,
//               backgroundColor: _color.withOpacity(0.12),
//               valueColor: AlwaysStoppedAnimation(_color),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('Low (0)',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 10)),
//               Text('Moderate (1–3)',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 10)),
//               Text('High (≥4)',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 10)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Factor breakdown list ──────────────────────────────────────
// class _StrokeFactorList extends StatelessWidget {
//   final List<ScoringFactor> factors;
//   const _StrokeFactorList({required this.factors});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppTheme.card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.border),
//       ),
//       child: Column(
//         children: factors.asMap().entries.map((e) {
//           final i = e.key;
//           final f = e.value;
//           final isLast = i == factors.length - 1;

//           Color dotColor;
//           if (f.triggered == null) {
//             dotColor = AppTheme.textSecondary;
//           } else if (f.triggered!) {
//             dotColor = f.points >= 2 ? AppTheme.danger : AppTheme.warning;
//           } else {
//             dotColor = AppTheme.secondary;
//           }

//           return Column(
//             children: [
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 28,
//                       height: 28,
//                       decoration: BoxDecoration(
//                         color: dotColor.withOpacity(0.12),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: f.triggered == null
//                             ? const Icon(Icons.remove,
//                                 size: 14, color: AppTheme.textSecondary)
//                             : f.triggered!
//                                 ? Icon(Icons.add, size: 14, color: dotColor)
//                                 : Icon(Icons.check, size: 14, color: dotColor),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(f.name,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyLarge
//                                   ?.copyWith(
//                                       fontSize: 13,
//                                       fontWeight: f.triggered == true
//                                           ? FontWeight.w600
//                                           : FontWeight.w400)),
//                           Text(f.source,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(fontSize: 10)),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       f.triggered == true
//                           ? '+${f.points}'
//                           : f.triggered == false
//                               ? '—'
//                               : 'N/A',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: f.triggered == true
//                             ? dotColor
//                             : AppTheme.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (!isLast) const Divider(height: 1, indent: 56),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// // ── Info card ──────────────────────────────────────────────────
// class _InfoCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String body;
//   final Color color;

//   const _InfoCard({
//     required this.icon,
//     required this.title,
//     required this.body,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(children: [
//                   Expanded(
//                     child: Text(title,
//                         style: Theme.of(context)
//                             .textTheme
//                             .titleMedium
//                             ?.copyWith(fontSize: 13, color: color)),
//                   ),
//                   ReadAloudIcon(text: '$title. $body'),
//                 ]),
//                 const SizedBox(height: 6),
//                 Text(body,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyMedium
//                         ?.copyWith(fontSize: 13)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── No profile warning ─────────────────────────────────────────
// class _NoProfileWarning extends StatelessWidget {
//   final BuildContext context;
//   const _NoProfileWarning({required this.context});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppTheme.warning.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.person_outline_rounded,
//               color: AppTheme.warning, size: 22),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Set up your profile to see stroke risk analysis. Go to the Profile tab.',
//               style: Theme.of(context)
//                   .textTheme
//                   .bodyMedium
//                   ?.copyWith(fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/storage_service.dart';
import 'dart:math' as math;
import '../services/stroke_algorithm.dart';
import '../models/stroke_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/tts_service.dart';
import 'recommendations_screen.dart';

class ResultsScreen extends StatelessWidget {
  final Measurement measurement;

  const ResultsScreen({super.key, required this.measurement});

  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getProfile();
    final scoreResult = profile != null
        ? StrokeAlgorithm.calculate(
            profile: profile,
            pRR50: measurement.pnn50,
            sdsd: measurement.rmssd / math.sqrt(2),
            afResultIndex: measurement.afResultIndex,
            systolicBP: measurement.systolicBP,
          )
        : null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          if (profile != null)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecommendationsScreen(
                    measurement: measurement,
                    scoreResult: scoreResult!,
                    profile: profile,
                  ),
                ),
              ),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
              label: const Text('Recommendations'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Timestamp ──────────────────────────────────────
          Text(
            _formatDateTime(measurement.timestamp),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── AF Result Banner ───────────────────────────────
          _AfBanner(result: measurement.afResult, score: measurement.afScore),
          const SizedBox(height: 20),

          // ── HRV Values ─────────────────────────────────────
          const SectionHeader(title: 'HRV Analysis'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HrvTile(
                  label: 'COEFFICIENT OF VARIATION',
                  value: measurement.cv.toStringAsFixed(3),
                  unit: '',
                  subtitle: measurement.cv >= 0.15
                      ? '⚠ Above threshold (0.15)'
                      : '✓ Within normal range',
                  highlight: measurement.cv >= 0.15 ? AppTheme.warning : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HrvTile(
                  label: 'RMSSD',
                  value: measurement.rmssd.toStringAsFixed(0),
                  unit: 'ms',
                  subtitle: measurement.rmssd >= 80
                      ? '⚠ Above threshold (80 ms)'
                      : '✓ Within normal range',
                  highlight: measurement.rmssd >= 80 ? AppTheme.warning : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HrvTile(
                  label: 'pNN50',
                  value: measurement.pnn50.toStringAsFixed(1),
                  unit: '%',
                  subtitle: measurement.pnn50 >= 50
                      ? '⚠ Above threshold (50%)'
                      : '✓ Within normal range',
                  highlight: measurement.pnn50 >= 50 ? AppTheme.warning : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HrvTile(
                  label: 'HEART RATE',
                  value: measurement.heartRate.toStringAsFixed(0),
                  unit: 'bpm',
                  subtitle:
                      'Mean RR: ${measurement.meanRR.toStringAsFixed(0)} ms',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stroke Risk ────────────────────────────────────
          if (scoreResult != null) ...[
            const SectionHeader(title: 'Stroke Risk Assessment'),
            const SizedBox(height: 12),
            _StrokeScoreCard(result: scoreResult),
            const SizedBox(height: 12),
            _StrokeFactorList(factors: scoreResult.factors),
          ] else ...[
            _NoProfileWarning(context: context),
          ],

          const SizedBox(height: 24),

          // ── AF Description ─────────────────────────────────
          _InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'About This Result',
            body: measurement.afResult.description,
            color: _afColor(measurement.afResult),
          ),

          if (scoreResult != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.medical_information_outlined,
              title: 'About Stroke Risk',
              body: scoreResult.risk.advice,
              color: _riskColor(scoreResult.risk),
            ),
          ],

          const SizedBox(height: 32),

          // ── Disclaimer ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  'This device is a screening tool only. Results are not a clinical diagnosis. Always consult a qualified healthcare professional before making any medical decisions.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              const ReadAloudIcon(
                text:
                    'This device is a screening tool only. Results are not a clinical diagnosis. Always consult a qualified healthcare professional before making any medical decisions.',
              ),
            ]),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _afColor(AfResult r) {
    switch (r) {
      case AfResult.normal:
        return AppTheme.afNormal;
      case AfResult.possibleAF:
        return AppTheme.afPossible;
      case AfResult.inconclusive:
        return AppTheme.afInconclusive;
    }
  }

  Color _riskColor(StrokeRisk r) {
    switch (r) {
      case StrokeRisk.low:
        return AppTheme.riskLow;
      case StrokeRisk.lowModerate:
        return AppTheme.riskModerate;
      case StrokeRisk.high:
        return AppTheme.riskHigh;
    }
  }
}

// ── AF Banner ──────────────────────────────────────────────────
class _AfBanner extends StatelessWidget {
  final AfResult result;
  final int score;

  const _AfBanner({required this.result, required this.score});

  Color get _color {
    switch (result) {
      case AfResult.normal:
        return AppTheme.afNormal;
      case AfResult.possibleAF:
        return AppTheme.afPossible;
      case AfResult.inconclusive:
        return AppTheme.afInconclusive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result == AfResult.normal
                  ? Icons.favorite_rounded
                  : result == AfResult.possibleAF
                      ? Icons.warning_rounded
                      : Icons.help_rounded,
              color: _color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AF Screening',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                AfResultBadge(result: result, large: true),
                const SizedBox(height: 6),
                Text(
                  'AF Score: $score / 5',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: _color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stroke Score Card ──────────────────────────────────────────
class _StrokeScoreCard extends StatelessWidget {
  final StrokeScoreResult result;

  const _StrokeScoreCard({required this.result});

  Color get _color {
    switch (result.risk) {
      case StrokeRisk.low:
        return AppTheme.riskLow;
      case StrokeRisk.lowModerate:
        return AppTheme.riskModerate;
      case StrokeRisk.high:
        return AppTheme.riskHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = result.totalScore / result.maxScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modified CHA₂DS₂-VASc Score',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11)),
                  const SizedBox(height: 6),
                  StrokeRiskChip(
                      risk: result.risk, score: result.totalScore, large: true),
                ],
              ),
              // Score circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _color, width: 3),
                  color: _color.withOpacity(0.08),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${result.totalScore}',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _color),
                    ),
                    Text('/ ${result.maxScore}',
                        style: TextStyle(
                            fontSize: 10, color: _color.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low (0)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10)),
              Text('Moderate (1–3)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10)),
              Text('High (≥4)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Factor breakdown list ──────────────────────────────────────
class _StrokeFactorList extends StatelessWidget {
  final List<ScoringFactor> factors;
  const _StrokeFactorList({required this.factors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: factors.asMap().entries.map((e) {
          final i = e.key;
          final f = e.value;
          final isLast = i == factors.length - 1;

          Color dotColor;
          if (f.triggered == null) {
            dotColor = AppTheme.textSecondary;
          } else if (f.triggered!) {
            dotColor = f.points >= 2 ? AppTheme.danger : AppTheme.warning;
          } else {
            dotColor = AppTheme.secondary;
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: f.triggered == null
                            ? const Icon(Icons.remove,
                                size: 14, color: AppTheme.textSecondary)
                            : f.triggered!
                                ? Icon(Icons.add, size: 14, color: dotColor)
                                : Icon(Icons.check, size: 14, color: dotColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: f.triggered == true
                                          ? FontWeight.w600
                                          : FontWeight.w400)),
                          Text(f.source,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(
                      f.triggered == true
                          ? '+${f.points}'
                          : f.triggered == false
                              ? '—'
                              : 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: f.triggered == true
                            ? dotColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Info card ──────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 13, color: color)),
                  ),
                  ReadAloudIcon(text: '$title. $body'),
                ]),
                const SizedBox(height: 6),
                Text(body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── No profile warning ─────────────────────────────────────────
class _NoProfileWarning extends StatelessWidget {
  final BuildContext context;
  const _NoProfileWarning({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppTheme.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set up your profile to see stroke risk analysis. Go to the Profile tab.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}