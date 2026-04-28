import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trades_store.dart';
import 'pdf_report_service.dart';
import 'report_builder.dart';
import 'report_options.dart';
import 'report_preview_screen.dart';
import '../state/app_settings.dart';
import '../l10n/strings.dart';

Future<void> showExportReportSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ExportReportSheet(parentContext: context),
  );
}

class ExportReportSheet extends StatefulWidget {
  final BuildContext parentContext;

  const ExportReportSheet({
    super.key,
    required this.parentContext,
  });

  @override
  State<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<ExportReportSheet> {
  ReportFormat _format = ReportFormat.image;
  ReportPeriod _period = ReportPeriod.currentFilter;
  DateTimeRange? _customRange;
  bool _exporting = false;

  String _formatLabel(ReportFormat format, bool isVi) {
    switch (format) {
      case ReportFormat.image:
        return isVi ? 'Ảnh tóm tắt' : 'Image summary';
      case ReportFormat.pdf:
        return isVi ? 'Báo cáo PDF' : 'PDF report';
    }
  }

  String _formatSubtitle(ReportFormat format, bool isVi) {
    switch (format) {
      case ReportFormat.image:
        return isVi
            ? 'Chia sẻ nhanh một ảnh hiệu suất gọn đẹp.'
            : 'Share a clean performance card.';
      case ReportFormat.pdf:
        return isVi
            ? 'Xuất báo cáo hiệu suất chi tiết.'
            : 'Export a detailed performance report.';
    }
  }

  IconData _formatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.image:
        return Icons.image_rounded;
      case ReportFormat.pdf:
        return Icons.picture_as_pdf_rounded;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _periodLabel(BuildContext context, ReportPeriod period) {
    final store = context.read<TradesStore>();
    final s = S.of(context);

    switch (period) {
      case ReportPeriod.currentFilter:
        return s.isVi
            ? 'Bộ lọc hiện tại: ${store.timeFilterLabel(isVi: true)}'
            : 'Current filter: ${store.timeFilterLabel(isVi: false)}';

      case ReportPeriod.thisMonth:
        return s.isVi ? 'Tháng này' : 'This month';

      case ReportPeriod.thisYear:
        return s.isVi ? 'Năm nay' : 'This year';

      case ReportPeriod.custom:
        if (_customRange == null) {
          return s.isVi ? 'Khoảng tùy chỉnh' : 'Custom range';
        }

        final start = _formatDate(_customRange!.start);
        final end = _formatDate(_customRange!.end);
        return '$start → $end';
    }
  }

  String _reportPeriodLabel(BuildContext context) {
    final store = context.read<TradesStore>();

    switch (_period) {
      case ReportPeriod.currentFilter:
        return store.timeFilterLabel(isVi: false);
      case ReportPeriod.thisMonth:
        return 'This month';
      case ReportPeriod.thisYear:
        return 'This year';
      case ReportPeriod.custom:
        if (_customRange == null) return 'Custom range';

        final start = _formatDate(_customRange!.start);
        final end = _formatDate(_customRange!.end);
        return '$start → $end';
    }
  }

  String _periodSubtitle(ReportPeriod period, bool isVi) {
    switch (period) {
      case ReportPeriod.currentFilter:
        return isVi
            ? 'Dùng đúng bộ lọc thời gian hiện tại trong app.'
            : 'Use the same time filter currently shown in the app.';
      case ReportPeriod.thisMonth:
        return isVi
            ? 'Xuất các lệnh trong tháng hiện tại.'
            : 'Export trades from the current month.';
      case ReportPeriod.thisYear:
        return isVi
            ? 'Xuất các lệnh trong năm hiện tại.'
            : 'Export trades from the current year.';
      case ReportPeriod.custom:
        return isVi
            ? 'Chọn khoảng thời gian tùy chỉnh.'
            : 'Choose a custom start and end date.';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final initialRange = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 29),
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
    if (!mounted) return;

    setState(() {
      _customRange = picked;
      _period = ReportPeriod.custom;
    });
  }

  Future<void> _export() async {
    debugPrint('[ExportReportSheet] Export tapped');

    if (_exporting) return;

    final parentNavigator = Navigator.of(widget.parentContext);
    final sheetNavigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final s = S.read(widget.parentContext);

    setState(() => _exporting = true);

    try {
      final store = context.read<TradesStore>();
      final settings = context.read<AppSettings>();

      final trades = store.itemsForReportPeriod(
        period: _period,
        customRange: _customRange,
      );

      debugPrint('[ExportReportSheet] trades count = ${trades.length}');

      if (trades.isEmpty) {
        if (mounted) {
          sheetNavigator.pop();
        }

        await Future<void>.delayed(const Duration(milliseconds: 220));

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              s.isVi
                  ? 'Không có lệnh nào trong khoảng thời gian này.'
                  : 'No trades in this period.',
            ),
          ),
        );
        return;
      }

      final data = ReportBuilder.build(
        trades: trades,
        periodLabel: _reportPeriodLabel(context),
        cashPerR: settings.cashPerR,
        isVi: s.isVi,
      );

      final selectedFormat = _format;

      if (mounted) {
        sheetNavigator.pop();
      }

      await Future<void>.delayed(const Duration(milliseconds: 220));

      if (selectedFormat == ReportFormat.image) {
        parentNavigator.push(
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(data: data),
          ),
        );
        return;
      }

      await PdfReportService.exportAndShare(data);
    } catch (e, st) {
      debugPrint('[ExportReportSheet] Export failed: $e');
      debugPrint('$st');

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            s.isVi ? 'Xuất report thất bại: $e' : 'Export report failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              icon: Icons.assessment_rounded,
              title: s.isVi ? 'Xuất report' : 'Export Report',
              subtitle: s.isVi
                  ? 'Tạo ảnh hoặc PDF từ journal giao dịch của bạn.'
                  : 'Create an image or PDF from your trading journal.',
            ),
            const SizedBox(height: 18),

            _SectionLabel(text: s.isVi ? 'Định dạng' : 'Format'),
            const SizedBox(height: 8),

            _OptionTile(
              selected: _format == ReportFormat.image,
              icon: _formatIcon(ReportFormat.image),
              title: _formatLabel(ReportFormat.image, s.isVi),
              subtitle: _formatSubtitle(ReportFormat.image, s.isVi),
              onTap: () => setState(() => _format = ReportFormat.image),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _format == ReportFormat.pdf,
              icon: _formatIcon(ReportFormat.pdf),
              title: _formatLabel(ReportFormat.pdf, s.isVi),
              subtitle: _formatSubtitle(ReportFormat.pdf, s.isVi),
              onTap: () => setState(() => _format = ReportFormat.pdf),
            ),

            const SizedBox(height: 18),

            _SectionLabel(text: s.isVi ? 'Thời gian' : 'Period'),
            const SizedBox(height: 8),

            _OptionTile(
              selected: _period == ReportPeriod.currentFilter,
              icon: Icons.filter_alt_rounded,
              title: _periodLabel(context, ReportPeriod.currentFilter),
              subtitle: _periodSubtitle(ReportPeriod.currentFilter, s.isVi),
              onTap: () => setState(() => _period = ReportPeriod.currentFilter),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.thisMonth,
              icon: Icons.calendar_month_rounded,
              title: _periodLabel(context, ReportPeriod.thisMonth),
              subtitle: _periodSubtitle(ReportPeriod.thisMonth, s.isVi),
              onTap: () => setState(() => _period = ReportPeriod.thisMonth),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.thisYear,
              icon: Icons.event_note_rounded,
              title: _periodLabel(context, ReportPeriod.thisYear),
              subtitle: _periodSubtitle(ReportPeriod.thisYear, s.isVi),
              onTap: () => setState(() => _period = ReportPeriod.thisYear),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.custom,
              icon: Icons.date_range_rounded,
              title: _periodLabel(context, ReportPeriod.custom),
              subtitle: _periodSubtitle(ReportPeriod.custom, s.isVi),
              onTap: _pickCustomRange,
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _exporting
                      ? (s.isVi ? 'Đang xuất...' : 'Exporting...')
                      : (s.isVi ? 'Xuất report' : 'Export report'),
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
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            icon,
            color: primary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
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
              const SizedBox(height: 4),
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
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? primary.withValues(alpha: isDark ? 0.18 : 0.09)
                : theme.colorScheme.surface.withValues(
              alpha: isDark ? 0.32 : 0.75,
            ),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.32)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.13)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: selected ? primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? primary : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? primary : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}