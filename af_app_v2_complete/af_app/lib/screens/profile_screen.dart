// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/services.dart';
// // // import '../models/patient_profile.dart';
// // // import '../services/storage_service.dart';
// // // import '../theme/app_theme.dart';

// // // class ProfileScreen extends StatefulWidget {
// // //   const ProfileScreen({super.key});

// // //   @override
// // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // }

// // // class _ProfileScreenState extends State<ProfileScreen> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   late TextEditingController _nameCtrl;
// // //   late TextEditingController _ageCtrl;
// // //   late TextEditingController _sbpCtrl;
// // //   late TextEditingController _dbpCtrl;

// // //   String _sex = 'Male';
// // //   bool _hypertension = false;
// // //   bool _diabetes = false;
// // //   bool _priorStroke = false;
// // //   bool _saved = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _nameCtrl = TextEditingController();
// // //     _ageCtrl  = TextEditingController();
// // //     _sbpCtrl  = TextEditingController();
// // //     _dbpCtrl  = TextEditingController();
// // //     _loadProfile();
// // //   }

// // //   void _loadProfile() {
// // //     final p = StorageService.getProfile();
// // //     if (p == null) return;
// // //     _nameCtrl.text = p.name;
// // //     _ageCtrl.text  = p.age.toString();
// // //     _sbpCtrl.text  = p.systolicBP?.toString() ?? '';
// // //     _dbpCtrl.text  = p.diastolicBP?.toString() ?? '';
// // //     _sex           = p.sex;
// // //     _hypertension  = p.hasHypertension;
// // //     _diabetes      = p.hasDiabetes;
// // //     _priorStroke   = p.hasPriorStrokeTIA;
// // //   }

// // //   Future<void> _save() async {
// // //     if (!_formKey.currentState!.validate()) return;

// // //     final profile = PatientProfile(
// // //       name: _nameCtrl.text.trim(),
// // //       age: int.parse(_ageCtrl.text.trim()),
// // //       sex: _sex,
// // //       hasHypertension: _hypertension,
// // //       hasDiabetes: _diabetes,
// // //       hasPriorStrokeTIA: _priorStroke,
// // //       systolicBP:  _sbpCtrl.text.isEmpty ? null : int.tryParse(_sbpCtrl.text),
// // //       diastolicBP: _dbpCtrl.text.isEmpty ? null : int.tryParse(_dbpCtrl.text),
// // //     );

// // //     await StorageService.saveProfile(profile);
// // //     setState(() => _saved = true);

// // //     if (!mounted) return;
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       const SnackBar(
// // //         content: Text('Profile saved ✓'),
// // //         backgroundColor: AppTheme.secondary,
// // //         behavior: SnackBarBehavior.floating,
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _nameCtrl.dispose();
// // //     _ageCtrl.dispose();
// // //     _sbpCtrl.dispose();
// // //     _dbpCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Patient Profile'),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: _save,
// // //             child: const Text('Save',
// // //                 style: TextStyle(
// // //                     color: AppTheme.primary, fontWeight: FontWeight.w700)),
// // //           ),
// // //         ],
// // //       ),
// // //       body: Form(
// // //         key: _formKey,
// // //         child: ListView(
// // //           padding: const EdgeInsets.all(20),
// // //           children: [
// // //             // ── Info banner ─────────────────────────────────
// // //             Container(
// // //               padding: const EdgeInsets.all(14),
// // //               decoration: BoxDecoration(
// // //                 color: AppTheme.primary.withOpacity(0.06),
// // //                 borderRadius: BorderRadius.circular(12),
// // //                 border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
// // //               ),
// // //               child: Row(
// // //                 children: [
// // //                   const Icon(Icons.info_outline_rounded,
// // //                       color: AppTheme.primary, size: 18),
// // //                   const SizedBox(width: 10),
// // //                   Expanded(
// // //                     child: Text(
// // //                       'Your profile is used to calculate personalised stroke risk. All data is stored only on this device.',
// // //                       style: Theme.of(context)
// // //                           .textTheme
// // //                           .bodyMedium
// // //                           ?.copyWith(fontSize: 12),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),

// // //             const SizedBox(height: 28),

// // //             // ── Personal Details ─────────────────────────────
// // //             const _SectionLabel('Personal Details'),
// // //             const SizedBox(height: 14),

// // //             TextFormField(
// // //               controller: _nameCtrl,
// // //               decoration: const InputDecoration(
// // //                 labelText: 'Full Name',
// // //                 prefixIcon: Icon(Icons.person_outline_rounded),
// // //               ),
// // //               textCapitalization: TextCapitalization.words,
// // //               validator: (v) =>
// // //                   v == null || v.trim().isEmpty ? 'Name is required' : null,
// // //             ),
// // //             const SizedBox(height: 14),

// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: TextFormField(
// // //                     controller: _ageCtrl,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Age (years)',
// // //                       prefixIcon: Icon(Icons.cake_outlined),
// // //                     ),
// // //                     keyboardType: TextInputType.number,
// // //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// // //                     validator: (v) {
// // //                       if (v == null || v.isEmpty) return 'Required';
// // //                       final n = int.tryParse(v);
// // //                       if (n == null || n < 1 || n > 120) return 'Invalid age';
// // //                       return null;
// // //                     },
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 14),
// // //                 Expanded(
// // //                   child: DropdownButtonFormField<String>(
// // //                     initialValue: _sex,
// // //                     decoration: const InputDecoration(labelText: 'Sex'),
// // //                     items: ['Male', 'Female', 'Other']
// // //                         .map((s) => DropdownMenuItem(value: s, child: Text(s)))
// // //                         .toList(),
// // //                     onChanged: (v) => setState(() => _sex = v!),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 28),

// // //             // ── Blood Pressure ───────────────────────────────
// // //             const _SectionLabel('Blood Pressure (most recent reading)'),
// // //             const SizedBox(height: 6),
// // //             Text(
// // //               'Leave blank if unknown — you can update this anytime',
// // //               style: Theme.of(context)
// // //                   .textTheme
// // //                   .bodyMedium
// // //                   ?.copyWith(fontSize: 11),
// // //             ),
// // //             const SizedBox(height: 14),

// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: TextFormField(
// // //                     controller: _sbpCtrl,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Systolic (mmHg)',
// // //                       hintText: 'e.g. 120',
// // //                       prefixIcon: Icon(Icons.arrow_upward_rounded),
// // //                     ),
// // //                     keyboardType: TextInputType.number,
// // //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// // //                     validator: (v) {
// // //                       if (v == null || v.isEmpty) return null;
// // //                       final n = int.tryParse(v);
// // //                       if (n == null || n < 60 || n > 250) return 'Invalid';
// // //                       return null;
// // //                     },
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 14),
// // //                 Expanded(
// // //                   child: TextFormField(
// // //                     controller: _dbpCtrl,
// // //                     decoration: const InputDecoration(
// // //                       labelText: 'Diastolic (mmHg)',
// // //                       hintText: 'e.g. 80',
// // //                       prefixIcon: Icon(Icons.arrow_downward_rounded),
// // //                     ),
// // //                     keyboardType: TextInputType.number,
// // //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// // //                     validator: (v) {
// // //                       if (v == null || v.isEmpty) return null;
// // //                       final n = int.tryParse(v);
// // //                       if (n == null || n < 40 || n > 150) return 'Invalid';
// // //                       return null;
// // //                     },
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),

// // //             const SizedBox(height: 28),

// // //             // ── Medical History ──────────────────────────────
// // //             const _SectionLabel('Medical History'),
// // //             const SizedBox(height: 6),
// // //             Text(
// // //               'These factors contribute to your stroke risk calculation',
// // //               style: Theme.of(context)
// // //                   .textTheme
// // //                   .bodyMedium
// // //                   ?.copyWith(fontSize: 11),
// // //             ),
// // //             const SizedBox(height: 14),

// // //             _MedicalToggle(
// // //               label: 'Hypertension (High Blood Pressure)',
// // //               sublabel: 'Diagnosed by a doctor or currently on BP medication',
// // //               icon: Icons.monitor_heart_outlined,
// // //               value: _hypertension,
// // //               onChanged: (v) => setState(() => _hypertension = v),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             _MedicalToggle(
// // //               label: 'Diabetes',
// // //               sublabel: 'Type 1 or Type 2 diabetes',
// // //               icon: Icons.bloodtype_outlined,
// // //               value: _diabetes,
// // //               onChanged: (v) => setState(() => _diabetes = v),
// // //             ),
// // //             const SizedBox(height: 10),
// // //             _MedicalToggle(
// // //               label: 'Prior Stroke or TIA',
// // //               sublabel: 'Previous stroke or transient ischaemic attack',
// // //               icon: Icons.psychology_outlined,
// // //               value: _priorStroke,
// // //               onChanged: (v) => setState(() => _priorStroke = v),
// // //             ),

// // //             const SizedBox(height: 36),

// // //             SizedBox(
// // //               width: double.infinity,
// // //               child: ElevatedButton.icon(
// // //                 onPressed: _save,
// // //                 icon: const Icon(Icons.save_rounded, size: 18),
// // //                 label: const Text('Save Profile'),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 20),

// // //             // ── CHA2DS2-VASc info ────────────────────────────
// // //             Container(
// // //               padding: const EdgeInsets.all(14),
// // //               decoration: BoxDecoration(
// // //                 color: AppTheme.border.withOpacity(0.4),
// // //                 borderRadius: BorderRadius.circular(12),
// // //               ),
// // //               child: Text(
// // //                 'ℹ️  Stroke risk is calculated using a modified CHA₂DS₂-VASc score, a clinically validated tool used worldwide for stroke risk assessment in patients with atrial fibrillation.',
// // //                 style: Theme.of(context)
// // //                     .textTheme
// // //                     .bodyMedium
// // //                     ?.copyWith(fontSize: 11, color: AppTheme.textSecondary),
// // //               ),
// // //             ),

// // //             const SizedBox(height: 40),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _SectionLabel extends StatelessWidget {
// // //   final String text;
// // //   const _SectionLabel(this.text);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Text(text,
// // //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
// // //               color: AppTheme.primary,
// // //               fontSize: 13,
// // //               fontWeight: FontWeight.w700,
// // //               letterSpacing: 0.3,
// // //             ));
// // //   }
// // // }

// // // class _MedicalToggle extends StatelessWidget {
// // //   final String label;
// // //   final String sublabel;
// // //   final IconData icon;
// // //   final bool value;
// // //   final ValueChanged<bool> onChanged;

// // //   const _MedicalToggle({
// // //     required this.label,
// // //     required this.sublabel,
// // //     required this.icon,
// // //     required this.value,
// // //     required this.onChanged,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         color: value
// // //             ? AppTheme.primary.withOpacity(0.05)
// // //             : AppTheme.card,
// // //         borderRadius: BorderRadius.circular(14),
// // //         border: Border.all(
// // //           color: value
// // //               ? AppTheme.primary.withOpacity(0.3)
// // //               : AppTheme.border,
// // //         ),
// // //       ),
// // //       child: SwitchListTile(
// // //         value: value,
// // //         onChanged: onChanged,
// // //         activeThumbColor: AppTheme.primary,
// // //         secondary: Icon(icon,
// // //             color: value ? AppTheme.primary : AppTheme.textSecondary),
// // //         title: Text(label,
// // //             style: Theme.of(context)
// // //                 .textTheme
// // //                 .bodyLarge
// // //                 ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
// // //         subtitle: Text(sublabel,
// // //             style: Theme.of(context)
// // //                 .textTheme
// // //                 .bodyMedium
// // //                 ?.copyWith(fontSize: 11)),
// // //         contentPadding:
// // //             const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// // //       ),
// // //     );
// // //   }
// // // }





// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import '../models/patient_profile.dart';
// // import '../services/storage_service.dart';
// // import '../services/pdf_report_service.dart';
// // import '../theme/app_theme.dart';

// // class ProfileScreen extends StatefulWidget {
// //   const ProfileScreen({super.key});

// //   @override
// //   State<ProfileScreen> createState() => _ProfileScreenState();
// // }

// // class _ProfileScreenState extends State<ProfileScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   late TextEditingController _nameCtrl;
// //   late TextEditingController _ageCtrl;
// //   late TextEditingController _sbpCtrl;
// //   late TextEditingController _dbpCtrl;

// //   String _sex           = 'Male';
// //   bool _hypertension    = false;
// //   bool _diabetes        = false;
// //   bool _priorStroke     = false;
// //   bool _saved           = false;
// //   bool _generatingPdf   = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _nameCtrl = TextEditingController();
// //     _ageCtrl  = TextEditingController();
// //     _sbpCtrl  = TextEditingController();
// //     _dbpCtrl  = TextEditingController();
// //     _loadProfile();
// //   }

// //   void _loadProfile() {
// //     final p = StorageService.getProfile();
// //     if (p == null) return;
// //     _nameCtrl.text = p.name;
// //     _ageCtrl.text  = p.age.toString();
// //     _sbpCtrl.text  = p.systolicBP?.toString() ?? '';
// //     _dbpCtrl.text  = p.diastolicBP?.toString() ?? '';
// //     _sex           = p.sex;
// //     _hypertension  = p.hasHypertension;
// //     _diabetes      = p.hasDiabetes;
// //     _priorStroke   = p.hasPriorStrokeTIA;
// //   }

// //   Future<void> _save() async {
// //     if (!_formKey.currentState!.validate()) return;

// //     final profile = PatientProfile(
// //       name:              _nameCtrl.text.trim(),
// //       age:               int.parse(_ageCtrl.text.trim()),
// //       sex:               _sex,
// //       hasHypertension:   _hypertension,
// //       hasDiabetes:       _diabetes,
// //       hasPriorStrokeTIA: _priorStroke,
// //       systolicBP:  _sbpCtrl.text.isEmpty ? null : int.tryParse(_sbpCtrl.text),
// //       diastolicBP: _dbpCtrl.text.isEmpty ? null : int.tryParse(_dbpCtrl.text),
// //     );

// //     await StorageService.saveProfile(profile);
// //     setState(() => _saved = true);

// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('Profile saved ✓'),
// //         backgroundColor: AppTheme.secondary,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }

// //   Future<void> _generateReport() async {
// //     final profile = StorageService.getProfile();
// //     if (profile == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Please save your profile first before generating a report.'),
// //           backgroundColor: AppTheme.warning,
// //           behavior: SnackBarBehavior.floating,
// //         ),
// //       );
// //       return;
// //     }

// //     final measurements = StorageService.getAllMeasurements();
// //     if (measurements.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('No measurements found. Take at least one reading first.'),
// //           backgroundColor: AppTheme.warning,
// //           behavior: SnackBarBehavior.floating,
// //         ),
// //       );
// //       return;
// //     }

// //     setState(() => _generatingPdf = true);
// //     try {
// //       await PdfReportService.generateAndShare(
// //         profile:         profile,
// //         allMeasurements: measurements,
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Failed to generate report: $e'),
// //           backgroundColor: AppTheme.danger,
// //           behavior: SnackBarBehavior.floating,
// //         ),
// //       );
// //     } finally {
// //       if (mounted) setState(() => _generatingPdf = false);
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _nameCtrl.dispose();
// //     _ageCtrl.dispose();
// //     _sbpCtrl.dispose();
// //     _dbpCtrl.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final hasProfile     = StorageService.hasProfile;
// //     final measureCount   = StorageService.measurementCount;

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Patient Profile'),
// //         actions: [
// //           TextButton(
// //             onPressed: _save,
// //             child: const Text('Save',
// //                 style: TextStyle(
// //                     color: AppTheme.primary, fontWeight: FontWeight.w700)),
// //           ),
// //         ],
// //       ),
// //       body: Form(
// //         key: _formKey,
// //         child: ListView(
// //           padding: const EdgeInsets.all(20),
// //           children: [

// //             // ── Info banner ──────────────────────────────────
// //             Container(
// //               padding: const EdgeInsets.all(14),
// //               decoration: BoxDecoration(
// //                 color: AppTheme.primary.withOpacity(0.06),
// //                 borderRadius: BorderRadius.circular(12),
// //                 border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
// //               ),
// //               child: Row(
// //                 children: [
// //                   const Icon(Icons.info_outline_rounded,
// //                       color: AppTheme.primary, size: 18),
// //                   const SizedBox(width: 10),
// //                   Expanded(
// //                     child: Text(
// //                       'Your profile is used to calculate personalised stroke risk. '
// //                       'All data is stored only on this device.',
// //                       style: Theme.of(context)
// //                           .textTheme
// //                           .bodyMedium
// //                           ?.copyWith(fontSize: 12),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             const SizedBox(height: 28),

// //             // ── Personal Details ─────────────────────────────
// //             const _SectionLabel('Personal Details'),
// //             const SizedBox(height: 14),

// //             TextFormField(
// //               controller: _nameCtrl,
// //               decoration: const InputDecoration(
// //                 labelText: 'Full Name',
// //                 prefixIcon: Icon(Icons.person_outline_rounded),
// //               ),
// //               textCapitalization: TextCapitalization.words,
// //               validator: (v) =>
// //                   v == null || v.trim().isEmpty ? 'Name is required' : null,
// //             ),
// //             const SizedBox(height: 14),

// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: TextFormField(
// //                     controller: _ageCtrl,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Age (years)',
// //                       prefixIcon: Icon(Icons.cake_outlined),
// //                     ),
// //                     keyboardType: TextInputType.number,
// //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// //                     validator: (v) {
// //                       if (v == null || v.isEmpty) return 'Required';
// //                       final n = int.tryParse(v);
// //                       if (n == null || n < 1 || n > 120) return 'Invalid age';
// //                       return null;
// //                     },
// //                   ),
// //                 ),
// //                 const SizedBox(width: 14),
// //                 Expanded(
// //                   child: DropdownButtonFormField<String>(
// //                     value: _sex,
// //                     decoration: const InputDecoration(labelText: 'Sex'),
// //                     items: ['Male', 'Female', 'Other']
// //                         .map((s) => DropdownMenuItem(value: s, child: Text(s)))
// //                         .toList(),
// //                     onChanged: (v) => setState(() => _sex = v!),
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 28),

// //             // ── Blood Pressure ───────────────────────────────
// //             const _SectionLabel('Blood Pressure (most recent reading)'),
// //             const SizedBox(height: 6),
// //             Text(
// //               'Leave blank if unknown — you can update this anytime',
// //               style: Theme.of(context)
// //                   .textTheme
// //                   .bodyMedium
// //                   ?.copyWith(fontSize: 11),
// //             ),
// //             const SizedBox(height: 14),

// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: TextFormField(
// //                     controller: _sbpCtrl,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Systolic (mmHg)',
// //                       hintText: 'e.g. 120',
// //                       prefixIcon: Icon(Icons.arrow_upward_rounded),
// //                     ),
// //                     keyboardType: TextInputType.number,
// //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// //                     validator: (v) {
// //                       if (v == null || v.isEmpty) return null;
// //                       final n = int.tryParse(v);
// //                       if (n == null || n < 60 || n > 250) return 'Invalid';
// //                       return null;
// //                     },
// //                   ),
// //                 ),
// //                 const SizedBox(width: 14),
// //                 Expanded(
// //                   child: TextFormField(
// //                     controller: _dbpCtrl,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Diastolic (mmHg)',
// //                       hintText: 'e.g. 80',
// //                       prefixIcon: Icon(Icons.arrow_downward_rounded),
// //                     ),
// //                     keyboardType: TextInputType.number,
// //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// //                     validator: (v) {
// //                       if (v == null || v.isEmpty) return null;
// //                       final n = int.tryParse(v);
// //                       if (n == null || n < 40 || n > 150) return 'Invalid';
// //                       return null;
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 28),

// //             // ── Medical History ──────────────────────────────
// //             const _SectionLabel('Medical History'),
// //             const SizedBox(height: 6),
// //             Text(
// //               'These factors contribute to your stroke risk calculation',
// //               style: Theme.of(context)
// //                   .textTheme
// //                   .bodyMedium
// //                   ?.copyWith(fontSize: 11),
// //             ),
// //             const SizedBox(height: 14),

// //             _MedicalToggle(
// //               label:     'Hypertension (High Blood Pressure)',
// //               sublabel:  'Diagnosed by a doctor or currently on BP medication',
// //               icon:      Icons.monitor_heart_outlined,
// //               value:     _hypertension,
// //               onChanged: (v) => setState(() => _hypertension = v),
// //             ),
// //             const SizedBox(height: 10),
// //             _MedicalToggle(
// //               label:     'Diabetes',
// //               sublabel:  'Type 1 or Type 2 diabetes',
// //               icon:      Icons.bloodtype_outlined,
// //               value:     _diabetes,
// //               onChanged: (v) => setState(() => _diabetes = v),
// //             ),
// //             const SizedBox(height: 10),
// //             _MedicalToggle(
// //               label:     'Prior Stroke or TIA',
// //               sublabel:  'Previous stroke or transient ischaemic attack',
// //               icon:      Icons.psychology_outlined,
// //               value:     _priorStroke,
// //               onChanged: (v) => setState(() => _priorStroke = v),
// //             ),

// //             const SizedBox(height: 28),

// //             // ── Save button ──────────────────────────────────
// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton.icon(
// //                 onPressed: _save,
// //                 icon: const Icon(Icons.save_rounded, size: 18),
// //                 label: const Text('Save Profile'),
// //               ),
// //             ),

// //             const SizedBox(height: 16),

// //             // ── PDF Report Section ───────────────────────────
// //             const _SectionLabel('Clinical Report'),
// //             const SizedBox(height: 8),

// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: AppTheme.card,
// //                 borderRadius: BorderRadius.circular(16),
// //                 border: Border.all(color: AppTheme.border),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     children: [
// //                       Container(
// //                         width: 40, height: 40,
// //                         decoration: BoxDecoration(
// //                           color: AppTheme.primary.withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(10),
// //                         ),
// //                         child: const Icon(Icons.picture_as_pdf_rounded,
// //                             color: AppTheme.primary, size: 20),
// //                       ),
// //                       const SizedBox(width: 12),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text('Generate PDF Report',
// //                                 style: Theme.of(context)
// //                                     .textTheme
// //                                     .titleMedium
// //                                     ?.copyWith(fontSize: 14)),
// //                             const SizedBox(height: 2),
// //                             Text(
// //                               'Share a structured clinical summary with your doctor',
// //                               style: Theme.of(context)
// //                                   .textTheme
// //                                   .bodyMedium
// //                                   ?.copyWith(fontSize: 11),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 14),

// //                   // Report contents summary
// //                   ..._reportContents(context),

// //                   const SizedBox(height: 14),

// //                   // Status row
// //                   Row(
// //                     children: [
// //                       _StatusPill(
// //                         label: hasProfile ? 'Profile ✓' : 'No profile',
// //                         color: hasProfile ? AppTheme.secondary : AppTheme.warning,
// //                       ),
// //                       const SizedBox(width: 8),
// //                       _StatusPill(
// //                         label: measureCount > 0
// //                             ? '$measureCount reading${measureCount == 1 ? '' : 's'}'
// //                             : 'No readings',
// //                         color: measureCount > 0
// //                             ? AppTheme.secondary
// //                             : AppTheme.warning,
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 14),

// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: ElevatedButton.icon(
// //                       onPressed: _generatingPdf ? null : _generateReport,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: AppTheme.primary,
// //                         foregroundColor: Colors.white,
// //                         padding: const EdgeInsets.symmetric(vertical: 14),
// //                         shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(12)),
// //                       ),
// //                       icon: _generatingPdf
// //                           ? const SizedBox(
// //                               width: 16, height: 16,
// //                               child: CircularProgressIndicator(
// //                                   strokeWidth: 2, color: Colors.white))
// //                           : const Icon(Icons.download_rounded, size: 18),
// //                       label: Text(
// //                         _generatingPdf ? 'Generating...' : 'Generate & Share Report',
// //                         style: const TextStyle(
// //                             fontWeight: FontWeight.w600, fontSize: 14),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             const SizedBox(height: 20),

// //             // ── CHA2DS2-VASc info ────────────────────────────
// //             Container(
// //               padding: const EdgeInsets.all(14),
// //               decoration: BoxDecoration(
// //                 color: AppTheme.border.withOpacity(0.4),
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Text(
// //                 'ℹ️  Stroke risk is calculated using a modified CHA₂DS₂-VASc score, '
// //                 'a clinically validated tool used worldwide for stroke risk assessment '
// //                 'in patients with atrial fibrillation.',
// //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                     fontSize: 11, color: AppTheme.textSecondary),
// //               ),
// //             ),

// //             const SizedBox(height: 40),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   List<Widget> _reportContents(BuildContext context) {
// //     final items = [
// //       ('Latest measurement result & HRV metrics',     Icons.monitor_heart_outlined),
// //       ('CHA₂DS₂-VASc score breakdown with citations', Icons.table_chart_outlined),
// //       ('Device HRV risk flags (pRR50, SDSD, BP)',      Icons.bar_chart_rounded),
// //       ('Last 10 readings history table',               Icons.history_rounded),
// //       ('Personalised recommendations',                  Icons.lightbulb_outline_rounded),
// //       ('Medical disclaimer & emergency contacts',       Icons.local_hospital_outlined),
// //     ];
// //     return items.map((item) => Padding(
// //       padding: const EdgeInsets.only(bottom: 4),
// //       child: Row(
// //         children: [
// //           Icon(item.$2, size: 14, color: AppTheme.textSecondary),
// //           const SizedBox(width: 8),
// //           Text(item.$1,
// //               style: Theme.of(context)
// //                   .textTheme
// //                   .bodyMedium
// //                   ?.copyWith(fontSize: 11)),
// //         ],
// //       ),
// //     )).toList();
// //   }
// // }

// // // ── Reusable widgets ──────────────────────────────────────────────

// // class _SectionLabel extends StatelessWidget {
// //   final String text;
// //   const _SectionLabel(this.text);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Text(text,
// //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //               color: AppTheme.primary,
// //               fontSize: 13,
// //               fontWeight: FontWeight.w700,
// //               letterSpacing: 0.3,
// //             ));
// //   }
// // }

// // class _MedicalToggle extends StatelessWidget {
// //   final String label;
// //   final String sublabel;
// //   final IconData icon;
// //   final bool value;
// //   final ValueChanged<bool> onChanged;

// //   const _MedicalToggle({
// //     required this.label,
// //     required this.sublabel,
// //     required this.icon,
// //     required this.value,
// //     required this.onChanged,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: value ? AppTheme.primary.withOpacity(0.05) : AppTheme.card,
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(
// //           color: value ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
// //         ),
// //       ),
// //       child: SwitchListTile(
// //         value: value,
// //         onChanged: onChanged,
// //         activeThumbColor: AppTheme.primary,
// //         secondary: Icon(icon,
// //             color: value ? AppTheme.primary : AppTheme.textSecondary),
// //         title: Text(label,
// //             style: Theme.of(context)
// //                 .textTheme
// //                 .bodyLarge
// //                 ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
// //         subtitle: Text(sublabel,
// //             style: Theme.of(context)
// //                 .textTheme
// //                 .bodyMedium
// //                 ?.copyWith(fontSize: 11)),
// //         contentPadding:
// //             const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
// //       ),
// //     );
// //   }
// // }

// // class _StatusPill extends StatelessWidget {
// //   final String label;
// //   final Color color;
// //   const _StatusPill({required this.label, required this.color});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.1),
// //         borderRadius: BorderRadius.circular(100),
// //         border: Border.all(color: color.withOpacity(0.4)),
// //       ),
// //       child: Text(label,
// //           style: TextStyle(
// //               fontSize: 11, fontWeight: FontWeight.w600, color: color)),
// //     );
// //   }
// // }


// import 'package:flutter/material.dart';
// import '../models/measurement.dart';
// import '../models/patient_profile.dart';
// import '../services/stroke_algorithm.dart';
// import 'dart:math' as math;
// import '../theme/app_theme.dart';
// import '../widgets/shared_widgets.dart';
// import '../services/tts_service.dart';

// class RecommendationsScreen extends StatelessWidget {
//   final Measurement measurement;
//   final StrokeScoreResult scoreResult;
//   final PatientProfile profile;

//   const RecommendationsScreen({
//     super.key,
//     required this.measurement,
//     required this.scoreResult,
//     required this.profile,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final recs = StrokeAlgorithm.getRecommendations(
//       result: scoreResult,
//       profile: profile,
//       afResult: measurement.afResult,
//       pRR50: measurement.pnn50,
//       sdsd: measurement.rmssd / math.sqrt(2),
//     );

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Recommendations'),
//         actions: [
//           ValueListenableBuilder<int>(
//             valueListenable: TtsService.instance.stateNotifier,
//             builder: (context, _, __) {
//               final buffer = StringBuffer();
//               for (final r in recs) {
//                 buffer.write('${r.title}. ${r.body} ');
//               }
//               final text = buffer.toString();
//               final playing = TtsService.instance.isPlaying &&
//                   TtsService.instance.currentText == text;
//               final paused = playing && TtsService.instance.isPaused;
//               final icon =
//                   paused ? Icons.play_arrow_rounded : Icons.volume_up_rounded;
//               return IconButton(
//                 icon: Icon(icon),
//                 onPressed: () {
//                   TtsService.instance.togglePlayPause(text);
//                 },
//                 tooltip: paused ? 'Resume' : 'Read all',
//               );
//             },
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           // Header card
//           Container(
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [AppTheme.primary, AppTheme.primary.withBlue(200)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Personalised for you',
//                     style: TextStyle(color: Colors.white70, fontSize: 12)),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     AfResultBadge(result: measurement.afResult, large: true),
//                     const SizedBox(width: 10),
//                     StrokeRiskChip(
//                         risk: scoreResult.risk,
//                         score: scoreResult.totalScore,
//                         large: true),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 24),

//           // Group urgent first
//           ...recs.map((r) => Padding(
//                 padding: const EdgeInsets.only(bottom: 14),
//                 child: _RecCard(rec: r),
//               )),

//           const SizedBox(height: 16),

//           // Emergency numbers
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppTheme.danger.withOpacity(0.06),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Row(children: [
//                   Icon(Icons.emergency_rounded,
//                       color: AppTheme.danger, size: 18),
//                   SizedBox(width: 8),
//                   Text('Emergency Numbers — Ghana',
//                       style: TextStyle(
//                           color: AppTheme.danger,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 13)),
//                 ]),
//                 const SizedBox(height: 12),
//                 _emergencyLine('Ambulance / GNEMS', '193'),
//                 _emergencyLine('Police', '191'),
//                 _emergencyLine('General Emergency', '112'),
//                 const SizedBox(height: 8),
//                 Text(
//                   'If you experience sudden weakness, numbness, slurred speech, severe headache, or vision loss — call immediately.',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   Widget _emergencyLine(String name, String number) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(name,
//               style:
//                   const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
//           Text(number,
//               style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                   color: AppTheme.danger)),
//         ],
//       ),
//     );
//   }
// }

// class _RecCard extends StatelessWidget {
//   final Recommendation rec;
//   const _RecCard({required this.rec});

//   Color get _borderColor {
//     switch (rec.priority) {
//       case RecommendationPriority.urgent:
//         return AppTheme.danger;
//       case RecommendationPriority.warning:
//         return AppTheme.warning;
//       case RecommendationPriority.info:
//         return AppTheme.border;
//     }
//   }

//   Color get _bgColor {
//     switch (rec.priority) {
//       case RecommendationPriority.urgent:
//         return AppTheme.danger.withOpacity(0.05);
//       case RecommendationPriority.warning:
//         return AppTheme.warning.withOpacity(0.05);
//       case RecommendationPriority.info:
//         return AppTheme.card;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _bgColor,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: _borderColor.withOpacity(0.35)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _iconFromKey(rec.icon),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(rec.title,
//                           style: Theme.of(context)
//                               .textTheme
//                               .titleMedium
//                               ?.copyWith(fontSize: 14)),
//                     ),
//                     ReadAloudIcon(text: '${rec.title}. ${rec.body}'),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Text(rec.body,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyMedium
//                         ?.copyWith(fontSize: 13, height: 1.5)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// // Maps icon key strings to Material icons
// Widget _iconFromKey(String key) {
//   const map = {
//     'heart':      Icons.favorite_rounded,
//     'brain':      Icons.psychology_rounded,
//     'nutrition':  Icons.restaurant_rounded,
//     'walk':       Icons.directions_walk_rounded,
//     'pill':       Icons.medication_rounded,
//     'no_smoking': Icons.smoke_free_rounded,
//     'sleep':      Icons.bedtime_rounded,
//     'hospital':   Icons.local_hospital_rounded,
//     'warning':    Icons.warning_rounded,
//     'chart':      Icons.bar_chart_rounded,
//     'clipboard':  Icons.assignment_rounded,
//     'trending':   Icons.trending_up_rounded,
//     'monitor':    Icons.monitor_heart_rounded,
//   };
//   return Icon(map[key] ?? Icons.info_outline_rounded,
//       size: 24, color: AppTheme.primary);
// }

// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/patient_profile.dart';
import '../services/storage_service.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';
import '../models/stroke_models.dart';

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

  String _sex           = 'Male';
  bool _hypertension    = false;
  bool _diabetes        = false;
  bool _priorStroke     = false;
  bool _saved           = false;
  bool _generatingPdf   = false;

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
      name:              _nameCtrl.text.trim(),
      age:               int.parse(_ageCtrl.text.trim()),
      sex:               _sex,
      hasHypertension:   _hypertension,
      hasDiabetes:       _diabetes,
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

  Future<void> _generateReport() async {
    final profile = StorageService.getProfile();
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save your profile first before generating a report.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final measurements = StorageService.getAllMeasurements();
    if (measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No measurements found. Take at least one reading first.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _generatingPdf = true);
    try {
      await PdfReportService.generateAndShare(
        profile:         profile,
        allMeasurements: measurements,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
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
    final hasProfile     = StorageService.hasProfile;
    final measureCount   = StorageService.measurementCount;

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

            // ── Info banner ──────────────────────────────────
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
                      'Your profile is used to calculate personalised stroke risk. '
                      'All data is stored only on this device.',
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
                    value: _sex,
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
              label:     'Hypertension (High Blood Pressure)',
              sublabel:  'Diagnosed by a doctor or currently on BP medication',
              icon:      Icons.monitor_heart_outlined,
              value:     _hypertension,
              onChanged: (v) => setState(() => _hypertension = v),
            ),
            const SizedBox(height: 10),
            _MedicalToggle(
              label:     'Diabetes',
              sublabel:  'Type 1 or Type 2 diabetes',
              icon:      Icons.bloodtype_outlined,
              value:     _diabetes,
              onChanged: (v) => setState(() => _diabetes = v),
            ),
            const SizedBox(height: 10),
            _MedicalToggle(
              label:     'Prior Stroke or TIA',
              sublabel:  'Previous stroke or transient ischaemic attack',
              icon:      Icons.psychology_outlined,
              value:     _priorStroke,
              onChanged: (v) => setState(() => _priorStroke = v),
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Profile'),
              ),
            ),

            const SizedBox(height: 16),

            // ── PDF Report Section ───────────────────────────
            const _SectionLabel('Clinical Report'),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Generate PDF Report',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Share a structured clinical summary with your doctor',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Report contents summary
                  ..._reportContents(context),

                  const SizedBox(height: 14),

                  // Status row
                  Row(
                    children: [
                      _StatusPill(
                        label: hasProfile ? 'Profile ✓' : 'No profile',
                        color: hasProfile ? AppTheme.secondary : AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: measureCount > 0
                            ? '$measureCount reading${measureCount == 1 ? '' : 's'}'
                            : 'No readings',
                        color: measureCount > 0
                            ? AppTheme.secondary
                            : AppTheme.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatingPdf ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _generatingPdf
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        _generatingPdf ? 'Generating...' : 'Generate & Share Report',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
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
                'Stroke risk is calculated using a modified CHA₂DS₂-VASc score, '
                'a clinically validated tool used worldwide for stroke risk assessment '
                'in patients with atrial fibrillation.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _reportContents(BuildContext context) {
    final items = [
      ('Latest measurement result & HRV metrics',     Icons.monitor_heart_outlined),
      ('CHA₂DS₂-VASc score breakdown with citations', Icons.table_chart_outlined),
      ('Device HRV risk flags (pRR50, SDSD, BP)',      Icons.bar_chart_rounded),
      ('Last 10 readings history table',               Icons.history_rounded),
      ('Personalised recommendations',                  Icons.lightbulb_outline_rounded),
      ('Medical disclaimer & emergency contacts',       Icons.local_hospital_outlined),
    ];
    return items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(item.$2, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(item.$1,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11)),
        ],
      ),
    )).toList();
  }
}

// ── Reusable widgets ──────────────────────────────────────────────

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
        color: value ? AppTheme.primary.withOpacity(0.05) : AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}