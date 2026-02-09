import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/session_repository.dart';
import '../models/session_record.dart';
import '../models/user_profile.dart';
import 'profile_setup_screen.dart';
import 'history_screen.dart';
import 'trends_screen.dart';
import 'dart:math';
import 'recommendations_screen.dart';




class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repo = SessionRepository();
  UserProfile? profile;
  List<SessionRecord> sessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await repo.getProfile();
    final s = await repo.getAllSessions(newestFirst: true);
    setState(() {
      profile = p;
      sessions = s;
      loading = false;
    });
  }

  String _ageLabel(AgeGroup g) {
    switch (g) {
      case AgeGroup.under40:
        return '< 40';
      case AgeGroup.from40to59:
        return '40–59';
      case AgeGroup.above60:
        return '60+';
    }
  }

  String _resultLabel(AfResult r) {
    switch (r) {
      case AfResult.ok:
        return 'OK';
      case AfResult.notOk:
        return 'NOT OK';
      case AfResult.inconclusive:
        return 'INCONCLUSIVE';
    }
  }

  Future<void> _addMockSession() async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  final rng = Random();

  final nextResult = (sessions.isEmpty)
      ? AfResult.ok
      : (sessions.first.afResult == AfResult.ok)
          ? AfResult.notOk
          : (sessions.first.afResult == AfResult.notOk)
              ? AfResult.inconclusive
              : AfResult.ok;

  // Random-ish realistic values
  final hr = 60 + rng.nextInt(50); // 60–109 bpm
  final conf = 55 + rng.nextInt(41); // 55–95
  final quality = 50 + rng.nextInt(46); // 50–95
  final spo2 = 92 + rng.nextInt(7); // 92–98
  final spo2Conf = 50 + rng.nextInt(51); // 50–100

  final record = SessionRecord(
    sessionId: id,
    timestamp: now,
    afResult: nextResult,
    confidence: conf,
    signalQuality: quality,
    heartRateBpm: hr.toDouble(),
    acceptedWindows: 3 + rng.nextInt(3), // 3–5
    totalWindows: 5,
    flags: const [],
    spo2: spo2.toDouble(),
    spo2Confidence: spo2Conf,
    ecgRmssdMs: (20 + rng.nextInt(60)).toDouble(),
    ppgRmssdMs: (15 + rng.nextInt(55)).toDouble(),
    durationSec: 30,
    deviceId: 'ESP32',
    firmwareVersion: '0.1',
  );

  await repo.addSession(record);
  await _load();
}

  Future<void> _resetSessions() async {
    await repo.deleteAllSessions();
    await _load();
  }

  Future<void> _resetProfile() async {
    // simplest reset: clear sessions and go back to setup
    await repo.deleteAllSessions();
    // You can also clear profile box if you add a deleteProfile method.
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = profile;
    final latest = sessions.isNotEmpty ? sessions.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (p != null) ...[
                      Text('Age group: ${_ageLabel(p.ageGroup)}'),
                      Text('Hypertension: ${p.hasHypertension ? "Yes" : "No"}'),
                      Text('Diabetes: ${p.hasDiabetes ? "Yes" : "No"}'),
                      if (p.notes != null) Text('Notes: ${p.notes}'),
                    ] else
                      const Text('No profile found.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latest screening', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (latest == null)
                      const Text('No sessions recorded yet.')
                    else ...[
                      Text('Result: ${_resultLabel(latest.afResult)}'),
                      Text('Confidence: ${latest.confidence}/100'),
                      Text('HR: ${latest.heartRateBpm.toStringAsFixed(0)} bpm'),
                      if (latest.spo2 != null) Text('SpO₂: ${latest.spo2!.toStringAsFixed(0)}%'),
                      Text('Time: ${latest.timestamp}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _addMockSession,
              child: const Text('Add mock session (for testing)'),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: _resetSessions,
              child: const Text('Clear session history'),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: const Text('View history'),
            ),

            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendsScreen()),
                );
              },
              child: const Text('View trends'),
            ),


            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                context,
                  MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
                );
              },
              child: const Text('View recommendations'),
            ),





          ],
        ),
      ),
    );
  }
}
