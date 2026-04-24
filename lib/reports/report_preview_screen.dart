import 'package:flutter/material.dart';

import 'image_report_card.dart';
import 'report_data.dart';

class ReportPreviewScreen extends StatelessWidget {
  final ReportData data;

  const ReportPreviewScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
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
                scale: 0.34,
                alignment: Alignment.topCenter,
                child: ImageReportCard(data: data),
              ),
            ),
          ),
        ),
      ),
    );
  }
}