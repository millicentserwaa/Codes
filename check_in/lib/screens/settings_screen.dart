import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import '../models/app_settings.dart';
import '../models/measurement.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/tts_service.dart';
import '../services/ble_service.dart';
import '../services/risk_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../main.dart';
import '../widgets/tts_button.dart';

class SettingsScreen extends StatefulWidget {
  // ← CHANGED: accept shared BleService instead of creating a new one
  final BleService bleService;

  const SettingsScreen({super.key, required this.bleService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  final TtsService _ttsService = TtsService();

  // ← CHANGED: use widget.bleService instead of a local instance
  // _bleService is now just a convenience getter
  BleService get _bleService => widget.bleService;

  String? _nameError;
  UserProfile? _profile;
  List<Measurement> _measurements = [];
  late AppSettings _settings;

  // Profile controllers
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Male';
  bool _hasHypertension = false;
  bool _hasDiabetes = false;
  bool _hasPriorStroke = false;
  bool _hasHeartFailure = false;
  bool _hasVascularDisease = false;
  bool _isSaving = false;

  // BLE state
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isSyncing = false;
  int _syncProgress = 0;
  String _bleStatus = '';

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadData();
    _listenToBleStreams();
  }

  void _loadData() {
    final profile = _hiveService.getUserProfile();
    final settings = _hiveService.getSettings();
    setState(() {
      _settings = settings;
      _measurements = _hiveService.getAllMeasurements();
      if (profile != null) {
        _profile = profile;
        _nameController.text = profile.name;
        _dateOfBirth = profile.dateOfBirth;
        _gender = profile.gender;
        _hasHypertension = profile.hasHypertension;
        _hasDiabetes = profile.hasDiabetes;
        _hasPriorStroke = profile.hasPriorStroke;
        _hasHeartFailure = profile.hasHeartFailure;
        _hasVascularDisease = profile.hasVascularDisease;
      }
    });
  }

  void _listenToBleStreams() {
    _bleService.statusStream.listen((status) {
      if (mounted) setState(() => _bleStatus = status);
    });
    _bleService.syncProgressStream.listen((progress) {
      if (mounted) setState(() => _syncProgress = progress);
    });
    _bleService.connectionStream.listen((connected) {
      if (mounted) setState(() {});
    });
  }

  // ── BLE Methods ───────────────────────────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s == PermissionStatus.granted);
  }

  Future<void> _startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth and location permissions required.'),
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
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _bleService.stopScan();
        setState(() => _isScanning = false);
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    _bleService.stopScan();
    final success = await _bleService.connectToDevice(device);
    if (mounted) {
      setState(() => _isConnecting = false);
      if (success) {
        await _ttsService.speakConnectionStatus(true); // ← ADD THIS
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
    });
    final count = await _bleService.syncData();
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _measurements = _hiveService.getAllMeasurements();
      });
      await _ttsService.speakSyncComplete(count); // ← ADD THIS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $count readings successfully')),
      );
    }
  }

  Future<void> _disconnect() async {
    await _bleService.disconnect();
    await _ttsService.speakConnectionStatus(false); // ← ADD THIS
    if (mounted) setState(() {});
  }

  Future<void> _clearDeviceData() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear device storage?',
      message:
          'This will delete all readings stored on the AF Monitor device. '
          'Readings already synced to this app will not be affected.',
      confirmLabel: 'Clear',
    );
    if (confirmed == true) {
      await _bleService.clearDeviceData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Device storage cleared')));
      }
    }
  }

  // ── Profile Methods ───────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    final nameError = Validators.validateName(_nameController.text);
    if (nameError != null) {
      setState(() => _nameError = nameError);
      return;
    }
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final profile = UserProfile(
      name: _nameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gender: _gender,
      hasHypertension: _hasHypertension,
      hasDiabetes: _hasDiabetes,
      hasPriorStroke: _hasPriorStroke,
      hasHeartFailure: _hasHeartFailure,
      hasVascularDisease: _hasVascularDisease,
    );
    await _hiveService.saveUserProfile(profile);
    setState(() {
      _profile = profile;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    await _hiveService.saveSettings(newSettings);
    setState(() => _settings = newSettings);
    if (mounted) {
      CheckInApp.of(context)?.updateSettings(newSettings);
    }
    if (newSettings.reminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        hour: newSettings.reminderHour,
        minute: newSettings.reminderMinute,
      );
    } else {
      await _notificationService.cancelReminder();
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1970),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      ),
    );
    if (picked != null) {
      await _updateSettings(
        _settings.copyWith(
          reminderHour: picked.hour,
          reminderMinute: picked.minute,
        ),
      );
    }
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear all data?',
      message:
          'This will permanently delete all your measurements. '
          'Your profile will not be affected.',
      confirmLabel: 'Clear',
    );
    if (confirmed == true) {
      await _hiveService.clearAllMeasurements();
      setState(() => _measurements = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All measurements cleared')),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          message,
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
              confirmLabel,
              style: GoogleFonts.inter(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ttsService.dispose();
    // ← REMOVED: _bleService.dispose() — we don't own it, HomeScreen does
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('AF Monitor Device'),
            const SizedBox(height: 16),
            _buildDeviceSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Profile'),
            const SizedBox(height: 16),
            _buildProfileSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Medical History'),
            const SizedBox(height: 4),
            Text(
              'Used for CHA\u2082DS\u2082-VASc stroke risk calculation.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMedicalSection(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionTitle('Recommendations'),
            const SizedBox(height: 16),
            _buildRecommendationsSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Export'),
            const SizedBox(height: 16),
            _buildExportSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Appearance'),
            const SizedBox(height: 16),
            _buildAppearanceSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Reminder'),
            const SizedBox(height: 16),
            _buildReminderSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('Data'),
            const SizedBox(height: 16),
            _buildDataSection(),
            const SizedBox(height: 28),

            _buildSectionTitle('About'),
            const SizedBox(height: 16),
            _buildAboutSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDeviceSection() {
    final isConnected = _bleService.isConnected;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isConnected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.bluetooth_rounded,
                    color: isConnected ? AppTheme.success : AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected
                            ? 'AF Monitor Connected'
                            : 'No Device Connected',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isConnected
                            ? 'Tap Sync to download readings'
                            : 'Tap Scan to find your device',
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
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_bleStatus.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bleStatus,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          if (!isConnected) ...[
            ListTile(
              leading: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.search_rounded, color: AppTheme.primary),
              title: Text(
                _isScanning ? 'Scanning...' : 'Scan for AF Monitor',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              onTap: _isScanning ? null : _startScan,
            ),
            if (_scanResults.isNotEmpty) ...[
              const Divider(height: 1, indent: 16),
              ..._scanResults.map((result) {
                final name = result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device';
                return ListTile(
                  leading: const Icon(
                    Icons.bluetooth_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Signal: ${result.rssi} dBm',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _isConnecting
                        ? null
                        : () => _connectToDevice(result.device),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Connect'),
                  ),
                );
              }),
            ],
          ],

          if (isConnected) ...[
            ListTile(
              leading: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: AppTheme.primary),
              title: Text(
                _isSyncing
                    ? 'Syncing... $_syncProgress received'
                    : 'Sync Measurements',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Download all readings from your device',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              onTap: _isSyncing ? null : _syncData,
            ),
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
              ),
              title: Text(
                'Clear Device Storage',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.danger,
                ),
              ),
              subtitle: Text(
                'Deletes readings on device only, not in this app',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              onTap: _clearDeviceData,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    int _calculateAge(DateTime dob) {
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    }

    return Container(
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
            'Full Name',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
            onChanged: (_) {
              final error = Validators.validateName(_nameController.text);
              if (error == null && _nameError != null) {
                setState(() => _nameError = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Date of Birth',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}  •  Age ${_calculateAge(_dateOfBirth!)}'
                          : 'Select your date of birth',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _dateOfBirth != null
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gender',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female'].map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: Container(
                    margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildConditionTile(
            title: 'Hypertension',
            subtitle: 'High blood pressure',
            icon: Icons.speed_rounded,
            value: _hasHypertension,
            onChanged: (v) => setState(() => _hasHypertension = v),
            isFirst: true,
          ),
          _buildConditionTile(
            title: 'Diabetes',
            subtitle: 'Type 1 or Type 2',
            icon: Icons.water_drop_outlined,
            value: _hasDiabetes,
            onChanged: (v) => setState(() => _hasDiabetes = v),
          ),
          _buildConditionTile(
            title: 'Prior Stroke or TIA',
            subtitle: 'Previous stroke or mini-stroke',
            icon: Icons.warning_amber_rounded,
            value: _hasPriorStroke,
            onChanged: (v) => setState(() => _hasPriorStroke = v),
          ),
          _buildConditionTile(
            title: 'Heart Failure',
            subtitle: 'Congestive heart failure',
            icon: Icons.favorite_border_rounded,
            value: _hasHeartFailure,
            onChanged: (v) => setState(() => _hasHeartFailure = v),
          ),
          _buildConditionTile(
            title: 'Vascular Disease',
            subtitle: 'Prior heart attack or peripheral artery disease',
            icon: Icons.timeline_rounded,
            value: _hasVascularDisease,
            onChanged: (v) => setState(() => _hasVascularDisease = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          secondary: Icon(
            icon,
            color: value ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    if (_profile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Text(
          'Complete your profile above to see personalised recommendations.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      );
    }

    final recommendations = RiskService.getRecommendations(
      _profile!,
      _measurements,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Recommendations',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Based on your profile and measurements',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // ← ADDED: "Read all" button
              TtsButton(
                onSpeak: () =>
                    _ttsService.speakRecommendations(recommendations),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...recommendations.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ← ADDED: per-item TTS button
                  TtsButton(
                    size: 18,
                    onSpeak: () => _ttsService.speakSingleRecommendation(
                      e.key + 1,
                      e.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
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
            'Export Health Report',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate a secure, password-protected PDF report of your '
            'measurements, stroke risk score and recommendations to share '
            'with your healthcare provider.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _profile == null || _measurements.isEmpty
                  ? null
                  : () async {
                      await PdfService.exportReport(
                        context: context,
                        profile: _profile!,
                        measurements: _measurements,
                      );
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: const Text('Generate Secure PDF Report'),
            ),
          ),
          if (_profile == null || _measurements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _profile == null
                    ? 'Complete your profile to enable export.'
                    : 'Sync measurements to enable export.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _settings.isDarkMode,
            onChanged: (v) =>
                _updateSettings(_settings.copyWith(isDarkMode: v)),
            activeColor: AppTheme.primary,
            title: Text(
              'Dark Mode',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'Switch to dark theme.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            secondary: const Icon(
              Icons.dark_mode_outlined,
              color: AppTheme.primary,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.text_fields_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Font Size',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _settings.fontScaleLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _settings.fontScale,
                  min: 1.0,
                  max: 1.4,
                  divisions: 2,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.divider,
                  onChanged: (value) =>
                      _updateSettings(_settings.copyWith(fontScale: value)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Normal', 'Large', 'Extra Large']
                      .map(
                        (l) => Text(
                          l,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    final formattedTime = TimeOfDay(
      hour: _settings.reminderHour,
      minute: _settings.reminderMinute,
    ).format(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _settings.reminderEnabled,
            onChanged: (v) =>
                _updateSettings(_settings.copyWith(reminderEnabled: v)),
            activeColor: AppTheme.primary,
            title: Text(
              'Daily Reminder',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'Get a daily reminder to take a reading.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.primary,
            ),
          ),
          if (_settings.reminderEnabled) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(
                Icons.access_time_rounded,
                color: AppTheme.primary,
              ),
              title: Text(
                'Reminder Time',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              trailing: Text(
                formattedTime,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              onTap: _selectReminderTime,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.danger,
        ),
        title: Text(
          'Clear All Measurements',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.danger,
          ),
        ),
        subtitle: Text(
          'Permanently delete all stored readings.',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary,
        ),
        onTap: _confirmClearAllData,
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _buildAboutTile('App Version', '1.0.0', isFirst: true),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildAboutTile('Device', 'AF Monitor v5.0'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildAboutTile(
            'Algorithm',
            'CHA\u2082DS\u2082-VASc (ESC Guidelines)',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildAboutTile(
            'Disclaimer',
            'For screening purposes only',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
