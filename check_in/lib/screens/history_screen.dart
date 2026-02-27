import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HiveService _hiveService = HiveService();
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _measurements = _hiveService.getAllMeasurements();
    });
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
          ? const EmptyState(
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
                    // Heart rate trend chart
                    _buildHeartRateTrend(),
                    const SizedBox(height: 24),

                    // AF vs Normal chart
                    _buildAFSummaryChart(),
                    const SizedBox(height: 24),

                    // Measurements list
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

  // ── Heart Rate Trend ─────────────────────────────────────
  Widget _buildHeartRateTrend() {
    // Take last 10 readings, reverse to show oldest to newest
    final data = _measurements.take(10).toList().reversed.toList();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.heartRate);
    }).toList();

    final minY = data
            .map((m) => m.heartRate)
            .reduce((a, b) => a < b ? a : b) -
        10;
    final maxY = data
            .map((m) => m.heartRate)
            .reduce((a, b) => a > b ? a : b) +
        10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                  ),
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
                        final isAF =
                            data[index].afPrediction == 1;
                        return FlDotCirclePainter(
                          radius: 5,
                          color: isAF
                              ? AppTheme.danger
                              : AppTheme.primary,
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── AF vs Normal Summary ─────────────────────────────────
  Widget _buildAFSummaryChart() {
    final normalCount =
        _measurements.where((m) => m.afPrediction == 0).length;
    final afCount =
        _measurements.where((m) => m.afPrediction == 1).length;
    final total = _measurements.length;

    final normalPercent = (normalCount / total * 100).toStringAsFixed(0);
    final afPercent = (afCount / total * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
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

          // Normal bar
          _buildSummaryBar(
            label: 'Normal',
            count: normalCount,
            percent: normalPercent,
            color: AppTheme.success,
            total: total,
          ),
          const SizedBox(height: 16),

          // AF bar
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

  // ── Confirm Clear ────────────────────────────────────────
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Clear all readings?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete all your measurement history. This cannot be undone.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
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