import '../models/trade.dart';
import 'report_data.dart';

class ReportBuilder {
  static ReportData build({
    required List<Trade> trades,
    required String periodLabel,
    required double cashPerR,
  }) {
    final sortedTrades = [...trades]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final totalTrades = sortedTrades.length;
    final netR = sortedTrades.fold<double>(
      0,
          (sum, trade) => sum + trade.resultR,
    );

    final avgR = totalTrades == 0 ? 0.0 : netR / totalTrades;

    final wins = sortedTrades.where((trade) => trade.resultR > 0).length;
    final winrate = totalTrades == 0 ? 0.0 : wins / totalTrades * 100;

    final equityCurve = _buildEquityCurve(sortedTrades);
    final maxDrawdown = _maxDrawdown(equityCurve);
    final totalFees = sortedTrades.fold<double>(
      0,
          (sum, trade) => sum + trade.fee,
    );

    final netMoney = sortedTrades.fold<double>(
      0,
          (sum, trade) => sum + trade.resultR * cashPerR - trade.fee,
    );

    return ReportData(
      title: 'Decision Journal Report',
      periodLabel: periodLabel,
      generatedAt: DateTime.now(),
      trades: sortedTrades,
      totalTrades: totalTrades,
      netR: netR,
      avgR: avgR,
      winrate: winrate,
      maxDrawdown: maxDrawdown,
      totalFees: totalFees,
      netMoney: netMoney,
      equityCurve: equityCurve,
      gradeBreakdown: _buildGradeBreakdown(sortedTrades),
      strategyBreakdown: _buildStrategyBreakdown(sortedTrades),
      insights: _buildInsights(
        totalTrades: totalTrades,
        netR: netR,
        avgR: avgR,
        winrate: winrate,
        maxDrawdown: maxDrawdown,
        trades: sortedTrades,
      ),
    );
  }

  static List<double> _buildEquityCurve(List<Trade> trades) {
    final curve = <double>[0];
    double equity = 0;

    for (final trade in trades) {
      equity += trade.resultR;
      curve.add(equity);
    }

    return curve;
  }

  static double _maxDrawdown(List<double> curve) {
    if (curve.isEmpty) return 0;

    double peak = curve.first;
    double maxDd = 0;

    for (final value in curve) {
      if (value > peak) {
        peak = value;
      }

      final dd = peak - value;
      if (dd > maxDd) {
        maxDd = dd;
      }
    }

    return maxDd;
  }

  static List<GradeReportData> _buildGradeBreakdown(List<Trade> trades) {
    final total = trades.length;

    GradeReportData item(TradeGrade grade) {
      final gradeTrades = trades.where((trade) => trade.grade == grade).toList();

      final count = gradeTrades.length;
      final percent = total == 0 ? 0.0 : count / total * 100;
      final netR = gradeTrades.fold<double>(
        0,
            (sum, trade) => sum + trade.resultR,
      );

      return GradeReportData(
        grade: grade,
        count: count,
        percent: percent,
        netR: netR,
      );
    }

    return [
      item(TradeGrade.a),
      item(TradeGrade.aMinus),
      item(TradeGrade.b),
    ];
  }

  static List<StrategyReportData> _buildStrategyBreakdown(List<Trade> trades) {
    final map = <String, List<Trade>>{};

    for (final trade in trades) {
      final strategy = trade.strategy.trim().isEmpty
          ? 'No strategy'
          : trade.strategy.trim();

      map.putIfAbsent(strategy, () => []).add(trade);
    }

    final result = map.entries.map((entry) {
      final strategyTrades = entry.value;
      final count = strategyTrades.length;

      final netR = strategyTrades.fold<double>(
        0,
            (sum, trade) => sum + trade.resultR,
      );

      final avgR = count == 0 ? 0.0 : netR / count;

      final wins = strategyTrades.where((trade) => trade.resultR > 0).length;
      final winrate = count == 0 ? 0.0 : wins / count * 100;

      return StrategyReportData(
        strategy: entry.key,
        count: count,
        netR: netR,
        avgR: avgR,
        winrate: winrate,
      );
    }).toList();

    result.sort((a, b) => b.netR.compareTo(a.netR));

    return result;
  }

  static List<String> _buildInsights({
    required int totalTrades,
    required double netR,
    required double avgR,
    required double winrate,
    required double maxDrawdown,
    required List<Trade> trades,
  }) {
    if (totalTrades == 0) {
      return [
        'No trades in this period yet.',
        'Add more trades to generate meaningful insights.',
      ];
    }

    final bTrades = trades.where((trade) => trade.grade == TradeGrade.b).length;
    final bRatio = totalTrades == 0 ? 0.0 : bTrades / totalTrades * 100;

    final insights = <String>[];

    if (netR > 0) {
      insights.add('Positive performance in this period.');
    } else if (netR < 0) {
      insights.add('Negative performance in this period.');
    } else {
      insights.add('Flat performance in this period.');
    }

    if (avgR > 0) {
      insights.add('Average R is positive, showing good trade expectancy.');
    } else {
      insights.add('Average R is not positive yet. Review entry quality and risk.');
    }

    if (bRatio > 25) {
      insights.add('B trades are high. Reducing low-quality trades may improve results.');
    } else {
      insights.add('B trade ratio is under control.');
    }

    if (maxDrawdown > 3) {
      insights.add('Drawdown is meaningful. Consider reducing size after losing streaks.');
    } else {
      insights.add('Drawdown is relatively controlled.');
    }

    return insights.take(3).toList();
  }
}