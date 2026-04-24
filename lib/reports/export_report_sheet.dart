import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trades_store.dart';
import 'pdf_report_service.dart';
import 'report_builder.dart';
import 'report_options.dart';
import 'report_preview_screen.dart';

Future<void> showExportReportSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const ExportReportSheet(),
  );
}

class ExportReportSheet extends StatefulWidget {
  const ExportReportSheet({super.key});

  @override
  State<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<ExportReportSheet> {
  ReportFormat _format = ReportFormat.image;
  ReportPeriod _period = ReportPeriod.currentFilter;
  DateTimeRange? _customRange;
  bool _exporting = false;

  String _formatLabel(ReportFormat format) {
    switch (format) {
      case ReportFormat.image:
        return 'Image summary';
      case ReportFormat.pdf:
        return 'PDF report';
    }
  }

  String _formatSubtitle(ReportFormat format) {
    switch (format) {
      case ReportFormat.image:
        return 'Share a clean performance card.';
      case ReportFormat.pdf:
        return 'Export a detailed performance report.';
    }
  }

  IconData _formatIcon(ReportFormat format) {
    switch (format) {
      case ReportFormat.image:
        return Icons.image_outlined;
      case ReportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  String _periodLabel(BuildContext context, ReportPeriod period) {
    final store = context.read<TradesStore>();

    switch (period) {
      case ReportPeriod.currentFilter:
        return 'Current filter: ${store.timeFilterLabel(isVi: false)}';
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

  String _periodSubtitle(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.currentFilter:
        return 'Use the same time filter currently shown in the app.';
      case ReportPeriod.thisMonth:
        return 'Export trades from the current month.';
      case ReportPeriod.thisYear:
        return 'Export trades from the current year.';
      case ReportPeriod.custom:
        return 'Choose a custom start and end date.';
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
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
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      final store = context.read<TradesStore>();

      final trades = store.itemsForReportPeriod(
        period: _period,
        customRange: _customRange,
      );
      if (trades.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trades in this period.'),
          ),
        );

        return;
      }
      final data = ReportBuilder.build(
        trades: trades,
        periodLabel: _reportPeriodLabel(context),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      if (_format == ReportFormat.image) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(data: data),
          ),
        );
        return;
      }

      await PdfReportService.exportAndShare(data);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export report failed: $e'),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHeader(),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Format',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _OptionTile(
              selected: _format == ReportFormat.image,
              icon: _formatIcon(ReportFormat.image),
              title: _formatLabel(ReportFormat.image),
              subtitle: _formatSubtitle(ReportFormat.image),
              onTap: () {
                setState(() => _format = ReportFormat.image);
              },
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _format == ReportFormat.pdf,
              icon: _formatIcon(ReportFormat.pdf),
              title: _formatLabel(ReportFormat.pdf),
              subtitle: _formatSubtitle(ReportFormat.pdf),
              onTap: () {
                setState(() => _format = ReportFormat.pdf);
              },
            ),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _OptionTile(
              selected: _period == ReportPeriod.currentFilter,
              icon: Icons.filter_alt_outlined,
              title: _periodLabel(context, ReportPeriod.currentFilter),
              subtitle: _periodSubtitle(ReportPeriod.currentFilter),
              onTap: () {
                setState(() => _period = ReportPeriod.currentFilter);
              },
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.thisMonth,
              icon: Icons.calendar_month_outlined,
              title: _periodLabel(context, ReportPeriod.thisMonth),
              subtitle: _periodSubtitle(ReportPeriod.thisMonth),
              onTap: () {
                setState(() => _period = ReportPeriod.thisMonth);
              },
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.thisYear,
              icon: Icons.event_note_outlined,
              title: _periodLabel(context, ReportPeriod.thisYear),
              subtitle: _periodSubtitle(ReportPeriod.thisYear),
              onTap: () {
                setState(() => _period = ReportPeriod.thisYear);
              },
            ),
            const SizedBox(height: 8),
            _OptionTile(
              selected: _period == ReportPeriod.custom,
              icon: Icons.date_range_outlined,
              title: _periodLabel(context, ReportPeriod.custom),
              subtitle: _periodSubtitle(ReportPeriod.custom),
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
                    : const Icon(Icons.ios_share_outlined),
                label: Text(_exporting ? 'Exporting...' : 'Export report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.assessment_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Export Report',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? color.withOpacity(0.08) : Theme.of(context).cardColor,
          border: Border.all(
            color: selected ? color.withOpacity(0.35) : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: selected
                  ? color.withOpacity(0.14)
                  : Colors.black.withOpacity(0.04),
              child: Icon(
                icon,
                color: selected ? color : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? color : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}