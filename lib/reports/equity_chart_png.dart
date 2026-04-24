import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class EquityChartPng {
  static Future<Uint8List> generate(
      List<double> equityCurve, {
        double width = 1000,
        double height = 420,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    const background = Color(0xFFFFFFFF);
    const panelBorder = Color(0xFFE2E8F0);
    const gridColor = Color(0xFFE2E8F0);
    const axisText = Color(0xFF94A3B8);
    const titleColor = Color(0xFF0F172A);
    const positive = Color(0xFF16A34A);
    const negative = Color(0xFFDC2626);

    final isPositive =
    equityCurve.isEmpty ? true : (equityCurve.last >= equityCurve.first);
    final lineColor = isPositive ? positive : negative;

    // Background
    final bgPaint = Paint()..color = background;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Card-like chart area
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = background
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = panelBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    const leftPad = 90.0;
    const rightPad = 28.0;
    const topPad = 70.0;
    const bottomPad = 52.0;

    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      width - leftPad - rightPad,
      height - topPad - bottomPad,
    );

    _drawText(
      canvas,
      'Equity Curve (R)',
      const Offset(28, 24),
      28,
      FontWeight.w700,
      titleColor,
    );

    if (equityCurve.isEmpty || equityCurve.length < 2) {
      _drawText(
        canvas,
        'No trades in this period',
        Offset(width / 2 - 120, height / 2 - 10),
        22,
        FontWeight.w600,
        axisText,
      );

      final image = await recorder.endRecording().toImage(
        width.toInt(),
        height.toInt(),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }

    final minValue = _minY(equityCurve);
    final maxValue = _maxY(equityCurve);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final horizontalLines = 5;
    final yStep = range / horizontalLines;

    // Grid + Y labels
    for (int i = 0; i <= horizontalLines; i++) {
      final value = minValue + yStep * i;
      final y = chartRect.bottom - (i / horizontalLines) * chartRect.height;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1.2,
      );

      _drawText(
        canvas,
        value.toStringAsFixed(1),
        Offset(12, y - 10),
        16,
        FontWeight.w500,
        axisText,
      );
    }

    // X labels
    final points = equityCurve.length;
    final xLabelCount = points <= 6 ? points : 6;
    for (int i = 0; i < xLabelCount; i++) {
      final t = xLabelCount == 1 ? 0.0 : i / (xLabelCount - 1);
      final index = ((points - 1) * t).round();
      final x = chartRect.left + (chartRect.width * t);

      _drawText(
        canvas,
        '$index',
        Offset(x - 8, chartRect.bottom + 10),
        16,
        FontWeight.w500,
        axisText,
      );
    }

    // Build line path
    final linePath = Path();
    final areaPath = Path();

    Offset pointAt(int i) {
      final x = chartRect.left +
          (i / (equityCurve.length - 1)) * chartRect.width;
      final normalized = (equityCurve[i] - minValue) / range;
      final y = chartRect.bottom - normalized * chartRect.height;
      return Offset(x, y);
    }

    final first = pointAt(0);
    linePath.moveTo(first.dx, first.dy);
    areaPath.moveTo(first.dx, chartRect.bottom);
    areaPath.lineTo(first.dx, first.dy);

    for (int i = 1; i < equityCurve.length; i++) {
      final p = pointAt(i);
      linePath.lineTo(p.dx, p.dy);
      areaPath.lineTo(p.dx, p.dy);
    }

    final last = pointAt(equityCurve.length - 1);
    areaPath.lineTo(last.dx, chartRect.bottom);
    areaPath.close();

    // Area
    canvas.drawPath(
      areaPath,
      Paint()
        ..color = lineColor.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );

    // Line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Last point dot
    canvas.drawCircle(
      last,
      6,
      Paint()..color = lineColor,
    );

    canvas.drawCircle(
      last,
      10,
      Paint()..color = lineColor.withOpacity(0.18),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static double _minY(List<double> curve) {
    final minVal = curve.reduce((a, b) => a < b ? a : b);
    return minVal == 0 ? -1 : minVal - (minVal.abs() * 0.18) - 0.5;
  }

  static double _maxY(List<double> curve) {
    final maxVal = curve.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 1 : maxVal + (maxVal.abs() * 0.18) + 0.5;
  }

  static void _drawText(
      Canvas canvas,
      String text,
      Offset offset,
      double fontSize,
      FontWeight fontWeight,
      Color color,
      ) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      )
      ..addText(text);

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 300));

    canvas.drawParagraph(paragraph, offset);
  }
}