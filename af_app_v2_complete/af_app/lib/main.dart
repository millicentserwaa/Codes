import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'services/auth_service.dart';
import 'services/ble_service.dart';
import 'services/storage_service.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/health_tips_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';

const bool kAutoSeedDemoData = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();

  if (kAutoSeedDemoData) {
    await StorageService.seedDemoData();
    await StorageService.seedDemoProfile();
  }

  await AuthService.initBoxes();
  await AppSettings.initBox();
  await ReminderService.init();

  final auth     = AuthService();
  final settings = AppSettings();

  await auth.restoreSession();
  await settings.load();

  // Re-schedule reminder on app start if it was enabled
  if (settings.reminderEnabled) {
    await ReminderService.scheduleDailyReminder(settings.reminderTime);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => BleService()),
      ],
      child: const AfScreenApp(),
    ),
  );
}

class AfScreenApp extends StatelessWidget {
  const AfScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final auth     = context.watch<AuthService>();

    return MaterialApp(
      title: 'AF Screen',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme:     AppTheme.lightTheme(fontScale: settings.fontScale),
      darkTheme: AppTheme.darkTheme(fontScale: settings.fontScale),
      home: kAuthDisabledForDebug
          ? const MainShell()
          : (auth.isSignedIn ? const MainShell() : const LoginScreen()),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    HistoryScreen(),
    HealthTipsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon:       Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart_rounded),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.health_and_safety_outlined),
              activeIcon: Icon(Icons.health_and_safety_rounded),
              label: 'Health Tips',
            ),
            BottomNavigationBarItem(
              icon:       Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}