import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/hive_service.dart';
import '../services/risk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final HiveService _hiveService = HiveService();
  UserProfile? _profile;
  List<Measurement> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
      appBar: AppBar(
        title: const Text('Stroke Risk'),
      ),
      body: profile == null
          ? const EmptyState(
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
                  _buildScoreCard(profile),
                  const SizedBox(height: 20),
                  _buildScoreBreakdown(profile),
                  const SizedBox(height: 20),
                  if (_measurements.isNotEmpty) ...[
                    _buildAFBurdenCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildRecommendations(profile),
                  const SizedBox(height: 20),
                  _buildDisclaimer(),
                ],
              ),
            ),
    );
  }

  // ── Score Card ───────────────────────────────────────────
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
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
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
                  Text(
                    '$riskLevel Risk',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 2,
                  ),
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

  // ── Score Breakdown ──────────────────────────────────────
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
              item.active
                  ? Icons.check_rounded
                  : Icons.remove_rounded,
              size: 14,
              color: item.active
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
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
                    fontWeight: item.active
                        ? FontWeight.w600
                        : FontWeight.w400,
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
              color: item.active
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── AF Burden ────────────────────────────────────────────
  Widget _buildAFBurdenCard() {
    final burden = RiskService.getAFBurden(_measurements);
    final trend = RiskService.getHeartRateTrend(_measurements);
    final afCount =
        _measurements.where((m) => m.afPrediction == 1).length;

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
            'AF Burden',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBurdenStat(
                  label: 'AF Burden',
                  value: '${burden.toStringAsFixed(0)}%',
                  color: burden > 50
                      ? AppTheme.danger
                      : burden > 20
                          ? AppTheme.warning
                          : AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildBurdenStat(
                  label: 'AF Events',
                  value: '$afCount',
                  color: afCount > 0
                      ? AppTheme.danger
                      : AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildBurdenStat(
                  label: 'HR Trend',
                  value: trend,
                  color: trend == 'Increasing'
                      ? AppTheme.warning
                      : trend == 'Decreasing'
                          ? AppTheme.primary
                          : AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurdenStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Recommendations ──────────────────────────────────────
  Widget _buildRecommendations(UserProfile profile) {
    final recommendations =
        RiskService.getRecommendations(profile, _measurements);

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
            'Recommendations',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.asMap().entries.map(
                (e) => _buildRecommendationItem(
                  e.key + 1,
                  e.value,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
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
        ],
      ),
    );
  }

  // ── Disclaimer ───────────────────────────────────────────
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