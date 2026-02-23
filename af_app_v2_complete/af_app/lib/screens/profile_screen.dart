import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/patient_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _sbpCtrl;
  late TextEditingController _dbpCtrl;

  String _sex = 'Male';
  bool _hypertension = false;
  bool _diabetes = false;
  bool _priorStroke = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl  = TextEditingController();
    _sbpCtrl  = TextEditingController();
    _dbpCtrl  = TextEditingController();
    _loadProfile();
  }

  void _loadProfile() {
    final p = StorageService.getProfile();
    if (p == null) return;
    _nameCtrl.text = p.name;
    _ageCtrl.text  = p.age.toString();
    _sbpCtrl.text  = p.systolicBP?.toString() ?? '';
    _dbpCtrl.text  = p.diastolicBP?.toString() ?? '';
    _sex           = p.sex;
    _hypertension  = p.hasHypertension;
    _diabetes      = p.hasDiabetes;
    _priorStroke   = p.hasPriorStrokeTIA;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = PatientProfile(
      name: _nameCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      sex: _sex,
      hasHypertension: _hypertension,
      hasDiabetes: _diabetes,
      hasPriorStrokeTIA: _priorStroke,
      systolicBP:  _sbpCtrl.text.isEmpty ? null : int.tryParse(_sbpCtrl.text),
      diastolicBP: _dbpCtrl.text.isEmpty ? null : int.tryParse(_dbpCtrl.text),
    );

    await StorageService.saveProfile(profile);
    setState(() => _saved = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved ✓'),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _sbpCtrl.dispose();
    _dbpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Info banner ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your profile is used to calculate personalised stroke risk. All data is stored only on this device.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Personal Details ─────────────────────────────
            const _SectionLabel('Personal Details'),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Age (years)',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 120) return 'Invalid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: ['Male', 'Female', 'Other']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _sex = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Blood Pressure ───────────────────────────────
            const _SectionLabel('Blood Pressure (most recent reading)'),
            const SizedBox(height: 6),
            Text(
              'Leave blank if unknown — you can update this anytime',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sbpCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Systolic (mmHg)',
                      hintText: 'e.g. 120',
                      prefixIcon: Icon(Icons.arrow_upward_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 60 || n > 250) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _dbpCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic (mmHg)',
                      hintText: 'e.g. 80',
                      prefixIcon: Icon(Icons.arrow_downward_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 40 || n > 150) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Medical History ──────────────────────────────
            const _SectionLabel('Medical History'),
            const SizedBox(height: 6),
            Text(
              'These factors contribute to your stroke risk calculation',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 14),

            _MedicalToggle(
              label: 'Hypertension (High Blood Pressure)',
              sublabel: 'Diagnosed by a doctor or currently on BP medication',
              icon: Icons.monitor_heart_outlined,
              value: _hypertension,
              onChanged: (v) => setState(() => _hypertension = v),
            ),
            const SizedBox(height: 10),
            _MedicalToggle(
              label: 'Diabetes',
              sublabel: 'Type 1 or Type 2 diabetes',
              icon: Icons.bloodtype_outlined,
              value: _diabetes,
              onChanged: (v) => setState(() => _diabetes = v),
            ),
            const SizedBox(height: 10),
            _MedicalToggle(
              label: 'Prior Stroke or TIA',
              sublabel: 'Previous stroke or transient ischaemic attack',
              icon: Icons.psychology_outlined,
              value: _priorStroke,
              onChanged: (v) => setState(() => _priorStroke = v),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Profile'),
              ),
            ),

            const SizedBox(height: 20),

            // ── CHA2DS2-VASc info ────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ℹ️  Stroke risk is calculated using a modified CHA₂DS₂-VASc score, a clinically validated tool used worldwide for stroke risk assessment in patients with atrial fibrillation.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ));
  }
}

class _MedicalToggle extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MedicalToggle({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primary.withOpacity(0.05)
            : AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        secondary: Icon(icon,
            color: value ? AppTheme.primary : AppTheme.textSecondary),
        title: Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(sublabel,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
