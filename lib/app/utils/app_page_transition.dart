import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:animations/animations.dart';
import 'package:get/get_navigation/src/routes/circular_reveal_clipper.dart';

class AppPageTransitions {


  // ------------------------------------------------------------
  // 1. Fade Transition
  // ------------------------------------------------------------
  static PageRoute fade(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  // ------------------------------------------------------------
  // 2. Fade + Scale (Zoom In)
  // ------------------------------------------------------------
  static PageRoute fadeScale(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeScaleTransition(animation: animation, child: child);
      },
    );
  }

  // ------------------------------------------------------------
  // 3. Slide From Right
  // ------------------------------------------------------------
  static PageRoute slideRight(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 4. Slide From Bottom
  // ------------------------------------------------------------
  static PageRoute slideUp(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 5. FadeThroughTransition (Material You)
  // ------------------------------------------------------------
  static PageRoute fadeThrough(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondary, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondary,
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 6. Shared Axis Horizontal
  // ------------------------------------------------------------
  static PageRoute sharedAxisX(Widget page, {Duration duration = const Duration(milliseconds: 600)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondary, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 7. Shared Axis Vertical
  // ------------------------------------------------------------
  static PageRoute sharedAxisY(Widget page, {Duration duration = const Duration(milliseconds: 600)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondary, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 8. Shared Axis Scale
  // ------------------------------------------------------------
  static PageRoute sharedAxisScale(Widget page, {Duration duration = const Duration(milliseconds: 600)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondary, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 9. Circular Reveal (Premium Smooth Transition)
  // ------------------------------------------------------------
  static PageRoute circularReveal(
    Widget page, {
    Alignment center = Alignment.topCenter,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final size = MediaQuery.of(context).size;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: curved.value,
            centerAlignment: center,
            minRadius: 0,
            maxRadius: size.longestSide * 1.5,
          ),
          child: child,
        );
      },
    );
  }

  static PageRoute circularRevealFromOffset(
  Widget page, {
  required Offset offset,
  Duration duration = const Duration(milliseconds: 900),
}) {
  return PageRouteBuilder(
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 600),

    pageBuilder: (_, __, ___) => page,

    transitionsBuilder: (context, animation, secondary, child) {
      final size = MediaQuery.of(context).size;

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return ClipPath(
        clipper: CircularRevealClipper(
          fraction: curved.value,
          centerOffset: offset,
          minRadius: 0,
          maxRadius: size.longestSide * 1.5,
        ),
        child: child,
      );
    },
  );
}

static PageRoute zoomFadeRoute(Widget page, {Duration duration = const Duration(milliseconds: 450)}) {
  return PageRouteBuilder(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeScaleTransition(
        animation: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    },
  );
}
}
