import 'package:flutter/material.dart';

class AbstractBackground extends StatelessWidget {
  final Widget child;
  const AbstractBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000), // True pitch black
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle, low-opacity pastel purple geometric shapes at edges to give depth
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4B2FF).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4B2FF).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -160,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4B2FF).withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 220,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4B2FF).withValues(alpha: 0.03),
              ),
            ),
          ),
          // Scrollable page content layer
          child,
        ],
      ),
    );
  }
}
