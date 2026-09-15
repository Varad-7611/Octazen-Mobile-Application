import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('splash'),
    body: DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF172B61)),
      child: Stack(
        children: [
          const Positioned.fill(child: DotPattern()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShieldMark(size: 92),
                const SizedBox(height: 22),
                const Text(
                  'EduTrust Academy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure Learning Platform',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 54,
            left: 0,
            right: 0,
            child: Text(
              'Powered by Octazen Technologies LLP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ShieldPainter());
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shield = Path()
      ..moveTo(32 * scale, 3 * scale)
      ..lineTo(51 * scale, 10 * scale)
      ..lineTo(51 * scale, 30 * scale)
      ..cubicTo(
        51 * scale,
        45 * scale,
        42 * scale,
        55 * scale,
        32 * scale,
        60 * scale,
      )
      ..cubicTo(
        22 * scale,
        55 * scale,
        13 * scale,
        45 * scale,
        13 * scale,
        30 * scale,
      )
      ..lineTo(13 * scale, 10 * scale)
      ..close();
    canvas.drawPath(shield, paint);
    final cap = Path()
      ..moveTo(22 * scale, 25 * scale)
      ..lineTo(32 * scale, 19 * scale)
      ..lineTo(42 * scale, 25 * scale)
      ..lineTo(32 * scale, 31 * scale)
      ..close();
    canvas.drawPath(cap, paint..style = PaintingStyle.fill);
    canvas.drawArc(
      Rect.fromLTWH(23 * scale, 26 * scale, 18 * scale, 14 * scale),
      0,
      3.14,
      false,
      paint..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(42 * scale, 39 * scale),
      1.5 * scale,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DotPattern extends StatelessWidget {
  const DotPattern({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotPainter());
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var y = 10.0; y < size.height; y += 22) {
      for (var x = 10.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
