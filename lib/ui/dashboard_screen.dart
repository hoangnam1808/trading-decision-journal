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
            tooltip: s.isVi ? 'Lọc thời gian' : 'Time filter',
            icon: const Icon(Icons.tune_rounded),
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
      return _EmptyDashboardState(
        title: s.dashboard,
        tagline: s.dashboardTagline,
        message: '${s.noTradesYet}\n${s.addFirstTradeToSeeStats}',
        isVi: s.isVi,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _FilterSummaryPill(
                label: filterLabel,
                count: items.length,
                isVi: s.isVi,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          s.dashboardTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _HeroSummaryCard(
          netR: netR,
          winrate: winrate,
          totalTrades: totalTrades,
          isVi: s.isVi,
        ),
        const SizedBox(height: 16),
        _MetricGrid(
          children: [
            _MetricCard(
              title: s.totalTrades,
              value: '$totalTrades',
              icon: Icons.format_list_numbered_rounded,
            ),
            _MetricCard(
              title: s.netR,
              value: _signedNumber(netR),
              icon: Icons.show_chart_rounded,
              valueColor: _resultColor(netR),
            ),
            _MetricCard(
              title: s.avgR,
              value: _signedNumber(avgR),
              icon: Icons.analytics_rounded,
              valueColor: _resultColor(avgR),
            ),
            _MetricCard(
              title: s.winrate,
              value: '${winrate.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: s.gradeBreakdown,
          subtitle: s.isVi
              ? 'Chất lượng quyết định theo từng nhóm lệnh'
              : 'Decision quality by trade grade',
        ),
        const SizedBox(height: 12),
        _GradeBreakdownCard(
          total: totalTrades,
          rows: [
            _GradeRowData(
              label: 'A',
              count: aCount,
              color: Colors.green,
              description: s.isVi ? 'Kèo chất lượng cao' : 'High quality',
            ),
            _GradeRowData(
              label: 'A-',
              count: aMinusCount,
              color: Colors.orange,
              description: s.isVi ? 'Kèo trung bình khá' : 'Mixed quality',
            ),
            _GradeRowData(
              label: 'B',
              count: bCount,
              color: Colors.red,
              description: s.isVi ? 'Nên hạn chế' : 'Should reduce',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _BTradeRatioCard(
          text: s.bTradeRatio(bRatio),
          bRatio: bRatio,
          isVi: s.isVi,
        ),
      ],
    );
  }
}

String _signedNumber(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}';
}

Color _resultColor(double value) {
  if (value > 0) return Colors.green;
  if (value < 0) return Colors.red;
  return Colors.orange;
}

class _ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  const _ProCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? isDark
            ? const Color(0xFF111827)
            : Colors.white
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.055),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  final double netR;
  final double winrate;
  final int totalTrades;
  final bool isVi;

  const _HeroSummaryCard({
    required this.netR,
    required this.winrate,
    required this.totalTrades,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = netR >= 0;
    final resultColor = positive ? Colors.green : Colors.red;

    return _ProCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withOpacity(0.14),
          theme.colorScheme.primaryContainer.withOpacity(0.20),
          theme.colorScheme.surface.withOpacity(0.94),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resultColor.withOpacity(0.13),
              border: Border.all(
                color: resultColor.withOpacity(0.24),
              ),
            ),
            child: Icon(
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: resultColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVi ? 'Hiệu suất theo bộ lọc' : 'Period result',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _signedNumber(netR),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: resultColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      icon: Icons.percent_rounded,
                      label: '${winrate.toStringAsFixed(1)}%',
                    ),
                    _MiniChip(
                      icon: Icons.receipt_long_rounded,
                      label: '$totalTrades ${isVi ? 'lệnh' : 'trades'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<Widget> children;

  const _MetricGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: wide ? 1.2 : 1.18,
          children: children,
        );
      },
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
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GradeBreakdownCard extends StatelessWidget {
  final int total;
  final List<_GradeRowData> rows;

  const _GradeBreakdownCard({
    required this.total,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _GradeBarRow(
              data: rows[i],
              total: total,
            ),
            if (i != rows.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _GradeRowData {
  final String label;
  final int count;
  final Color color;
  final String description;

  const _GradeRowData({
    required this.label,
    required this.count,
    required this.color,
    required this.description,
  });
}

class _GradeBarRow extends StatelessWidget {
  final _GradeRowData data;
  final int total;

  const _GradeBarRow({
    required this.data,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : data.count / total;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: data.color.withOpacity(0.22),
                ),
              ),
              child: Text(
                data.label,
                style: TextStyle(
                  color: data.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.count} / $total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(ratio * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: data.color,
                fontWeight: FontWeight.w900,
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
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(data.color),
          ),
        ),
      ],
    );
  }
}

class _BTradeRatioCard extends StatelessWidget {
  final String text;
  final double bRatio;
  final bool isVi;

  const _BTradeRatioCard({
    required this.text,
    required this.bRatio,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthy = bRatio <= 10;
    final color = healthy ? Colors.green : Colors.orange;

    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              healthy
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  healthy
                      ? isVi
                      ? 'Kỷ luật đang ổn. Tiếp tục giữ B trade thấp.'
                      : 'Discipline looks healthy. Keep B trades low.'
                      : isVi
                      ? 'Cần giảm B trade để bảo vệ expectancy.'
                      : 'Reduce B trades to protect expectancy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$label · $count ${isVi ? 'lệnh' : 'trades'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  final String title;
  final String tagline;
  final String message;
  final bool isVi;

  const _EmptyDashboardState({
    required this.title,
    required this.tagline,
    required this.message,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ProCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 34,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: primary.withOpacity(0.08),
                  border: Border.all(
                    color: primary.withOpacity(0.18),
                  ),
                ),
                child: Text(
                  isVi
                      ? 'Làm bởi trader, dành cho trader.'
                      : 'Built by a trader, for traders.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}