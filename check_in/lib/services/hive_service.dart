import 'package:hive_flutter/hive_flutter.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../models/app_settings.dart';
import 'encryption_service.dart';

class HiveService {
  static const String measurementBoxName = 'measurements';
  static const String userProfileBoxName = 'user_profile';
  static const String appSettingsBoxName = 'app_settings';

  // Initialize Hive and open boxes with encryption
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MeasurementAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    // Get or generate AES-256 key from Android Keystore / iOS Keychain
    final encryptionKey = await EncryptionService.getEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    // Open all boxes with encryption — same box names, now encrypted
    await Hive.openBox<Measurement>(
      measurementBoxName,
      encryptionCipher: cipher,
    );
    await Hive.openBox<UserProfile>(
      userProfileBoxName,
      encryptionCipher: cipher,
    );
    await Hive.openBox<AppSettings>(
      appSettingsBoxName,
      encryptionCipher: cipher,
    );
  }

  // ── Measurement Box ──────────────────────────────────────
  Box<Measurement> get measurementBox =>
      Hive.box<Measurement>(measurementBoxName);

  Future<void> saveMeasurement(Measurement measurement, {String? key}) async {
    final k = key ?? measurement.timestamp.millisecondsSinceEpoch.toString();
    await measurementBox.put(k, measurement);
  }

  List<Measurement> getAllMeasurements() {
    final measurements = measurementBox.values.toList();
    measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return measurements;
  }

  Measurement? getLatestMeasurement() {
    final measurements = getAllMeasurements();
    return measurements.isEmpty ? null : measurements.first;
  }

  Future<void> deleteMeasurement(String id) async {
    await measurementBox.delete(id);
  }

  Future<void> clearAllMeasurements() async {
    await measurementBox.clear();
  }

  // ── UserProfile Box ──────────────────────────────────────
  Box<UserProfile> get userProfileBox =>
      Hive.box<UserProfile>(userProfileBoxName);

  Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put('profile', profile);
  }

  UserProfile? getUserProfile() {
    return userProfileBox.get('profile');
  }

  bool get hasProfile => userProfileBox.containsKey('profile');

  // ── AppSettings Box ──────────────────────────────────────
  Box<AppSettings> get appSettingsBox =>
      Hive.box<AppSettings>(appSettingsBoxName);

  AppSettings getSettings() {
    return appSettingsBox.get('settings') ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await appSettingsBox.put('settings', settings);
  }
}
