  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'time_filter_sheet.dart';
  import '../l10n/strings.dart';
  import '../models/trade.dart';
  import '../state/trades_store.dart';


  class DashboardScreen extends StatelessWidget {
    const DashboardScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final store = context.watch<TradesStore>();
      final s = S.of(context);

      return Scaffold(
        appBar: AppBar(
          title: Text(s.dashboard),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: () {
                showTimeFilterBottomSheet(context);
              },
            ),
          ],
        ),
        body: _buildBody(context, store, s),
      );
    }

    Widget _buildBody(BuildContext context, TradesStore store, S s) {
      if (!store.loaded) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = store.filteredItems;
      final filterLabel = store.timeFilterLabel(isVi: s.isVi);

      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 56,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 14),
                Text(
                  s.dashboard,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.dashboardTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                Text(
                  '${s.noTradesYet}\n${s.addFirstTradeToSeeStats}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        );
      }

      final totalTrades = items.length;
      final double netR = items.fold<double>(0, (sum, t) => sum + t.resultR);
      final double avgR = totalTrades == 0 ? 0.0 : netR / totalTrades;
      final wins = items.where((t) => t.resultR > 0).length;
      final double winrate =
      totalTrades == 0 ? 0.0 : (wins / totalTrades) * 100.0;

      final aCount = items.where((t) => t.grade == TradeGrade.a).length;
      final aMinusCount = items.where((t) => t.grade == TradeGrade.aMinus).length;
      final bCount = items.where((t) => t.grade == TradeGrade.b).length;
      final double bRatio =
      totalTrades == 0 ? 0.0 : (bCount / totalTrades) * 100.0;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FilterSummaryPill(
            label: filterLabel,
            count: items.length,
            isVi: s.isVi,
          ),
          const SizedBox(height: 12),
          Text(
            s.dashboardTagline,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _HeroSummaryCard(
            netR: netR,
            winrate: winrate,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                title: s.totalTrades,
                value: '$totalTrades',
                icon: Icons.format_list_numbered,
              ),
              _MetricCard(
                title: s.netR,
                value: netR.toStringAsFixed(2),
                icon: Icons.show_chart,
                valueColor: netR >= 0 ? Colors.green : Colors.red,
              ),
              _MetricCard(
                title: s.avgR,
                value: avgR.toStringAsFixed(2),
                icon: Icons.analytics_outlined,
                valueColor: avgR >= 0 ? Colors.green : Colors.red,
              ),
              _MetricCard(
                title: s.winrate,
                value: '${winrate.toStringAsFixed(1)}%',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            s.gradeBreakdown,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _GradeBarCard(
            label: 'A',
            count: aCount,
            total: totalTrades,
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          _GradeBarCard(
            label: 'A-',
            count: aMinusCount,
            total: totalTrades,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          _GradeBarCard(
            label: 'B',
            count: bCount,
            total: totalTrades,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: bRatio > 0 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.bTradeRatio(bRatio),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  class _HeroSummaryCard extends StatelessWidget {
    final double netR;
    final double winrate;

    const _HeroSummaryCard({
      required this.netR,
      required this.winrate,
    });

    @override
    Widget build(BuildContext context) {
      final positive = netR >= 0;
      final color = positive ? Colors.green : Colors.red;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                positive ? Icons.trending_up : Icons.trending_down,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net R',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${positive ? '+' : ''}${netR.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Winrate ${winrate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  class _MetricCard extends StatelessWidget {
    final String title;
    final String value;
    final IconData icon;
    final Color? valueColor;

    const _MetricCard({
      required this.title,
      required this.value,
      required this.icon,
      this.valueColor,
    });

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: 165,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  class _GradeBarCard extends StatelessWidget {
    final String label;
    final int count;
    final int total;
    final Color color;

    const _GradeBarCard({
      required this.label,
      required this.count,
      required this.total,
      required this.color,
    });

    @override
    Widget build(BuildContext context) {
      final ratio = total == 0 ? 0.0 : count / total;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withOpacity(0.14),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count / $total',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${(ratio * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  class _FilterSummaryPill extends StatelessWidget {
    final String label;
    final int count;
    final bool isVi;

    const _FilterSummaryPill({
      required this.label,
      required this.count,
      required this.isVi,
    });

    @override
    Widget build(BuildContext context) {
      final color = Theme.of(context).colorScheme.primary;

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                '$label · $count ${isVi ? 'lệnh' : 'trades'}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }