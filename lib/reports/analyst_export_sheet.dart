import 'package:flutter/material.dart';

import '../models/trade.dart';
import 'pdf_report_service.dart';
import 'report_builder.dart';
import 'report_options.dart';
import 'report_preview_screen.dart';
import 'package:provider/provider.dart';

import '../state/app_settings.dart';

Future<void> showAnalystExportSheet(
    BuildContext context, {
      required List<Trade> trades,
      required String contextLabel,
    }) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => AnalystExportSheet(
      trades: trades,
      contextLabel: contextLabel,
    ),
  );
}

class AnalystExportSheet extends StatefulWidget {
  final List<Trade> trades;
  final String contextLabel;

  const AnalystExportSheet({
    super.key,
    required this.trades,
    required this.contextLabel,
  });

  @override
  State<AnalystExportSheet> createState() => _AnalystExportSheetState();
}

class _AnalystExportSheetState extends State<AnalystExportSheet> {
  ReportFormat _format = ReportFormat.image;
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

  Future<void> _export() async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      if (widget.trades.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trades in this analyst view.'),
          ),
        );

        return;
      }

      final settings = context.read<AppSettings>();

      final data = ReportBuilder.build(
        trades: widget.trades,
        periodLabel: widget.contextLabel,
        cashPerR: settings.cashPerR,
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
    final color = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Export Analyst View',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.contextLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

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