import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw Wave 1 (Deepest wave, slightly lighter dark gray)
    paint.color = const Color(0xFF141416);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.55);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.48,
      size.width * 0.52,
      size.height * 0.58,
    );
    path1.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.65,
      size.width,
      size.height * 0.56,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Draw Wave 2 (Middle wave, darker gray)
    paint.color = const Color(0xFF1A1A1D);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.66);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.72,
      size.width * 0.68,
      size.height * 0.63,
    );
    path2.quadraticBezierTo(
      size.width * 0.86,
      size.height * 0.58,
      size.width,
      size.height * 0.68,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // Draw Wave 3 (Foreground wave, slightly dark grey)
    paint.color = const Color(0xFF222227);
    final path3 = Path();
    path3.moveTo(0, size.height * 0.76);
    path3.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.72,
      size.width * 0.55,
      size.height * 0.79,
    );
    path3.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.84,
      size.width,
      size.height * 0.75,
    );
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
