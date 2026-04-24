import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'image_report_card.dart';
import 'report_data.dart';

class ReportPreviewScreen extends StatefulWidget {
  final ReportData data;

  const ReportPreviewScreen({
    super.key,
    required this.data,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final _captureKey = GlobalKey();
  bool _exporting = false;

  Future<void> _exportImage() async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final boundary = _captureKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not capture report image.');
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Could not convert report image to PNG.');
      }

      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final fileName =
          'decision_journal_report_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Decision Journal Report',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export image failed: $e'),
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
    final preview = RepaintBoundary(
      key: _captureKey,
      child: ImageReportCard(data: widget.data),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        actions: [
          IconButton(
            tooltip: 'Share image',
            onPressed: _exporting ? null : _exportImage,
            icon: _exporting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.25,
        maxScale: 2.5,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Transform.scale(
                scale: 0.42,
                alignment: Alignment.topCenter,
                child: preview,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _exporting ? null : _exportImage,
            icon: _exporting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.image_outlined),
            label: Text(_exporting ? 'Exporting...' : 'Export Image'),
          ),
        ),
      ),
    );
  }
}