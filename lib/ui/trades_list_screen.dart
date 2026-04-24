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
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              showTimeFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              const Text(
                'No trades yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your saved trades will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
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
    final gradeColor = _gradeColor(trade.grade);
    final rColor = trade.resultR >= 0 ? Colors.green : Colors.red;
    final dt = trade.dateTime;

    final dtText =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: gradeColor.withOpacity(0.15),
                      child: Text(
                        trade.grade.label,
                        style: TextStyle(
                          color: gradeColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                trade.market.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '• ${trade.symbol}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              _MiniPill(
                                text: trade.direction.label,
                                bg: trade.direction == TradeDirection.long
                                    ? Colors.green.withOpacity(0.10)
                                    : Colors.red.withOpacity(0.10),
                                fg: trade.direction == TradeDirection.long
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dtText,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MiniPill(
                      text:
                      '${trade.resultR >= 0 ? '+' : ''}${trade.resultR.toStringAsFixed(2)}R',
                      bg: rColor.withOpacity(0.10),
                      fg: rColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Entry', value: '${trade.entry}'),
                    _InfoChip(label: 'SL', value: '${trade.stopLoss}'),
                    _InfoChip(label: 'Exit', value: '${trade.exit}'),
                  ],
                ),
                if ((trade.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.black.withOpacity(0.03),
                    ),
                    child: Text(
                      trade.note!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ),
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

class _MiniPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _MiniPill({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withOpacity(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
      ],
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