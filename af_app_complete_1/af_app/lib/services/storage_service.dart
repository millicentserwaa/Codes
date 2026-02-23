import 'package:hive_flutter/hive_flutter.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';

class StorageService {
  static const _profileBox = 'profile';
  static const _measureBox = 'measurements';

  // ── Init ──────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MeasurementAdapter());
    }

    await Hive.openBox<PatientProfile>(_profileBox);
    await Hive.openBox<Measurement>(_measureBox);
  }

  // ── Profile ───────────────────────────────────────────────
  static Box<PatientProfile> get _pBox =>
      Hive.box<PatientProfile>(_profileBox);

  static PatientProfile? getProfile() => _pBox.get('current');

  static Future<void> saveProfile(PatientProfile profile) async =>
      _pBox.put('current', profile);

  static bool get hasProfile => _pBox.containsKey('current');

  // ── Measurements ──────────────────────────────────────────
  static Box<Measurement> get _mBox => Hive.box<Measurement>(_measureBox);

  static List<Measurement> getAllMeasurements() {
    final list = _mBox.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  static Measurement? getLatestMeasurement() {
    if (_mBox.isEmpty) return null;
    return getAllMeasurements().first;
  }

  static Future<void> saveMeasurement(Measurement m) async =>
      _mBox.add(m);

  static Future<void> deleteMeasurement(int key) async =>
      _mBox.delete(key);

  static Future<void> clearAllMeasurements() async => _mBox.clear();

  static int get measurementCount => _mBox.length;

  // ── Seed demo data ────────────────────────────────────────
  static Future<void> seedDemoData() async {
    if (_mBox.isNotEmpty) return;

    final now = DateTime.now();
    final samples = [
      Measurement(
        timestamp: now.subtract(const Duration(days: 6)),
        cv: 0.07, rmssd: 30, pnn50: 10, meanRR: 860, heartRate: 70,
        afResultIndex: 0, afScore: 0, strokeScore: 1, strokeRiskIndex: 1,
      ),
      Measurement(
        timestamp: now.subtract(const Duration(days: 5)),
        cv: 0.08, rmssd: 35, pnn50: 13, meanRR: 840, heartRate: 71,
        afResultIndex: 0, afScore: 0, strokeScore: 1, strokeRiskIndex: 1,
      ),
      Measurement(
        timestamp: now.subtract(const Duration(days: 4)),
        cv: 0.21, rmssd: 98, pnn50: 61, meanRR: 780, heartRate: 77,
        afResultIndex: 1, afScore: 5, strokeScore: 4, strokeRiskIndex: 2,
      ),
      Measurement(
        timestamp: now.subtract(const Duration(days: 3)),
        cv: 0.19, rmssd: 88, pnn50: 55, meanRR: 800, heartRate: 75,
        afResultIndex: 1, afScore: 4, strokeScore: 4, strokeRiskIndex: 2,
      ),
      Measurement(
        timestamp: now.subtract(const Duration(days: 2)),
        cv: 0.09, rmssd: 38, pnn50: 15, meanRR: 850, heartRate: 71,
        afResultIndex: 0, afScore: 0, strokeScore: 1, strokeRiskIndex: 1,
      ),
      Measurement(
        timestamp: now.subtract(const Duration(days: 1)),
        cv: 0.06, rmssd: 28, pnn50: 9, meanRR: 870, heartRate: 69,
        afResultIndex: 0, afScore: 0, strokeScore: 1, strokeRiskIndex: 1,
      ),
      Measurement(
        timestamp: now,
        cv: 0.24, rmssd: 110, pnn50: 67, meanRR: 760, heartRate: 79,
        afResultIndex: 1, afScore: 5, strokeScore: 5, strokeRiskIndex: 2,
      ),
    ];

    for (final s in samples) {
      await _mBox.add(s);
    }
  }
}
