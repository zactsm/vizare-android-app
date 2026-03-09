import 'package:flutter/material.dart';

/// Simple Fade Transition
PageRouteBuilder fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

///  Fade + Slide Transition (for smooth movement)
PageRouteBuilder fadeSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from bottom with fade
      const begin = Offset(0.0, 0.05); // small vertical movement (5%)
      const end = Offset.zero;
      final curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
