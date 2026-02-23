import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement.dart';
import '../services/storage_service.dart';
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
  }

  void _load() {
    setState(() => _measurements = StorageService.getAllMeasurements());
  }

  @override
  void dispose() {
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
          _MeasurementList(
              measurements: _measurements, onRefresh: _load),
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

  const _MeasurementList(
      {required this.measurements, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'No readings yet',
        subtitle: 'Your measurement history will appear here after your first reading.',
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ResultsScreen(measurement: m)),
            ).then((_) => onRefresh()),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ChartCard(
          title: 'Coefficient of Variation (CV)',
          subtitle: 'AF threshold: 0.15',
          thresholdY: 0.15,
          data: sorted.map((m) => m.cv).toList(),
          color: AppTheme.primary,
          timestamps: sorted.map((m) => m.timestamp).toList(),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'RMSSD',
          subtitle: 'AF threshold: 80 ms',
          thresholdY: 80,
          data: sorted.map((m) => m.rmssd).toList(),
          color: AppTheme.secondary,
          timestamps: sorted.map((m) => m.timestamp).toList(),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Stroke Risk Score',
          subtitle: 'High risk threshold: 4',
          thresholdY: 4,
          data: sorted.map((m) => m.strokeScore.toDouble()).toList(),
          color: AppTheme.danger,
          timestamps: sorted.map((m) => m.timestamp).toList(),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Heart Rate',
          subtitle: 'Beats per minute',
          data: sorted.map((m) => m.heartRate).toList(),
          color: AppTheme.warning,
          timestamps: sorted.map((m) => m.timestamp).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> data;
  final List<DateTime> timestamps;
  final Color color;
  final double? thresholdY;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.data,
    required this.timestamps,
    required this.color,
    this.thresholdY,
  });

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final paddedMax = (maxY * 1.25).ceilToDouble();
    final paddedMin = (minY * 0.75).floorToDouble().clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11)),
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
                          color: AppTheme.danger.withOpacity(0.5),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            labelResolver: (_) => ' threshold',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.danger),
                          ),
                        ),
                      ])
                    : const ExtraLinesData(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
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
                            fontSize: 9, color: AppTheme.textSecondary),
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
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.08),
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
                            fontWeight: FontWeight.w600),
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
