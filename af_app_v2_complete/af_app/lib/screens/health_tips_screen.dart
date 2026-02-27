// // import 'package:flutter/material.dart';
// // import '../models/measurement.dart';
// // import '../models/patient_profile.dart';
// // import '../services/storage_service.dart';
// // import '../theme/app_theme.dart';
// // import '../widgets/shared_widgets.dart';
// // import '../services/tts_service.dart';

// // // ─────────────────────────────────────────────────────────────────────────────
// // // All tips are derived from:
// // //   • WHO Cardiovascular Disease Guidelines (2021)
// // //   • ESC Guidelines for AF Management (Hindricks et al., 2021)
// // //   • JNC 8 Hypertension Guidelines (James et al., 2014)
// // //   • ADA Standards of Medical Care in Diabetes (2023)
// // //   • Ghana Standard Treatment Guidelines (7th ed., 2017)
// // // ─────────────────────────────────────────────────────────────────────────────

// // class HealthTipsScreen extends StatefulWidget {
// //   const HealthTipsScreen({super.key});
// //   @override
// //   State<HealthTipsScreen> createState() => _HealthTipsScreenState();
// // }

// // class _HealthTipsScreenState extends State<HealthTipsScreen> {
// //   Measurement? _latest;
// //   PatientProfile? _profile;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _load();
// //   }

// //   void _load() {
// //     // stop any narration whenever the tips change
// //     TtsService.instance.stop();
// //     setState(() {
// //       _latest = StorageService.getLatestMeasurement();
// //       _profile = StorageService.getProfile();
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     TtsService.instance.stop();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final tips = _buildTips();

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Health Tips'),
// //         // removed refresh/read buttons per request
// //       ),
// //       body: ListView(
// //         padding: const EdgeInsets.all(20),
// //         children: [
// //           // ── Personalised header ─────────────────────────────
// //           _latest != null
// //               ? _PersonalisedBanner(measurement: _latest!, profile: _profile)
// //               : _GeneralBanner(),
// //           const SizedBox(height: 24),

// //           // ── Source note ─────────────────────────────────────
// //           _SourceNote(),
// //           const SizedBox(height: 24),

// //           // ── Tips by category ────────────────────────────────
// //           ...tips.map((category) => Padding(
// //                 padding: const EdgeInsets.only(bottom: 24),
// //                 child: _CategorySection(category: category),
// //               )),

// //           const SizedBox(height: 40),
// //         ],
// //       ),
// //     );
// //   }

// //   // ── Build tip list ─────────────────────────────────────────
// //   List<TipCategory> _buildTips() {
// //     final hasAF = _latest?.afResult == AfResult.possibleAF;
// //     final highStroke = (_latest?.strokeRiskIndex ?? 0) >= 2;
// //     final isHyper = _profile?.hasHypertension ?? false;
// //     final isDiabetic = _profile?.hasDiabetes ?? false;
// //     final elevatedBP = (_profile?.systolicBP ?? 0) >= 140;
// //     final hasData = _latest != null;

// //     final categories = <TipCategory>[];

// //     // ── 1. AF-Specific ──────────────────────────────────────
// //     categories.add(TipCategory(
// //       icon: '❤️',
// //       title: 'Atrial Fibrillation',
// //       color: AppTheme.danger,
// //       priority: hasAF ? TipPriority.urgent : TipPriority.info,
// //       personalised: hasAF,
// //       personalisedNote: hasAF
// //           ? 'Your last reading showed a possible AF result. These steps are important for you.'
// //           : null,
// //       tips: [
// //         const HealthTip(
// //           title: 'Know the symptoms of AF',
// //           body:
// //               'AF can cause palpitations (fluttering or racing heartbeat), shortness of breath, '
// //               'dizziness, chest discomfort, or extreme fatigue. Some people feel nothing at all. '
// //               'Regular screening — as you are doing — is the best way to detect silent AF.',
// //           reference: 'ESC AF Guidelines, Hindricks et al., Eur Heart J, 2021',
// //           urgent: false,
// //         ),
// //         const HealthTip(
// //           title: 'When to go to hospital immediately',
// //           body: 'Seek emergency care at once if you experience:\n'
// //               '• Sudden numbness or weakness on one side of the face, arm, or leg\n'
// //               '• Sudden difficulty speaking or understanding speech\n'
// //               '• Sudden vision loss in one or both eyes\n'
// //               '• Sudden severe headache with no known cause\n'
// //               '• Loss of balance or coordination\n\n'
// //               'These are warning signs of stroke. Call 193 (Ghana Emergency) immediately.',
// //           reference: 'WHO Stroke Recognition Guidelines, 2020',
// //           urgent: true,
// //         ),
// //         HealthTip(
// //           title: 'Take anticoagulant medication as prescribed',
// //           body:
// //               'If your doctor has prescribed blood thinners (anticoagulants such as warfarin or apixaban), '
// //               'take them exactly as directed — even if you feel well. Missing doses significantly increases '
// //               'stroke risk in AF patients. Never stop without consulting your doctor.',
// //           reference: 'ESC AF Guidelines, 2021; Ghana STG, 2017',
// //           urgent: hasAF,
// //         ),
// //         const HealthTip(
// //           title: 'Avoid AF triggers',
// //           body:
// //               'Common triggers that can bring on or worsen AF episodes include:\n'
// //               '• Excessive caffeine (more than 2 cups of coffee or tea per day)\n'
// //               '• Alcohol — even moderate amounts can trigger episodes\n'
// //               '• Sleep deprivation and high stress\n'
// //               '• Vigorous unaccustomed exercise\n'
// //               '• Dehydration',
// //           reference: 'Larsson et al., Heart, 2016; ESC AF Guidelines, 2021',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     // ── 2. Stroke Prevention ────────────────────────────────
// //     categories.add(TipCategory(
// //       icon: '🧠',
// //       title: 'Stroke Prevention',
// //       color: const Color(0xFF7C3AED),
// //       priority: highStroke ? TipPriority.urgent : TipPriority.warning,
// //       personalised: hasData && highStroke,
// //       personalisedNote: highStroke
// //           ? 'Your stroke risk score is elevated. These steps are especially important for you.'
// //           : null,
// //       tips: [
// //         const HealthTip(
// //           title: 'FAST — Recognise stroke instantly',
// //           body: 'Use the FAST test to recognise stroke:\n'
// //               '🅵 Face — Does one side of the face droop when smiling?\n'
// //               '🅰 Arms — Can both arms be raised? Does one drift down?\n'
// //               '🆂 Speech — Is speech slurred or strange?\n'
// //               '🆃 Time — If YES to any, call 193 immediately.\n\n'
// //               'Every minute without treatment, 1.9 million brain cells die. Act fast.',
// //           reference: 'American Stroke Association, 2020; WHO, 2020',
// //           urgent: true,
// //         ),
// //         HealthTip(
// //           title: 'Control your blood pressure',
// //           body:
// //               'High blood pressure is the single biggest modifiable risk factor for stroke. '
// //               'Target blood pressure for most adults is below 130/80 mmHg. '
// //               'Take your antihypertensive medications consistently, reduce salt intake, '
// //               'exercise regularly, and attend all follow-up appointments.',
// //           reference: 'JNC 8 Guidelines, James et al., JAMA, 2014; WHO, 2021',
// //           urgent: elevatedBP,
// //         ),
// //         const HealthTip(
// //           title: 'Monitor your blood pressure at home',
// //           body:
// //               'Check your BP at the same time each morning before eating or taking medication. '
// //               'Sit quietly for 5 minutes first. Record the readings in a diary or this app '
// //               'and bring the log to every doctor visit. A consistent log helps your doctor '
// //               'make better treatment decisions.',
// //           reference: 'ESH/ESC Hypertension Guidelines, 2018',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     // ── 3. Diet & Nutrition ─────────────────────────────────
// //     categories.add(TipCategory(
// //       icon: '🥗',
// //       title: 'Diet & Nutrition',
// //       color: AppTheme.secondary,
// //       priority: TipPriority.info,
// //       personalised: isHyper || isDiabetic,
// //       personalisedNote: (isHyper && isDiabetic)
// //           ? 'Tailored for hypertension and diabetes management.'
// //           : isHyper
// //               ? 'Tailored for hypertension management.'
// //               : isDiabetic
// //                   ? 'Tailored for diabetes management.'
// //                   : null,
// //       tips: [
// //         HealthTip(
// //           title: 'Reduce salt (sodium) intake',
// //           body:
// //               'Excess salt raises blood pressure directly. Aim for less than 5g of salt per day '
// //               '(about one teaspoon). Practical steps:\n'
// //               '• Avoid adding salt at the table\n'
// //               '• Limit processed foods, tinned fish, and fast food\n'
// //               '• Use herbs, lime, and spices for flavour instead\n'
// //               '• Be aware that bouillon cubes and soy sauce are very high in sodium.',
// //           reference: 'WHO Salt Reduction Fact Sheet, 2020; Ghana STG, 2017',
// //           urgent: isHyper,
// //         ),
// //         if (isDiabetic)
// //           const HealthTip(
// //             title: 'Manage blood sugar through diet',
// //             body:
// //                 'Poorly controlled blood sugar damages blood vessels and increases stroke risk. '
// //                 'Choose:\n'
// //                 '• Complex carbohydrates — brown rice, oats, yam, beans — over white rice and white bread\n'
// //                 '• Smaller, more frequent meals to prevent glucose spikes\n'
// //                 '• Vegetables at every meal — aim for half your plate\n'
// //                 '• Limit sugary drinks, sweets, and heavily processed snacks entirely.',
// //             reference: 'ADA Standards of Medical Care, 2023',
// //             urgent: true,
// //           ),
// //         const HealthTip(
// //           title: 'Eat heart-healthy fats',
// //           body:
// //               'Replace saturated fats (palm oil, lard, fatty meat) with unsaturated fats '
// //               '(groundnuts, avocado, fish). Include oily fish (sardines, mackerel, tuna) '
// //               'at least twice a week — the omega-3 fatty acids have proven benefits for '
// //               'heart rhythm and cardiovascular health.',
// //           reference:
// //               'WHO Healthy Diet Fact Sheet, 2020; ESC Prevention Guidelines, 2021',
// //           urgent: false,
// //         ),
// //         const HealthTip(
// //           title: 'Increase fibre and potassium',
// //           body:
// //               'High fibre intake (fruits, vegetables, legumes, whole grains) lowers blood '
// //               'pressure and improves cholesterol. Potassium-rich foods (bananas, oranges, '
// //               'sweet potatoes, spinach, beans) help counteract the effect of sodium on blood '
// //               'pressure. Aim for at least 5 portions of fruits and vegetables daily.',
// //           reference: 'DASH Diet Evidence; Appel et al., NEJM, 1997; WHO, 2020',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     // ── 4. Exercise ─────────────────────────────────────────
// //     categories.add(const TipCategory(
// //       icon: '🚶',
// //       title: 'Physical Activity',
// //       color: Color(0xFF0891B2),
// //       priority: TipPriority.info,
// //       personalised: false,
// //       tips: [
// //         HealthTip(
// //           title: 'Aim for 150 minutes of moderate exercise per week',
// //           body:
// //               'The WHO recommends at least 150 minutes of moderate-intensity aerobic activity '
// //               'per week for adults — that is 30 minutes on 5 days. Suitable activities include:\n'
// //               '• Brisk walking\n'
// //               '• Swimming or water aerobics\n'
// //               '• Cycling on flat ground\n'
// //               '• Dancing\n\n'
// //               'If you have known AF or heart disease, consult your doctor before starting a '
// //               'new exercise programme.',
// //           reference:
// //               'WHO Physical Activity Guidelines, 2020; ESC AF Guidelines, 2021',
// //           urgent: false,
// //         ),
// //         HealthTip(
// //           title: 'Avoid prolonged sitting',
// //           body:
// //               'Sitting for long periods is independently associated with increased cardiovascular risk, '
// //               'even in people who exercise regularly. Break up sitting time every hour — stand up, '
// //               'walk to get water, or do a few gentle stretches.',
// //           reference: 'Biswas et al., Ann Intern Med, 2015',
// //           urgent: false,
// //         ),
// //         HealthTip(
// //           title: 'Start slowly if you have been inactive',
// //           body:
// //               'If you have been sedentary, start with 10-minute walks and increase gradually. '
// //               'Warning signs to stop exercise and seek medical attention: chest pain, severe '
// //               'shortness of breath, palpitations that do not settle, or dizziness.',
// //           reference: 'ESC Prevention Guidelines, 2021',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     // ── 5. Medication adherence ─────────────────────────────
// //     categories.add(TipCategory(
// //       icon: '💊',
// //       title: 'Medication Adherence',
// //       color: AppTheme.warning,
// //       priority: (isHyper || isDiabetic || hasAF)
// //           ? TipPriority.warning
// //           : TipPriority.info,
// //       personalised: isHyper || isDiabetic || hasAF,
// //       personalisedNote: (isHyper || isDiabetic || hasAF)
// //           ? 'Consistent medication use is critical given your conditions.'
// //           : null,
// //       tips: [
// //         const HealthTip(
// //           title: 'Take your medications at the same time every day',
// //           body:
// //               'Consistency is the most important factor in medication effectiveness. '
// //               'Set a daily alarm, link it to a daily habit (e.g. brushing teeth), '
// //               'or use a pill organiser. Missing doses of antihypertensives, '
// //               'anticoagulants, or antidiabetic medications can have serious consequences '
// //               'within 24–48 hours.',
// //           reference: 'WHO Adherence to Long-Term Therapies Report, 2003',
// //           urgent: false,
// //         ),
// //         const HealthTip(
// //           title: 'Never stop medication without consulting your doctor',
// //           body:
// //               'Stopping antihypertensives abruptly can cause rebound hypertension. '
// //               'Stopping anticoagulants suddenly increases stroke risk significantly. '
// //               'If you have side effects or cannot afford medication, speak to your '
// //               'doctor or pharmacist — there are often alternatives or support programmes available.',
// //           reference:
// //               'ESC Guidelines; Ghana National Health Insurance Authority (NHIA)',
// //           urgent: true,
// //         ),
// //         const HealthTip(
// //           title: 'Bring your medications to every appointment',
// //           body:
// //               'Bring all your medication bottles (including traditional medicine and supplements) '
// //               'to every doctor or clinic visit. Some herbal remedies interact with blood thinners '
// //               'and antidiabetic drugs. Your healthcare provider needs a complete picture.',
// //           reference: 'Ghana STG, 2017; WHO Medication Safety Guidelines',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     // ── 6. Alcohol & Smoking ────────────────────────────────
// //     categories.add(TipCategory(
// //       icon: '🚭',
// //       title: 'Alcohol & Smoking',
// //       color: AppTheme.danger,
// //       priority: TipPriority.warning,
// //       personalised: false,
// //       tips: [
// //         const HealthTip(
// //           title: 'Stop smoking — the single most impactful change you can make',
// //           body:
// //               'Smoking doubles the risk of stroke and significantly increases AF risk. '
// //               'The benefits of stopping begin within 24 hours (blood pressure and carbon '
// //               'monoxide levels normalise) and continue for years. '
// //               'Seek support from your doctor — nicotine replacement therapy is available '
// //               'and significantly improves quit rates.',
// //           reference:
// //               'WHO Tobacco Fact Sheet, 2021; ESC Prevention Guidelines, 2021',
// //           urgent: true,
// //         ),
// //         HealthTip(
// //           title: 'Limit or eliminate alcohol',
// //           body:
// //               'Even moderate alcohol consumption is associated with increased AF risk. '
// //               'Heavy drinking raises blood pressure and can trigger AF episodes directly '
// //               '(known as "holiday heart syndrome"). '
// //               'The safest approach for cardiac patients is to avoid alcohol entirely. '
// //               'If you drink, limit to no more than 1 standard drink per day for women '
// //               'and 2 for men.',
// //           reference:
// //               'Larsson et al., Heart, 2016; Voskoboinik et al., JACC, 2020',
// //           urgent: hasAF,
// //         ),
// //       ],
// //     ));

// //     // ── 7. Sleep & Stress ───────────────────────────────────
// //     categories.add(const TipCategory(
// //       icon: '😴',
// //       title: 'Sleep & Stress',
// //       color: Color(0xFF6366F1),
// //       priority: TipPriority.info,
// //       personalised: false,
// //       tips: [
// //         HealthTip(
// //           title: 'Prioritise 7–9 hours of quality sleep',
// //           body:
// //               'Poor sleep is associated with increased blood pressure, worsened blood sugar '
// //               'control, and higher AF episode frequency. Sleep apnoea — where breathing '
// //               'temporarily stops during sleep — is particularly common in AF patients and '
// //               'worsens outcomes significantly. Signs include loud snoring, waking unrefreshed, '
// //               'or excessive daytime sleepiness. Mention this to your doctor.',
// //           reference: 'Gami et al., JACC, 2004; ESC AF Guidelines, 2021',
// //           urgent: false,
// //         ),
// //         HealthTip(
// //           title: 'Manage stress actively',
// //           body:
// //               'Chronic psychological stress activates the sympathetic nervous system, '
// //               'raises blood pressure, and can trigger AF episodes. Effective, evidence-based '
// //               'stress reduction techniques include:\n'
// //               '• Diaphragmatic (belly) breathing — 4 seconds in, hold 4, out 6\n'
// //               '• Daily 10-minute walks in nature\n'
// //               '• Social connection — talking to trusted family or friends\n'
// //               '• Prayer or mindfulness practice\n'
// //               '• Reducing workload where possible',
// //           reference:
// //               'Lampert et al., Circulation, 2014; ESC Prevention Guidelines, 2021',
// //           urgent: false,
// //         ),
// //       ],
// //     ));

// //     return categories;
// //   }
// // }

// // // ── Personalised banner ────────────────────────────────────────
// // class _PersonalisedBanner extends StatelessWidget {
// //   final Measurement measurement;
// //   final PatientProfile? profile;

// //   const _PersonalisedBanner({required this.measurement, required this.profile});

// //   @override
// //   Widget build(BuildContext context) {
// //     final afColor = measurement.afResult == AfResult.possibleAF
// //         ? AppTheme.danger
// //         : measurement.afResult == AfResult.inconclusive
// //             ? AppTheme.warning
// //             : AppTheme.secondary;

// //     return Container(
// //       padding: const EdgeInsets.all(18),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           colors: [AppTheme.primary, AppTheme.primary.withBlue(210)],
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //         ),
// //         borderRadius: BorderRadius.circular(18),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text('Personalised for your results',
// //               style: TextStyle(color: Colors.white70, fontSize: 12)),
// //           const SizedBox(height: 10),
// //           Row(children: [
// //             AfResultBadge(result: measurement.afResult, large: true),
// //             const SizedBox(width: 10),
// //             StrokeRiskChip(
// //               risk: measurement.strokeRisk,
// //               score: measurement.strokeScore,
// //               large: true,
// //             ),
// //           ]),
// //           const SizedBox(height: 10),
// //           const Text(
// //             'Tips marked ★ are most relevant based on your latest reading.',
// //             style: TextStyle(color: Colors.white70, fontSize: 11),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _GeneralBanner extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(18),
// //       decoration: BoxDecoration(
// //         color: AppTheme.secondary.withValues(alpha: 0.08),
// //         borderRadius: BorderRadius.circular(16),
// //         border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 48,
// //             height: 48,
// //             decoration: BoxDecoration(
// //               color: AppTheme.secondary.withValues(alpha: 0.15),
// //               shape: BoxShape.circle,
// //             ),
// //             child: const Icon(Icons.health_and_safety_outlined,
// //                 color: AppTheme.secondary, size: 26),
// //           ),
// //           const SizedBox(width: 14),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('General Health Guidelines',
// //                     style: Theme.of(context)
// //                         .textTheme
// //                         .titleMedium
// //                         ?.copyWith(color: AppTheme.secondary)),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   'Evidence-based tips for heart health, hypertension, and diabetes. '
// //                   'Connect your device to get personalised recommendations.',
// //                   style: Theme.of(context)
// //                       .textTheme
// //                       .bodyMedium
// //                       ?.copyWith(fontSize: 12),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Source note ────────────────────────────────────────────────
// // class _SourceNote extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: AppTheme.border.withValues(alpha: 0.5),
// //         borderRadius: BorderRadius.circular(10),
// //       ),
// //       child: Row(
// //         children: [
// //           const Icon(Icons.verified_outlined,
// //               size: 16, color: AppTheme.textSecondary),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Row(children: [
// //               Expanded(
// //                 child: Text(
// //                   'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
// //                   'This app does not replace professional medical advice.',
// //                   style: Theme.of(context)
// //                       .textTheme
// //                       .bodyMedium
// //                       ?.copyWith(fontSize: 10, color: AppTheme.textSecondary),
// //                 ),
// //               ),
// //               const ReadAloudIcon(
// //                 text:
// //                     'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
// //                     'This app does not replace professional medical advice.',
// //               ),
// //             ]),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ── Category section ───────────────────────────────────────────
// // class _CategorySection extends StatelessWidget {
// //   final TipCategory category;
// //   const _CategorySection({required this.category});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         // Category header
// //         Row(children: [
// //           Text(category.icon, style: const TextStyle(fontSize: 20)),
// //           const SizedBox(width: 10),
// //           Text(category.title, style: Theme.of(context).textTheme.titleMedium),
// //           const SizedBox(width: 8),
// //           if (category.personalised)
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //               decoration: BoxDecoration(
// //                 color: AppTheme.primary.withValues(alpha: 0.1),
// //                 borderRadius: BorderRadius.circular(100),
// //               ),
// //               child: const Text('★ Personalised',
// //                   style: TextStyle(
// //                       fontSize: 10,
// //                       fontWeight: FontWeight.w700,
// //                       color: AppTheme.primary)),
// //             ),
// //         ]),

// //         // Personalised note
// //         if (category.personalisedNote != null) ...[
// //           const SizedBox(height: 6),
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //             decoration: BoxDecoration(
// //               color: category.color.withValues(alpha: 0.08),
// //               borderRadius: BorderRadius.circular(8),
// //               border: Border.all(color: category.color.withValues(alpha: 0.3)),
// //             ),
// //             child: Text(category.personalisedNote!,
// //                 style: TextStyle(
// //                     fontSize: 12,
// //                     color: category.color,
// //                     fontWeight: FontWeight.w500)),
// //           ),
// //         ],

// //         const SizedBox(height: 12),
// //         // Tips list
// //         ...category.tips.map((tip) => Padding(
// //               padding: const EdgeInsets.only(bottom: 10),
// //               child: _TipCard(tip: tip, accent: category.color),
// //             )),
// //       ],
// //     );
// //   }
// // }

// // // ── Individual tip card ────────────────────────────────────────
// // class _TipCard extends StatefulWidget {
// //   final HealthTip tip;
// //   final Color accent;
// //   const _TipCard({required this.tip, required this.accent});

// //   @override
// //   State<_TipCard> createState() => _TipCardState();
// // }

// // class _TipCardState extends State<_TipCard> {
// //   bool _expanded = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () => setState(() => _expanded = !_expanded),
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 200),
// //         padding: const EdgeInsets.all(16),
// //         decoration: BoxDecoration(
// //           color: widget.tip.urgent
// //               ? widget.accent.withValues(alpha: 0.06)
// //               : AppTheme.card,
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(
// //             color: widget.tip.urgent
// //                 ? widget.accent.withValues(alpha: 0.35)
// //                 : AppTheme.border,
// //             width: widget.tip.urgent ? 1.5 : 1,
// //           ),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(children: [
// //               if (widget.tip.urgent) ...[
// //                 Icon(Icons.priority_high_rounded,
// //                     size: 16, color: widget.accent),
// //                 const SizedBox(width: 4),
// //               ],
// //               Expanded(
// //                 child: Text(widget.tip.title,
// //                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //                           fontSize: 14,
// //                           color: widget.tip.urgent
// //                               ? widget.accent
// //                               : AppTheme.textPrimary,
// //                         )),
// //               ),
// //               ReadAloudIcon(text: '${widget.tip.title}. ${widget.tip.body}'),
// //               const SizedBox(width: 4),
// //               Icon(
// //                 _expanded
// //                     ? Icons.keyboard_arrow_up_rounded
// //                     : Icons.keyboard_arrow_down_rounded,
// //                 color: AppTheme.textSecondary,
// //                 size: 20,
// //               ),
// //             ]),
// //             if (_expanded) ...[
// //               const SizedBox(height: 10),
// //               Text(widget.tip.body,
// //                   style: Theme.of(context)
// //                       .textTheme
// //                       .bodyMedium
// //                       ?.copyWith(fontSize: 13, height: 1.55)),
// //               const SizedBox(height: 8),
// //               Row(children: [
// //                 const Icon(Icons.article_outlined,
// //                     size: 12, color: AppTheme.textSecondary),
// //                 const SizedBox(width: 4),
// //                 Expanded(
// //                   child: Text('Source: ${widget.tip.reference}',
// //                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                           fontSize: 10,
// //                           color: AppTheme.textSecondary,
// //                           fontStyle: FontStyle.italic)),
// //                 ),
// //               ]),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ── Data classes ───────────────────────────────────────────────
// // enum TipPriority { urgent, warning, info }

// // class TipCategory {
// //   final String icon;
// //   final String title;
// //   final Color color;
// //   final TipPriority priority;
// //   final bool personalised;
// //   final String? personalisedNote;
// //   final List<HealthTip> tips;

// //   const TipCategory({
// //     required this.icon,
// //     required this.title,
// //     required this.color,
// //     required this.priority,
// //     required this.personalised,
// //     required this.tips,
// //     this.personalisedNote,
// //   });
// // }

// // class HealthTip {
// //   final String title;
// //   final String body;
// //   final String reference;
// //   final bool urgent;

// //   const HealthTip({
// //     required this.title,
// //     required this.body,
// //     required this.reference,
// //     required this.urgent,
// //   });
// // }



// import 'package:flutter/material.dart';
// import '../models/measurement.dart';
// import '../models/patient_profile.dart';
// import '../services/storage_service.dart';
// import '../theme/app_theme.dart';
// import '../widgets/shared_widgets.dart';
// import '../services/tts_service.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // All tips are derived from:
// //   • WHO Cardiovascular Disease Guidelines (2021)
// //   • ESC Guidelines for AF Management (Hindricks et al., 2021)
// //   • JNC 8 Hypertension Guidelines (James et al., 2014)
// //   • ADA Standards of Medical Care in Diabetes (2023)
// //   • Ghana Standard Treatment Guidelines (7th ed., 2017)
// // ─────────────────────────────────────────────────────────────────────────────

// class HealthTipsScreen extends StatefulWidget {
//   const HealthTipsScreen({super.key});
//   @override
//   State<HealthTipsScreen> createState() => _HealthTipsScreenState();
// }

// class _HealthTipsScreenState extends State<HealthTipsScreen> {
//   Measurement? _latest;
//   PatientProfile? _profile;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   void _load() {
//     // stop any narration whenever the tips change
//     TtsService.instance.stop();
//     setState(() {
//       _latest = StorageService.getLatestMeasurement();
//       _profile = StorageService.getProfile();
//     });
//   }

//   @override
//   void dispose() {
//     TtsService.instance.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tips = _buildTips();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Health Tips'),
//         // removed refresh/read buttons per request
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           // ── Personalised header ─────────────────────────────
//           _latest != null
//               ? _PersonalisedBanner(measurement: _latest!, profile: _profile)
//               : _GeneralBanner(),
//           const SizedBox(height: 24),

//           // ── Source note ─────────────────────────────────────
//           _SourceNote(),
//           const SizedBox(height: 24),

//           // ── Tips by category ────────────────────────────────
//           ...tips.map((category) => Padding(
//                 padding: const EdgeInsets.only(bottom: 24),
//                 child: _CategorySection(category: category),
//               )),

//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // ── Build tip list ─────────────────────────────────────────
//   List<TipCategory> _buildTips() {
//     final hasAF = _latest?.afResult == AfResult.possibleAF;
//     final highStroke = (_latest?.strokeRiskIndex ?? 0) >= 2;
//     final isHyper = _profile?.hasHypertension ?? false;
//     final isDiabetic = _profile?.hasDiabetes ?? false;
//     final elevatedBP = (_profile?.systolicBP ?? 0) >= 140;
//     final hasData = _latest != null;

//     final categories = <TipCategory>[];

//     // ── 1. AF-Specific ──────────────────────────────────────
//     categories.add(TipCategory(
//       icon: 'heart',
//       title: 'Atrial Fibrillation',
//       color: AppTheme.danger,
//       priority: hasAF ? TipPriority.urgent : TipPriority.info,
//       personalised: hasAF,
//       personalisedNote: hasAF
//           ? 'Your last reading showed a possible AF result. These steps are important for you.'
//           : null,
//       tips: [
//         const HealthTip(
//           title: 'Know the symptoms of AF',
//           body:
//               'AF can cause palpitations (fluttering or racing heartbeat), shortness of breath, '
//               'dizziness, chest discomfort, or extreme fatigue. Some people feel nothing at all. '
//               'Regular screening — as you are doing — is the best way to detect silent AF.',
//           reference: 'ESC AF Guidelines, Hindricks et al., Eur Heart J, 2021',
//           urgent: false,
//         ),
//         const HealthTip(
//           title: 'When to go to hospital immediately',
//           body: 'Seek emergency care at once if you experience:\n'
//               '• Sudden numbness or weakness on one side of the face, arm, or leg\n'
//               '• Sudden difficulty speaking or understanding speech\n'
//               '• Sudden vision loss in one or both eyes\n'
//               '• Sudden severe headache with no known cause\n'
//               '• Loss of balance or coordination\n\n'
//               'These are warning signs of stroke. Call 193 (Ghana Emergency) immediately.',
//           reference: 'WHO Stroke Recognition Guidelines, 2020',
//           urgent: true,
//         ),
//         HealthTip(
//           title: 'Take anticoagulant medication as prescribed',
//           body:
//               'If your doctor has prescribed blood thinners (anticoagulants such as warfarin or apixaban), '
//               'take them exactly as directed — even if you feel well. Missing doses significantly increases '
//               'stroke risk in AF patients. Never stop without consulting your doctor.',
//           reference: 'ESC AF Guidelines, 2021; Ghana STG, 2017',
//           urgent: hasAF,
//         ),
//         const HealthTip(
//           title: 'Avoid AF triggers',
//           body:
//               'Common triggers that can bring on or worsen AF episodes include:\n'
//               '• Excessive caffeine (more than 2 cups of coffee or tea per day)\n'
//               '• Alcohol — even moderate amounts can trigger episodes\n'
//               '• Sleep deprivation and high stress\n'
//               '• Vigorous unaccustomed exercise\n'
//               '• Dehydration',
//           reference: 'Larsson et al., Heart, 2016; ESC AF Guidelines, 2021',
//           urgent: false,
//         ),
//       ],
//     ));

//     // ── 2. Stroke Prevention ────────────────────────────────
//     categories.add(TipCategory(
//       icon: 'brain',
//       title: 'Stroke Prevention',
//       color: const Color(0xFF7C3AED),
//       priority: highStroke ? TipPriority.urgent : TipPriority.warning,
//       personalised: hasData && highStroke,
//       personalisedNote: highStroke
//           ? 'Your stroke risk score is elevated. These steps are especially important for you.'
//           : null,
//       tips: [
//         const HealthTip(
//           title: 'FAST — Recognise stroke instantly',
//           body: 'Use the FAST test to recognise stroke:\n'
//               '🅵 Face — Does one side of the face droop when smiling?\n'
//               '🅰 Arms — Can both arms be raised? Does one drift down?\n'
//               '🆂 Speech — Is speech slurred or strange?\n'
//               '🆃 Time — If YES to any, call 193 immediately.\n\n'
//               'Every minute without treatment, 1.9 million brain cells die. Act fast.',
//           reference: 'American Stroke Association, 2020; WHO, 2020',
//           urgent: true,
//         ),
//         HealthTip(
//           title: 'Control your blood pressure',
//           body:
//               'High blood pressure is the single biggest modifiable risk factor for stroke. '
//               'Target blood pressure for most adults is below 130/80 mmHg. '
//               'Take your antihypertensive medications consistently, reduce salt intake, '
//               'exercise regularly, and attend all follow-up appointments.',
//           reference: 'JNC 8 Guidelines, James et al., JAMA, 2014; WHO, 2021',
//           urgent: elevatedBP,
//         ),
//         const HealthTip(
//           title: 'Monitor your blood pressure at home',
//           body:
//               'Check your BP at the same time each morning before eating or taking medication. '
//               'Sit quietly for 5 minutes first. Record the readings in a diary or this app '
//               'and bring the log to every doctor visit. A consistent log helps your doctor '
//               'make better treatment decisions.',
//           reference: 'ESH/ESC Hypertension Guidelines, 2018',
//           urgent: false,
//         ),
//       ],
//     ));

//     // ── 3. Diet & Nutrition ─────────────────────────────────
//     categories.add(TipCategory(
//       icon: 'nutrition',
//       title: 'Diet & Nutrition',
//       color: AppTheme.secondary,
//       priority: TipPriority.info,
//       personalised: isHyper || isDiabetic,
//       personalisedNote: (isHyper && isDiabetic)
//           ? 'Tailored for hypertension and diabetes management.'
//           : isHyper
//               ? 'Tailored for hypertension management.'
//               : isDiabetic
//                   ? 'Tailored for diabetes management.'
//                   : null,
//       tips: [
//         HealthTip(
//           title: 'Reduce salt (sodium) intake',
//           body:
//               'Excess salt raises blood pressure directly. Aim for less than 5g of salt per day '
//               '(about one teaspoon). Practical steps:\n'
//               '• Avoid adding salt at the table\n'
//               '• Limit processed foods, tinned fish, and fast food\n'
//               '• Use herbs, lime, and spices for flavour instead\n'
//               '• Be aware that bouillon cubes and soy sauce are very high in sodium.',
//           reference: 'WHO Salt Reduction Fact Sheet, 2020; Ghana STG, 2017',
//           urgent: isHyper,
//         ),
//         if (isDiabetic)
//           const HealthTip(
//             title: 'Manage blood sugar through diet',
//             body:
//                 'Poorly controlled blood sugar damages blood vessels and increases stroke risk. '
//                 'Choose:\n'
//                 '• Complex carbohydrates — brown rice, oats, yam, beans — over white rice and white bread\n'
//                 '• Smaller, more frequent meals to prevent glucose spikes\n'
//                 '• Vegetables at every meal — aim for half your plate\n'
//                 '• Limit sugary drinks, sweets, and heavily processed snacks entirely.',
//             reference: 'ADA Standards of Medical Care, 2023',
//             urgent: true,
//           ),
//         const HealthTip(
//           title: 'Eat heart-healthy fats',
//           body:
//               'Replace saturated fats (palm oil, lard, fatty meat) with unsaturated fats '
//               '(groundnuts, avocado, fish). Include oily fish (sardines, mackerel, tuna) '
//               'at least twice a week — the omega-3 fatty acids have proven benefits for '
//               'heart rhythm and cardiovascular health.',
//           reference:
//               'WHO Healthy Diet Fact Sheet, 2020; ESC Prevention Guidelines, 2021',
//           urgent: false,
//         ),
//         const HealthTip(
//           title: 'Increase fibre and potassium',
//           body:
//               'High fibre intake (fruits, vegetables, legumes, whole grains) lowers blood '
//               'pressure and improves cholesterol. Potassium-rich foods (bananas, oranges, '
//               'sweet potatoes, spinach, beans) help counteract the effect of sodium on blood '
//               'pressure. Aim for at least 5 portions of fruits and vegetables daily.',
//           reference: 'DASH Diet Evidence; Appel et al., NEJM, 1997; WHO, 2020',
//           urgent: false,
//         ),
//       ],
//     ));

//     // ── 4. Exercise ─────────────────────────────────────────
//     categories.add(const TipCategory(
//       icon: 'walk',
//       title: 'Physical Activity',
//       color: Color(0xFF0891B2),
//       priority: TipPriority.info,
//       personalised: false,
//       tips: [
//         HealthTip(
//           title: 'Aim for 150 minutes of moderate exercise per week',
//           body:
//               'The WHO recommends at least 150 minutes of moderate-intensity aerobic activity '
//               'per week for adults — that is 30 minutes on 5 days. Suitable activities include:\n'
//               '• Brisk walking\n'
//               '• Swimming or water aerobics\n'
//               '• Cycling on flat ground\n'
//               '• Dancing\n\n'
//               'If you have known AF or heart disease, consult your doctor before starting a '
//               'new exercise programme.',
//           reference:
//               'WHO Physical Activity Guidelines, 2020; ESC AF Guidelines, 2021',
//           urgent: false,
//         ),
//         HealthTip(
//           title: 'Avoid prolonged sitting',
//           body:
//               'Sitting for long periods is independently associated with increased cardiovascular risk, '
//               'even in people who exercise regularly. Break up sitting time every hour — stand up, '
//               'walk to get water, or do a few gentle stretches.',
//           reference: 'Biswas et al., Ann Intern Med, 2015',
//           urgent: false,
//         ),
//         HealthTip(
//           title: 'Start slowly if you have been inactive',
//           body:
//               'If you have been sedentary, start with 10-minute walks and increase gradually. '
//               'Warning signs to stop exercise and seek medical attention: chest pain, severe '
//               'shortness of breath, palpitations that do not settle, or dizziness.',
//           reference: 'ESC Prevention Guidelines, 2021',
//           urgent: false,
//         ),
//       ],
//     ));

//     // ── 5. Medication adherence ─────────────────────────────
//     categories.add(TipCategory(
//       icon: 'pill',
//       title: 'Medication Adherence',
//       color: AppTheme.warning,
//       priority: (isHyper || isDiabetic || hasAF)
//           ? TipPriority.warning
//           : TipPriority.info,
//       personalised: isHyper || isDiabetic || hasAF,
//       personalisedNote: (isHyper || isDiabetic || hasAF)
//           ? 'Consistent medication use is critical given your conditions.'
//           : null,
//       tips: [
//         const HealthTip(
//           title: 'Take your medications at the same time every day',
//           body:
//               'Consistency is the most important factor in medication effectiveness. '
//               'Set a daily alarm, link it to a daily habit (e.g. brushing teeth), '
//               'or use a pill organiser. Missing doses of antihypertensives, '
//               'anticoagulants, or antidiabetic medications can have serious consequences '
//               'within 24–48 hours.',
//           reference: 'WHO Adherence to Long-Term Therapies Report, 2003',
//           urgent: false,
//         ),
//         const HealthTip(
//           title: 'Never stop medication without consulting your doctor',
//           body:
//               'Stopping antihypertensives abruptly can cause rebound hypertension. '
//               'Stopping anticoagulants suddenly increases stroke risk significantly. '
//               'If you have side effects or cannot afford medication, speak to your '
//               'doctor or pharmacist — there are often alternatives or support programmes available.',
//           reference:
//               'ESC Guidelines; Ghana National Health Insurance Authority (NHIA)',
//           urgent: true,
//         ),
//         const HealthTip(
//           title: 'Bring your medications to every appointment',
//           body:
//               'Bring all your medication bottles (including traditional medicine and supplements) '
//               'to every doctor or clinic visit. Some herbal remedies interact with blood thinners '
//               'and antidiabetic drugs. Your healthcare provider needs a complete picture.',
//           reference: 'Ghana STG, 2017; WHO Medication Safety Guidelines',
//           urgent: false,
//         ),
//       ],
//     ));

//     // ── 6. Alcohol & Smoking ────────────────────────────────
//     categories.add(TipCategory(
//       icon: 'no_smoking',
//       title: 'Alcohol & Smoking',
//       color: AppTheme.danger,
//       priority: TipPriority.warning,
//       personalised: false,
//       tips: [
//         const HealthTip(
//           title: 'Stop smoking — the single most impactful change you can make',
//           body:
//               'Smoking doubles the risk of stroke and significantly increases AF risk. '
//               'The benefits of stopping begin within 24 hours (blood pressure and carbon '
//               'monoxide levels normalise) and continue for years. '
//               'Seek support from your doctor — nicotine replacement therapy is available '
//               'and significantly improves quit rates.',
//           reference:
//               'WHO Tobacco Fact Sheet, 2021; ESC Prevention Guidelines, 2021',
//           urgent: true,
//         ),
//         HealthTip(
//           title: 'Limit or eliminate alcohol',
//           body:
//               'Even moderate alcohol consumption is associated with increased AF risk. '
//               'Heavy drinking raises blood pressure and can trigger AF episodes directly '
//               '(known as "holiday heart syndrome"). '
//               'The safest approach for cardiac patients is to avoid alcohol entirely. '
//               'If you drink, limit to no more than 1 standard drink per day for women '
//               'and 2 for men.',
//           reference:
//               'Larsson et al., Heart, 2016; Voskoboinik et al., JACC, 2020',
//           urgent: hasAF,
//         ),
//       ],
//     ));

//     // ── 7. Sleep & Stress ───────────────────────────────────
//     categories.add(const TipCategory(
//       icon: 'sleep',
//       title: 'Sleep & Stress',
//       color: Color(0xFF6366F1),
//       priority: TipPriority.info,
//       personalised: false,
//       tips: [
//         HealthTip(
//           title: 'Prioritise 7–9 hours of quality sleep',
//           body:
//               'Poor sleep is associated with increased blood pressure, worsened blood sugar '
//               'control, and higher AF episode frequency. Sleep apnoea — where breathing '
//               'temporarily stops during sleep — is particularly common in AF patients and '
//               'worsens outcomes significantly. Signs include loud snoring, waking unrefreshed, '
//               'or excessive daytime sleepiness. Mention this to your doctor.',
//           reference: 'Gami et al., JACC, 2004; ESC AF Guidelines, 2021',
//           urgent: false,
//         ),
//         HealthTip(
//           title: 'Manage stress actively',
//           body:
//               'Chronic psychological stress activates the sympathetic nervous system, '
//               'raises blood pressure, and can trigger AF episodes. Effective, evidence-based '
//               'stress reduction techniques include:\n'
//               '• Diaphragmatic (belly) breathing — 4 seconds in, hold 4, out 6\n'
//               '• Daily 10-minute walks in nature\n'
//               '• Social connection — talking to trusted family or friends\n'
//               '• Prayer or mindfulness practice\n'
//               '• Reducing workload where possible',
//           reference:
//               'Lampert et al., Circulation, 2014; ESC Prevention Guidelines, 2021',
//           urgent: false,
//         ),
//       ],
//     ));

//     return categories;
//   }
// }

// // ── Personalised banner ────────────────────────────────────────
// class _PersonalisedBanner extends StatelessWidget {
//   final Measurement measurement;
//   final PatientProfile? profile;

//   const _PersonalisedBanner({required this.measurement, required this.profile});

//   @override
//   Widget build(BuildContext context) {
//     final afColor = measurement.afResult == AfResult.possibleAF
//         ? AppTheme.danger
//         : measurement.afResult == AfResult.inconclusive
//             ? AppTheme.warning
//             : AppTheme.secondary;

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppTheme.primary, AppTheme.primary.withBlue(210)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Personalised for your results',
//               style: TextStyle(color: Colors.white70, fontSize: 12)),
//           const SizedBox(height: 10),
//           Row(children: [
//             AfResultBadge(result: measurement.afResult, large: true),
//             const SizedBox(width: 10),
//             StrokeRiskChip(
//               risk: measurement.strokeRisk,
//               score: measurement.strokeScore,
//               large: true,
//             ),
//           ]),
//           const SizedBox(height: 10),
//           const Text(
//             'Tips marked ★ are most relevant based on your latest reading.',
//             style: TextStyle(color: Colors.white70, fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _GeneralBanner extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppTheme.secondary.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: AppTheme.secondary.withValues(alpha: 0.15),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.health_and_safety_outlined,
//                 color: AppTheme.secondary, size: 26),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('General Health Guidelines',
//                     style: Theme.of(context)
//                         .textTheme
//                         .titleMedium
//                         ?.copyWith(color: AppTheme.secondary)),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Evidence-based tips for heart health, hypertension, and diabetes. '
//                   'Connect your device to get personalised recommendations.',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Source note ────────────────────────────────────────────────
// class _SourceNote extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppTheme.border.withValues(alpha: 0.5),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.verified_outlined,
//               size: 16, color: AppTheme.textSecondary),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Row(children: [
//               Expanded(
//                 child: Text(
//                   'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
//                   'This app does not replace professional medical advice.',
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 10, color: AppTheme.textSecondary),
//                 ),
//               ),
//               const ReadAloudIcon(
//                 text:
//                     'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
//                     'This app does not replace professional medical advice.',
//               ),
//             ]),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Category section ───────────────────────────────────────────
// class _CategorySection extends StatelessWidget {
//   final TipCategory category;
//   const _CategorySection({required this.category});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Category header
//         Row(children: [
//           _iconFromKey(category.icon),
//           const SizedBox(width: 10),
//           Text(category.title, style: Theme.of(context).textTheme.titleMedium),
//           const SizedBox(width: 8),
//           if (category.personalised)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: AppTheme.primary.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(100),
//               ),
//               child: const Text('★ Personalised',
//                   style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w700,
//                       color: AppTheme.primary)),
//             ),
//         ]),

//         // Personalised note
//         if (category.personalisedNote != null) ...[
//           const SizedBox(height: 6),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: category.color.withValues(alpha: 0.08),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: category.color.withValues(alpha: 0.3)),
//             ),
//             child: Text(category.personalisedNote!,
//                 style: TextStyle(
//                     fontSize: 12,
//                     color: category.color,
//                     fontWeight: FontWeight.w500)),
//           ),
//         ],

//         const SizedBox(height: 12),
//         // Tips list
//         ...category.tips.map((tip) => Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: _TipCard(tip: tip, accent: category.color),
//             )),
//       ],
//     );
//   }
// }

// // ── Individual tip card ────────────────────────────────────────
// class _TipCard extends StatefulWidget {
//   final HealthTip tip;
//   final Color accent;
//   const _TipCard({required this.tip, required this.accent});

//   @override
//   State<_TipCard> createState() => _TipCardState();
// }

// class _TipCardState extends State<_TipCard> {
//   bool _expanded = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => setState(() => _expanded = !_expanded),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: widget.tip.urgent
//               ? widget.accent.withValues(alpha: 0.06)
//               : AppTheme.card,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: widget.tip.urgent
//                 ? widget.accent.withValues(alpha: 0.35)
//                 : AppTheme.border,
//             width: widget.tip.urgent ? 1.5 : 1,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(children: [
//               if (widget.tip.urgent) ...[
//                 Icon(Icons.priority_high_rounded,
//                     size: 16, color: widget.accent),
//                 const SizedBox(width: 4),
//               ],
//               Expanded(
//                 child: Text(widget.tip.title,
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontSize: 14,
//                           color: widget.tip.urgent
//                               ? widget.accent
//                               : AppTheme.textPrimary,
//                         )),
//               ),
//               ReadAloudIcon(text: '${widget.tip.title}. ${widget.tip.body}'),
//               const SizedBox(width: 4),
//               Icon(
//                 _expanded
//                     ? Icons.keyboard_arrow_up_rounded
//                     : Icons.keyboard_arrow_down_rounded,
//                 color: AppTheme.textSecondary,
//                 size: 20,
//               ),
//             ]),
//             if (_expanded) ...[
//               const SizedBox(height: 10),
//               Text(widget.tip.body,
//                   style: Theme.of(context)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(fontSize: 13, height: 1.55)),
//               const SizedBox(height: 8),
//               Row(children: [
//                 const Icon(Icons.article_outlined,
//                     size: 12, color: AppTheme.textSecondary),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text('Source: ${widget.tip.reference}',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           fontSize: 10,
//                           color: AppTheme.textSecondary,
//                           fontStyle: FontStyle.italic)),
//                 ),
//               ]),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Data classes ───────────────────────────────────────────────
// enum TipPriority { urgent, warning, info }

// class TipCategory {
//   final String icon;
//   final String title;
//   final Color color;
//   final TipPriority priority;
//   final bool personalised;
//   final String? personalisedNote;
//   final List<HealthTip> tips;

//   const TipCategory({
//     required this.icon,
//     required this.title,
//     required this.color,
//     required this.priority,
//     required this.personalised,
//     required this.tips,
//     this.personalisedNote,
//   });
// }

// class HealthTip {
//   final String title;
//   final String body;
//   final String reference;
//   final bool urgent;

//   const HealthTip({
//     required this.title,
//     required this.body,
//     required this.reference,
//     required this.urgent,
//   });

// // Maps icon key strings to Material icons (replaces emoji for cross-platform compat)
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
//       size: 20, color: AppTheme.primary);
// }

// }



import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/tts_service.dart';


class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});
  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  Measurement? _latest;
  PatientProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // stop any narration whenever the tips change
    TtsService.instance.stop();
    setState(() {
      _latest = StorageService.getLatestMeasurement();
      _profile = StorageService.getProfile();
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _buildTips();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips'),
        // removed refresh/read buttons per request
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Personalised header ─────────────────────────────
          _latest != null
              ? _PersonalisedBanner(measurement: _latest!, profile: _profile)
              : _GeneralBanner(),
          const SizedBox(height: 24),

          // ── Source note ─────────────────────────────────────
          _SourceNote(),
          const SizedBox(height: 24),

          // ── Tips by category ────────────────────────────────
          ...tips.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _CategorySection(category: category),
              )),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Build tip list ─────────────────────────────────────────
  List<TipCategory> _buildTips() {
    final hasAF = _latest?.afResult == AfResult.possibleAF;
    final highStroke = (_latest?.strokeRiskIndex ?? 0) >= 2;
    final isHyper = _profile?.hasHypertension ?? false;
    final isDiabetic = _profile?.hasDiabetes ?? false;
    final elevatedBP = (_profile?.systolicBP ?? 0) >= 140;
    final hasData = _latest != null;

    final categories = <TipCategory>[];

    // ── 1. AF-Specific ──────────────────────────────────────
    categories.add(TipCategory(
      icon: 'heart',
      title: 'Atrial Fibrillation',
      color: AppTheme.danger,
      priority: hasAF ? TipPriority.urgent : TipPriority.info,
      personalised: hasAF,
      personalisedNote: hasAF
          ? 'Your last reading showed a possible AF result. These steps are important for you.'
          : null,
      tips: [
        const HealthTip(
          title: 'Know the symptoms of AF',
          body:
              'AF can cause palpitations (fluttering or racing heartbeat), shortness of breath, '
              'dizziness, chest discomfort, or extreme fatigue. Some people feel nothing at all. '
              'Regular screening — as you are doing — is the best way to detect silent AF.',
          reference: 'ESC AF Guidelines, Hindricks et al., Eur Heart J, 2021',
          urgent: false,
        ),
        const HealthTip(
          title: 'When to go to hospital immediately',
          body: 'Seek emergency care at once if you experience:\n'
              '• Sudden numbness or weakness on one side of the face, arm, or leg\n'
              '• Sudden difficulty speaking or understanding speech\n'
              '• Sudden vision loss in one or both eyes\n'
              '• Sudden severe headache with no known cause\n'
              '• Loss of balance or coordination\n\n'
              'These are warning signs of stroke. Call 193 (Ghana Emergency) immediately.',
          reference: 'WHO Stroke Recognition Guidelines, 2020',
          urgent: true,
        ),
        HealthTip(
          title: 'Take anticoagulant medication as prescribed',
          body:
              'If your doctor has prescribed blood thinners (anticoagulants such as warfarin or apixaban), '
              'take them exactly as directed — even if you feel well. Missing doses significantly increases '
              'stroke risk in AF patients. Never stop without consulting your doctor.',
          reference: 'ESC AF Guidelines, 2021; Ghana STG, 2017',
          urgent: hasAF,
        ),
        const HealthTip(
          title: 'Avoid AF triggers',
          body:
              'Common triggers that can bring on or worsen AF episodes include:\n'
              '• Excessive caffeine (more than 2 cups of coffee or tea per day)\n'
              '• Alcohol — even moderate amounts can trigger episodes\n'
              '• Sleep deprivation and high stress\n'
              '• Vigorous unaccustomed exercise\n'
              '• Dehydration',
          reference: 'Larsson et al., Heart, 2016; ESC AF Guidelines, 2021',
          urgent: false,
        ),
      ],
    ));

    // ── 2. Stroke Prevention ────────────────────────────────
    categories.add(TipCategory(
      icon: 'brain',
      title: 'Stroke Prevention',
      color: const Color(0xFF7C3AED),
      priority: highStroke ? TipPriority.urgent : TipPriority.warning,
      personalised: hasData && highStroke,
      personalisedNote: highStroke
          ? 'Your stroke risk score is elevated. These steps are especially important for you.'
          : null,
      tips: [
        const HealthTip(
          title: 'FAST — Recognise stroke instantly',
          body: 'Use the FAST test to recognise stroke:\n'
              '🅵 Face — Does one side of the face droop when smiling?\n'
              '🅰 Arms — Can both arms be raised? Does one drift down?\n'
              '🆂 Speech — Is speech slurred or strange?\n'
              '🆃 Time — If YES to any, call 193 immediately.\n\n'
              'Every minute without treatment, 1.9 million brain cells die. Act fast.',
          reference: 'American Stroke Association, 2020; WHO, 2020',
          urgent: true,
        ),
        HealthTip(
          title: 'Control your blood pressure',
          body:
              'High blood pressure is the single biggest modifiable risk factor for stroke. '
              'Target blood pressure for most adults is below 130/80 mmHg. '
              'Take your antihypertensive medications consistently, reduce salt intake, '
              'exercise regularly, and attend all follow-up appointments.',
          reference: 'JNC 8 Guidelines, James et al., JAMA, 2014; WHO, 2021',
          urgent: elevatedBP,
        ),
        const HealthTip(
          title: 'Monitor your blood pressure at home',
          body:
              'Check your BP at the same time each morning before eating or taking medication. '
              'Sit quietly for 5 minutes first. Record the readings in a diary or this app '
              'and bring the log to every doctor visit. A consistent log helps your doctor '
              'make better treatment decisions.',
          reference: 'ESH/ESC Hypertension Guidelines, 2018',
          urgent: false,
        ),
      ],
    ));

    // ── 3. Diet & Nutrition ─────────────────────────────────
    categories.add(TipCategory(
      icon: 'nutrition',
      title: 'Diet & Nutrition',
      color: AppTheme.secondary,
      priority: TipPriority.info,
      personalised: isHyper || isDiabetic,
      personalisedNote: (isHyper && isDiabetic)
          ? 'Tailored for hypertension and diabetes management.'
          : isHyper
              ? 'Tailored for hypertension management.'
              : isDiabetic
                  ? 'Tailored for diabetes management.'
                  : null,
      tips: [
        HealthTip(
          title: 'Reduce salt (sodium) intake',
          body:
              'Excess salt raises blood pressure directly. Aim for less than 5g of salt per day '
              '(about one teaspoon). Practical steps:\n'
              '• Avoid adding salt at the table\n'
              '• Limit processed foods, tinned fish, and fast food\n'
              '• Use herbs, lime, and spices for flavour instead\n'
              '• Be aware that bouillon cubes and soy sauce are very high in sodium.',
          reference: 'WHO Salt Reduction Fact Sheet, 2020; Ghana STG, 2017',
          urgent: isHyper,
        ),
        if (isDiabetic)
          const HealthTip(
            title: 'Manage blood sugar through diet',
            body:
                'Poorly controlled blood sugar damages blood vessels and increases stroke risk. '
                'Choose:\n'
                '• Complex carbohydrates — brown rice, oats, yam, beans — over white rice and white bread\n'
                '• Smaller, more frequent meals to prevent glucose spikes\n'
                '• Vegetables at every meal — aim for half your plate\n'
                '• Limit sugary drinks, sweets, and heavily processed snacks entirely.',
            reference: 'ADA Standards of Medical Care, 2023',
            urgent: true,
          ),
        const HealthTip(
          title: 'Eat heart-healthy fats',
          body:
              'Replace saturated fats (palm oil, lard, fatty meat) with unsaturated fats '
              '(groundnuts, avocado, fish). Include oily fish (sardines, mackerel, tuna) '
              'at least twice a week — the omega-3 fatty acids have proven benefits for '
              'heart rhythm and cardiovascular health.',
          reference:
              'WHO Healthy Diet Fact Sheet, 2020; ESC Prevention Guidelines, 2021',
          urgent: false,
        ),
        const HealthTip(
          title: 'Increase fibre and potassium',
          body:
              'High fibre intake (fruits, vegetables, legumes, whole grains) lowers blood '
              'pressure and improves cholesterol. Potassium-rich foods (bananas, oranges, '
              'sweet potatoes, spinach, beans) help counteract the effect of sodium on blood '
              'pressure. Aim for at least 5 portions of fruits and vegetables daily.',
          reference: 'DASH Diet Evidence; Appel et al., NEJM, 1997; WHO, 2020',
          urgent: false,
        ),
      ],
    ));

    // ── 4. Exercise ─────────────────────────────────────────
    categories.add(const TipCategory(
      icon: 'walk',
      title: 'Physical Activity',
      color: Color(0xFF0891B2),
      priority: TipPriority.info,
      personalised: false,
      tips: [
        HealthTip(
          title: 'Aim for 150 minutes of moderate exercise per week',
          body:
              'The WHO recommends at least 150 minutes of moderate-intensity aerobic activity '
              'per week for adults — that is 30 minutes on 5 days. Suitable activities include:\n'
              '• Brisk walking\n'
              '• Swimming or water aerobics\n'
              '• Cycling on flat ground\n'
              '• Dancing\n\n'
              'If you have known AF or heart disease, consult your doctor before starting a '
              'new exercise programme.',
          reference:
              'WHO Physical Activity Guidelines, 2020; ESC AF Guidelines, 2021',
          urgent: false,
        ),
        HealthTip(
          title: 'Avoid prolonged sitting',
          body:
              'Sitting for long periods is independently associated with increased cardiovascular risk, '
              'even in people who exercise regularly. Break up sitting time every hour — stand up, '
              'walk to get water, or do a few gentle stretches.',
          reference: 'Biswas et al., Ann Intern Med, 2015',
          urgent: false,
        ),
        HealthTip(
          title: 'Start slowly if you have been inactive',
          body:
              'If you have been sedentary, start with 10-minute walks and increase gradually. '
              'Warning signs to stop exercise and seek medical attention: chest pain, severe '
              'shortness of breath, palpitations that do not settle, or dizziness.',
          reference: 'ESC Prevention Guidelines, 2021',
          urgent: false,
        ),
      ],
    ));

    // ── 5. Medication adherence ─────────────────────────────
    categories.add(TipCategory(
      icon: 'pill',
      title: 'Medication Adherence',
      color: AppTheme.warning,
      priority: (isHyper || isDiabetic || hasAF)
          ? TipPriority.warning
          : TipPriority.info,
      personalised: isHyper || isDiabetic || hasAF,
      personalisedNote: (isHyper || isDiabetic || hasAF)
          ? 'Consistent medication use is critical given your conditions.'
          : null,
      tips: [
        const HealthTip(
          title: 'Take your medications at the same time every day',
          body:
              'Consistency is the most important factor in medication effectiveness. '
              'Set a daily alarm, link it to a daily habit (e.g. brushing teeth), '
              'or use a pill organiser. Missing doses of antihypertensives, '
              'anticoagulants, or antidiabetic medications can have serious consequences '
              'within 24–48 hours.',
          reference: 'WHO Adherence to Long-Term Therapies Report, 2003',
          urgent: false,
        ),
        const HealthTip(
          title: 'Never stop medication without consulting your doctor',
          body:
              'Stopping antihypertensives abruptly can cause rebound hypertension. '
              'Stopping anticoagulants suddenly increases stroke risk significantly. '
              'If you have side effects or cannot afford medication, speak to your '
              'doctor or pharmacist — there are often alternatives or support programmes available.',
          reference:
              'ESC Guidelines; Ghana National Health Insurance Authority (NHIA)',
          urgent: true,
        ),
        const HealthTip(
          title: 'Bring your medications to every appointment',
          body:
              'Bring all your medication bottles (including traditional medicine and supplements) '
              'to every doctor or clinic visit. Some herbal remedies interact with blood thinners '
              'and antidiabetic drugs. Your healthcare provider needs a complete picture.',
          reference: 'Ghana STG, 2017; WHO Medication Safety Guidelines',
          urgent: false,
        ),
      ],
    ));

    // ── 6. Alcohol & Smoking ────────────────────────────────
    categories.add(TipCategory(
      icon: 'no_smoking',
      title: 'Alcohol & Smoking',
      color: AppTheme.danger,
      priority: TipPriority.warning,
      personalised: false,
      tips: [
        const HealthTip(
          title: 'Stop smoking — the single most impactful change you can make',
          body:
              'Smoking doubles the risk of stroke and significantly increases AF risk. '
              'The benefits of stopping begin within 24 hours (blood pressure and carbon '
              'monoxide levels normalise) and continue for years. '
              'Seek support from your doctor — nicotine replacement therapy is available '
              'and significantly improves quit rates.',
          reference:
              'WHO Tobacco Fact Sheet, 2021; ESC Prevention Guidelines, 2021',
          urgent: true,
        ),
        HealthTip(
          title: 'Limit or eliminate alcohol',
          body:
              'Even moderate alcohol consumption is associated with increased AF risk. '
              'Heavy drinking raises blood pressure and can trigger AF episodes directly '
              '(known as "holiday heart syndrome"). '
              'The safest approach for cardiac patients is to avoid alcohol entirely. '
              'If you drink, limit to no more than 1 standard drink per day for women '
              'and 2 for men.',
          reference:
              'Larsson et al., Heart, 2016; Voskoboinik et al., JACC, 2020',
          urgent: hasAF,
        ),
      ],
    ));

    // ── 7. Sleep & Stress ───────────────────────────────────
    categories.add(const TipCategory(
      icon: 'sleep',
      title: 'Sleep & Stress',
      color: Color(0xFF6366F1),
      priority: TipPriority.info,
      personalised: false,
      tips: [
        HealthTip(
          title: 'Prioritise 7–9 hours of quality sleep',
          body:
              'Poor sleep is associated with increased blood pressure, worsened blood sugar '
              'control, and higher AF episode frequency. Sleep apnoea — where breathing '
              'temporarily stops during sleep — is particularly common in AF patients and '
              'worsens outcomes significantly. Signs include loud snoring, waking unrefreshed, '
              'or excessive daytime sleepiness. Mention this to your doctor.',
          reference: 'Gami et al., JACC, 2004; ESC AF Guidelines, 2021',
          urgent: false,
        ),
        HealthTip(
          title: 'Manage stress actively',
          body:
              'Chronic psychological stress activates the sympathetic nervous system, '
              'raises blood pressure, and can trigger AF episodes. Effective, evidence-based '
              'stress reduction techniques include:\n'
              '• Diaphragmatic (belly) breathing — 4 seconds in, hold 4, out 6\n'
              '• Daily 10-minute walks in nature\n'
              '• Social connection — talking to trusted family or friends\n'
              '• Prayer or mindfulness practice\n'
              '• Reducing workload where possible',
          reference:
              'Lampert et al., Circulation, 2014; ESC Prevention Guidelines, 2021',
          urgent: false,
        ),
      ],
    ));

    return categories;
  }
}

// ── Personalised banner ────────────────────────────────────────
class _PersonalisedBanner extends StatelessWidget {
  final Measurement measurement;
  final PatientProfile? profile;

  const _PersonalisedBanner({required this.measurement, required this.profile});

  @override
  Widget build(BuildContext context) {
    final afColor = measurement.afResult == AfResult.possibleAF
        ? AppTheme.danger
        : measurement.afResult == AfResult.inconclusive
            ? AppTheme.warning
            : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withBlue(210)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personalised for your results',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Row(children: [
            AfResultBadge(result: measurement.afResult, large: true),
            const SizedBox(width: 10),
            StrokeRiskChip(
              risk: measurement.strokeRisk,
              score: measurement.strokeScore,
              large: true,
            ),
          ]),
          const SizedBox(height: 10),
          const Text(
            'Tips marked ★ are most relevant based on your latest reading.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GeneralBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                color: AppTheme.secondary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('General Health Guidelines',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.secondary)),
                const SizedBox(height: 4),
                Text(
                  'Evidence-based tips for heart health, hypertension, and diabetes. '
                  'Connect your device to get personalised recommendations.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Source note ────────────────────────────────────────────────
class _SourceNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              Expanded(
                child: Text(
                  'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
                  'This app does not replace professional medical advice.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
              const ReadAloudIcon(
                text:
                    'All tips are based on WHO, ESC, JNC 8, ADA, and Ghana Standard Treatment Guidelines. '
                    'This app does not replace professional medical advice.',
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Category section ───────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final TipCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Row(children: [
          _iconFromKey(category.icon),
          const SizedBox(width: 10),
          Text(category.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          if (category.personalised)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('★ Personalised',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
        ]),

        // Personalised note
        if (category.personalisedNote != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: category.color.withValues(alpha: 0.3)),
            ),
            child: Text(category.personalisedNote!,
                style: TextStyle(
                    fontSize: 12,
                    color: category.color,
                    fontWeight: FontWeight.w500)),
          ),
        ],

        const SizedBox(height: 12),
        // Tips list
        ...category.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TipCard(tip: tip, accent: category.color),
            )),
      ],
    );
  }
}

// ── Individual tip card ────────────────────────────────────────
class _TipCard extends StatefulWidget {
  final HealthTip tip;
  final Color accent;
  const _TipCard({required this.tip, required this.accent});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.tip.urgent
              ? widget.accent.withValues(alpha: 0.06)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.tip.urgent
                ? widget.accent.withValues(alpha: 0.35)
                : AppTheme.border,
            width: widget.tip.urgent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (widget.tip.urgent) ...[
                Icon(Icons.priority_high_rounded,
                    size: 16, color: widget.accent),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(widget.tip.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          color: widget.tip.urgent
                              ? widget.accent
                              : AppTheme.textPrimary,
                        )),
              ),
              ReadAloudIcon(text: '${widget.tip.title}. ${widget.tip.body}'),
              const SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(widget.tip.body,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 13, height: 1.55)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.article_outlined,
                    size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Source: ${widget.tip.reference}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic)),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────
enum TipPriority { urgent, warning, info }

class TipCategory {
  final String icon;
  final String title;
  final Color color;
  final TipPriority priority;
  final bool personalised;
  final String? personalisedNote;
  final List<HealthTip> tips;

  const TipCategory({
    required this.icon,
    required this.title,
    required this.color,
    required this.priority,
    required this.personalised,
    required this.tips,
    this.personalisedNote,
  });
}

class HealthTip {
  final String title;
  final String body;
  final String reference;
  final bool urgent;

  const HealthTip({
    required this.title,
    required this.body,
    required this.reference,
    required this.urgent,
  });
}

// Maps icon key strings to Material icons (replaces emoji for cross-platform compat)
Widget _iconFromKey(String key) {
  const map = {
    'heart':      Icons.favorite_rounded,
    'brain':      Icons.psychology_rounded,
    'nutrition':  Icons.restaurant_rounded,
    'walk':       Icons.directions_walk_rounded,
    'pill':       Icons.medication_rounded,
    'no_smoking': Icons.smoke_free_rounded,
    'sleep':      Icons.bedtime_rounded,
    'hospital':   Icons.local_hospital_rounded,
    'warning':    Icons.warning_rounded,
    'chart':      Icons.bar_chart_rounded,
    'clipboard':  Icons.assignment_rounded,
    'trending':   Icons.trending_up_rounded,
    'monitor':    Icons.monitor_heart_rounded,
  };
  return Icon(map[key] ?? Icons.info_outline_rounded,
      size: 20, color: AppTheme.primary);
}