import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final BleService _bleService = BleService();
  final TtsService _ttsService = TtsService();

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSyncing = false;
  int _syncProgress = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _listenToStreams();
  }

  void _listenToStreams() {
    _bleService.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    _bleService.syncProgressStream.listen((progress) {
      if (mounted) setState(() => _syncProgress = progress);
    });

    _bleService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {});
        _ttsService.speakConnectionStatus(connected);
      }
    });
  }

  // ── Request permissions ──────────────────────────────────
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
  }

  // ── Start scan ───────────────────────────────────────────
  Future<void> _startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth and location permissions are required.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _scanResults = [];
      _isScanning = true;
    });

    _bleService.scanForDevice().listen(
      (results) {
        if (mounted) setState(() => _scanResults = results);
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );

    // Stop scan after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _bleService.stopScan();
        setState(() => _isScanning = false);
      }
    });
  }

  // ── Connect to device ────────────────────────────────────
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    _bleService.stopScan();

    final success = await _bleService.connectToDevice(device);

    if (mounted) {
      setState(() => _isConnecting = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Please try again.'),
          ),
        );
      }
    }
  }

  // ── Sync data ────────────────────────────────────────────
  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
    });

    final count = await _bleService.syncData();

    if (mounted) {
      setState(() => _isSyncing = false);
      await _ttsService.speakSyncComplete(count);
    }
  }

  // ── Disconnect ───────────────────────────────────────────
  Future<void> _disconnect() async {
    await _bleService.disconnect();
    if (mounted) setState(() {});
  }

  // ── Clear device data ────────────────────────────────────
  Future<void> _clearDeviceData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Clear device storage?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will delete all readings stored on the AF Monitor device. '
          'Readings already synced to this app will not be affected.',
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
      await _bleService.clearDeviceData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device storage cleared')),
        );
      }
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status card
            _buildConnectionCard(),
            const SizedBox(height: 20),

            // Scan results
            if (!_bleService.isConnected) ...[
              _buildScanSection(),
              const SizedBox(height: 20),
            ],

            // Device actions
            if (_bleService.isConnected) ...[
              _buildDeviceActions(),
              const SizedBox(height: 20),
            ],

            // Status banner
            if (_status.isNotEmpty) _buildStatusBanner(),
          ],
        ),
      ),
    );
  }

  // ── Connection card ──────────────────────────────────────
  Widget _buildConnectionCard() {
    final isConnected = _bleService.isConnected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConnected
              ? [
                  AppTheme.success.withOpacity(0.15),
                  AppTheme.success.withOpacity(0.05),
                ]
              : [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.primary.withOpacity(0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isConnected
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_rounded,
              color: isConnected ? AppTheme.success : AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'AF Monitor' : 'No Device Connected',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Connected' : 'Scan to find your device',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isConnected
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            TextButton(
              onPressed: _disconnect,
              child: Text(
                'Disconnect',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Scan section ─────────────────────────────────────────
  Widget _buildScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Find Device'),
        const SizedBox(height: 16),

        // Scan button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.search_rounded, size: 20),
            label: Text(_isScanning ? 'Scanning...' : 'Scan for AF Monitor'),
          ),
        ),

        // Scan results
        if (_scanResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._scanResults.map(
            (result) => _buildDeviceTile(result),
          ),
        ],

        if (!_isScanning && _scanResults.isEmpty) ...[
          const SizedBox(height: 20),
          const EmptyState(
            icon: Icons.bluetooth_searching_rounded,
            title: 'No devices found',
            subtitle:
                'Make sure your AF Monitor is powered on and within range, then scan again.',
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(ScanResult result) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown Device';
    final rssi = result.rssi;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bluetooth_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Signal: $rssi dBm',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isConnecting
                ? null
                : () => _connectToDevice(result.device),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // ── Device actions ───────────────────────────────────────
  Widget _buildDeviceActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Device Actions'),
        const SizedBox(height: 16),

        // Sync button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync Measurements',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Download all stored readings from your AF Monitor.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_isSyncing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_syncProgress readings received...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _syncData,
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  label: Text(
                    _isSyncing ? 'Syncing...' : 'Sync Now',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Clear device storage
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear Device Storage',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Delete all readings stored on the AF Monitor device. '
                'This does not affect readings already synced to this app.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearDeviceData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Clear Device Storage'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Status banner ────────────────────────────────────────
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
              _status,
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
}