import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';

class StorageService {
  static const _profileBox = 'profile';
  static const _measureBox = 'measurements';

  /// Notifier fired whenever stored data is modified.
  ///
  /// Widgets can listen to this to refresh UI without manually calling
  /// storage methods. The value itself is meaningless; it is incremented each
  /// time a change occurs.
  static final ValueNotifier<int> onDataChanged = ValueNotifier<int>(0);

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
  static Box<PatientProfile> get _pBox => Hive.box<PatientProfile>(_profileBox);

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

  static Future<void> saveMeasurement(Measurement m) async {
    await _mBox.add(m);
    onDataChanged.value++;
  }

  static Future<void> deleteMeasurement(int key) async {
    await _mBox.delete(key);
    onDataChanged.value++;
  }

  static Future<void> clearAllMeasurements() async {
    await _mBox.clear();
    onDataChanged.value++;
  }

  static int get measurementCount => _mBox.length;

  // ── Seed demo data ────────────────────────────────────────
  static Future<void> seedDemoData() async {
    if (_mBox.isNotEmpty) return;

    final now = DateTime.now();
    final rand = Random();

    // produce roughly a month of readings with varied metrics
    for (int day = 30; day >= 0; day--) {
      final ts = now.subtract(Duration(days: day));
      final hr = 60 + rand.nextInt(30); // 60–90 bpm
      final isAf = rand.nextDouble() < 0.2; // 20% chance
      final cv = isAf
          ? 0.18 + rand.nextDouble() * 0.12
          : 0.05 + rand.nextDouble() * 0.1;
      final rmssd =
          isAf ? 70 + rand.nextDouble() * 60 : 15 + rand.nextDouble() * 25;
      final pnn50 = (rmssd * 0.5); // double
      final meanRR = (60000 / hr); // double
      final strokeScore = rand.nextInt(6);
      final strokeRiskIndex = strokeScore >= 4 ? 2 : (strokeScore >= 2 ? 1 : 0);
      final afScore = isAf ? 3 + rand.nextInt(4) : 0;

      await _mBox.add(Measurement(
        timestamp: ts,
        cv: cv,
        rmssd: rmssd,
        pnn50: pnn50,
        meanRR: meanRR,
        heartRate: hr.toDouble(),
        afResultIndex: isAf ? 1 : 0,
        afScore: afScore,
        strokeScore: strokeScore,
        strokeRiskIndex: strokeRiskIndex,
      ));
    }
  }

  // ── Seed demo patient profile (for personalised screens) ───
  static Future<void> seedDemoProfile() async {
    if (_pBox.containsKey('current')) return;
    final demo = PatientProfile(
      name: 'Jane Doe',
      age: 58,
      sex: 'Female',
      hasHypertension: true,
      hasDiabetes: false,
      hasPriorStrokeTIA: false,
      systolicBP: 150,
      diastolicBP: 92,
    );
    await saveProfile(demo);
    onDataChanged.value++;
  }
}
