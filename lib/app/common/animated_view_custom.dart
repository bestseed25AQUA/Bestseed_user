import 'package:flutter/material.dart';

enum AnimationType {
  fade,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scale,
  fadeSlide,
  none,
}

class AnimatedAppearance extends StatelessWidget {
  final Widget child;
  final AnimationType type;
  final Duration duration;

  const AnimatedAppearance({
    super.key,
    required this.child,
    this.type = AnimationType.fadeSlide, // default
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        switch (type) {
          case AnimationType.fade:
            return Opacity(opacity: value, child: child);

          case AnimationType.scale:
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.slideUp:
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.slideDown:
            return Transform.translate(
              offset: Offset(0, -30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.slideLeft:
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.slideRight:
            return Transform.translate(
              offset: Offset(-30 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.fadeSlide: // default — fade + slide
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );

          case AnimationType.none:
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );

          default:
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
        }
      },
      child: child,
    );
  }
}
