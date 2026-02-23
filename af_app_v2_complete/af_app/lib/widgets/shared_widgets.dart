import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

// ── Read‑aloud icon (plays provided text when tapped) ─────────────
class ReadAloudIcon extends StatefulWidget {
  final String text;
  const ReadAloudIcon({super.key, required this.text});

  @override
  State<ReadAloudIcon> createState() => _ReadAloudIconState();
}

class _ReadAloudIconState extends State<ReadAloudIcon> {
  final TtsService _tts = TtsService.instance;

  @override
  void initState() {
    super.initState();
    _tts.stateNotifier.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _tts.stateNotifier.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    // rebuild to update icon
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playing = _tts.isPlaying && _tts.currentText == widget.text;
    final paused = playing && _tts.isPaused;
    final iconData =
        paused ? Icons.play_arrow_rounded : Icons.volume_up_rounded;
    final tooltip = paused ? 'Resume' : 'Read aloud';

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(iconData, size: 20, color: AppTheme.textSecondary),
      onPressed: () {
        // debug
        // ignore: avoid_print
        print('[ReadAloudIcon] tapped, text="${widget.text}"');
        _tts.togglePlayPause(widget.text);
      },
      tooltip: tooltip,
    );
  }
}

// ── AF Result Badge ────────────────────────────────────────────
class AfResultBadge extends StatelessWidget {
  final AfResult result;
  final bool large;

  const AfResultBadge({super.key, required this.result, this.large = false});

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

  IconData get _icon {
    switch (result) {
      case AfResult.normal:
        return Icons.check_circle_rounded;
      case AfResult.possibleAF:
        return Icons.warning_rounded;
      case AfResult.inconclusive:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = large ? 22.0 : 14.0;
    final padding = large
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: size),
          const SizedBox(width: 6),
          Text(
            result.label,
            style: TextStyle(
              color: _color,
              fontSize: size - 4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stroke Risk Chip ───────────────────────────────────────────
class StrokeRiskChip extends StatelessWidget {
  final StrokeRisk risk;
  final int score;
  final bool large;

  const StrokeRiskChip({
    super.key,
    required this.risk,
    required this.score,
    this.large = false,
  });

  Color get _color {
    switch (risk) {
      case StrokeRisk.low:
        return AppTheme.riskLow;
      case StrokeRisk.moderate:
        return AppTheme.riskModerate;
      case StrokeRisk.high:
        return AppTheme.riskHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Score $score',
            style: TextStyle(
              color: _color,
              fontSize: large ? 15 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: _color.withOpacity(0.3)),
          const SizedBox(width: 8),
          Text(
            risk.label,
            style: TextStyle(
              color: _color,
              fontSize: large ? 15 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── HRV Metric Tile ────────────────────────────────────────────
class HrvTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? subtitle;
  final Color? highlight;

  const HrvTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.subtitle,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              highlight != null ? highlight!.withOpacity(0.4) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  )),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 28,
                        color: highlight ?? AppTheme.textPrimary,
                      )),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        )),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    )),
          ]
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ]
          ],
        ),
      ),
    );
  }
}

// ── Measurement List Tile ──────────────────────────────────────
class MeasurementListTile extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onTap;

  const MeasurementListTile({
    super.key,
    required this.measurement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = measurement.timestamp;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Left icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _afColor(measurement.afResult).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _afIcon(measurement.afResult),
                color: _afColor(measurement.afResult),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(measurement.afResult.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(
                          'CV ${measurement.cv.toStringAsFixed(2)}',
                          measurement.cv >= 0.15
                              ? AppTheme.warning
                              : AppTheme.secondary),
                      const SizedBox(width: 6),
                      _pill(
                          'HR ${measurement.heartRate.toStringAsFixed(0)} bpm',
                          AppTheme.primary),
                    ],
                  )
                ],
              ),
            ),
            // Right: stroke score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StrokeRiskChip(
                    risk: measurement.strokeRisk,
                    score: measurement.strokeScore),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
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
