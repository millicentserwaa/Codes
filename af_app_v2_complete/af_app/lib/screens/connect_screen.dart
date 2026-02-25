import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/measurement.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../services/stroke_algorithm.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'results_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for new readings from device
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleService>();
      ble.readingStream.listen(_onReadingReceived);
    });
  }

  void _onReadingReceived(DeviceReading reading) async {
    final profile = StorageService.getProfile();

    // Compute stroke score
    int strokeScore = 0;
    int strokeRiskIndex = 0;
    if (profile != null) {
      // new algorithm expects pRR50 and SDSD instead of CV/RMSSD
      final result = StrokeAlgorithm.calculate(
        profile: profile,
        pRR50: reading.pnn50,
        sdsd: reading.rmssd / math.sqrt(2),
        afResultIndex: reading.afResultIndex,
        systolicBP: reading.systolicBP > 0 ? reading.systolicBP : null,
      );
      strokeScore = result.totalScore;
      strokeRiskIndex = result.risk.index;
    }

    final m = Measurement(
      timestamp: reading.timestamp,
      cv: reading.cv,
      rmssd: reading.rmssd,
      pnn50: reading.pnn50,
      meanRR: reading.meanRR,
      heartRate: reading.heartRate,
      afResultIndex: reading.afResultIndex,
      afScore: reading.afScore,
      strokeScore: strokeScore,
      strokeRiskIndex: strokeRiskIndex,
      systolicBP: reading.systolicBP > 0 ? reading.systolicBP : null,
    );

    await StorageService.saveMeasurement(m);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(measurement: m)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return Scaffold(
        appBar: AppBar(title: const Text('Device Connection')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Device animation ────────────────────────────
                _DeviceIcon(status: ble.status),
                const SizedBox(height: 32),

                // ── Status message ──────────────────────────────
                Text(
                  ble.statusMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (ble.status == BleStatus.scanning &&
                    ble.scanResults.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: ble.scanResults.map((r) {
                      final title = r.device.name.isNotEmpty
                          ? r.device.name
                          : r.device.id.id;
                      return ListTile(
                        dense: true,
                        title: Text(title),
                        subtitle: Text(r.device.id.id),
                        trailing: TextButton(
                          child: const Text('Connect'),
                          onPressed: () => ble.connect(r.device),
                        ),
                      );
                    }).toList(),
                  ),

                if (ble.isConnected)
                  Text(
                    'Connected to ${ble.device?.name ?? ble.device?.platformName ?? "AF-SCREEN"}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.secondary),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 40),

                // ── Action button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ble.isConnected
                      ? OutlinedButton.icon(
                          onPressed: () => ble.disconnect(),
                          icon: const Icon(Icons.bluetooth_disabled_rounded),
                          label: const Text('Disconnect'),
                        )
                      : ble.status == BleStatus.scanning ||
                              ble.status == BleStatus.connecting
                          ? OutlinedButton.icon(
                              onPressed: () => ble.stopScan(),
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Cancel'),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => ble.startScan(),
                              icon:
                                  const Icon(Icons.bluetooth_searching_rounded),
                              label: const Text('Scan for Device'),
                            ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // ── Instructions ────────────────────────────────
                _Instructions(),

                const SizedBox(height: 40),

                // ── Simulate measurement (dev/demo) ─────────────
                OutlinedButton.icon(
                  onPressed: () => _simulateMeasurement(context),
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text('Simulate Measurement (Demo)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this to test the app without the hardware',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ));
  }

  void _simulateMeasurement(BuildContext context) async {
    // Pick a random-ish result for demo purposes
    final isAF = DateTime.now().second % 3 == 0;
    final reading = DeviceReading(
      cv: isAF ? 0.22 : 0.07,
      rmssd: isAF ? 95 : 32,
      pnn50: isAF ? 58 : 12,
      meanRR: isAF ? 780 : 855,
      heartRate: isAF ? 77 : 70,
      afResultIndex: isAF ? 1 : 0,
      afScore: isAF ? 4 : 0,
      systolicBP: 0,
      timestamp: DateTime.now(),
    );
    _onReadingReceived(reading);
  }
}

// ── Device icon with animated ring ────────────────────────────
class _DeviceIcon extends StatefulWidget {
  final BleStatus status;
  const _DeviceIcon({required this.status});

  @override
  State<_DeviceIcon> createState() => _DeviceIconState();
}

class _DeviceIconState extends State<_DeviceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulse = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status == BleStatus.scanning ||
        widget.status == BleStatus.connecting;
    final isConnected = widget.status == BleStatus.connected;

    final color = isConnected
        ? AppTheme.secondary
        : isActive
            ? AppTheme.primary
            : AppTheme.textSecondary;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: isActive ? _pulse.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(
          isConnected
              ? Icons.bluetooth_connected_rounded
              : isActive
                  ? Icons.bluetooth_searching_rounded
                  : Icons.bluetooth_rounded,
          size: 52,
          color: color,
        ),
      ),
    );
  }
}

// ── Setup instructions ─────────────────────────────────────────
class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How to connect', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        ...[
          (
            '1',
            'Power on the AF-Screen device and ensure its Bluetooth is enabled',
            Icons.power_settings_new_rounded
          ),
          (
            '2',
            'Tap "Scan for Device" above and wait until the app shows it has connected',
            Icons.search_rounded
          ),
        ]
            .map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(step.$1,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(step.$3, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(step.$2,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 13,
                                    )),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}