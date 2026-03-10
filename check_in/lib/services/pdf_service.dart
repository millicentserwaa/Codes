import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/measurement.dart';
import '../models/user_profile.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class PdfService {
  // Watermark with patient name for confidentiality — visible on the PDF but not encrypted.
  static pw.Widget _buildWatermark(String patientName) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -pi / 4,
          child: pw.Opacity(
            opacity: 0.06,
            child: pw.Text(
              'CONFIDENTIAL: $patientName',
              style: pw.TextStyle(
                fontSize: 58,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Secure export
  static Future<void> exportReport({
    required BuildContext context,
    required UserProfile profile,
    required List<Measurement> measurements,
  }) async {
    try {
      // 1. Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            buildForeground: (context) => _buildWatermark(profile.name),
          ),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(profile),
                pw.SizedBox(height: 24),
                _buildProfileSection(profile),
                pw.SizedBox(height: 24),
                _buildRiskSection(profile),
                pw.SizedBox(height: 24),
                if (measurements.isNotEmpty) ...[
                  _buildSummarySection(measurements),
                  pw.SizedBox(height: 24),
                  _buildMeasurementsTable(measurements),
                  pw.SizedBox(height: 24),
                ],
                _buildDisclaimer(),
              ],
            ),
          ],
        ),
      );

      // 2. Save to bytes
      final List<int> pdfBytes = await pdf.save();

      // 3. Write to temp file
      final filename =
          'CheckIn_Report_${profile.name.replaceAll(' ', '_')}_'
          '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(pdfBytes);

      // 4. Share via native share sheet (WhatsApp, Gmail, Drive, etc.)
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/pdf')],
        subject: 'CheckIn Health Report: ${profile.name}',
        text: 'Please find attached your CheckIn heart health report.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(UserProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#00695C'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CheckIn',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Heart Health Report',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
              ),
              pw.Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile section ───────────────────────────────────────────────────────────
  static pw.Widget _buildProfileSection(UserProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0D8CC')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Patient Profile',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#00695C'),
            ),
          ),
          pw.Divider(color: PdfColor.fromHex('#E0D8CC')),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildProfileRow('Name', profile.name)),
              pw.Expanded(
                child: _buildProfileRow('Age', '${profile.age} years'),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildProfileRow('Gender', profile.gender)),
              pw.Expanded(
                child: _buildProfileRow(
                  'Date of Birth',
                  '${profile.dateOfBirth.day}/${profile.dateOfBirth.month}/${profile.dateOfBirth.year}',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Medical History',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#4A4A6A'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConditionBadge('Hypertension', profile.hasHypertension),
              _buildConditionBadge('Diabetes', profile.hasDiabetes),
              _buildConditionBadge('Prior Stroke/TIA', profile.hasPriorStroke),
              _buildConditionBadge('Heart Failure', profile.hasHeartFailure),
              _buildConditionBadge(
                'Vascular Disease',
                profile.hasVascularDisease,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfileRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1A2E'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConditionBadge(String label, bool active) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(
          color: active
              ? PdfColor.fromHex('#00695C')
              : PdfColor.fromHex('#cccccc'),
          width: 0.8,
        ),
      ),
      child: pw.Text(
        active ? '+ $label' : label,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: active ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: active
              ? PdfColor.fromHex('#00695C')
              : PdfColor.fromHex('#888888'),
        ),
      ),
    );
  }

  // ── Risk section ──────────────────────────────────────────────────────────────
  static pw.Widget _buildRiskSection(UserProfile profile) {
    final score = profile.strokeRiskScore;
    final level = profile.strokeRiskLevel;

    PdfColor riskColor;
    if (level == 'Low') {
      riskColor = PdfColor.fromHex('#2E7D32');
    } else if (level == 'Moderate') {
      riskColor = PdfColor.fromHex('#E65100');
    } else {
      riskColor = PdfColor.fromHex('#C62828');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: riskColor, width: 4),
          top: pw.BorderSide(color: PdfColor.fromHex('#E0D8CC'), width: 0.8),
          right: pw.BorderSide(color: PdfColor.fromHex('#E0D8CC'), width: 0.8),
          bottom: pw.BorderSide(color: PdfColor.fromHex('#E0D8CC'), width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CHA2DS2-VASc Stroke Risk Score',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1A1A2E'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$level Risk',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: riskColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _getRiskDescription(level),
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 64,
            height: 64,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: riskColor, width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                '$score',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary section ───────────────────────────────────────────────────────────
  static pw.Widget _buildSummarySection(List<Measurement> measurements) {
    final total = measurements.length;
    final afCount = measurements.where((m) => m.afPrediction == 1).length;
    final normalCount = total - afCount;
    final avgHR =
        measurements.map((m) => m.heartRate).reduce((a, b) => a + b) / total;
    final afBurden = (afCount / total * 100).toStringAsFixed(0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0D8CC')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Measurement Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#00695C'),
            ),
          ),
          pw.Divider(color: PdfColor.fromHex('#E0D8CC')),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat(
                'Total Readings',
                '$total',
                PdfColor.fromHex('#00695C'),
              ),
              _buildSummaryStat(
                'Normal',
                '$normalCount',
                PdfColor.fromHex('#2E7D32'),
              ),
              _buildSummaryStat(
                'Possible AF',
                '$afCount',
                PdfColor.fromHex('#C62828'),
              ),
              _buildSummaryStat(
                'Avg Heart Rate',
                '${avgHR.toStringAsFixed(0)} BPM',
                PdfColor.fromHex('#C9A84C'),
              ),
              _buildSummaryStat(
                'AF Burden',
                '$afBurden%',
                PdfColor.fromHex('#C62828'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryStat(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // ── Measurements table ────────────────────────────────────────────────────────
  static pw.Widget _buildMeasurementsTable(List<Measurement> measurements) {
    final data = measurements.take(20).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0D8CC')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recent Measurements (Last ${data.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#00695C'),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E0D8CC'),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#00695C'),
                ),
                children: [
                  _buildTableHeader('Date & Time'),
                  _buildTableHeader('Heart Rate'),
                  _buildTableHeader('Rhythm'),
                  _buildTableHeader('Confidence'),
                ],
              ),
              ...data.asMap().entries.map((entry) {
                final m = entry.value;
                final isAF = m.afPrediction == 1;
                final isEven = entry.key % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven
                        ? PdfColors.white
                        : PdfColor.fromHex('#F9F6F0'),
                  ),
                  children: [
                    _buildTableCell(
                      '${m.timestamp.day}/${m.timestamp.month}/${m.timestamp.year}\n'
                      '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    _buildTableCell('${m.heartRate.toStringAsFixed(0)} BPM'),
                    _buildTableCell(
                      m.rhythm,
                      color: isAF
                          ? PdfColor.fromHex('#C62828')
                          : PdfColor.fromHex('#2E7D32'),
                      bold: true,
                    ),
                    _buildTableCell('${m.confidence}%'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColor.fromHex('#1A1A2E'),
        ),
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F3EFE7'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColor.fromHex('#E0D8CC')),
      ),
      child: pw.Text(
        'DISCLAIMER: This report is generated by the CheckIn app for '
        'screening purposes only and does not constitute medical advice, '
        'diagnosis, or treatment. Always consult a qualified healthcare '
        'professional for medical decisions. The CHA2DS2-VASc score is '
        'based on ESC Guidelines and is intended as a screening tool only.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  static String _getRiskDescription(String level) {
    switch (level) {
      case 'Low':
        return 'Current risk factors suggest a low probability of stroke.\nContinue maintaining a healthy lifestyle.';
      case 'Moderate':
        return 'Risk factors suggest a moderate probability of stroke.\nConsult your healthcare provider for guidance.';
      case 'High':
        return 'Risk factors suggest a high probability of stroke.\nPlease consult a healthcare provider promptly.';
      default:
        return '';
    }
  }
}
