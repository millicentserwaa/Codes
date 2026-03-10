import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement.dart';
import '../services/hive_service.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  final BleService bleService;
  const HistoryScreen({super.key, required this.bleService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HiveService _hiveService = HiveService();
  List<Measurement> _measurements = [];
  StreamSubscription? _measurementSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _measurementSub = widget.bleService.measurementStream.listen((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _measurementSub?.cancel();
    super.dispose();
  }

  void _loadData() {
    final data = _hiveService.getAllMeasurements();
    if (mounted) setState(() => _measurements = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_measurements.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _measurements.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: 'No readings yet',
              subtitle:
                  'Connect your AF Monitor and sync to see your measurement history here.',
            )
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeartRateTrend(),
                    const SizedBox(height: 24),
                    _buildAFSummaryChart(),
                    const SizedBox(height: 24),
                    _buildAFBurdenChart(),
                    const SizedBox(height: 24),
                    _buildRhythmStreakCard(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'All Readings',
                      actionLabel: '${_measurements.length} total',
                    ),
                    const SizedBox(height: 16),
                    ..._measurements.map(
                      (m) => MeasurementTile(
                        rhythm: m.rhythm,
                        heartRate: m.heartRate,
                        confidence: m.confidence,
                        timestamp: m.timestamp,
                        afPrediction: m.afPrediction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Shared card decoration ────────────────────────────────────────────────────
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppTheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.divider),
  );

  // ── Heart Rate Trend ──────────────────────────────────────────────────────────
  Widget _buildHeartRateTrend() {
    if (_measurements.isEmpty) return const SizedBox.shrink();

    final data = _measurements.take(10).toList().reversed.toList();
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.heartRate))
        .toList();

    // Clamp Y axis to sensible BPM range, never go below 0
    final hrValues = data.map((m) => m.heartRate).toList();
    final minY = (hrValues.reduce((a, b) => a < b ? a : b) - 10)
        .clamp(0, 300)
        .toDouble();
    final maxY = (hrValues.reduce((a, b) => a > b ? a : b) + 10)
        .clamp(0, 300)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heart Rate Trend',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Last ${data.length} readings',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final dt = data[index].timestamp;
                        return Text(
                          '${dt.day}/${dt.month}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isAF = data[index].afPrediction == 1;
                        return FlDotCirclePainter(
                          radius: 5,
                          color: isAF ? AppTheme.danger : AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(AppTheme.primary, 'Normal'),
              const SizedBox(width: 16),
              _buildLegendDot(AppTheme.danger, 'Possible AF'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── Rhythm Summary bars ───────────────────────────────────────────────────────
  Widget _buildAFSummaryChart() {
    final total = _measurements.length;
    if (total == 0) return const SizedBox.shrink();

    final normalCount = _measurements.where((m) => m.afPrediction == 0).length;
    final afCount = _measurements.where((m) => m.afPrediction == 1).length;
    final normalPercent = (normalCount / total * 100).toStringAsFixed(0);
    final afPercent = (afCount / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rhythm Summary',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Based on $total total readings',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryBar(
            label: 'Normal',
            count: normalCount,
            percent: normalPercent,
            color: AppTheme.success,
            total: total,
          ),
          const SizedBox(height: 16),
          _buildSummaryBar(
            label: 'Possible AF',
            count: afCount,
            percent: afPercent,
            color: AppTheme.danger,
            total: total,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar({
    required String label,
    required int count,
    required String percent,
    required Color color,
    required int total,
  }) {
    final fraction = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '$count readings ($percent%)',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── AF Burden Over Time ───────────────────────────────────────────────────────
  // For each reading (oldest→newest), computes the rolling % of AF readings
  // up to that point. Shows whether AF burden is increasing or decreasing.
  Widget _buildAFBurdenChart() {
    if (_measurements.length < 2) return const SizedBox.shrink();

    // Reverse so oldest is first (index 0)
    final data = _measurements.reversed.toList();

    // Build rolling AF burden spots
    int afRunningCount = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i].afPrediction == 1) afRunningCount++;
      final burden = (afRunningCount / (i + 1)) * 100;
      spots.add(FlSpot(i.toDouble(), burden));
    }

    final currentBurden = spots.last.y.toStringAsFixed(1);
    double trend = 0.0;
    if (spots.length >= 6) {
      final recent =
          spots.reversed.take(5).map((s) => s.y).reduce((a, b) => a + b) / 5;
      final earlier =
          spots.reversed
              .skip(5)
              .take(5)
              .map((s) => s.y)
              .reduce((a, b) => a + b) /
          5;
      trend = recent - earlier;
    } else if (spots.length >= 2) {
      trend = spots.last.y - spots.first.y;
    }
    final trendText = trend > 0
        ? '↑ increasing'
        : trend < 0
        ? '↓ decreasing'
        : '→ stable';
    final trendColor = trend > 0
        ? AppTheme.danger
        : trend < 0
        ? AppTheme.success
        : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AF Burden Over Time',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Rolling % of AF readings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentBurden%',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: spots.last.y > 20
                          ? AppTheme.danger
                          : AppTheme.success,
                    ),
                  ),
                  Text(
                    trendText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= data.length ||
                            index % (data.length > 6 ? 2 : 1) != 0) {
                          return const SizedBox.shrink();
                        }
                        final dt = data[index].timestamp;
                        return Text(
                          '${dt.day}/${dt.month}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  // 20% danger threshold reference line shown as dashed area
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 20),
                      FlSpot((data.length - 1).toDouble(), 20),
                    ],
                    isCurved: false,
                    color: AppTheme.danger.withOpacity(0.3),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
                  // Actual burden line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.danger,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: spot.y > 20
                                ? AppTheme.danger
                                : AppTheme.success,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.danger.withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 20,
                height: 2,
                color: AppTheme.danger.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                '20% clinical attention threshold',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rhythm Streak Card ────────────────────────────────────────────────────────
  // Shows a visual timeline of each reading as a colored block,
  // plus current streak (consecutive Normal or AF readings).
  Widget _buildRhythmStreakCard() {
    if (_measurements.isEmpty) return const SizedBox.shrink();

    // Oldest → newest
    final data = _measurements.reversed.toList();

    // Calculate current streak (from most recent reading backwards)
    int streak = 1;
    final latestIsNormal = data.last.afPrediction == 0;
    for (int i = data.length - 2; i >= 0; i--) {
      final isNormal = data[i].afPrediction == 0;
      if (isNormal == latestIsNormal) {
        streak++;
      } else {
        break;
      }
    }

    final streakLabel = latestIsNormal
        ? '$streak consecutive Normal reading${streak > 1 ? 's' : ''}'
        : '$streak consecutive Possible AF reading${streak > 1 ? 's' : ''}';
    final streakColor = latestIsNormal ? AppTheme.success : AppTheme.danger;
    final streakIcon = latestIsNormal
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    // Confidence average
    final avgConfidence =
        data.map((m) => m.confidence).reduce((a, b) => a + b) / data.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rhythm Streak',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Each block = one reading, oldest → newest',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Timeline blocks
          Builder(
            builder: (context) {
              const maxBlocks = 50;
              final display = data.length > maxBlocks
                  ? data.sublist(data.length - maxBlocks)
                  : data;
              final overflow = data.length - display.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overflow > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '+ $overflow earlier readings not shown',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: display.map((m) {
                      final isAF = m.afPrediction == 1;
                      return Tooltip(
                        message:
                            '${m.timestamp.day}/${m.timestamp.month}  ${m.heartRate.toStringAsFixed(0)} BPM  ${m.rhythm}  ${m.confidence}%',
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isAF
                                ? AppTheme.danger.withOpacity(0.85)
                                : AppTheme.success.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendDot(AppTheme.success, 'Normal'),
              const SizedBox(width: 16),
              _buildLegendDot(AppTheme.danger, 'Possible AF'),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Current streak
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: streakColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(streakIcon, color: streakColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      streakLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: streakColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Avg confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avg Detection Confidence',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${avgConfidence.toStringAsFixed(1)}% across all readings',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Confirm Clear ─────────────────────────────────────────────────────────────
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all readings?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete all your measurement history. This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hiveService.clearAllMeasurements();
      _loadData();
    }
  }
}
