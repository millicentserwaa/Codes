import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/measurement.dart';
import '../models/patient_profile.dart';
import '../models/stroke_models.dart';
import '../services/stroke_algorithm.dart';


class PdfReportService {
  static const _blue   = PdfColor.fromInt(0xFF2563EB);
  static const _green  = PdfColor.fromInt(0xFF10B981);
  static const _amber  = PdfColor.fromInt(0xFFF59E0B);
  static const _red    = PdfColor.fromInt(0xFFEF4444);
  static const _grey   = PdfColor.fromInt(0xFF6B7280);
  static const _greyBg = PdfColor.fromInt(0xFFF3F4F6);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _white  = PdfColors.white;
  static const _black  = PdfColor.fromInt(0xFF111827);


  static String _clean(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x20 && r <= 0x7E) {
        buf.writeCharCode(r);           // standard ASCII printable
      } else if (r >= 0xC0 && r <= 0xFF) {
        buf.writeCharCode(r);           // Latin-1 supplement accented chars
      } else {
        // Map common special chars to ASCII equivalents
        switch (r) {
          case 0x2013: buf.write('-');   break; // en dash
          case 0x2014: buf.write('-');   break; // em dash
          case 0x2018: buf.write("'");  break; // left single quote
          case 0x2019: buf.write("'");  break; // right single quote
          case 0x201C: buf.write('"');  break; // left double quote
          case 0x201D: buf.write('"');  break; // right double quote
          case 0x2022: buf.write('*');  break; // bullet
          case 0x2082: buf.write('2');  break; // subscript 2
          case 0x2265: buf.write('>='); break; // >=
          case 0x2264: buf.write('<='); break; // <=
          case 0x00B1: buf.write('+/-'); break; // plus-minus
          case 0x00B2: buf.write('2');  break; // superscript 2
          case 0x00B3: buf.write('3');  break; // superscript 3
        }
      }
    }
    return buf.toString();
  }

  // Main entry point
  static Future<void> generateAndShare({
    required PatientProfile profile,
    required List<Measurement> allMeasurements,
  }) async {
    final pdf    = await _buildPdf(profile, allMeasurements);
    final bytes  = await pdf.save();
    final fname  = 'AF_Screen_Report_${_stamp(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fname);
  }

  // Build the PDF document 
  static Future<pw.Document> _buildPdf(
      PatientProfile profile, List<Measurement> allMeasurements) async {
    final pdf     = pw.Document(title: 'AF-Screen Clinical Report');
    final latest  = allMeasurements.isNotEmpty ? allMeasurements.first : null;
    final history = allMeasurements.take(10).toList();
    final now     = DateTime.now();

    StrokeScoreResult? strokeResult;
    if (latest != null) {
      strokeResult = StrokeAlgorithm.calculate(
        profile:       profile,
        pRR50:         latest.pRR50,
        sdsd:          latest.sdsd > 0 ? latest.sdsd : latest.rmssd / 1.414,
        afResultIndex: latest.afResultIndex,
        systolicBP:    latest.systolicBP,
      );
    }

    final recs = strokeResult != null && latest != null
        ? StrokeAlgorithm.getRecommendations(
            result:        strokeResult,
            profile:       profile,
            afResultIndex: latest.afResultIndex,
            pRR50:         latest.pRR50,
            sdsd:          latest.sdsd > 0 ? latest.sdsd : latest.rmssd / 1.414,
          )
        : <Recommendation>[];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.all(32),
        header:     (ctx) => _header(ctx, profile, now),
        footer:     (ctx) => _footer(ctx),
        build: (ctx) => [
          _secTitle('Latest Measurement'),
          pw.SizedBox(height: 8),
          if (latest == null)
            _infoBox('No measurements recorded yet.', _grey)
          else ...[
            _resultBanner(latest),
            pw.SizedBox(height: 10),
            _hrvGrid(latest),
          ],
          pw.SizedBox(height: 20),

          _secTitle('CHA2DS2-VASc Stroke Risk Assessment'),
          pw.SizedBox(height: 4),
          pw.Text(
            'Note: Factors C (congestive heart failure) and V (vascular disease) '
            'excluded - require clinical imaging unavailable from wearable ECG. '
            'Max implemented score = 7.',
            style: pw.TextStyle(
                fontSize: 7, color: _grey,
                fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 8),
          if (strokeResult == null)
            _infoBox('Complete your patient profile to see stroke risk.', _grey)
          else ...[
            _scoreHeader(strokeResult),
            pw.SizedBox(height: 10),
            _factorsTable('CHA2DS2-VASc Factors', strokeResult.chadFactors),
            pw.SizedBox(height: 10),
            _factorsTable(
                'Device HRV Flags (informational - not added to score)',
                strokeResult.hrvFactors),
          ],
          pw.SizedBox(height: 20),

          _secTitle('Measurement History (Last ${history.length})'),
          pw.SizedBox(height: 8),
          if (history.isEmpty)
            _infoBox('No history available.', _grey)
          else
            _historyTable(history),
          pw.SizedBox(height: 20),

          if (recs.isNotEmpty) ...[
            _secTitle('Personalised Recommendations'),
            pw.SizedBox(height: 8),
            ...recs.map(_recCard),
          ],

          pw.SizedBox(height: 20),
          _disclaimer(),
        ],
      ),
    );

    return pdf;
  }

  // Page header 
  static pw.Widget _header(
      pw.Context ctx, PatientProfile p, DateTime d) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: pw.BoxDecoration(
          color: _blue, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('AF-Screen Clinical Report',
                style: pw.TextStyle(
                    fontSize: 14, color: _white,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(
                'Patient: ${_clean(p.name)}   '
                'Age: ${p.age}   Sex: ${_clean(p.sex)}',
                style: pw.TextStyle(fontSize: 8, color: _white)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Generated',
                style: pw.TextStyle(fontSize: 7, color: _white)),
            pw.Text(_fmtDate(d),
                style: pw.TextStyle(
                    fontSize: 8, color: _white,
                    fontWeight: pw.FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  // Page footer
  static pw.Widget _footer(pw.Context ctx) {
    final s = pw.TextStyle(fontSize: 7, color: _grey);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('AF-Screen v5.0 | Ashesi University Capstone 2024/25',
              style: s),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: s),
        ],
      ),
    );
  }

  // Section title 
  static pw.Widget _secTitle(String t) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _blue, width: 1.5))),
      child: pw.Text(t,
          style: pw.TextStyle(
              fontSize: 12, color: _blue,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  // ── AF result banner ──────────────────────────────────────────
  static pw.Widget _resultBanner(Measurement m) {
    final isAF     = m.afResult == AfResult.possibleAF;
    final isInconc = m.afResult == AfResult.inconclusive;
    final color    = isAF ? _red : isInconc ? _amber : _green;
    final label    = isAF ? 'Possible AF'
        : isInconc ? 'Inconclusive' : 'Normal Sinus Rhythm';
    final desc     = isAF
        ? 'Irregular rhythm detected. Please consult a doctor for a 12-lead ECG.'
        : isInconc
            ? 'Insufficient signal quality. Please retake the measurement.'
            : 'Heart rhythm appears regular. No signs of AF detected.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _greyBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Row(children: [
        pw.Container(
            width: 10, height: 10,
            decoration:
                pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 13, color: color,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(desc,
                    style: pw.TextStyle(fontSize: 7, color: _grey)),
              ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Heart Rate',
              style: pw.TextStyle(fontSize: 7, color: _grey)),
          pw.Text('${m.heartRate.toStringAsFixed(0)} bpm',
              style: pw.TextStyle(
                  fontSize: 14, color: _black,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(_fmtDateTime(m.timestamp),
              style: pw.TextStyle(fontSize: 7, color: _grey)),
        ]),
      ]),
    );
  }

  // ── HRV metrics grid ─────────────────────────────────────────
  static pw.Widget _hrvGrid(Measurement m) {
    final sdsdVal = m.sdsd > 0 ? m.sdsd : m.rmssd / 1.414;
    final metrics = [
      _M('Mean RR',    '${m.meanRR.toStringAsFixed(0)} ms',    null),
      _M('Heart Rate', '${m.heartRate.toStringAsFixed(0)} bpm', null),
      _M('pRR50 (%)',  '${m.pRR50.toStringAsFixed(1)}',        m.pRR50 < 3.0 ? _amber : null),
      _M('pRR20 (%)',  '${m.pRR20.toStringAsFixed(1)}',        null),
      _M('SDSD (ms)',  '${sdsdVal.toStringAsFixed(1)}',         sdsdVal > 50 ? _amber : null),
      _M('RMSSD (ms)', '${m.rmssd.toStringAsFixed(1)}',        null),
    ];

    final rows = <pw.Widget>[];
    for (int i = 0; i < metrics.length; i += 3) {
      rows.add(pw.Row(children: [
        for (int j = i; j < i + 3 && j < metrics.length; j++)
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 5),
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: pw.BoxDecoration(
                color: metrics[j].flag != null
                    ? metrics[j].flag!.shade(0.9)
                    : _greyBg,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(
                    color: metrics[j].flag ?? _border,
                    width: metrics[j].flag != null ? 1.0 : 0.5),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(metrics[j].label,
                        style: pw.TextStyle(fontSize: 7, color: _grey)),
                    pw.SizedBox(height: 2),
                    pw.Text(metrics[j].value,
                        style: pw.TextStyle(
                            fontSize: 11,
                            color: metrics[j].flag ?? _black,
                            fontWeight: pw.FontWeight.bold)),
                  ]),
            ),
          ),
      ]));
      rows.add(pw.SizedBox(height: 6));
    }
    return pw.Column(children: rows);
  }

  // ── Score header ──────────────────────────────────────────────
  static pw.Widget _scoreHeader(StrokeScoreResult r) {
    final color = _riskColor(r.risk);
    final label = r.risk == StrokeRisk.low ? 'Low Risk'
        : r.risk == StrokeRisk.lowModerate ? 'Low-Moderate Risk'
        : 'High Risk';
    final advice = r.risk == StrokeRisk.low
        ? 'Score 0. Continue monitoring and maintain a healthy lifestyle.'
        : r.risk == StrokeRisk.lowModerate
            ? 'Score 1. Anticoagulation may be considered. Discuss with your doctor.'
            : 'Score >= 2. High risk. Anticoagulation therapy recommended. See your doctor promptly.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _greyBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Row(children: [
        pw.Container(
          width: 50, height: 50,
          decoration: pw.BoxDecoration(
              color: color, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Center(
            child: pw.Text('${r.totalScore}/${r.maxScore}',
                style: pw.TextStyle(
                    fontSize: 14, color: _white,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 12, color: color,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text(advice,
                    style: pw.TextStyle(fontSize: 8, color: _grey)),
                if (r.afDetected) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'AF detected - score is clinically indicated.',
                    style: pw.TextStyle(
                        fontSize: 7, color: _red,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ]),
        ),
      ]),
    );
  }

  // ── Factors table ─────────────────────────────────────────────
  static pw.Widget _factorsTable(
      String title, List<ScoringFactor> factors) {
    if (factors.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 9, color: _black,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.5),
            1: const pw.FlexColumnWidth(0.7),
            2: const pw.FlexColumnWidth(0.9),
            3: const pw.FlexColumnWidth(2.8),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _greyBg),
              children: [
                _tc('Factor',    hdr: true),
                _tc('Pts',       hdr: true),
                _tc('Status',    hdr: true),
                _tc('Reference', hdr: true),
              ],
            ),
            ...factors.map((f) {
              final isTriggered = f.triggered == true;
              final statusText  = f.triggered == null ? 'N/A'
                  : isTriggered ? 'Yes' : 'No';
              final statusColor = f.triggered == null ? _grey
                  : isTriggered ? _red : _green;
              return pw.TableRow(children: [
                _tc(_clean(f.name)),
                _tc(isTriggered && f.points > 0 ? '+${f.points}' : '-',
                    color: isTriggered && f.points > 0 ? _red : _grey),
                _tc(statusText, color: statusColor, bld: isTriggered),
                _tc(_clean(f.reference), sm: true),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  // ── History table ─────────────────────────────────────────────
  static pw.Widget _historyTable(List<Measurement> history) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(0.9),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _greyBg),
          children: [
            _tc('Date & Time', hdr: true),
            _tc('AF Result',   hdr: true),
            _tc('HR (bpm)',    hdr: true),
            _tc('pRR50 (%)',   hdr: true),
            _tc('SDSD (ms)',   hdr: true),
            _tc('Score /7',    hdr: true),
          ],
        ),
        ...history.map((m) {
          final isAF    = m.afResult == AfResult.possibleAF;
          final sdsdVal = m.sdsd > 0 ? m.sdsd : m.rmssd / 1.414;
          return pw.TableRow(children: [
            _tc(_fmtDateTime(m.timestamp)),
            _tc(isAF ? 'Possible AF'
                : m.afResult == AfResult.inconclusive
                    ? 'Inconclusive' : 'Normal',
                color: isAF ? _red : _green, bld: isAF),
            _tc(m.heartRate.toStringAsFixed(0)),
            _tc(m.pRR50.toStringAsFixed(1),
                color: m.pRR50 < 3.0 ? _amber : null),
            _tc(sdsdVal.toStringAsFixed(1),
                color: sdsdVal > 50 ? _amber : null),
            _tc('${m.strokeScore}/7',
                color: m.strokeScore >= 2 ? _red : _green),
          ]);
        }),
      ],
    );
  }

  // ── Recommendation card ───────────────────────────────────────
  static pw.Widget _recCard(Recommendation r) {
    final color = r.priority == RecommendationPriority.urgent ? _red
        : r.priority == RecommendationPriority.warning ? _amber
        : _green;
    final tag = r.priority == RecommendationPriority.urgent ? '[URGENT]'
        : r.priority == RecommendationPriority.warning ? '[NOTE]'
        : '[TIP]';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _greyBg,
        border: pw.Border(
          left:   pw.BorderSide(color: color,   width: 3),
          top:    pw.BorderSide(color: _border, width: 0.5),
          right:  pw.BorderSide(color: _border, width: 0.5),
          bottom: pw.BorderSide(color: _border, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text(tag,
                style: pw.TextStyle(
                    fontSize: 8, color: color,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Text(_clean(r.title),
                  style: pw.TextStyle(
                      fontSize: 9, color: _black,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ]),
          pw.SizedBox(height: 3),
          pw.Text(_clean(r.body),
              style: pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
    );
  }

  // ── Disclaimer ────────────────────────────────────────────────
  static pw.Widget _disclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greyBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Text(
        'MEDICAL DISCLAIMER: This report is generated by a research prototype '
        'and is NOT a substitute for professional medical advice, diagnosis, or '
        'treatment. The AF detection algorithm uses a machine learning classifier '
        'validated on the MIT-BIH Atrial Fibrillation Database. CHA2DS2-VASc '
        'scoring is based on self-reported clinical history and may be incomplete. '
        'Always consult a qualified healthcare professional before making any '
        'medical decisions. Ghana Emergency: 112 | Ambulance: 193.',
        style: pw.TextStyle(
            fontSize: 7, color: _grey,
            fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  // ── Info box ──────────────────────────────────────────────────
  static pw.Widget _infoBox(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _greyBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 9, color: color)),
    );
  }

  // ── Table cell ────────────────────────────────────────────────
  static pw.Widget _tc(String text, {
    bool hdr = false,
    bool bld = false,
    bool sm  = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize:   sm ? 6.5 : hdr ? 8 : 7.5,
            color:      color ?? _black,
            fontWeight: (hdr || bld)
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          )),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  static PdfColor _riskColor(StrokeRisk r) {
    switch (r) {
      case StrokeRisk.low:         return _green;
      case StrokeRisk.lowModerate: return _amber;
      case StrokeRisk.high:        return _red;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  static String _stamp(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}

class _M {
  final String label;
  final String value;
  final PdfColor? flag;
  const _M(this.label, this.value, this.flag);
}