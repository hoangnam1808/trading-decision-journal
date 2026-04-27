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

  Future<void> _pickAfterImage(BuildContext context, Trade currentTrade) async {
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

    await context.read<TradesStore>().updateAfterImageAt(index, copied.path);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.afterChartUpdated)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
    await context.read<TradesStore>().deleteTradeAt(index);

    if (!context.mounted) return;
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(content: Text(s.tradeDeleted)),
    );
  }

  void _openEdit(BuildContext context, Trade currentTrade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTradeFlow(
          initialTrade: currentTrade,
          editIndex: index,
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

    if (index < 0 || index >= store.items.length) {
      return Scaffold(
        appBar: AppBar(title: Text(s.tradeDetail)),
        body: Center(child: Text(s.tradeNotFound)),
      );
    }

    final currentTrade = store.items[index];
    final gradeColor = _gradeColor(currentTrade.grade);
    final resultColor =
    currentTrade.resultR >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tradeDetail),
        actions: [
          IconButton(
            tooltip: s.deleteTrade,
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: gradeColor.withOpacity(0.15),
                      child: Text(
                        currentTrade.grade.label,
                        style: TextStyle(
                          color: gradeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Text(
                                currentTrade.symbol,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              _Pill(
                                text: currentTrade.market.label,
                                color: Colors.blueGrey,
                              ),
                              _Pill(
                                text: currentTrade.direction.label,
                                color: currentTrade.direction ==
                                    TradeDirection.long
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateText(currentTrade.dateTime),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: resultColor.withOpacity(0.10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentTrade.resultR >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: resultColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${currentTrade.resultR >= 0 ? '+' : ''}${currentTrade.resultR.toStringAsFixed(2)}R',
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Execution',
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
                  value: currentTrade.strategy,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: s.decisionChecklist,
            child: Column(
              children: [
                _ChecklistRow(
                  title: s.isVi ? 'Bối cảnh đúng' : 'Market context valid',
                  value: currentTrade.checklist.contextOk,
                ),
                const Divider(height: 18),
                _ChecklistRow(
                  title: s.isVi ? 'Vùng vào hợp lệ' : 'Entry zone valid',
                  value: currentTrade.checklist.entryZoneOk,
                ),
                const Divider(height: 18),
                _ChecklistRow(
                  title: s.isVi ? 'Execution đúng' : 'Execution valid',
                  value: currentTrade.checklist.executionOk,
                ),
                const Divider(height: 18),
                _ChecklistRow(
                  title: s.isVi ? 'Risk đúng' : 'Risk valid',
                  value: currentTrade.checklist.riskOk,
                ),
                const Divider(height: 18),
                _ChecklistRow(
                  title: s.isVi ? 'Kỷ luật cảm xúc' : 'Emotional discipline',
                  value: !currentTrade.checklist.emotional,
                ),
              ],
            ),
          ),

          if ((currentTrade.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: s.note,
              child: Text(
                currentTrade.note!.trim(),
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Charts',
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
                  Text(
                    s.noTradesOnThisDay,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEdit(context, currentTrade),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.editTrade),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickAfterImage(context, currentTrade),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    currentTrade.afterImagePath?.isNotEmpty ?? false
                        ? s.replaceLabel
                        : s.afterChartTitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
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

  static String _dateText(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
String _feeText(double fee) {
  if (fee.abs() < 0.005) return '0.00';
  return fee.toStringAsFixed(2);
}
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
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
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
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
    final good = value;
    final color = good ? Colors.green : Colors.red;

    return Row(
      children: [
        Icon(
          good ? Icons.check_circle : Icons.cancel,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value
              ? (s.isVi ? 'Đạt' : 'Yes')
              : (s.isVi ? 'Không đạt' : 'No'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
      body: InteractiveViewer(
        child: Center(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}