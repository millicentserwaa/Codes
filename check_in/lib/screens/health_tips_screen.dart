// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/measurement.dart';
// import '../models/user_profile.dart';
// import '../services/hive_service.dart';
// import '../theme/app_theme.dart';
// import '../widgets/tts_button.dart';
// class HealthTipsScreen extends StatefulWidget {
//   const HealthTipsScreen({super.key});

//   @override
//   State<HealthTipsScreen> createState() => _HealthTipsScreenState();
// }

// class _HealthTipsScreenState extends State<HealthTipsScreen> {
//   final HiveService _hiveService = HiveService();
//   UserProfile? _profile;
//   Measurement? _latestMeasurement;
//   List<Measurement> _measurements = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   void _loadData() {
//     setState(() {
//       _profile = _hiveService.getUserProfile();
//       _measurements = _hiveService.getAllMeasurements();
//       _latestMeasurement =
//           _measurements.isNotEmpty ? _measurements.first : null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Health Tips'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Personalised banner
//             _buildPersonalisedBanner(),
//             const SizedBox(height: 8),

//             // Citation note
//             _buildCitationNote(),
//             const SizedBox(height: 24),

//             // Categories
//             _buildCategory(
//               icon: Icons.favorite_rounded,
//               color: AppTheme.danger,
//               title: 'Atrial Fibrillation',
//               tips: _afTips(),
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.shield_rounded,
//               color: AppTheme.primary,
//               title: 'Stroke Prevention',
//               tips: _strokeTips(),
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.restaurant_rounded,
//               color: Colors.orange,
//               title: 'Diet & Nutrition',
//               tips: _dietTips(),
//               personalised: _profile?.hasHypertension == true ||
//                   _profile?.hasDiabetes == true,
//               personalisedNote: _profile?.hasHypertension == true
//                   ? 'Tailored for hypertension management.'
//                   : _profile?.hasDiabetes == true
//                       ? 'Tailored for diabetes management.'
//                       : null,
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.directions_run_rounded,
//               color: Colors.green,
//               title: 'Physical Activity',
//               tips: _activityTips(),
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.medication_rounded,
//               color: Colors.purple,
//               title: 'Medication Adherence',
//               tips: _medicationTips(),
//               personalised: _profile?.hasHypertension == true ||
//                   _profile?.hasDiabetes == true ||
//                   _profile?.hasPriorStroke == true,
//               personalisedNote: 'Consistent medication use is critical given your conditions.',
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.no_drinks_rounded,
//               color: Colors.brown,
//               title: 'Alcohol & Smoking',
//               tips: _lifestyleTips(),
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.bedtime_rounded,
//               color: Colors.indigo,
//               title: 'Sleep & Stress',
//               tips: _sleepTips(),
//             ),
//             const SizedBox(height: 20),
//             _buildCategory(
//               icon: Icons.local_hospital_rounded,
//               color: AppTheme.danger,
//               title: 'Emergency Signs',
//               tips: _emergencyTips(),
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Personalised banner ──────────────────────────────────
//   Widget _buildPersonalisedBanner() {
//     final isAF = _latestMeasurement?.afPrediction == 1;
//     final riskLevel = _profile?.strokeRiskLevel ?? 'Unknown';
//     final riskScore = _profile?.strokeRiskScore ?? 0;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppTheme.primary,
//             AppTheme.primary.withOpacity(0.8),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Personalised for your results',
//             style: GoogleFonts.inter(
//               fontSize: 12,
//               color: Colors.white.withOpacity(0.8),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               _buildBannerBadge(
//                 isAF ? 'Possible AF' : 'Normal',
//                 isAF ? AppTheme.danger : AppTheme.success,
//                 isAF
//                     ? Icons.warning_amber_rounded
//                     : Icons.check_circle_rounded,
//               ),
//               const SizedBox(width: 8),
//               if (_profile != null) ...[
//                 _buildBannerBadge(
//                   'Score $riskScore',
//                   Colors.white.withOpacity(0.3),
//                   Icons.shield_outlined,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildBannerBadge(
//                   '$riskLevel Risk',
//                   AppTheme.riskColor(riskLevel).withOpacity(0.8),
//                   Icons.monitor_heart_outlined,
//                 ),
//               ],
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tips marked with ! are most relevant based on your latest reading.',
//             style: GoogleFonts.inter(
//               fontSize: 11,
//               color: Colors.white.withOpacity(0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBannerBadge(String label, Color color, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 12, color: Colors.white),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: GoogleFonts.inter(
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Citation note ────────────────────────────────────────
//   Widget _buildCitationNote() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppTheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppTheme.divider),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.info_outline_rounded,
//               size: 14, color: AppTheme.textSecondary),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
//               'This app does not replace professional medical advice.',
//               style: GoogleFonts.inter(
//                 fontSize: 11,
//                 color: AppTheme.textSecondary,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Category builder ─────────────────────────────────────
//   Widget _buildCategory({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required List<_Tip> tips,
//     bool personalised = false,
//     String? personalisedNote,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Category header
//         Row(
//           children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               title,
//               style: GoogleFonts.inter(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//                 color: AppTheme.textPrimary,
//               ),
//             ),
//             if (personalised) ...[
//               const SizedBox(width: 8),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppTheme.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                       color: AppTheme.primary.withOpacity(0.3)),
//                 ),
//                 child: Text(
//                   '✦ Personalised',
//                   style: GoogleFonts.inter(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.primary,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         if (personalisedNote != null) ...[
//           const SizedBox(height: 6),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: AppTheme.primary.withOpacity(0.06),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               personalisedNote,
//               style: GoogleFonts.inter(
//                 fontSize: 11,
//                 color: AppTheme.primary,
//               ),
//             ),
//           ),
//         ],
//         const SizedBox(height: 10),
//         ...tips.map((tip) => _buildTipTile(tip)),
//       ],
//     );
//   }

//   // ── Tip tile ─────────────────────────────────────────────
//   Widget _buildTipTile(_Tip tip) {
//     final isHighlighted = tip.priority && _isRelevant(tip);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: isHighlighted
//             ? AppTheme.danger.withOpacity(0.06)
//             : AppTheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isHighlighted
//               ? AppTheme.danger.withOpacity(0.3)
//               : AppTheme.divider,
//         ),
//       ),
//       child: ExpansionTile(
//         tilePadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         childrenPadding:
//             const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//         leading: isHighlighted
//             ? const Icon(Icons.priority_high_rounded,
//                 color: AppTheme.danger, size: 18)
//             : null,
//         title: Text(
//           tip.title,
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
//             color: isHighlighted
//                 ? AppTheme.danger
//                 : AppTheme.textPrimary,
//           ),
//         ),
//         children: [
//           Text(
//             tip.content,
//             style: GoogleFonts.inter(
//               fontSize: 13,
//               color: AppTheme.textSecondary,
//               height: 1.6,
//             ),
//           ),
//           if (tip.reference != null) ...[
//             const SizedBox(height: 8),
//             Text(
//               'Ref: ${tip.reference}',
//               style: GoogleFonts.inter(
//                 fontSize: 11,
//                 color: AppTheme.textSecondary,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   bool _isRelevant(_Tip tip) {
//     final isAF = _latestMeasurement?.afPrediction == 1;
//     final riskLevel = _profile?.strokeRiskLevel ?? 'Low';
//     if (tip.relevantForAF && isAF) return true;
//     if (tip.relevantForHighRisk && riskLevel == 'High') return true;
//     if (tip.relevantForHypertension &&
//         _profile?.hasHypertension == true) return true;
//     return false;
//   }

//   // ── Tips data ────────────────────────────────────────────
//   List<_Tip> _afTips() => [
//         _Tip(
//           title: 'Know the symptoms of AF',
//           content:
//               'Atrial fibrillation symptoms include palpitations (fluttering or racing heart), '
//               'shortness of breath, dizziness, fatigue, and chest discomfort. '
//               'Some people have no symptoms at all, making regular screening important.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//         _Tip(
//           title: 'When to go to hospital immediately',
//           content:
//               'Seek emergency care immediately if you experience: sudden severe chest pain, '
//               'difficulty breathing at rest, fainting or loss of consciousness, '
//               'sudden weakness or numbness on one side of the body, or sudden confusion. '
//               'In Ghana, call your nearest emergency service or go to your nearest hospital.',
//           priority: true,
//           relevantForAF: true,
//           reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
//         ),
//         _Tip(
//           title: 'Take anticoagulant medication as prescribed',
//           content:
//               'If your doctor has prescribed blood thinners (anticoagulants) for AF, '
//               'take them exactly as directed. Never stop or change the dose without '
//               'consulting your doctor. These medications significantly reduce stroke risk.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//         _Tip(
//           title: 'Avoid AF triggers',
//           content:
//               'Common AF triggers include excessive alcohol, caffeine, stress, '
//               'lack of sleep, and certain medications. Keep a diary of episodes '
//               'to identify your personal triggers and share with your doctor.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//       ];

//   List<_Tip> _strokeTips() => [
//         _Tip(
//           title: 'FAST — Recognise stroke instantly',
//           content:
//               'Use the FAST method: Face drooping, Arm weakness, Speech difficulty, '
//               'Time to call emergency services. Every minute counts during a stroke. '
//               'In Ghana, contact the nearest hospital with emergency services immediately.',
//           priority: true,
//           relevantForHighRisk: true,
//           reference: 'WHO Stroke Guidelines',
//         ),
//         _Tip(
//           title: 'Control your blood pressure',
//           content:
//               'High blood pressure is the single most important modifiable risk factor for stroke. '
//               'Target blood pressure is below 130/80 mmHg. '
//               'Monitor regularly and take medications as prescribed.',
//           priority: true,
//           relevantForHypertension: true,
//           reference: 'JNC 8 Guidelines',
//         ),
//         _Tip(
//           title: 'Monitor your blood pressure at home',
//           content:
//               'Check your blood pressure at the same time each day, '
//               'ideally in the morning before taking medications. '
//               'Keep a log to share with your healthcare provider.',
//           reference: 'JNC 8 Guidelines',
//         ),
//         _Tip(
//           title: 'Attend all follow-up appointments',
//           content:
//               'Regular check-ups allow your doctor to monitor your risk factors '
//               'and adjust your treatment plan. Do not skip appointments even if you feel well.',
//           reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
//         ),
//       ];

//   List<_Tip> _dietTips() => [
//         _Tip(
//           title: 'Reduce salt (sodium) intake',
//           content:
//               'Limit salt to less than 5g per day (about 1 teaspoon). '
//               'Avoid adding salt during cooking or at the table. '
//               'Choose fresh foods over processed or canned foods which are high in sodium. '
//               'This is especially important for blood pressure management.',
//           priority: true,
//           relevantForHypertension: true,
//           reference: 'WHO Guidelines on Sodium Intake, 2012',
//         ),
//         _Tip(
//           title: 'Eat heart-healthy fats',
//           content:
//               'Choose unsaturated fats from sources like avocado, nuts, and fish. '
//               'Reduce saturated fats from red meat and dairy. '
//               'Avoid trans fats found in processed and fried foods.',
//           reference: 'ADA Standards of Medical Care, 2023',
//         ),
//         _Tip(
//           title: 'Increase fibre and potassium',
//           content:
//               'Eat plenty of fruits, vegetables, and whole grains. '
//               'Potassium-rich foods like bananas, plantain, and beans help lower blood pressure. '
//               'Aim for at least 5 portions of fruit and vegetables per day.',
//           reference: 'WHO Healthy Diet Guidelines',
//         ),
//         _Tip(
//           title: 'Manage blood sugar through diet',
//           content:
//               'If you have diabetes, choose low-glycaemic foods such as whole grains, '
//               'legumes, and non-starchy vegetables. Limit sugary drinks, white bread, '
//               'and refined carbohydrates. Eat regular, balanced meals.',
//           reference: 'ADA Standards of Medical Care, 2023',
//         ),
//       ];

//   List<_Tip> _activityTips() => [
//         _Tip(
//           title: 'Aim for 150 minutes of moderate exercise per week',
//           content:
//               'The WHO recommends at least 150 minutes of moderate-intensity aerobic activity '
//               'per week, such as brisk walking, cycling, or swimming. '
//               'This can be broken into 30-minute sessions, 5 days a week.',
//           reference: 'WHO Global Guidelines on Physical Activity, 2020',
//         ),
//         _Tip(
//           title: 'Avoid prolonged sitting',
//           content:
//               'Sitting for long periods increases cardiovascular risk. '
//               'Take a short walk or do light stretching every 30-60 minutes. '
//               'Use stairs instead of lifts when possible.',
//           reference: 'WHO Global Guidelines on Physical Activity, 2020',
//         ),
//         _Tip(
//           title: 'Start slowly if you have been inactive',
//           content:
//               'If you are new to exercise or have heart conditions, start with light activity '
//               'and gradually increase intensity. Consult your doctor before starting '
//               'a new exercise programme, especially if you have AF or high stroke risk.',
//           reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
//         ),
//       ];

//   List<_Tip> _medicationTips() => [
//         _Tip(
//           title: 'Take your medications at the same time every day',
//           content:
//               'Consistency in medication timing maintains stable drug levels in your blood. '
//               'Use a pill organiser or phone alarm to remind you. '
//               'Missing doses can increase your risk of complications.',
//           reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
//         ),
//         _Tip(
//           title: 'Never stop medication without consulting your doctor',
//           content:
//               'Even if you feel well, stopping medications abruptly can be dangerous. '
//               'Blood pressure, anticoagulant, and diabetes medications must be tapered '
//               'or changed under medical supervision only.',
//           priority: true,
//           relevantForHighRisk: true,
//           reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
//         ),
//         _Tip(
//           title: 'Bring your medications to every appointment',
//           content:
//               'Show your full list of medications to every healthcare provider you see, '
//               'including traditional healers and pharmacists. Some herbal remedies '
//               'interact with heart and blood thinning medications.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//       ];

//   List<_Tip> _lifestyleTips() => [
//         _Tip(
//           title: 'Stop smoking — the single most impactful change you can make',
//           content:
//               'Smoking doubles the risk of stroke and significantly increases AF burden. '
//               'Seek support from your doctor for smoking cessation strategies. '
//               'Benefits begin within 24 hours of quitting.',
//           priority: true,
//           relevantForHighRisk: true,
//           reference: 'WHO Report on the Global Tobacco Epidemic, 2021',
//         ),
//         _Tip(
//           title: 'Limit alcohol consumption',
//           content:
//               'Heavy alcohol use is a major trigger for AF episodes. '
//               'Men should consume no more than 2 units per day, '
//               'women no more than 1 unit per day. '
//               'Avoid binge drinking entirely.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//         _Tip(
//           title: 'Maintain a healthy weight',
//           content:
//               'Obesity increases the risk of AF, hypertension, diabetes, and stroke. '
//               'Aim for a BMI between 18.5 and 24.9. '
//               'Even a 5-10% weight reduction has significant cardiovascular benefits.',
//           reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
//         ),
//       ];

//   List<_Tip> _sleepTips() => [
//         _Tip(
//           title: 'Get 7-9 hours of quality sleep',
//           content:
//               'Poor sleep increases inflammation and blood pressure, raising AF and stroke risk. '
//               'Establish a consistent sleep schedule. '
//               'Avoid screens for at least 1 hour before bed.',
//           reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
//         ),
//         _Tip(
//           title: 'Manage stress actively',
//           content:
//               'Chronic stress increases cortisol levels, raising blood pressure and AF risk. '
//               'Practice stress reduction techniques such as deep breathing, '
//               'meditation, prayer, or regular physical activity.',
//           reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
//         ),
//         _Tip(
//           title: 'Screen for sleep apnoea',
//           content:
//               'Obstructive sleep apnoea is strongly linked to AF and hypertension. '
//               'If you snore loudly, wake up tired, or have been told you stop breathing '
//               'during sleep, discuss a sleep study with your doctor.',
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//       ];

//   List<_Tip> _emergencyTips() => [
//         _Tip(
//           title: 'Ghana emergency contacts',
//           content:
//               'National Ambulance Service: 0302 775 931\n'
//               'Police Emergency: 191\n'
//               'Fire Service: 192\n'
//               'Korle Bu Teaching Hospital: 0302 665 401\n'
//               'Komfo Anokye Teaching Hospital (Kumasi): 0322 022 301',
//           priority: true,
//           relevantForAF: true,
//           relevantForHighRisk: true,
//         ),
//         _Tip(
//           title: 'What to do during a suspected AF episode',
//           content:
//               'Sit or lie down in a comfortable position. '
//               'Try to stay calm and breathe slowly. '
//               'If symptoms include chest pain, fainting, or severe breathlessness, '
//               'call emergency services immediately. '
//               'Do not drive yourself to hospital.',
//           relevantForAF: true,
//           reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
//         ),
//       ];
// }

// class _Tip {
//   final String title;
//   final String content;
//   final String? reference;
//   final bool priority;
//   final bool relevantForAF;
//   final bool relevantForHighRisk;
//   final bool relevantForHypertension;

//   _Tip({
//     required this.title,
//     required this.content,
//     this.reference,
//     this.priority = false,
//     this.relevantForAF = false,
//     this.relevantForHighRisk = false,
//     this.relevantForHypertension = false,
//   });
// }





import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tts_button.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final HiveService _hiveService = HiveService();
  final TtsService _ttsService = TtsService();  // ← ADDED

  UserProfile? _profile;
  Measurement? _latestMeasurement;
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _ttsService.init();  // ← ADDED
    _loadData();
  }

  @override
  void dispose() {
    _ttsService.dispose();  // ← ADDED
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _profile = _hiveService.getUserProfile();
      _measurements = _hiveService.getAllMeasurements();
      _latestMeasurement = _measurements.isNotEmpty ? _measurements.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Tips')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalisedBanner(),
            const SizedBox(height: 8),
            _buildCitationNote(),
            const SizedBox(height: 24),
            _buildCategory(
              icon: Icons.favorite_rounded,
              color: AppTheme.danger,
              title: 'Atrial Fibrillation',
              tips: _afTips(),
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.shield_rounded,
              color: AppTheme.primary,
              title: 'Stroke Prevention',
              tips: _strokeTips(),
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.restaurant_rounded,
              color: Colors.orange,
              title: 'Diet & Nutrition',
              tips: _dietTips(),
              personalised: _profile?.hasHypertension == true ||
                  _profile?.hasDiabetes == true,
              personalisedNote: _profile?.hasHypertension == true
                  ? 'Tailored for hypertension management.'
                  : _profile?.hasDiabetes == true
                      ? 'Tailored for diabetes management.'
                      : null,
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.directions_run_rounded,
              color: Colors.green,
              title: 'Physical Activity',
              tips: _activityTips(),
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.medication_rounded,
              color: Colors.purple,
              title: 'Medication Adherence',
              tips: _medicationTips(),
              personalised: _profile?.hasHypertension == true ||
                  _profile?.hasDiabetes == true ||
                  _profile?.hasPriorStroke == true,
              personalisedNote:
                  'Consistent medication use is critical given your conditions.',
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.no_drinks_rounded,
              color: Colors.brown,
              title: 'Alcohol & Smoking',
              tips: _lifestyleTips(),
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.bedtime_rounded,
              color: Colors.indigo,
              title: 'Sleep & Stress',
              tips: _sleepTips(),
            ),
            const SizedBox(height: 20),
            _buildCategory(
              icon: Icons.local_hospital_rounded,
              color: AppTheme.danger,
              title: 'Emergency Signs',
              tips: _emergencyTips(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Personalised banner ───────────────────────────────────────────────────────
  Widget _buildPersonalisedBanner() {
    final isAF = _latestMeasurement?.afPrediction == 1;
    final riskLevel = _profile?.strokeRiskLevel ?? 'Unknown';
    final riskScore = _profile?.strokeRiskScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalised for your results',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBannerBadge(
                isAF ? 'Possible AF' : 'Normal',
                isAF ? AppTheme.danger : AppTheme.success,
                isAF ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              ),
              const SizedBox(width: 8),
              if (_profile != null) ...[
                _buildBannerBadge(
                  'Score $riskScore',
                  Colors.white.withOpacity(0.3),
                  Icons.shield_outlined,
                ),
                const SizedBox(width: 8),
                _buildBannerBadge(
                  '$riskLevel Risk',
                  AppTheme.riskColor(riskLevel).withOpacity(0.8),
                  Icons.monitor_heart_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tips marked with ! are most relevant based on your latest reading.',
            style: GoogleFonts.inter(
                fontSize: 11, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Citation note ─────────────────────────────────────────────────────────────
  Widget _buildCitationNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
              'This app does not replace professional medical advice.',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category builder ──────────────────────────────────────────────────────────
  Widget _buildCategory({
    required IconData icon,
    required Color color,
    required String title,
    required List<_Tip> tips,
    bool personalised = false,
    String? personalisedNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            if (personalised) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '✦ Personalised',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
        if (personalisedNote != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              personalisedNote,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary),
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...tips.map((tip) => _buildTipTile(tip)),
      ],
    );
  }

  // ── Tip tile — TTS button added in the trailing of the ExpansionTile ─────────
  Widget _buildTipTile(_Tip tip) {
    final isHighlighted = tip.priority && _isRelevant(tip);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.danger.withOpacity(0.06)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.danger.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: isHighlighted
            ? const Icon(Icons.priority_high_rounded,
                color: AppTheme.danger, size: 18)
            : null,
        // ← ADDED: TTS button in the trailing slot
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TtsButton(
              size: 18,
              onSpeak: () => _ttsService.speakHealthTip(tip.title, tip.content),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
        title: Text(
          tip.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted ? AppTheme.danger : AppTheme.textPrimary,
          ),
        ),
        children: [
          Text(
            tip.content,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
          ),
          if (tip.reference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ref: ${tip.reference}',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  bool _isRelevant(_Tip tip) {
    final isAF = _latestMeasurement?.afPrediction == 1;
    final riskLevel = _profile?.strokeRiskLevel ?? 'Low';
    if (tip.relevantForAF && isAF) return true;
    if (tip.relevantForHighRisk && riskLevel == 'High') return true;
    if (tip.relevantForHypertension && _profile?.hasHypertension == true) {
      return true;
    }
    return false;
  }

  // ── Tips data (unchanged) ─────────────────────────────────────────────────────
  List<_Tip> _afTips() => [
        _Tip(
          title: 'Know the symptoms of AF',
          content:
              'Atrial fibrillation symptoms include palpitations (fluttering or racing heart), '
              'shortness of breath, dizziness, fatigue, and chest discomfort. '
              'Some people have no symptoms at all, making regular screening important.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
        _Tip(
          title: 'When to go to hospital immediately',
          content:
              'Seek emergency care immediately if you experience: sudden severe chest pain, '
              'difficulty breathing at rest, fainting or loss of consciousness, '
              'sudden weakness or numbness on one side of the body, or sudden confusion. '
              'In Ghana, call your nearest emergency service or go to your nearest hospital.',
          priority: true,
          relevantForAF: true,
          reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
        ),
        _Tip(
          title: 'Take anticoagulant medication as prescribed',
          content:
              'If your doctor has prescribed blood thinners (anticoagulants) for AF, '
              'take them exactly as directed. Never stop or change the dose without '
              'consulting your doctor. These medications significantly reduce stroke risk.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
        _Tip(
          title: 'Avoid AF triggers',
          content:
              'Common AF triggers include excessive alcohol, caffeine, stress, '
              'lack of sleep, and certain medications. Keep a diary of episodes '
              'to identify your personal triggers and share with your doctor.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
      ];

  List<_Tip> _strokeTips() => [
        _Tip(
          title: 'FAST — Recognise stroke instantly',
          content:
              'Use the FAST method: Face drooping, Arm weakness, Speech difficulty, '
              'Time to call emergency services. Every minute counts during a stroke. '
              'In Ghana, contact the nearest hospital with emergency services immediately.',
          priority: true,
          relevantForHighRisk: true,
          reference: 'WHO Stroke Guidelines',
        ),
        _Tip(
          title: 'Control your blood pressure',
          content:
              'High blood pressure is the single most important modifiable risk factor for stroke. '
              'Target blood pressure is below 130/80 mmHg. '
              'Monitor regularly and take medications as prescribed.',
          priority: true,
          relevantForHypertension: true,
          reference: 'JNC 8 Guidelines',
        ),
        _Tip(
          title: 'Monitor your blood pressure at home',
          content:
              'Check your blood pressure at the same time each day, '
              'ideally in the morning before taking medications. '
              'Keep a log to share with your healthcare provider.',
          reference: 'JNC 8 Guidelines',
        ),
        _Tip(
          title: 'Attend all follow-up appointments',
          content:
              'Regular check-ups allow your doctor to monitor your risk factors '
              'and adjust your treatment plan. Do not skip appointments even if you feel well.',
          reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
        ),
      ];

  List<_Tip> _dietTips() => [
        _Tip(
          title: 'Reduce salt (sodium) intake',
          content:
              'Limit salt to less than 5g per day (about 1 teaspoon). '
              'Avoid adding salt during cooking or at the table. '
              'Choose fresh foods over processed or canned foods which are high in sodium. '
              'This is especially important for blood pressure management.',
          priority: true,
          relevantForHypertension: true,
          reference: 'WHO Guidelines on Sodium Intake, 2012',
        ),
        _Tip(
          title: 'Eat heart-healthy fats',
          content:
              'Choose unsaturated fats from sources like avocado, nuts, and fish. '
              'Reduce saturated fats from red meat and dairy. '
              'Avoid trans fats found in processed and fried foods.',
          reference: 'ADA Standards of Medical Care, 2023',
        ),
        _Tip(
          title: 'Increase fibre and potassium',
          content:
              'Eat plenty of fruits, vegetables, and whole grains. '
              'Potassium-rich foods like bananas, plantain, and beans help lower blood pressure. '
              'Aim for at least 5 portions of fruit and vegetables per day.',
          reference: 'WHO Healthy Diet Guidelines',
        ),
        _Tip(
          title: 'Manage blood sugar through diet',
          content:
              'If you have diabetes, choose low-glycaemic foods such as whole grains, '
              'legumes, and non-starchy vegetables. Limit sugary drinks, white bread, '
              'and refined carbohydrates. Eat regular, balanced meals.',
          reference: 'ADA Standards of Medical Care, 2023',
        ),
      ];

  List<_Tip> _activityTips() => [
        _Tip(
          title: 'Aim for 150 minutes of moderate exercise per week',
          content:
              'The WHO recommends at least 150 minutes of moderate-intensity aerobic activity '
              'per week, such as brisk walking, cycling, or swimming. '
              'This can be broken into 30-minute sessions, 5 days a week.',
          reference: 'WHO Global Guidelines on Physical Activity, 2020',
        ),
        _Tip(
          title: 'Avoid prolonged sitting',
          content:
              'Sitting for long periods increases cardiovascular risk. '
              'Take a short walk or do light stretching every 30-60 minutes. '
              'Use stairs instead of lifts when possible.',
          reference: 'WHO Global Guidelines on Physical Activity, 2020',
        ),
        _Tip(
          title: 'Start slowly if you have been inactive',
          content:
              'If you are new to exercise or have heart conditions, start with light activity '
              'and gradually increase intensity. Consult your doctor before starting '
              'a new exercise programme, especially if you have AF or high stroke risk.',
          reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
        ),
      ];

  List<_Tip> _medicationTips() => [
        _Tip(
          title: 'Take your medications at the same time every day',
          content:
              'Consistency in medication timing maintains stable drug levels in your blood. '
              'Use a pill organiser or phone alarm to remind you. '
              'Missing doses can increase your risk of complications.',
          reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
        ),
        _Tip(
          title: 'Never stop medication without consulting your doctor',
          content:
              'Even if you feel well, stopping medications abruptly can be dangerous. '
              'Blood pressure, anticoagulant, and diabetes medications must be tapered '
              'or changed under medical supervision only.',
          priority: true,
          relevantForHighRisk: true,
          reference: 'Ghana Standard Treatment Guidelines, 7th Ed.',
        ),
        _Tip(
          title: 'Bring your medications to every appointment',
          content:
              'Show your full list of medications to every healthcare provider you see, '
              'including traditional healers and pharmacists. Some herbal remedies '
              'interact with heart and blood thinning medications.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
      ];

  List<_Tip> _lifestyleTips() => [
        _Tip(
          title: 'Stop smoking — the single most impactful change you can make',
          content:
              'Smoking doubles the risk of stroke and significantly increases AF burden. '
              'Seek support from your doctor for smoking cessation strategies. '
              'Benefits begin within 24 hours of quitting.',
          priority: true,
          relevantForHighRisk: true,
          reference: 'WHO Report on the Global Tobacco Epidemic, 2021',
        ),
        _Tip(
          title: 'Limit alcohol consumption',
          content:
              'Heavy alcohol use is a major trigger for AF episodes. '
              'Men should consume no more than 2 units per day, '
              'women no more than 1 unit per day. '
              'Avoid binge drinking entirely.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
        _Tip(
          title: 'Maintain a healthy weight',
          content:
              'Obesity increases the risk of AF, hypertension, diabetes, and stroke. '
              'Aim for a BMI between 18.5 and 24.9. '
              'Even a 5-10% weight reduction has significant cardiovascular benefits.',
          reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
        ),
      ];

  List<_Tip> _sleepTips() => [
        _Tip(
          title: 'Get 7-9 hours of quality sleep',
          content:
              'Poor sleep increases inflammation and blood pressure, raising AF and stroke risk. '
              'Establish a consistent sleep schedule. '
              'Avoid screens for at least 1 hour before bed.',
          reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
        ),
        _Tip(
          title: 'Manage stress actively',
          content:
              'Chronic stress increases cortisol levels, raising blood pressure and AF risk. '
              'Practice stress reduction techniques such as deep breathing, '
              'meditation, prayer, or regular physical activity.',
          reference: 'ESC Guidelines on Cardiovascular Disease Prevention, 2021',
        ),
        _Tip(
          title: 'Screen for sleep apnoea',
          content:
              'Obstructive sleep apnoea is strongly linked to AF and hypertension. '
              'If you snore loudly, wake up tired, or have been told you stop breathing '
              'during sleep, discuss a sleep study with your doctor.',
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
      ];

  List<_Tip> _emergencyTips() => [
        _Tip(
          title: 'Ghana emergency contacts',
          content:
              'National Ambulance Service: 0302 775 931\n'
              'Police Emergency: 191\n'
              'Fire Service: 192\n'
              'Korle Bu Teaching Hospital: 0302 665 401\n'
              'Komfo Anokye Teaching Hospital (Kumasi): 0322 022 301',
          priority: true,
          relevantForAF: true,
          relevantForHighRisk: true,
        ),
        _Tip(
          title: 'What to do during a suspected AF episode',
          content:
              'Sit or lie down in a comfortable position. '
              'Try to stay calm and breathe slowly. '
              'If symptoms include chest pain, fainting, or severe breathlessness, '
              'call emergency services immediately. '
              'Do not drive yourself to hospital.',
          relevantForAF: true,
          reference: 'ESC Guidelines on Atrial Fibrillation, 2020',
        ),
      ];
}

class _Tip {
  final String title;
  final String content;
  final String? reference;
  final bool priority;
  final bool relevantForAF;
  final bool relevantForHighRisk;
  final bool relevantForHypertension;

  _Tip({
    required this.title,
    required this.content,
    this.reference,
    this.priority = false,
    this.relevantForAF = false,
    this.relevantForHighRisk = false,
    this.relevantForHypertension = false,
  });
}