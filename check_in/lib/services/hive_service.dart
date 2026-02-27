import 'package:hive_flutter/hive_flutter.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';

class HiveService {
  static const String measurementBoxName = 'measurements';
  static const String userProfileBoxName = 'user_profile';

  // Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MeasurementAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    await Hive.openBox<Measurement>(measurementBoxName);
    await Hive.openBox<UserProfile>(userProfileBoxName);
  }

  // Measurement Methods 

  Box<Measurement> get measurementBox =>
      Hive.box<Measurement>(measurementBoxName);

  // Save a single measurement
  Future<void> saveMeasurement(Measurement measurement) async {
    await measurementBox.put(measurement.id, measurement);
  }

  // Get all measurements sorted by newest first
  List<Measurement> getAllMeasurements() {
    final measurements = measurementBox.values.toList();
    measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return measurements;
  }

  // Get most recent measurement
  Measurement? getLatestMeasurement() {
    final measurements = getAllMeasurements();
    return measurements.isEmpty ? null : measurements.first;
  }

  // Delete a measurement
  Future<void> deleteMeasurement(String id) async {
    await measurementBox.delete(id);
  }

  // Clear all measurements
  Future<void> clearAllMeasurements() async {
    await measurementBox.clear();
  }

  // ── UserProfile Methods ──────────────────────────────────

  Box<UserProfile> get userProfileBox =>
      Hive.box<UserProfile>(userProfileBoxName);

  // Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put('profile', profile);
  }

  // Get user profile
  UserProfile? getUserProfile() {
    return userProfileBox.get('profile');
  }

  // Check if profile exists
  bool get hasProfile => userProfileBox.containsKey('profile');
}