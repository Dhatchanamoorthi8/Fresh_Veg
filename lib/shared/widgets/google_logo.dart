import 'package:flutter/material.dart';

/// Official Google 'G' 4-color Vector Logo Widget.
///
/// Complies with official Google Brand guidelines with exact hex colors:
/// - Blue:   #4285F4
/// - Green:  #34A853
/// - Yellow: #FBBC05
/// - Red:    #EA4335
///
/// Drawn via high-performance vector [CustomPainter] with zero network
/// latency and zero external dependencies.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48.0;
    final dx = (size.width - 48.0 * scale) / 2.0;
    final dy = (size.height - 48.0 * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);

    final paintBlue = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintGreen = Paint()
      ..color = _green
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintYellow = Paint()
      ..color = _yellow
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintRed = Paint()
      ..color = _red
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Blue path (horizontal bar and right curve)
    final bluePath = Path()
      ..moveTo(46.98 * scale, 24.55 * scale)
      ..cubicTo(46.98 * scale, 22.98 * scale, 46.83 * scale, 21.46 * scale, 46.6 * scale, 20.0 * scale)
      ..lineTo(24.0 * scale, 20.0 * scale)
      ..lineTo(24.0 * scale, 29.02 * scale)
      ..lineTo(36.94 * scale, 29.02 * scale)
      ..cubicTo(36.36 * scale, 31.98 * scale, 34.68 * scale, 34.5 * scale, 32.16 * scale, 36.2 * scale)
      ..lineTo(39.89 * scale, 42.2 * scale)
      ..cubicTo(44.4 * scale, 38.02 * scale, 46.98 * scale, 31.84 * scale, 46.98 * scale, 24.55 * scale)
      ..close();
    canvas.drawPath(bluePath, paintBlue);

    // 2. Green path (bottom curve)
    final greenPath = Path()
      ..moveTo(24.0 * scale, 48.0 * scale)
      ..cubicTo(30.48 * scale, 48.0 * scale, 35.93 * scale, 45.87 * scale, 39.89 * scale, 42.19 * scale)
      ..lineTo(32.16 * scale, 36.19 * scale)
      ..cubicTo(30.01 * scale, 37.64 * scale, 27.24 * scale, 38.5 * scale, 24.0 * scale, 38.5 * scale)
      ..cubicTo(17.74 * scale, 38.5 * scale, 12.43 * scale, 34.28 * scale, 10.53 * scale, 28.59 * scale)
      ..lineTo(2.56 * scale, 34.78 * scale)
      ..cubicTo(6.51 * scale, 42.62 * scale, 14.62 * scale, 48.0 * scale, 24.0 * scale, 48.0 * scale)
      ..close();
    canvas.drawPath(greenPath, paintGreen);

    // 3. Yellow path (bottom-left curve)
    final yellowPath = Path()
      ..moveTo(10.53 * scale, 28.59 * scale)
      ..cubicTo(10.05 * scale, 27.14 * scale, 9.77 * scale, 25.6 * scale, 9.77 * scale, 24.0 * scale)
      ..cubicTo(9.77 * scale, 22.4 * scale, 10.04 * scale, 20.86 * scale, 10.53 * scale, 19.41 * scale)
      ..lineTo(2.55 * scale, 13.22 * scale)
      ..cubicTo(0.92 * scale, 16.46 * scale, 0.0 * scale, 20.12 * scale, 0.0 * scale, 24.0 * scale)
      ..cubicTo(0.0 * scale, 27.88 * scale, 0.92 * scale, 31.54 * scale, 2.56 * scale, 34.78 * scale)
      ..lineTo(10.53 * scale, 28.59 * scale)
      ..close();
    canvas.drawPath(yellowPath, paintYellow);

    // 4. Red path (top curve)
    final redPath = Path()
      ..moveTo(24.0 * scale, 9.5 * scale)
      ..cubicTo(27.54 * scale, 9.5 * scale, 30.71 * scale, 10.72 * scale, 33.21 * scale, 13.1 * scale)
      ..lineTo(40.06 * scale, 6.25 * scale)
      ..cubicTo(35.9 * scale, 2.38 * scale, 30.47 * scale, 0.0 * scale, 24.0 * scale, 0.0 * scale)
      ..cubicTo(14.62 * scale, 0.0 * scale, 6.51 * scale, 5.38 * scale, 2.56 * scale, 13.22 * scale)
      ..lineTo(10.54 * scale, 19.41 * scale)
      ..cubicTo(12.43 * scale, 13.72 * scale, 17.74 * scale, 9.5 * scale, 24.0 * scale, 9.5 * scale)
      ..close();
    canvas.drawPath(redPath, paintRed);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
