import 'package:flutter/material.dart';
import 'dart:math' as math;

class MauritaniaFlag extends StatelessWidget {
  final double width;
  final double height;
  final bool showBorder;
  const MauritaniaFlag({super.key, this.width=40, this.height=26, this.showBorder=false});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      border: showBorder ? Border.all(color: Colors.white30, width: 0.5) : null),
    child: CustomPaint(painter: _FlagPainter()));
}

class _FlagPainter extends CustomPainter {
  static const Color green = Color(0xFF006233);
  static const Color red   = Color(0xFFD90012);
  static const Color gold  = Color(0xFFFFD700);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final redH = h * 0.15;
    final gPaint  = Paint()..color = green;
    final rPaint  = Paint()..color = red;
    final goPaint = Paint()..color = gold;

    // Fond vert
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gPaint);
    // Bande rouge haut
    canvas.drawRect(Rect.fromLTWH(0, 0, w, redH), rPaint);
    // Bande rouge bas
    canvas.drawRect(Rect.fromLTWH(0, h - redH, w, redH), rPaint);

    final cx = w / 2;
    final cy = h / 2;

    // Croissant
    final outerR = h * 0.30;
    final innerR = h * 0.22;
    canvas.drawCircle(Offset(cx, cy), outerR, goPaint);
    canvas.drawCircle(Offset(cx + h * 0.07, cy), innerR, gPaint);

    // Etoile 5 branches
    _drawStar(canvas, cx, cy - h * 0.03, h * 0.10, goPaint);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path();
    final inner = r * 0.4;
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final rad = i.isEven ? r : inner;
      final x = cx + rad * math.cos(angle);
      final y = cy + rad * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}