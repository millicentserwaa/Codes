import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/ble_service.dart';
import '../services/risk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  final BleService _bleService = BleService();

  UserProfile? _profile;
  List<Measurement> _measurements = [];
  Measurement? _latest;
  bool _isSyncing = false;
  int _syncProgress = 0;
  String _bleStatus = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToBle();
  }

  void _loadData() {
    setState(() {
      _profile = _hiveService.getUserProfile();
      _measurements = _hiveService.getAllMeasurements();
      _latest = _hiveService.getLatestMeasurement();
    });
  }

  void _listenToBle() {
    _bleService.statusStream.listen((status) {
      if (mounted) setState(() => _bleStatus = status);
    });

    _bleService.syncProgressStream.listen((progress) {
      if (mounted) setState(() => _syncProgress = progress);
    });

    _bleService.measurementStream.listen((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
    });
    await _bleService.syncData();
    _loadData();
    setState(() => _isSyncing = false);
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          const HistoryPlaceholder(),
          const RiskPlaceholder(),
          const DevicePlaceholder(),
          const SettingsPlaceholder(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboard() {
    final profile = _profile;
    final latest = _latest;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(profile),
            const SizedBox(height: 28),

            // Latest reading card
            if (latest != null) ...[
              _buildLatestCard(latest),
              const SizedBox(height: 20),
            ] else ...[
              _buildNoDataCard(),
              const SizedBox(height: 20),
            ],

            // Stroke risk card
            if (profile != null) ...[
              _buildStrokeRiskCard(profile),
              const SizedBox(height: 20),
            ],

            // Sync card
            _buildSyncCard(),
            const SizedBox(height: 20),

            // Stats row
            if (_measurements.isNotEmpty) ...[
              _buildStatsRow(),
              const SizedBox(height: 20),
            ],

            // BLE status
            if (_bleStatus.isNotEmpty)
              _buildStatusBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile? profile) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    if (hour >= 17) greeting = 'Good evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile?.name ?? 'Welcome',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestCard(Measurement latest) {
    final isAF = latest.afPrediction == 1;
    final color = AppTheme.rhythmColor(latest.afPrediction);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAF
              ? [
                  AppTheme.danger.withOpacity(0.15),
                  AppTheme.danger.withOpacity(0.05),
                ]
              : [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primary.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Reading',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  latest.rhythm,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.heartRate.toStringAsFixed(0),
                style: GoogleFonts.inter(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'BPM',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Confidence',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${latest.confidence}%',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatTimestamp(latest.timestamp),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: AppTheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No readings yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect your AF Monitor device and sync to see your readings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeRiskCard(UserProfile profile) {
    final riskLevel = profile.strokeRiskLevel;
    final score = profile.strokeRiskScore;
    final color = AppTheme.riskColor(riskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stroke Risk',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$riskLevel Risk',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Score: $score',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Device Sync',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _bleService.isConnected
                      ? AppTheme.success
                      : AppTheme.textSecondary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _bleService.isConnected
                ? 'AF Monitor connected'
                : 'No device connected',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          if (_isSyncing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: AppTheme.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Syncing... $_syncProgress readings received',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/device'),
                  icon: const Icon(Icons.bluetooth_rounded, size: 18),
                  label: const Text('Connect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _bleService.isConnected && !_isSyncing
                      ? _syncData
                      : null,
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sync'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final afCount =
        _measurements.where((m) => m.afPrediction == 1).length;
    final avgHR = _measurements
            .map((m) => m.heartRate)
            .reduce((a, b) => a + b) /
        _measurements.length;
    final afBurden = RiskService.getAFBurden(_measurements);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Readings',
            value: '${_measurements.length}',
            icon: Icons.bar_chart_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Avg Heart Rate',
            value: '${avgHR.toStringAsFixed(0)} BPM',
            icon: Icons.favorite_rounded,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'AF Events',
            value: '$afCount',
            icon: Icons.warning_amber_rounded,
            color: afCount > 0 ? AppTheme.danger : AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _bleStatus,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shield_outlined),
          activeIcon: Icon(Icons.shield_rounded),
          label: 'Risk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bluetooth_outlined),
          activeIcon: Icon(Icons.bluetooth_rounded),
          label: 'Device',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// Placeholders for other screens
class HistoryPlaceholder extends StatelessWidget {
  const HistoryPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('History Screen'));
}

class RiskPlaceholder extends StatelessWidget {
  const RiskPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Risk Screen'));
}

class DevicePlaceholder extends StatelessWidget {
  const DevicePlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Device Screen'));
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Settings Screen'));
}