import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/trade.dart';
import 'equity_chart_png.dart';
import 'report_data.dart';

class PdfReportService {
  static Future<void> exportAndShare(ReportData data) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final chartBytes = await EquityChartPng.generate(data.equityCurve);
    final chartImage = pw.MemoryImage(chartBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            _buildHeader(data),
            pw.SizedBox(height: 18),
            _buildSummaryGrid(data),
            pw.SizedBox(height: 18),
            _buildEquityChart(data, chartImage),
            pw.SizedBox(height: 18),
            _buildGradeBreakdown(data),
            pw.SizedBox(height: 18),
            _buildStrategyBreakdown(data),
            pw.SizedBox(height: 18),
            _buildInsights(data),
            pw.SizedBox(height: 24),
            _buildFooter(data),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName =
        'decision_journal_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: data.isVi
          ? 'Báo cáo PDF Decision Journal'
          : 'Decision Journal PDF Report',
    );
  }

  static pw.Widget _buildHeader(ReportData data) {
    final generatedText = DateFormat('dd/MM/yyyy HH:mm').format(data.generatedAt);

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EFF6FF'),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            data.title,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.isVi
                ? 'Giai đoạn: ${data.periodLabel}'
                : 'Period: ${data.periodLabel}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColor.fromHex('#334155'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.isVi ? 'Tạo lúc: $generatedText' : 'Generated: $generatedText',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryGrid(ReportData data) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricBox(
          data.isVi ? 'Tổng lệnh' : 'Total Trades',
          '${data.totalTrades}',
        ),
        _metricBox('Net R', _signed(data.netR)),
        _metricBox('Avg R', _signed(data.avgR)),
        _metricBox('Winrate', '${data.winrate.toStringAsFixed(1)}%'),
        _metricBox('Max DD', _drawdownText(data.maxDrawdown)),
        _metricBox(
          data.isVi ? 'Tổng phí' : 'Total Fees',
          '-\$${data.totalFees.toStringAsFixed(2)}',
        ),
        _metricBox('Net Money', _moneyText(data.netMoney)),
      ],
    );
  }

  static pw.Widget _metricBox(String label, String value) {
    return pw.Container(
      width: 135,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEquityChart(
      ReportData data,
      pw.MemoryImage chartImage,
      ) {
    return _section(
      title: data.isVi ? 'Đường Equity' : 'Equity Curve',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(
            chartImage,
            fit: pw.BoxFit.contain,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.isVi
                ? 'Kết quả net: ${_signed(data.netR)} · Net money: ${_moneyText(data.netMoney)} · Phí: -\$${data.totalFees.toStringAsFixed(2)}'
                : 'Net result: ${_signed(data.netR)} · Net money: ${_moneyText(data.netMoney)} · Fees: -\$${data.totalFees.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGradeBreakdown(ReportData data) {
    return _section(
      title: data.isVi ? 'Phân bổ chất lượng' : 'Grade Breakdown',
      child: pw.Column(
        children: data.gradeBreakdown.map((g) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 36,
                  child: pw.Text(
                    _gradeLabel(g.grade),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.LayoutBuilder(
                    builder: (context, constraints) {
                      final ratio = (g.percent / 100).clamp(0.0, 1.0);
                      final maxWidth = constraints?.maxWidth ?? 160;
                      final barWidth = maxWidth * ratio;

                      return pw.Container(
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#E2E8F0'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: barWidth <= 0
                            ? pw.SizedBox()
                            : pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Container(
                            width: barWidth,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: _gradePdfColor(g.grade),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    data.isVi
                        ? '${g.count} lệnh · ${g.percent.toStringAsFixed(0)}%'
                        : '${g.count} trades · ${g.percent.toStringAsFixed(0)}%',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildStrategyBreakdown(ReportData data) {
    final strategies = data.strategyBreakdown.take(6).toList();

    return _section(
      title: data.isVi ? 'Phân bổ chiến lược' : 'Strategy Breakdown',
      child: strategies.isEmpty
          ? pw.Text(
        data.isVi ? 'Chưa có dữ liệu chiến lược.' : 'No strategy data.',
        style: const pw.TextStyle(fontSize: 10),
      )
          : pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0')),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          _tableRow(
            [
              data.isVi ? 'Chiến lược' : 'Strategy',
              data.isVi ? 'Lệnh' : 'Trades',
              'Net R',
              'Winrate',
            ],
            header: true,
          ),
          ...strategies.map(
                (s) => _tableRow([
              s.strategy,
              '${s.count}',
              _signed(s.netR),
              '${s.winrate.toStringAsFixed(1)}%',
            ]),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _tableRow(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: header
          ? pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9'))
          : null,
      children: cells.map((text) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildInsights(ReportData data) {
    final insights = data.insights.isEmpty
        ? [
      data.isVi
          ? 'Chưa có đủ dữ liệu để tạo điểm đáng chú ý.'
          : 'No insights available yet.'
    ]
        : data.insights;

    return _section(
      title: data.isVi ? 'Điểm đáng chú ý' : 'Key Insights',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: insights.map((insight) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              '• $insight',
              style: const pw.TextStyle(fontSize: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildFooter(ReportData data) {
    return pw.Center(
      child: pw.Text(
        data.isVi
            ? 'Được tạo bởi Decision Journal'
            : 'Generated by Decision Journal',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromHex('#64748B'),
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _section({
    required String title,
    required pw.Widget child,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  static String _signed(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}R';
  }

  static String _moneyText(double value) {
    return '${value >= 0 ? '+' : ''}\$${value.toStringAsFixed(2)}';
  }

  static String _drawdownText(double value) {
    if (value.abs() < 0.005) return '0.00R';
    return '-${value.toStringAsFixed(2)}R';
  }

  static String _gradeLabel(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return 'A';
      case TradeGrade.aMinus:
        return 'A-';
      case TradeGrade.b:
        return 'B';
    }
  }

  static PdfColor _gradePdfColor(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return PdfColor.fromHex('#16A34A');
      case TradeGrade.aMinus:
        return PdfColor.fromHex('#EA580C');
      case TradeGrade.b:
        return PdfColor.fromHex('#DC2626');
    }
  }
}