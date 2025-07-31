import 'package:flutter/material.dart';
import 'dart:math' show pi;

class AvatarPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  AvatarPainter({required this.borderColor, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..arcToPoint(Offset(size.width, size.height / 2), radius: Radius.circular(size.width / 2));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class HalfCirclePainter extends CustomPainter {
  final Color firstColor;
  final Color secondColor;

  HalfCirclePainter({required this.firstColor, required this.secondColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Draw the left half
    paint.color = firstColor;
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), -pi / 4, -pi, true, paint);

    // Draw the right half
    paint.color = secondColor;
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), -pi / 4, pi, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
