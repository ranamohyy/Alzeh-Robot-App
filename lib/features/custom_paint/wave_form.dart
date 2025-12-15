import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = size.height / 2;
    final spacing = size.width / 50;

    for (int i = 0; i < 50; i++) {
      final x = i * spacing;
      final height = (i % 3 == 0
              ? 40
              : i % 2 == 0
                  ? 60
                  : 30)
          .toDouble();
      canvas.drawLine(
        Offset(x, center - height / 2),
        Offset(x, center + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
