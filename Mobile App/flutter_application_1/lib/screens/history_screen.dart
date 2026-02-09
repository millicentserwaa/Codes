import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../models/session_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final repo = SessionRepository();
  bool loading = true;
  List<SessionRecord> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await repo.getAllSessions(newestFirst: true);
    setState(() {
      sessions = s;
      loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = sessions[i];
                return Card(
                  child: ListTile(
                    title: Text(_resultLabel(s.afResult)),
                    subtitle: Text(
                      'HR: ${s.heartRateBpm.toStringAsFixed(0)} bpm'
                      '${s.spo2 != null ? ' • SpO₂: ${s.spo2!.toStringAsFixed(0)}%' : ''}'
                      '\n${s.timestamp}',
                    ),
                    trailing: Text('${s.confidence}/100'),
                  ),
                );
              },
            ),
    );
  }
}
