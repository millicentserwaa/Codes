import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    StorageService.onDataChanged.addListener(_load);
  }

  void _load() {
    setState(() => _measurements = StorageService.getAllMeasurements());
  }

  @override
  void dispose() {
    StorageService.onDataChanged.removeListener(_load);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Readings'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MeasurementList(measurements: _measurements, onRefresh: _load),
          _TrendsView(measurements: _measurements),
        ],
      ),
    );
  }
}

// ── List tab ───────────────────────────────────────────────────
class _MeasurementList extends StatelessWidget {
  final List<Measurement> measurements;
  final VoidCallback onRefresh;

  const _MeasurementList({required this.measurements, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No readings yet',
        subtitle:
            'Your measurement history will appear here after your first reading.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: measurements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = measurements[i];
          return MeasurementListTile(
            measurement: m,
            onTap: () {
              TtsService.instance.stop();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ResultsScreen(measurement: m)),
              ).then((_) => onRefresh());
            },
          );
        },
      ),
    );
  }
}

// ── Trends / Charts tab ────────────────────────────────────────
class _TrendsView extends StatelessWidget {
  final List<Measurement> measurements;

  const _TrendsView({required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.length < 2) {
      return const EmptyState(
        icon: Icons.show_chart_rounded,
        title: 'Not enough data',
        subtitle: 'Take at least 2 readings to see trend charts.',
      );
    }

    // Chronological order for charts
    final sorted = [...measurements]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final timestamps = sorted.map((m) => m.timestamp).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // ── pRR50 ─────────────────────────────────────────────
        // Stroke HRV flag: low pRR50 (<3%) indicates autonomic dysfunction
        // Ref: Liao et al. Stroke. 1997;28(10):1944-1950
        _ChartCard(
          title: 'pRR50 (Autonomic Modulation)',
          subtitle: 'Stroke risk flag: below 3% — Ref: Liao et al. 1997',
          thresholdY: 3.0,
          thresholdLabel: '3% threshold',
          thresholdBelow: true,  // flag when BELOW threshold (low is bad)
          data: sorted.map((m) => m.pRR50).toList(),
          color: AppTheme.secondary,
          timestamps: timestamps,
        ),
        const SizedBox(height: 20),

        // ── SDSD ──────────────────────────────────────────────
        // Stroke HRV flag: high SDSD (>50ms) indicates autonomic instability
        // Ref: Task Force ESC/NASPE. Circulation. 1996;93(5):1043-1065
        _ChartCard(
          title: 'SDSD (Beat-to-Beat Irregularity)',
          subtitle: 'Stroke risk flag: above 50ms — Ref: Task Force ESC/NASPE 1996',
          thresholdY: 50.0,
          thresholdLabel: '50ms threshold',
          thresholdBelow: false, // flag when ABOVE threshold (high is bad)
          data: sorted.map((m) => m.sdsd).toList(),
          color: AppTheme.warning,
          timestamps: timestamps,
        ),
        const SizedBox(height: 20),

        // ── pRR20 ─────────────────────────────────────────────
        // Top-ranked AF classifier feature from RF model
        _ChartCard(
          title: 'pRR20 (RR Interval Variation)',
          subtitle: 'Top AF detection feature — proportion of diffs > 20ms',
          data: sorted.map((m) => m.pRR20).toList(),
          color: AppTheme.primary,
          timestamps: timestamps,
        ),
        const SizedBox(height: 20),

        // ── Stroke Risk Score ──────────────────────────────────
        // CHA₂DS₂-VASc score — high risk threshold is ≥2
        _ChartCard(
          title: 'CHA₂DS₂-VASc Stroke Score',
          subtitle: 'High risk threshold: ≥ 2',
          thresholdY: 2.0,
          thresholdLabel: 'High risk (≥2)',
          thresholdBelow: false,
          data: sorted.map((m) => m.strokeScore.toDouble()).toList(),
          color: AppTheme.danger,
          timestamps: timestamps,
        ),
        const SizedBox(height: 20),

        // ── Heart Rate ────────────────────────────────────────
        _ChartCard(
          title: 'Heart Rate',
          subtitle: 'Beats per minute',
          data: sorted.map((m) => m.heartRate).toList(),
          color: AppTheme.primary,
          timestamps: timestamps,
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Chart card ─────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> data;
  final List<DateTime> timestamps;
  final Color color;
  final double? thresholdY;
  final String? thresholdLabel;

  // thresholdBelow = true  → warn when value is BELOW threshold (e.g. pRR50)
  // thresholdBelow = false → warn when value is ABOVE threshold (e.g. SDSD)
  final bool thresholdBelow;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.data,
    required this.timestamps,
    required this.color,
    this.thresholdY,
    this.thresholdLabel,
    this.thresholdBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxY      = data.reduce((a, b) => a > b ? a : b);
    final minY      = data.reduce((a, b) => a < b ? a : b);
    final paddedMax = (maxY * 1.25).ceilToDouble();
    final paddedMin =
        (minY * 0.75).floorToDouble().clamp(0.0, double.infinity);

    // Determine chart line color — highlight in danger if any point breaches threshold
    final hasFlag = thresholdY != null &&
        data.any((v) => thresholdBelow ? v < thresholdY! : v > thresholdY!);
    final lineColor = hasFlag ? AppTheme.danger : color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFlag
              ? AppTheme.danger.withOpacity(0.35)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with optional flag badge
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (hasFlag)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: AppTheme.danger.withOpacity(0.4)),
                  ),
                  child: const Text(
                    '⚠ Flagged',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: paddedMin,
                maxY: paddedMax,
                extraLinesData: thresholdY != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: thresholdY!,
                          color: AppTheme.danger.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (_) =>
                                ' ${thresholdLabel ?? 'threshold'}',
                            style: const TextStyle(
                                fontSize: 9, color: AppTheme.danger),
                          ),
                        ),
                      ])
                    : const ExtraLinesData(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (val, _) => Text(
                        val.toStringAsFixed(
                            val < 1 ? 2 : val < 10 ? 1 : 0),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: data.length <= 7
                          ? 1
                          : (data.length / 5).ceil().toDouble(),
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= timestamps.length) {
                          return const SizedBox.shrink();
                        }
                        final d = timestamps[idx];
                        return Text(
                          '${d.day}/${d.month}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        // Highlight individual flagged points in red
                        final isFlagged = thresholdY != null &&
                            (thresholdBelow
                                ? spot.y < thresholdY!
                                : spot.y > thresholdY!);
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isFlagged ? AppTheme.danger : lineColor,
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textPrimary,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        s.y.toStringAsFixed(s.y < 1 ? 3 : 1),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}