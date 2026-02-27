
import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';
import '../services/storage_service.dart';
import '../services/stroke_algorithm.dart';
import '../models/stroke_models.dart';
import '../services/tts_service.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Measurement? _latest;
  PatientProfile? _profile;
  StrokeScoreResult? _stroke;

  @override
  void initState() {
    super.initState();
    _load();
    // refresh whenever new data arrives (e.g. demo seed or manual changes)
    StorageService.onDataChanged.addListener(_load);
  }

  void _load() {
    final m = StorageService.getLatestMeasurement();
    final p = StorageService.getProfile();
    StrokeScoreResult? stroke;
    if (m != null && p != null) {
      // algorithm signature changed – we now supply pRR50 and SDSD
      // we map existing HRV metrics: use pnn50 as pRR50 and rmssd as a proxy for SDSD
      stroke = StrokeAlgorithm.calculate(
        profile: p,
        pRR50: m.pnn50,
        // sdsd not stored directly; derive from rmssd using relationship SDSD = RMSSD / √2
        sdsd: m.rmssd / math.sqrt(2),
        afResultIndex: m.afResultIndex,
        systolicBP: m.systolicBP,
      );
    }
    setState(() {
      _latest = m;
      _profile = p;
      _stroke = stroke;
    });
  }

  @override
  void dispose() {
    StorageService.onDataChanged.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // make sure any speech is halted and reload data
              TtsService.instance.stop();
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analysis refreshed')),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _latest == null
          ? _NoDataState()
          : _AnalysisBody(
              measurement: _latest!,
              profile: _profile,
              stroke: _stroke,
            ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────
class _NoDataState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_heart_outlined,
                  size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text('No Analysis Yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Take your first measurement to see your AF screening results, HRV analysis, and stroke risk assessment here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bluetooth_rounded, size: 18),
              label: const Text('Go to Connect tab to measure'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full analysis body ─────────────────────────────────────────
class _AnalysisBody extends StatelessWidget {
  final Measurement measurement;
  final PatientProfile? profile;
  final StrokeScoreResult? stroke;

  const _AnalysisBody({
    required this.measurement,
    required this.profile,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Timestamp ────────────────────────────────────────
        _timestampRow(context),
        const SizedBox(height: 18),

        // ── AF Result ────────────────────────────────────────
        const _SectionLabel('AF Screening Result'),
        const SizedBox(height: 10),
        _AfCard(measurement: measurement),
        const SizedBox(height: 22),

        // ── HRV Analysis ─────────────────────────────────────
        const _SectionLabel('Heart Rate Variability (HRV)'),
        const SizedBox(height: 10),
        _HrvGrid(measurement: measurement),
        const SizedBox(height: 22),

        // ── Stroke Risk ───────────────────────────────────────
        const _SectionLabel('Stroke Risk Assessment'),
        const SizedBox(height: 10),
        if (stroke != null) ...[
          _StrokeScoreCard(result: stroke!),
          const SizedBox(height: 12),

          // ── Stroke Indicators breakdown ───────────────────
          const _SectionLabel('Stroke Risk Indicators'),
          const SizedBox(height: 6),
          Text(
            'Factors contributing to your modified CHA₂DS₂-VASc score',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),
          _StrokeIndicatorList(factors: stroke!.factors),
        ] else
          _NoProfilePrompt(),
        const SizedBox(height: 22),

        // ── Clinical disclaimer ───────────────────────────────
        _Disclaimer(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _timestampRow(BuildContext context) {
    final dt = measurement.timestamp;
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
    final str =
        '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Row(children: [
      const Icon(Icons.access_time_rounded,
          size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Text('Latest reading — $str',
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
    ]);
  }
}

// ── AF result card ─────────────────────────────────────────────
class _AfCard extends StatelessWidget {
  final Measurement measurement;
  const _AfCard({required this.measurement});

  Color get _color => _afColor(measurement.afResult);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(_afIcon(measurement.afResult), color: _color, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AfResultBadge(result: measurement.afResult, large: true),
                const SizedBox(height: 4),
                Text('AF Score: ${measurement.afScore} / 5',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _color)),
              ],
            ),
          ]),
          const SizedBox(height: 14),
          Text(measurement.afResult.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 13, height: 1.5)),
        ],
      ),
    );
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

  IconData _afIcon(AfResult r) {
    switch (r) {
      case AfResult.normal:
        return Icons.favorite_rounded;
      case AfResult.possibleAF:
        return Icons.warning_rounded;
      case AfResult.inconclusive:
        return Icons.help_rounded;
    }
  }
}

// ── HRV 2×2 grid ──────────────────────────────────────────────
class _HrvGrid extends StatelessWidget {
  final Measurement measurement;
  const _HrvGrid({required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: HrvTile(
          label: 'COEFFICIENT OF VARIATION',
          value: measurement.cv.toStringAsFixed(3),
          unit: '',
          subtitle: measurement.cv >= 0.15
              ? '⚠ Above AF threshold (0.15)'
              : '✓ Within normal range',
          highlight: measurement.cv >= 0.15 ? AppTheme.warning : null,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: HrvTile(
          label: 'RMSSD',
          value: measurement.rmssd.toStringAsFixed(0),
          unit: 'ms',
          subtitle: measurement.rmssd >= 80
              ? '⚠ Above AF threshold (80 ms)'
              : '✓ Within normal range',
          highlight: measurement.rmssd >= 80 ? AppTheme.warning : null,
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: HrvTile(
          label: 'pNN50',
          value: measurement.pnn50.toStringAsFixed(1),
          unit: '%',
          subtitle: measurement.pnn50 >= 50
              ? '⚠ Above AF threshold (50%)'
              : '✓ Within normal range',
          highlight: measurement.pnn50 >= 50 ? AppTheme.warning : null,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: HrvTile(
          label: 'HEART RATE',
          value: measurement.heartRate.toStringAsFixed(0),
          unit: 'bpm',
          subtitle: 'Mean RR: ${measurement.meanRR.toStringAsFixed(0)} ms',
        )),
      ]),
    ]);
  }
}

// ── Stroke score summary card ──────────────────────────────────
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modified CHA₂DS₂-VASc',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                StrokeRiskChip(
                    risk: result.risk, score: result.totalScore, large: true),
              ],
            ),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _color, width: 3),
                color: _color.withValues(alpha: 0.08),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${result.totalScore}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _color)),
                  Text('/ ${result.maxScore}',
                      style: TextStyle(
                          fontSize: 10, color: _color.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: _color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
        const SizedBox(height: 8),
        Text(result.risk.advice,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12, height: 1.5)),
      ]),
    );
  }
}

// ── Stroke indicator factor list ───────────────────────────────
class _StrokeIndicatorList extends StatelessWidget {
  final List<ScoringFactor> factors;
  const _StrokeIndicatorList({required this.factors});

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

          // Colour coding
          Color dotColor;
          String statusLabel;
          IconData statusIcon;

          if (f.triggered == null) {
            dotColor = AppTheme.textSecondary;
            statusLabel = 'N/A';
            statusIcon = Icons.remove;
          } else if (f.triggered!) {
            dotColor = f.points >= 2 ? AppTheme.danger : AppTheme.warning;
            statusLabel = '+${f.points}';
            statusIcon = Icons.add_circle_outline_rounded;
          } else {
            dotColor = AppTheme.secondary;
            statusLabel = '—';
            statusIcon = Icons.check_circle_outline_rounded;
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                // Status icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, size: 16, color: dotColor),
                ),
                const SizedBox(width: 12),
                // Factor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 13,
                                    fontWeight: f.triggered == true
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: f.triggered == true
                                        ? dotColor
                                        : AppTheme.textPrimary,
                                  )),
                      const SizedBox(height: 2),
                      Text(f.source,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                // Points
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: f.triggered == true
                        ? dotColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: f.triggered == true
                              ? dotColor
                              : AppTheme.textSecondary)),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, indent: 60, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── No profile prompt ──────────────────────────────────────────
class _NoProfilePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.person_outline_rounded, color: AppTheme.warning, size: 22),
        SizedBox(width: 12),
        Expanded(
            child: Text(
          'Complete your profile in Settings to see personalised stroke risk analysis.',
          style: TextStyle(fontSize: 13),
        )),
      ]),
    );
  }
}

// ── Disclaimer ─────────────────────────────────────────────────
class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            'This device is a screening tool only and does not constitute a clinical diagnosis. '
            'Always consult a qualified healthcare professional before making any medical decisions.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        const ReadAloudIcon(
          text:
              'This device is a screening tool only and does not constitute a clinical diagnosis. '
              'Always consult a qualified healthcare professional before making any medical decisions.',
        ),
      ]),
    );
  }
}

// ── Section label ──────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(String text) : text = text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}