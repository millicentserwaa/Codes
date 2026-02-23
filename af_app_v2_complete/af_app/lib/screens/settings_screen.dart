import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'connect_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final auth = context.watch<AuthService>();
    final ble = context.watch<BleService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Account ────────────────────────────────────────
          const _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.person_rounded,
            iconColor: AppTheme.primary,
            title: auth.currentUser?.name ?? 'Profile',
            subtitle: auth.currentUser?.email ?? 'Not signed in',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppTheme.danger,
            title: 'Sign Out',
            subtitle: 'You will be returned to the login screen',
            onTap: () => _confirmSignOut(context, auth),
          ),

          const SizedBox(height: 8),

          // ── Device ─────────────────────────────────────────
          const _SectionHeader('Device'),
          _SettingsTile(
            icon: Icons.bluetooth_rounded,
            iconColor:
                ble.isConnected ? AppTheme.secondary : AppTheme.textSecondary,
            title: 'AF-Screen Device',
            subtitle: ble.isConnected
                ? 'Connected — ${ble.device?.platformName ?? "AF-SCREEN"}'
                : 'Not connected',
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ble.isConnected
                    ? AppTheme.secondary
                    : AppTheme.textSecondary,
              ),
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectScreen())),
          ),

          const SizedBox(height: 8),

          // ── Appearance ─────────────────────────────────────
          const _SectionHeader('Appearance'),
          // Dark mode toggle
          _SettingsTile(
            icon: settings.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            iconColor: AppTheme.warning,
            title: 'Dark Mode',
            subtitle: settings.isDark ? 'On' : 'Off',
            trailing: Switch(
              value: settings.isDark,
              activeThumbColor: AppTheme.primary,
              onChanged: (v) =>
                  settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const Divider(height: 1, indent: 56),
          // Font size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.text_fields_rounded,
                        color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Text Size',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 15)),
                      Text(_fontLabel(settings.fontScale),
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('A',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: settings.fontScale,
                      min: 0.85,
                      max: 1.4,
                      divisions: 3,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => settings.setFontScale(v),
                    ),
                  ),
                  const Text('A',
                      style: TextStyle(
                          fontSize: 20, color: AppTheme.textSecondary)),
                ]),
                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'Sample text — your readings will appear at this size.',
                    style: TextStyle(
                        fontSize: 14 * settings.fontScale,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Data ───────────────────────────────────────────
          const _SectionHeader('Data'),
          // allow developer to quickly populate measurements/profile
          _SettingsTile(
            icon: Icons.download_rounded,
            iconColor: AppTheme.secondary,
            title: 'Load Demo Data',
            subtitle: 'Add sample measurements and profile',
            onTap: () async {
              await StorageService.seedDemoData();
              await StorageService.seedDemoProfile();
              // always fire notifier in case box was non-empty but UI stale
              StorageService.onDataChanged.value++;
              if (!context.mounted) return;
              final count = StorageService.measurementCount;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Demo data seeded. $count readings available.')),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            iconColor: AppTheme.danger,
            title: 'Clear All Measurement Data',
            subtitle: '${StorageService.measurementCount} readings stored',
            onTap: () => _confirmClearData(context),
          ),

          const SizedBox(height: 8),

          // ── About ──────────────────────────────────────────
          const _SectionHeader('About'),
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.textSecondary,
            title: 'AF Screen',
            subtitle: 'Version 1.0.0 · Capstone 2024/25 · Ashesi University',
          ),
          _SettingsTile(
            icon: Icons.verified_outlined,
            iconColor: AppTheme.textSecondary,
            title: 'Clinical References',
            subtitle: 'WHO, ESC, JNC 8, ADA, Ghana STG',
            onTap: () => _showReferences(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _fontLabel(double scale) {
    if (scale <= 0.85) return 'Small';
    if (scale <= 1.0) return 'Default';
    if (scale <= 1.2) return 'Large';
    return 'Extra Large';
  }

  void _confirmSignOut(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: Text(
          'This will permanently delete all ${StorageService.measurementCount} '
          'stored readings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await StorageService.clearAllMeasurements();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All measurement data cleared.')),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showReferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Clinical References',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...[
              'Hindricks et al. 2021 ESC Guidelines for the diagnosis and management of atrial fibrillation. Eur Heart J. 2021;42(5):373–498.',
              'James PA et al. 2014 Evidence-Based Guideline for the Management of High Blood Pressure in Adults (JNC 8). JAMA. 2014;311(5):507–520.',
              'American Diabetes Association. Standards of Medical Care in Diabetes — 2023. Diabetes Care. 2023;46(Suppl 1).',
              'WHO. Cardiovascular Diseases Fact Sheet. Geneva: World Health Organization; 2021.',
              'WHO. Global Action Plan for the Prevention and Control of NCDs 2013–2020. Geneva: WHO; 2020.',
              'Ghana Health Service. Standard Treatment Guidelines, 7th Edition. Accra: GHS; 2017.',
              'Lip GYH et al. Refining clinical risk stratification for predicting stroke and thromboembolism in atrial fibrillation using a novel risk factor-based approach: the euro heart survey on atrial fibrillation. Chest. 2010;137(2):263–272.',
              'Voskoboinik A et al. Alcohol and Atrial Fibrillation: A Sobering Review. J Am Coll Cardiol. 2016;68(23):2567–2576.',
              'Larsson SC et al. Alcohol consumption and risk of atrial fibrillation: a prospective study and dose-response meta-analysis. J Am Coll Cardiol. 2016;67(5):516–523.',
              'WHO. Physical Activity Fact Sheet. Geneva: WHO; 2020.',
            ].map((ref) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Text(ref,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12, height: 1.5)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              )),
    );
  }
}

// ── Settings tile ──────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary, size: 20)
              : null),
    );
  }
}
