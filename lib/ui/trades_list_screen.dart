import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../state/trades_store.dart';
import 'time_filter_sheet.dart';
import 'trade_detail_screen.dart';

class TradesListScreen extends StatelessWidget {
  const TradesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.watch<TradesStore>();
    final items = store.filteredItems;
    final filterLabel = store.timeFilterLabel(isVi: s.isVi);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.trades),
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
      body: items.isEmpty
          ? _EmptyTradesState(isVi: s.isVi)
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _FilterSummaryPill(
              label: filterLabel,
              count: items.length,
              isVi: s.isVi,
            );
          }

          final t = items[i - 1];
          return _TradeCard(
            trade: t,
            index: i - 1,
          );
        },
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final Trade trade;
  final int index;

  const _TradeCard({
    required this.trade,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final gradeColor = _gradeColor(trade.grade);
    final rColor = trade.resultR >= 0 ? Colors.green : Colors.red;
    final dt = trade.dateTime;

    final dtText =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final strategyText =
    trade.strategy.trim().isEmpty ? '—' : trade.strategy.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TradeDetailScreen(
                trade: trade,
                index: index,
              ),
            ),
          );
        },
        child: _ProCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradeBadge(
                    label: trade.grade.label,
                    color: gradeColor,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              trade.symbol,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            _MiniPill(
                              text: trade.market.label,
                              color: theme.colorScheme.primary,
                            ),
                            _MiniPill(
                              text: trade.direction.label,
                              icon: trade.direction == TradeDirection.long
                                  ? Icons.north_east_rounded
                                  : Icons.south_east_rounded,
                              color: trade.direction == TradeDirection.long
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                dtText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ResultPill(
                    value: trade.resultR,
                    color: rColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: s.entry, value: '${trade.entry}'),
                  _InfoChip(label: 'SL', value: '${trade.stopLoss}'),
                  _InfoChip(label: s.exit, value: '${trade.exit}'),
                  _InfoChip(label: s.strategy, value: strategyText),
                ],
              ),
              if ((trade.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _NoteBox(text: trade.note!.trim()),
              ],
              if ((trade.beforeImagePath?.isNotEmpty ?? false) ||
                  (trade.afterImagePath?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (trade.beforeImagePath?.isNotEmpty ?? false)
                      _ThumbBlock(
                        title: 'Before',
                        path: trade.beforeImagePath!,
                      ),
                    if ((trade.beforeImagePath?.isNotEmpty ?? false) &&
                        (trade.afterImagePath?.isNotEmpty ?? false))
                      const SizedBox(width: 10),
                    if (trade.afterImagePath?.isNotEmpty ?? false)
                      _ThumbBlock(
                        title: 'After',
                        path: trade.afterImagePath!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeColor(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return Colors.green;
      case TradeGrade.aMinus:
        return Colors.orange;
      case TradeGrade.b:
        return Colors.red;
    }
  }
}

class _ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ProCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Ink(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
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

class _GradeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _GradeBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final double value;
  final Color color;

  const _ResultPill({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}R';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _MiniPill({
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;

  const _NoteBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThumbBlock extends StatelessWidget {
  final String title;
  final String path;

  const _ThumbBlock({
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: 92,
              fit: BoxFit.cover,
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

class _EmptyTradesState extends StatelessWidget {
  final bool isVi;

  const _EmptyTradesState({
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVi ? 'Chưa có lệnh nào' : 'No trades yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isVi
                    ? 'Các lệnh đã lưu sẽ xuất hiện ở đây.'
                    : 'Your saved trades will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}