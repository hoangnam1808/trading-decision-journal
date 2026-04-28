import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import 'pdf_report_service.dart';
import 'report_builder.dart';
import 'report_options.dart';
import 'report_preview_screen.dart';
import '../l10n/strings.dart';
import '../state/app_settings.dart';

Future<void> showAnalystExportSheet(
    BuildContext context, {
      required List<Trade> trades,
      required String contextLabel,
    }) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AnalystExportSheet(
      parentContext: context,
      trades: trades,
      contextLabel: contextLabel,
    ),
  );
}

class AnalystExportSheet extends StatefulWidget {
  final BuildContext parentContext;
  final List<Trade> trades;
  final String contextLabel;

  const AnalystExportSheet({
    super.key,
    required this.parentContext,
    required this.trades,
    required this.contextLabel,
  });

  @override
  State<AnalystExportSheet> createState() => _AnalystExportSheetState();
}

class _AnalystExportSheetState extends State<AnalystExportSheet> {
  ReportFormat _format = ReportFormat.image;
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

  Future<void> _export() async {
    debugPrint('[AnalystExportSheet] Export tapped');

    if (_exporting) return;

    final parentNavigator = Navigator.of(widget.parentContext);
    final sheetNavigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final s = S.read(widget.parentContext);

    setState(() => _exporting = true);

    try {
      debugPrint('[AnalystExportSheet] trades count = ${widget.trades.length}');

      if (widget.trades.isEmpty) {
        if (mounted) {
          sheetNavigator.pop();
        }

        await Future<void>.delayed(const Duration(milliseconds: 220));

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              s.isVi
                  ? 'Không có lệnh nào trong chế độ Analyst hiện tại.'
                  : 'No trades in this analyst view.',
            ),
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
      debugPrint('[AnalystExportSheet] Export failed: $e');
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              icon: Icons.assessment_rounded,
              title: s.isVi ? 'Xuất chế độ Analyst' : 'Export Analyst View',
              subtitle: s.isVi
                  ? 'Xuất đúng dữ liệu đang xem trong Analyst.'
                  : 'Export the exact data currently shown in Analyst.',
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primary.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    color: primary,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.contextLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
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