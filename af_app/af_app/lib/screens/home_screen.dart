import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/measurement.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'results_screen.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Measurement? _latest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _latest = StorageService.getLatestMeasurement());
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          child: CustomScrollView(
            slivers: [
              // ── App Bar ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AF Screen',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontSize: 22)),
                      Text('Cardiac Monitoring',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                actions: [
                  // BLE status dot
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ConnectScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ble.isConnected
                              ? AppTheme.secondary.withOpacity(0.1)
                              : AppTheme.border,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: ble.isConnected
                                ? AppTheme.secondary
                                : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: ble.isConnected
                                    ? AppTheme.secondary
                                    : AppTheme.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ble.isConnected ? 'Connected' : 'Not connected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ble.isConnected
                                    ? AppTheme.secondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Latest Result Card ────────────────────
                    if (_latest != null)
                      _LatestResultCard(
                        measurement: _latest!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultsScreen(measurement: _latest!),
                          ),
                        ).then((_) => _load()),
                      )
                    else
                      _NoDataCard(
                        onConnect: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ConnectScreen())),
                      ),

                    const SizedBox(height: 24),

                    // ── 7-Day Summary ─────────────────────────
                    if (StorageService.measurementCount > 0)
                      _WeekSummary(),

                    const SizedBox(height: 24),

                    // ── Quick tips ────────────────────────────
                    _QuickTipsCard(),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Latest result card ─────────────────────────────────────────
class _LatestResultCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onTap;

  const _LatestResultCard({required this.measurement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withBlue(220),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Latest Result',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white70, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            AfResultBadge(result: measurement.afResult, large: true),
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem('Heart Rate',
                    '${measurement.heartRate.toStringAsFixed(0)} bpm'),
                const SizedBox(width: 24),
                _statItem('CV', measurement.cv.toStringAsFixed(3)),
                const SizedBox(width: 24),
                _statItem('RMSSD', '${measurement.rmssd.toStringAsFixed(0)} ms'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Stroke Risk: ',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(
                  '${measurement.strokeRisk.label} (score ${measurement.strokeScore})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── No data card ───────────────────────────────────────────────
class _NoDataCard extends StatelessWidget {
  final VoidCallback onConnect;
  const _NoDataCard({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text('No measurements yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Connect your AF-Screen device and take your first reading.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.bluetooth_rounded, size: 18),
            label: const Text('Connect Device'),
          ),
        ],
      ),
    );
  }
}

// ── 7-day summary ──────────────────────────────────────────────
class _WeekSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final all = StorageService.getAllMeasurements();
    final week = all
        .where((m) =>
            m.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    final afCount =
        week.where((m) => m.afResult == AfResult.possibleAF).length;
    final avgCV = week.isEmpty
        ? 0.0
        : week.map((m) => m.cv).reduce((a, b) => a + b) / week.length;
    final avgHR = week.isEmpty
        ? 0.0
        : week.map((m) => m.heartRate).reduce((a, b) => a + b) / week.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Last 7 Days'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '${week.length}',
                label: 'Readings',
                color: AppTheme.primary,
                icon: Icons.monitor_heart_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: '$afCount',
                label: 'AF Events',
                color: afCount > 0 ? AppTheme.danger : AppTheme.secondary,
                icon: afCount > 0
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: avgHR.toStringAsFixed(0),
                label: 'Avg HR (bpm)',
                color: AppTheme.warning,
                icon: Icons.favorite_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 24, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Quick tips card ────────────────────────────────────────────
class _QuickTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tips_and_updates_rounded,
                color: AppTheme.secondary, size: 18),
            const SizedBox(width: 8),
            Text('Tips for Best Results',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.secondary)),
          ]),
          const SizedBox(height: 12),
          ...[
            '🤫  Sit quietly and rest for 2 minutes before measuring',
            '🫰  Place fingers firmly and flat on the pads — don\'t press too hard',
            '🕐  Measure at the same time each day for best trend data',
            '☕  Avoid caffeine or exercise 30 minutes before',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
