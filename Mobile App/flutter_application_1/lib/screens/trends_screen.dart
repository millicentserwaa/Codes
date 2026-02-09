import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/session_repository.dart';
import '../models/session_record.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final repo = SessionRepository();
  bool loading = true;
  List<SessionRecord> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await repo.getAllSessions(newestFirst: false);
    setState(() {
      sessions = s;
      loading = false;
    });
  }

  // ---- Build spots ----
  List<FlSpot> _hrSpots() {
    return List.generate(
      sessions.length,
      (i) => FlSpot(i.toDouble(), sessions[i].heartRateBpm),
    );
  }

  List<FlSpot> _confidenceSpots() {
    return List.generate(
      sessions.length,
      (i) => FlSpot(i.toDouble(), sessions[i].confidence.toDouble()),
    );
  }

  List<FlSpot> _spo2Spots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      if (s.spo2 != null && (s.spo2Confidence ?? 0) >= 60) {
        spots.add(FlSpot(i.toDouble(), s.spo2!));
      }
    }
    return spots;
  }

  // ---- Dynamic scaling helpers ----
  double _minY(List<FlSpot> spots, double fallback) {
    if (spots.isEmpty) return fallback;
    final min = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    return min - 5;
  }

  double _maxY(List<FlSpot> spots, double fallback) {
    if (spots.isEmpty) return fallback;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return max + 5;
  }

  double _clamp(double v, double lo, double hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  }

  // ---- Chart widget ----
  Widget _buildChart(String title, List<FlSpot> spots, double minY, double maxY) {
    if (spots.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$title: not enough data'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
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

              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  dotData: const FlDotData(show: true),
                  barWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // compute spots once (so we can reuse for min/max)
    final hr = _hrSpots();
    final conf = _confidenceSpots();
    final spo2 = _spo2Spots();

    // dynamic scaling
    final hrMin = _clamp(_minY(hr, 40), 30, 160);
    final hrMax = _clamp(_maxY(hr, 140), 30, 160);

    // confidence is naturally 0–100, keep fixed for readability
    const confMin = 0.0;
    const confMax = 100.0;

    final spo2Min = _clamp(_minY(spo2, 85), 80, 100);
    final spo2Max = _clamp(_maxY(spo2, 100), 80, 100);

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildChart('Heart Rate (bpm)', hr, hrMin, hrMax),
            const SizedBox(height: 24),
            _buildChart('Confidence Score', conf, confMin, confMax),
            const SizedBox(height: 24),
            _buildChart('SpO₂ (%)', spo2, spo2Min, spo2Max),
          ],
        ),
      ),
    );
  }
}
