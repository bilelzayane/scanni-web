import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that paints a pixel-perfect top border matching a `BottomAppBar`
/// with a `CircularNotchedRectangle` shape and a docked `FloatingActionButton`.
///
/// It listens to [ScaffoldGeometry] to ensure the notch position is exactly
/// synchronized with the actual `FloatingActionButton` position.
class TopNotchedBorder extends StatelessWidget {
  final Widget child;
  final double notchMargin;
  final Color color;
  final double strokeWidth;

  const TopNotchedBorder({
    super.key,
    required this.child,
    this.notchMargin = 14.0,
    this.color = Colors.white54,
    this.strokeWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TopNotchedBorderPainter(
                geometryListenable: Scaffold.geometryOf(context),
                notchMargin: notchMargin,
                color: color,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopNotchedBorderPainter extends CustomPainter {
  final ValueListenable<ScaffoldGeometry> geometryListenable;
  final double notchMargin;
  final Color color;
  final double strokeWidth;

  _TopNotchedBorderPainter({
    required this.geometryListenable,
    required this.notchMargin,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: geometryListenable);

  @override
  void paint(Canvas canvas, Size size) {
    final ScaffoldGeometry geometry = geometryListenable.value;
    final Rect hostRect = Offset.zero & size;
    Rect? guestRect = geometry.floatingActionButtonArea;

    // Convert guestRect from Scaffold coordinate system to local coordinate system
    if (guestRect != null) {
      final double bottomNavigationBarTop =
          geometry.bottomNavigationBarTop ?? 0.0;
      guestRect = guestRect.translate(0.0, -bottomNavigationBarTop);
      guestRect = guestRect.inflate(notchMargin);
    }

    final Path path = Path();
    path.moveTo(hostRect.left, hostRect.top);

    if (guestRect != null && hostRect.overlaps(guestRect)) {
      final double r = guestRect.width / 2.0;
      final Radius notchRadius = Radius.circular(r);

      const double s1 = 15.0;
      const double s2 = 1.0;

      final double a = -r - s2;
      final double b = hostRect.top - guestRect.center.dy;

      final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
      final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
      final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
      final double p2yA = math.sqrt(r * r - p2xA * p2xA);
      final double p2yB = math.sqrt(r * r - p2xB * p2xB);

      final List<Offset> p = List<Offset>.filled(6, Offset.zero);

      p[0] = Offset(a - s1, b);
      p[1] = Offset(a, b);
      final double cmp = b < 0 ? -1.0 : 1.0;
      p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

      p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
      p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
      p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

      for (int i = 0; i < p.length; i += 1) {
        p[i] += guestRect.center;
      }

      path.lineTo(p[0].dx, p[0].dy);
      path.quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy);
      path.arcToPoint(p[3], radius: notchRadius, clockwise: false);
      path.quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy);
    }

    path.lineTo(hostRect.right, hostRect.top);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TopNotchedBorderPainter oldDelegate) {
    return oldDelegate.geometryListenable != geometryListenable ||
        oldDelegate.notchMargin != notchMargin ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
