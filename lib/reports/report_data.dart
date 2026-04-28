import '../models/trade.dart';

class GradeReportData {
  final TradeGrade grade;
  final int count;
  final double percent;
  final double netR;

  const GradeReportData({
    required this.grade,
    required this.count,
    required this.percent,
    required this.netR,
  });
}

class StrategyReportData {
  final String strategy;
  final int count;
  final double netR;
  final double avgR;
  final double winrate;

  const StrategyReportData({
    required this.strategy,
    required this.count,
    required this.netR,
    required this.avgR,
    required this.winrate,
  });
}

class ReportData {
  final bool isVi;

  final String title;
  final String periodLabel;
  final DateTime generatedAt;

  final List<Trade> trades;

  final int totalTrades;
  final double netR;
  final double avgR;
  final double winrate;
  final double maxDrawdown;

  final double totalFees;
  final double netMoney;

  final List<double> equityCurve;
  final List<GradeReportData> gradeBreakdown;
  final List<StrategyReportData> strategyBreakdown;
  final List<String> insights;

  const ReportData({
    required this.isVi,
    required this.title,
    required this.periodLabel,
    required this.generatedAt,
    required this.trades,
    required this.totalTrades,
    required this.netR,
    required this.avgR,
    required this.winrate,
    required this.maxDrawdown,
    required this.totalFees,
    required this.netMoney,
    required this.equityCurve,
    required this.gradeBreakdown,
    required this.strategyBreakdown,
    required this.insights,
  });
}