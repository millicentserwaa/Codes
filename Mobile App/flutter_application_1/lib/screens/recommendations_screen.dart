import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../logic/recommendation_engine.dart';
import '../models/user_profile.dart';
import '../models/session_record.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final repo = SessionRepository();
  bool loading = true;

  UserProfile? profile;
  List<SessionRecord> sessions = [];
  Recommendation? rec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await repo.getProfile();
    final s = await repo.getAllSessions(newestFirst: true);

    Recommendation? r;
    if (p != null) {
      r = RecommendationEngine.generate(profile: p, sessionsNewestFirst: s);
    }

    setState(() {
      profile = p;
      sessions = s;
      rec = r;
      loading = false;
    });
  }

  String _levelLabel(ConcernLevel level) {
    switch (level) {
      case ConcernLevel.low:
        return 'LOW';
      case ConcernLevel.moderate:
        return 'MODERATE';
      case ConcernLevel.high:
        return 'HIGH';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found.')),
      );
    }

    final r = rec!;
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
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
                    Text(
                      _levelLabel(r.level),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(r.title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Based on last ${sessions.take(10).length} sessions'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Why', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...r.reasons.map((x) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.info_outline),
                  title: Text(x),
                )),

            const SizedBox(height: 8),
            const Text('What to do next',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...r.actions.map((x) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(x),
                )),
          ],
        ),
      ),
    );
  }
}
