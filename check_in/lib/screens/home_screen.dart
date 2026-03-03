import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'risk_screen.dart';
import 'health_tips_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ── Single BleService instance shared across ALL tabs ─────────────────────
  // This is the critical fix: one instance means one stream.
  // SettingsScreen syncs data → BleService emits on measurementStream
  // → HistoryScreen and DashboardTab both hear it and refresh.
  final BleService _bleService = BleService();

  // Screens are built once but receive the shared _bleService
  // NOT const — they need runtime references
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardTab(bleService: _bleService),
      RiskScreen(),
      HistoryScreen(bleService: _bleService),
      HealthTipsScreen(),
      SettingsScreen(bleService: _bleService),
    ];
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
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety_rounded),
            label: 'Health Tips',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final BleService bleService;
  const _DashboardTab({required this.bleService});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final HiveService _hiveService = HiveService();
  Measurement? _latest;
  UserProfile? _profile;
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    // Refresh dashboard whenever a new measurement comes in via BLE
    widget.bleService.measurementStream.listen((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      _profile = _hiveService.getUserProfile();
      _measurements = _hiveService.getAllMeasurements();
      _latest = _measurements.isNotEmpty ? _measurements.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = _profile?.name.split(' ').first ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $name',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Your heart health at a glance',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLatestCard(),
              const SizedBox(height: 20),
              if (_profile != null) ...[
                _buildRiskCard(),
                const SizedBox(height: 20),
              ],
              if (_measurements.isNotEmpty) ...[
                _buildStatsRow(),
                const SizedBox(height: 20),
              ],
              if (_latest == null) _buildNoDataCard(),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildLatestCard() {
    if (_latest == null) {
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
              Icons.monitor_heart_outlined,
              size: 48,
              color: AppTheme.primary.withOpacity(0.4),
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
              'Go to Settings to connect your AF Monitor and sync your first reading.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final isAF = _latest!.afPrediction == 1;
    final color = isAF ? AppTheme.danger : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _formatTimestamp(_latest!.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _latest!.heartRate.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'BPM',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAF
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _latest!.rhythm,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_latest!.confidence}%',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    'confidence',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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

  Widget _buildRiskCard() {
    final riskLevel = _profile!.strokeRiskLevel;
    final riskScore = _profile!.strokeRiskScore;
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
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                '$riskScore',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
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
                Text(
                  '$riskLevel Risk',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  'CHA\u2082DS\u2082-VASc score $riskScore/9',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _measurements.length;
    final afCount = _measurements.where((m) => m.afPrediction == 1).length;
    final avgHR =
        _measurements.map((m) => m.heartRate).reduce((a, b) => a + b) / total;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Readings',
            value: '$total',
            icon: Icons.list_alt_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Avg Heart Rate',
            value: '${avgHR.toStringAsFixed(0)} BPM',
            icon: Icons.favorite_rounded,
            color: AppTheme.danger,
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
      padding: const EdgeInsets.all(16),
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

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Go to Settings tab to connect your AF Monitor device and sync readings.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hrs ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}