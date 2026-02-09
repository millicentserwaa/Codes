import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import 'profile_setup_screen.dart';
import 'dashboard_screen.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  final repo = SessionRepository();
  bool loading = true;
  bool hasProfile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await repo.getProfile();
    setState(() {
      hasProfile = profile != null;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return hasProfile ? const DashboardScreen() : const ProfileSetupScreen();
  }
}
