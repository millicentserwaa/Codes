import 'package:check_in/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_settings.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive
  await HiveService.init();

  // Initialize notifications
  await NotificationService().init();


  runApp(const CheckInApp());
}

class CheckInApp extends StatefulWidget {
  const CheckInApp({super.key});

  // Allow child widgets to trigger a rebuild
  static _CheckInAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_CheckInAppState>();

  @override
  State<CheckInApp> createState() => _CheckInAppState();
}

class _CheckInAppState extends State<CheckInApp> {
  final HiveService _hiveService = HiveService();
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _hiveService.getSettings();
  }

  // Call this from settings screen to rebuild app
  void updateSettings(AppSettings settings) {
    setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // Apply font scale from settings
      data: MediaQueryData.fromView(
        View.of(context),
      ).copyWith(textScaler: TextScaler.linear(_settings.fontScale)),
      child: MaterialApp(
        title: 'CheckIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _settings.isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}