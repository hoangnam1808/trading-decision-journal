import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/trades_store.dart';

Future<void> showTimeFilterBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const TimeFilterSheet(),
  );
}

class TimeFilterSheet extends StatelessWidget {
  const TimeFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.watch<TradesStore>();
    final theme = Theme.of(context);

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

    IconData icon(TimeFilter filter) {
      switch (filter) {
        case TimeFilter.all:
          return Icons.all_inclusive_rounded;
        case TimeFilter.today:
          return Icons.today_rounded;
        case TimeFilter.week:
          return Icons.view_week_rounded;
        case TimeFilter.month:
          return Icons.calendar_month_rounded;
        case TimeFilter.year:
          return Icons.event_available_rounded;
        case TimeFilter.custom:
          return Icons.date_range_rounded;
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

    String? subtitle(TimeFilter filter) {
      switch (filter) {
        case TimeFilter.all:
          return s.isVi ? 'Xem toàn bộ journal' : 'View your entire journal';
        case TimeFilter.today:
          return s.isVi ? 'Chỉ lệnh trong hôm nay' : 'Only today’s trades';
        case TimeFilter.week:
          return s.isVi ? 'Lọc theo tuần hiện tại' : 'Filter by current week';
        case TimeFilter.month:
          return s.isVi ? 'Lọc theo tháng hiện tại' : 'Filter by current month';
        case TimeFilter.year:
          return s.isVi ? 'Lọc theo năm hiện tại' : 'Filter by current year';
        case TimeFilter.custom:
          return customSubtitle() ??
              (s.isVi ? 'Chọn ngày bắt đầu và kết thúc' : 'Choose start and end date');
      }
    }

    Future<void> pickCustomRange() async {
      final tradesStore = context.read<TradesStore>();
      final navigator = Navigator.of(context);
      final now = DateTime.now();

      final initialRange =
      tradesStore.customStart != null && tradesStore.customEnd != null
          ? DateTimeRange(
        start: tradesStore.customStart!,
        end: tradesStore.customEnd!,
      )
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

      tradesStore.setCustomRange(picked);
      navigator.pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: s.isVi ? 'Lọc theo thời gian' : 'Filter by time',
              subtitle: s.isVi
                  ? 'Áp dụng cho Dashboard, danh sách lệnh và Analyst.'
                  : 'Applies to Dashboard, Trades, and Analyst.',
            ),
            const SizedBox(height: 12),

            _FilterTile(
              icon: icon(TimeFilter.all),
              title: label(TimeFilter.all),
              subtitle: subtitle(TimeFilter.all),
              selected: store.currentFilter == TimeFilter.all,
              onTap: () {
                context.read<TradesStore>().setTimeFilter(TimeFilter.all);
                Navigator.of(context).pop();
              },
            ),
            _FilterTile(
              icon: icon(TimeFilter.today),
              title: label(TimeFilter.today),
              subtitle: subtitle(TimeFilter.today),
              selected: store.currentFilter == TimeFilter.today,
              onTap: () {
                context.read<TradesStore>().setTimeFilter(TimeFilter.today);
                Navigator.of(context).pop();
              },
            ),
            _FilterTile(
              icon: icon(TimeFilter.week),
              title: label(TimeFilter.week),
              subtitle: subtitle(TimeFilter.week),
              selected: store.currentFilter == TimeFilter.week,
              onTap: () {
                context.read<TradesStore>().setTimeFilter(TimeFilter.week);
                Navigator.of(context).pop();
              },
            ),
            _FilterTile(
              icon: icon(TimeFilter.month),
              title: label(TimeFilter.month),
              subtitle: subtitle(TimeFilter.month),
              selected: store.currentFilter == TimeFilter.month,
              onTap: () {
                context.read<TradesStore>().setTimeFilter(TimeFilter.month);
                Navigator.of(context).pop();
              },
            ),
            _FilterTile(
              icon: icon(TimeFilter.year),
              title: label(TimeFilter.year),
              subtitle: subtitle(TimeFilter.year),
              selected: store.currentFilter == TimeFilter.year,
              onTap: () {
                context.read<TradesStore>().setTimeFilter(TimeFilter.year);
                Navigator.of(context).pop();
              },
            ),
            _FilterTile(
              icon: icon(TimeFilter.custom),
              title: label(TimeFilter.custom),
              subtitle: subtitle(TimeFilter.custom),
              selected: store.currentFilter == TimeFilter.custom,
              onTap: pickCustomRange,
            ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: Text(s.close),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: isDark ? 0.18 : 0.09)
                  : theme.colorScheme.surface.withValues(
                alpha: isDark ? 0.32 : 0.75,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.30)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.13)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? primary : theme.colorScheme.onSurfaceVariant,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: selected ? primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey('selected'),
                    color: primary,
                  )
                      : Icon(
                    Icons.circle_outlined,
                    key: const ValueKey('unselected'),
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}