
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/risk_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/tts_button.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final HiveService _hiveService = HiveService();
  final TtsService _ttsService = TtsService();

  UserProfile? _profile;
  List<Measurement> _measurements = [];

  // Expandable state for the two new cards
  bool _actionsExpanded = true;
  bool _lifestyleExpanded = false;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadData();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _profile = _hiveService.getUserProfile();
      _measurements = _hiveService.getAllMeasurements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Stroke Risk')),
      body: profile == null
          ? EmptyState(
              icon: Icons.shield_outlined,
              title: 'No profile found',
              subtitle:
                  'Please complete your profile in settings to see your stroke risk assessment.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Kept unchanged ──────────────────────
                  _buildScoreCard(profile),
                  const SizedBox(height: 20),
                  _buildScoreBreakdown(profile),
                  const SizedBox(height: 20),

                  // ── New combined analysis section ───────
                  _buildCombinedAnalysis(profile),
                  const SizedBox(height: 16),
                  _buildActionsCard(profile),
                  const SizedBox(height: 16),
                  _buildLifestyleCard(profile),
                  const SizedBox(height: 20),

                  // ── Kept unchanged ──────────────────────
                  _buildDisclaimer(),
                ],
              ),
            ),
    );
  }

  // ── Score Card (unchanged) ────────────────────────────────
  Widget _buildScoreCard(UserProfile profile) {
    final score = profile.strokeRiskScore;
    final riskLevel = profile.strokeRiskLevel;
    final color = AppTheme.riskColor(riskLevel);
    final description = RiskService.getRiskDescription(profile);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHA\u2082DS\u2082-VASc Score',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$riskLevel Risk',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TtsButton(
                        onSpeak: () => _ttsService.speakRiskScore(profile),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Breakdown (unchanged) ───────────────────────────
  Widget _buildScoreBreakdown(UserProfile profile) {
    final items = [
      _ScoreItem(
        label: 'Heart Failure',
        points: profile.hasHeartFailure ? 1 : 0,
        active: profile.hasHeartFailure,
      ),
      _ScoreItem(
        label: 'Hypertension',
        points: profile.hasHypertension ? 1 : 0,
        active: profile.hasHypertension,
      ),
      _ScoreItem(
        label: 'Age ${profile.age} years',
        points: profile.age >= 75
            ? 2
            : profile.age >= 65
            ? 1
            : 0,
        active: profile.age >= 65,
        note: profile.age >= 75
            ? '(+2 for age \u226575)'
            : profile.age >= 65
            ? '(+1 for age 65\u201374)'
            : '(no points below 65)',
      ),
      _ScoreItem(
        label: 'Diabetes',
        points: profile.hasDiabetes ? 1 : 0,
        active: profile.hasDiabetes,
      ),
      _ScoreItem(
        label: 'Prior Stroke / TIA',
        points: profile.hasPriorStroke ? 2 : 0,
        active: profile.hasPriorStroke,
        note: profile.hasPriorStroke ? '(+2 double weight)' : null,
      ),
      _ScoreItem(
        label: 'Vascular Disease',
        points: profile.hasVascularDisease ? 1 : 0,
        active: profile.hasVascularDisease,
      ),
      _ScoreItem(
        label: 'Female Sex',
        points: profile.gender == 'Female' ? 1 : 0,
        active: profile.gender == 'Female',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildScoreRow(item)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Score',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${profile.strokeRiskScore} / 9',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(_ScoreItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: item.active
                  ? AppTheme.primary.withOpacity(0.1)
                  : AppTheme.divider.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.active ? Icons.check_rounded : Icons.remove_rounded,
              size: 14,
              color: item.active ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: item.active
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: item.active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (item.note != null)
                  Text(
                    item.note!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.active ? '+${item.points}' : '0',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: item.active ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Combined Analysis — new ───────────────────────────────
  Widget _buildCombinedAnalysis(UserProfile profile) {
    final state = RiskService.getCombinedState(profile, _measurements);
    final interpretation = RiskService.getCombinedInterpretation(
      profile,
      _measurements,
    );
    final stateLabel = RiskService.getCombinedStateLabel(state);
    final bannerColor = _stateColor(state);
    final afBurden = RiskService.getAFBurden(_measurements);
    final afCount = _measurements.where((m) => m.afPrediction == 1).length;
    final totalCount = _measurements.length;
    final chaLabel = profile.strokeRiskLevel;

    return Column(
      children: [
        // ── Two input cards side by side ──────────────────
        Row(
          children: [
            // AF Burden card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AF Burden',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${afBurden.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: afBurden >= 20
                            ? AppTheme.danger
                            : AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (afBurden / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppTheme.divider,
                        color: afBurden >= 20
                            ? AppTheme.danger
                            : AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$afCount of $totalCount readings flagged',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // CHA2DS2-VASc card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHA\u2082DS\u2082-VASc',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.strokeRiskScore} / 9',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.riskColor(chaLabel),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.riskColor(chaLabel).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$chaLabel Risk',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.riskColor(chaLabel),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.gender == 'Female'
                          ? 'High if score \u22653'
                          : 'High if score \u22652',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Combined banner ───────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bannerColor.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_stateIcon(state), color: bannerColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: bannerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      interpretation,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── What to do next — expandable ─────────────────────────
  Widget _buildActionsCard(UserProfile profile) {
    final actions = RiskService.getActions(profile, _measurements);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Header — tappable to expand/collapse
          InkWell(
            onTap: () => setState(() => _actionsExpanded = !_actionsExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'What to do next',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TtsButton(
                    onSpeak: () => _ttsService.speakRecommendations(actions),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _actionsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_actionsExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                children: actions
                    .asMap()
                    .entries
                    .map(
                      (e) => _buildListItem(
                        number: e.key + 1,
                        text: e.value,
                        color: AppTheme.primary,
                        onSpeak: () => _ttsService.speakSingleRecommendation(
                          e.key + 1,
                          e.value,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Lifestyle tips — expandable ───────────────────────────
  Widget _buildLifestyleCard(UserProfile profile) {
    final tips = RiskService.getLifestyleTips(profile, _measurements);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () =>
                setState(() => _lifestyleExpanded = !_lifestyleExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_outline_rounded,
                      color: AppTheme.success,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lifestyle tips',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TtsButton(
                    onSpeak: () => _ttsService.speakRecommendations(tips),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _lifestyleExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_lifestyleExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                children: tips
                    .asMap()
                    .entries
                    .map(
                      (e) => _buildListItem(
                        number: e.key + 1,
                        text: e.value,
                        color: AppTheme.success,
                        onSpeak: () async => _ttsService.speakSingleRecommendation(e.key + 1, e.value),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared list item widget ───────────────────────────────
  Widget _buildListItem({
    required int number,
    required String text,
    required Color color,
    required Future<void> Function() onSpeak,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TtsButton(size: 18, onSpeak: onSpeak),
        ],
      ),
    );
  }

  // ── Disclaimer (unchanged) ────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This assessment is for screening purposes only and does '
              'not constitute medical advice. Always consult a qualified '
              'healthcare professional for diagnosis and treatment.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── State colour mapping ──────────────────────────────────
  Color _stateColor(CombinedRiskState state) {
    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return AppTheme.success;
      case CombinedRiskState.lowBurdenHighScore:
        return AppTheme.warning;
      case CombinedRiskState.highBurdenLowScore:
        return const Color(0xFFE65100);
      case CombinedRiskState.highBurdenHighScore:
        return AppTheme.danger;
    }
  }

  // ── State icon mapping ────────────────────────────────────
  IconData _stateIcon(CombinedRiskState state) {
    switch (state) {
      case CombinedRiskState.lowBurdenLowScore:
        return Icons.check_circle_outline_rounded;
      case CombinedRiskState.lowBurdenHighScore:
        return Icons.warning_amber_rounded;
      case CombinedRiskState.highBurdenLowScore:
        return Icons.monitor_heart_outlined;
      case CombinedRiskState.highBurdenHighScore:
        return Icons.emergency_rounded;
    }
  }
}

class _ScoreItem {
  final String label;
  final int points;
  final bool active;
  final String? note;

  _ScoreItem({
    required this.label,
    required this.points,
    required this.active,
    this.note,
  });
}
