import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 1024, 1024));
  
  // Background
  final bgPaint = Paint()..color = const Color(0xFF121212);
  canvas.drawRRect(RRect.fromLTRBR(0, 0, 1024, 1024, const Radius.circular(200)), bgPaint);

  // Gradient Circles
  final circlePaint1 = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(1024, 1024),
      [const Color(0x26FFD700), const Color(0x00FFD700)],
    );
  canvas.drawCircle(const Offset(900, 120), 240, circlePaint1);

  final circlePaint2 = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(1024, 1024),
      const Offset(0, 0),
      [const Color(0x1AFFD700), const Color(0x00FFD700)],
    );
  canvas.drawCircle(const Offset(120, 900), 300, circlePaint2);

  // Ratio Lines
  final lineBgPaint = Paint()..color = const Color(0x4DFFD700);
  canvas.drawRRect(RRect.fromLTRBR(160, 840, 864, 848, const Radius.circular(4)), lineBgPaint);
  
  final lineFillPaint = Paint()..color = const Color(0xFFFFD700);
  canvas.drawRRect(RRect.fromLTRBR(160, 840, 560, 848, const Radius.circular(4)), lineFillPaint);

  // Text "RATIO"
  const textStyle = TextStyle(
    color: Color(0xFFFFD700),
    fontSize: 220,
    fontWeight: FontWeight.w900,
    letterSpacing: 16,
    fontFamily: 'Arial',
  );
  
  final textPainter = TextPainter(
    text: const TextSpan(text: 'RATIO', style: textStyle),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset(512 - textPainter.width / 2, 512 - textPainter.height / 2));

  // Divider
  final dividerPaint = Paint()
    ..color = const Color(0xCCFFD700)
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(360, 640), const Offset(664, 640), dividerPaint);

  final picture = recorder.endRecording();
  final img = await picture.toImage(1024, 1024);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  File('assets/images/app_icon.png').writeAsBytesSync(buffer);
  print('Icon generated successfully!');
  exit(0);
}
