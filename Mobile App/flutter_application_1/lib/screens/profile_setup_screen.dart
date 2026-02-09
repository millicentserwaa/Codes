import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../models/user_profile.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final repo = SessionRepository();

  AgeGroup _ageGroup = AgeGroup.under40;
  bool _htn = false;
  bool _dm = false;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

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

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();

    final profile = UserProfile(
      profileId: 'local',
      ageGroup: _ageGroup,
      hasHypertension: _htn,
      hasDiabetes: _dm,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await repo.upsertProfile(profile);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'This profile helps interpret screening trends. '
              'It does not provide diagnosis.',
            ),
            const SizedBox(height: 16),

            const Text('Age group'),
            DropdownButton<AgeGroup>(
              value: _ageGroup,
              isExpanded: true,
              items: AgeGroup.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(_ageLabel(g)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _ageGroup = v!),
            ),

            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hypertension'),
              value: _htn,
              onChanged: (v) => setState(() => _htn = v),
            ),
            SwitchListTile(
              title: const Text('Diabetes'),
              value: _dm,
              onChanged: (v) => setState(() => _dm = v),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
