import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/trades_store.dart';

Future<void> showTimeFilterBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const TimeFilterSheet(),
  );
}

class TimeFilterSheet extends StatelessWidget {
  const TimeFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.watch<TradesStore>();

    String label(TimeFilter filter) {
      switch (filter) {
        case TimeFilter.all:
          return s.isVi ? 'Tất cả thời gian' : 'All time';
        case TimeFilter.today:
          return s.isVi ? 'Hôm nay' : 'Today';
        case TimeFilter.week:
          return s.isVi ? 'Tuần này' : 'This week';
        case TimeFilter.month:
          return s.isVi ? 'Tháng này' : 'This month';
        case TimeFilter.year:
          return s.isVi ? 'Năm nay' : 'This year';
        case TimeFilter.custom:
          return s.isVi ? 'Khoảng tùy chọn' : 'Custom range';
      }
    }

    String? customSubtitle() {
      if (store.customStart == null || store.customEnd == null) return null;
      final a = store.customStart!;
      final b = store.customEnd!;
      return '${a.day.toString().padLeft(2, '0')}/${a.month.toString().padLeft(2, '0')}/${a.year}'
          ' → '
          '${b.day.toString().padLeft(2, '0')}/${b.month.toString().padLeft(2, '0')}/${b.year}';
    }

    Widget tile({
      required TimeFilter filter,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      final selected = store.currentFilter == filter;

      return ListTile(
        title: Text(label(filter)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: onTap ??
                () {
              context.read<TradesStore>().setTimeFilter(filter);
              Navigator.of(context).pop();
            },
      );
    }

    Future<void> pickCustomRange() async {
      final now = DateTime.now();
      final initialRange = store.customStart != null && store.customEnd != null
          ? DateTimeRange(start: store.customStart!, end: store.customEnd!)
          : DateTimeRange(
        start: DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 6),
        ),
        end: DateTime(now.year, now.month, now.day),
      );

      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: initialRange,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2100, 12, 31),
      );

      if (picked == null) return;
      if (!context.mounted) return;

      context.read<TradesStore>().setCustomRange(picked);
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                s.isVi ? 'Lọc theo thời gian' : 'Filter by time',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            tile(filter: TimeFilter.all),
            tile(filter: TimeFilter.today),
            tile(filter: TimeFilter.week),
            tile(filter: TimeFilter.month),
            tile(filter: TimeFilter.year),
            tile(
              filter: TimeFilter.custom,
              subtitle: customSubtitle(),
              onTap: pickCustomRange,
            ),
          ],
        ),
      ),
    );
  }
}