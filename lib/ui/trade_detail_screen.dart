import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../state/trades_store.dart';
import 'add_trade_flow.dart';

class TradeDetailScreen extends StatelessWidget {
  final Trade trade;
  final int index;

  const TradeDetailScreen({
    super.key,
    required this.trade,
    required this.index,
  });

  int _resolveStoreIndex(TradesStore store) {
    if (index >= 0 &&
        index < store.items.length &&
        _sameTradeBase(store.items[index], trade)) {
      return index;
    }

    return store.items.indexWhere((t) => _sameTradeBase(t, trade));
  }

  static bool _sameTradeBase(Trade a, Trade b) {
    return a.dateTime == b.dateTime &&
        a.market == b.market &&
        a.strategy == b.strategy &&
        a.symbol == b.symbol &&
        a.direction == b.direction &&
        a.entry == b.entry &&
        a.stopLoss == b.stopLoss &&
        a.exit == b.exit &&
        a.fee == b.fee;
  }

  Future<void> _pickAfterImage(
      BuildContext context,
      Trade currentTrade,
      int storeIndex,
      ) async {
    final s = S.read(context);
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory('${appDir.path}/trade_images');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final newPath =
        '${folder.path}/after_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final copied = await File(picked.path).copy(newPath);

    await context.read<TradesStore>().updateAfterImageAt(storeIndex, copied.path);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.afterChartUpdated)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int storeIndex) async {
    final s = S.read(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(s.deleteConfirmTitle),
          content: Text(s.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(s.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    await context.read<TradesStore>().deleteTradeAt(storeIndex);

    if (!context.mounted) return;
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(content: Text(s.tradeDeleted)),
    );
  }

  void _openEdit(BuildContext context, Trade currentTrade, int storeIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTradeFlow(
          initialTrade: currentTrade,
          editIndex: storeIndex,
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String path, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullImageScreen(
          imagePath: path,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.watch<TradesStore>();
    final theme = Theme.of(context);

    final storeIndex = _resolveStoreIndex(store);

    if (storeIndex < 0 || storeIndex >= store.items.length) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tradeDetail)),
        body: Center(
          child: Text(
            s.tradeNotFound,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final currentTrade = store.items[storeIndex];
    final gradeColor = _gradeColor(currentTrade.grade);
    final resultColor = currentTrade.resultR >= 0 ? Colors.green : Colors.red;

    final hasPositionSizing =
        currentTrade.plannedVolume != null ||
            currentTrade.plannedRiskMoney != null ||
            currentTrade.actualRiskMoney != null ||
            (currentTrade.riskCalculatorProfile ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tradeDetail),
        actions: [
          IconButton(
            tooltip: s.deleteTrade,
            onPressed: () => _confirmDelete(context, storeIndex),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _HeroTradeCard(
            trade: currentTrade,
            gradeColor: gradeColor,
            resultColor: resultColor,
          ),
          const SizedBox(height: 14),

          _SectionCard(
            title: s.isVi ? 'Thực thi' : 'Execution',
            icon: Icons.query_stats_rounded,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DetailStat(label: s.entry, value: '${currentTrade.entry}'),
                _DetailStat(
                  label: s.stopLoss,
                  value: '${currentTrade.stopLoss}',
                ),
                _DetailStat(label: s.exit, value: '${currentTrade.exit}'),
                _DetailStat(
                  label: s.isVi ? 'Phí' : 'Fee',
                  value: _feeText(currentTrade.fee),
                ),
                _DetailStat(label: s.grade, value: currentTrade.grade.label),
                _DetailStat(
                  label: s.strategy,
                  value: currentTrade.strategy.trim().isEmpty
                      ? '—'
                      : currentTrade.strategy,
                ),
              ],
            ),
          ),

          if (hasPositionSizing) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Position sizing',
              icon: Icons.calculate_rounded,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DetailStat(
                    label: 'Volume',
                    value: _formatDetailNumber(currentTrade.plannedVolume),
                  ),
                  _DetailStat(
                    label: s.isVi ? 'Risk dự kiến' : 'Planned risk',
                    value: _moneyText(
                      currentTrade.plannedRiskMoney,
                      currentTrade.riskCalculatorAccountCurrency,
                    ),
                  ),
                  _DetailStat(
                    label: s.isVi ? 'Risk thực tế' : 'Actual risk',
                    value: _moneyText(
                      currentTrade.actualRiskMoney,
                      currentTrade.riskCalculatorAccountCurrency,
                    ),
                  ),
                  _DetailStat(
                    label: 'Profile',
                    value: (currentTrade.riskCalculatorProfile ?? '').trim().isEmpty
                        ? '—'
                        : currentTrade.riskCalculatorProfile!,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          _SectionCard(
            title: s.decisionChecklist,
            icon: Icons.fact_check_rounded,
            child: Column(
              children: [
                _ChecklistRow(
                  title: s.isVi ? 'Bối cảnh đúng' : 'Market context valid',
                  value: currentTrade.checklist.contextOk,
                ),
                const SizedBox(height: 10),
                _ChecklistRow(
                  title: s.isVi ? 'Vùng vào hợp lệ' : 'Entry zone valid',
                  value: currentTrade.checklist.entryZoneOk,
                ),
                const SizedBox(height: 10),
                _ChecklistRow(
                  title: s.isVi ? 'Execution đúng' : 'Execution valid',
                  value: currentTrade.checklist.executionOk,
                ),
                const SizedBox(height: 10),
                _ChecklistRow(
                  title: s.isVi ? 'Risk đúng' : 'Risk valid',
                  value: currentTrade.checklist.riskOk,
                ),
                const SizedBox(height: 10),
                _ChecklistRow(
                  title: s.isVi ? 'Kỷ luật cảm xúc' : 'Emotional discipline',
                  value: !currentTrade.checklist.emotional,
                ),
              ],
            ),
          ),

          if ((currentTrade.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: s.note,
              icon: Icons.notes_rounded,
              child: Text(
                currentTrade.note!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          _SectionCard(
            title: s.isVi ? 'Biểu đồ' : 'Charts',
            icon: Icons.image_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentTrade.beforeImagePath?.isNotEmpty ?? false)
                  _ChartPreview(
                    title: s.beforeChartTitle,
                    path: currentTrade.beforeImagePath!,
                    onTap: () => _openImage(
                      context,
                      currentTrade.beforeImagePath!,
                      s.beforeChartTitle,
                    ),
                  ),
                if ((currentTrade.beforeImagePath?.isNotEmpty ?? false) &&
                    (currentTrade.afterImagePath?.isNotEmpty ?? false))
                  const SizedBox(height: 14),
                if (currentTrade.afterImagePath?.isNotEmpty ?? false)
                  _ChartPreview(
                    title: s.afterChartTitle,
                    path: currentTrade.afterImagePath!,
                    onTap: () => _openImage(
                      context,
                      currentTrade.afterImagePath!,
                      s.afterChartTitle,
                    ),
                  ),
                if (!(currentTrade.beforeImagePath?.isNotEmpty ?? false) &&
                    !(currentTrade.afterImagePath?.isNotEmpty ?? false))
                  _EmptyChartMessage(
                    text: s.isVi
                        ? 'Chưa có ảnh chart cho lệnh này.'
                        : 'No chart images for this trade yet.',
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openEdit(context, currentTrade, storeIndex),
                icon: const Icon(Icons.edit_rounded),
                label: Text(s.editTrade),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _pickAfterImage(
                  context,
                  currentTrade,
                  storeIndex,
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  currentTrade.afterImagePath?.isNotEmpty ?? false
                      ? s.replaceLabel
                      : s.afterChartTitle,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _gradeColor(TradeGrade grade) {
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

String _feeText(double fee) {
  if (fee.abs() < 0.005) return '0.00';
  return fee.toStringAsFixed(2);
}

String _formatDetailNumber(double? value) {
  if (value == null) return '—';

  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _moneyText(double? value, String? currency) {
  if (value == null) return '—';

  final c = (currency ?? 'USD').trim().toUpperCase();
  final n = _formatDetailNumber(value);

  if (c == 'USD') return '\$$n';

  return '$c $n';
}

String _dateText(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _HeroTradeCard extends StatelessWidget {
  final Trade trade;
  final Color gradeColor;
  final Color resultColor;

  const _HeroTradeCard({
    required this.trade,
    required this.gradeColor,
    required this.resultColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GradeBadge(
                label: trade.grade.label,
                color: gradeColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          trade.symbol,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        _Pill(
                          text: trade.market.label,
                          color: theme.colorScheme.primary,
                        ),
                        _Pill(
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _dateText(trade.dateTime),
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
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: resultColor.withOpacity(0.12),
              border: Border.all(
                color: resultColor.withOpacity(0.24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  trade.resultR >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: resultColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Result',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: resultColor,
                    ),
                  ),
                ),
                Text(
                  '${trade.resultR >= 0 ? '+' : ''}${trade.resultR.toStringAsFixed(2)}R',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
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

    return Container(
      width: double.infinity,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: icon),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;

  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withOpacity(0.18),
        ),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 20,
      ),
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 142,
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
          const SizedBox(height: 6),
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

class _ChecklistRow extends StatelessWidget {
  final String title;
  final bool value;

  const _ChecklistRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final good = value;
    final color = good ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            good ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value
                ? (s.isVi ? 'Đạt' : 'Yes')
                : (s.isVi ? 'Không đạt' : 'No'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPreview extends StatelessWidget {
  final String title;
  final String path;
  final VoidCallback onTap;

  const _ChartPreview({
    required this.title,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  final String text;

  const _EmptyChartMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Pill({
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.11),
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
              color: color,
              size: 13,
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

class _FullImageScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const _FullImageScreen({
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: InteractiveViewer(
        child: Center(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}