import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trade.dart';
import 'report_data.dart';

class ImageReportCard extends StatelessWidget {
  final ReportData data;

  const ImageReportCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final generatedText = DateFormat('dd/MM/yyyy HH:mm').format(data.generatedAt);

    return Container(
      width: 1080,
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
      ),
      child: Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              periodLabel: data.periodLabel,
              generatedText: generatedText,
            ),
            const SizedBox(height: 30),
            _EquityCurveSection(data: data),
            const SizedBox(height: 28),
            _MetricGrid(data: data),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _GradeBreakdown(data: data)),
                const SizedBox(width: 22),
                Expanded(child: _Insights(data: data)),
              ],
            ),
            const SizedBox(height: 30),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String periodLabel;
  final String generatedText;

  const _Header({
    required this.periodLabel,
    required this.generatedText,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.assessment_outlined,
            color: primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Decision Journal Report',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _SmallPill(
                    icon: Icons.date_range_outlined,
                    text: periodLabel,
                    color: primary,
                  ),
                  _SmallPill(
                    icon: Icons.schedule_outlined,
                    text: generatedText,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquityCurveSection extends StatelessWidget {
  final ReportData data;

  const _EquityCurveSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final curve = data.equityCurve;
    final minY = _minY(curve);
    final maxY = _maxY(curve);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Equity Curve (R)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _SmallPill(
                icon: Icons.trending_up,
                text: '${data.netR >= 0 ? '+' : ''}${data.netR.toStringAsFixed(2)}R',
                color: data.netR >= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 300,
            child: data.totalTrades == 0
                ? const Center(
              child: Text(
                'No trades in this period',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                : LineChart(
              LineChartData(
                minX: 0,
                maxX: (curve.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _niceInterval(minY, maxY),
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      interval: _niceInterval(minY, maxY),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _bottomInterval(curve.length),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= curve.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      curve.length,
                          (i) => FlSpot(i.toDouble(), curve[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.18,
                    color: data.netR >= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    barWidth: 5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (data.netR >= 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626))
                          .withOpacity(0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _minY(List<double> curve) {
    if (curve.isEmpty) return -1;
    final minVal = curve.reduce((a, b) => a < b ? a : b);
    return minVal == 0 ? -1 : minVal - (minVal.abs() * 0.18) - 0.5;
  }

  static double _maxY(List<double> curve) {
    if (curve.isEmpty) return 1;
    final maxVal = curve.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 1 : maxVal + (maxVal.abs() * 0.18) + 0.5;
  }

  static double _niceInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return 10;
  }

  static double _bottomInterval(int length) {
    if (length <= 6) return 1;
    if (length <= 15) return 2;
    if (length <= 30) return 5;
    if (length <= 60) return 10;
    return 20;
  }
}

class _MetricGrid extends StatelessWidget {
  final ReportData data;

  const _MetricGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Total',
            value: '${data.totalTrades}',
            subtitle: 'trades',
            icon: Icons.format_list_numbered,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Net R',
            value: '${data.netR >= 0 ? '+' : ''}${data.netR.toStringAsFixed(2)}',
            subtitle: 'total result',
            icon: Icons.show_chart,
            color: data.netR >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Avg R',
            value: '${data.avgR >= 0 ? '+' : ''}${data.avgR.toStringAsFixed(2)}',
            subtitle: 'per trade',
            icon: Icons.analytics_outlined,
            color: data.avgR >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Winrate',
            value: '${data.winrate.toStringAsFixed(1)}%',
            subtitle: 'winning trades',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            label: 'Max DD',
            value: '-${data.maxDrawdown.toStringAsFixed(2)}',
            subtitle: 'R drawdown',
            icon: Icons.trending_down,
            color: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withOpacity(0.10),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBreakdown extends StatelessWidget {
  final ReportData data;

  const _GradeBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grade Breakdown',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          ...data.gradeBreakdown.map(
                (g) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _GradeRow(data: g),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final GradeReportData data;

  const _GradeRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor(data.grade);
    final label = _gradeLabel(data.grade);

    return Row(
      children: [
        Container(
          width: 48,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.percent / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            '${data.count} · ${data.percent.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Color _gradeColor(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return const Color(0xFF16A34A);
      case TradeGrade.aMinus:
        return const Color(0xFFEA580C);
      case TradeGrade.b:
        return const Color(0xFFDC2626);
    }
  }

  String _gradeLabel(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return 'A';
      case TradeGrade.aMinus:
        return 'A-';
      case TradeGrade.b:
        return 'B';
    }
  }
}

class _Insights extends StatelessWidget {
  final ReportData data;

  const _Insights({required this.data});

  @override
  Widget build(BuildContext context) {
    final insights = data.insights.isEmpty
        ? ['No insights available yet.']
        : data.insights.take(3).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ...insights.map(
                (text) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_graph_outlined,
          color: Color(0xFF2563EB),
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Generated by Decision Journal',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SmallPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}