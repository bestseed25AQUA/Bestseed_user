import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get_navigation/src/routes/circular_reveal_clipper.dart';

class AppAnimations {
  // ============================
  // Slide Right → Left (default onboarding style)
  // ============================

 static Route circularRevealRoute(
  Widget page, {
  Alignment center = Alignment.topCenter,
}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 1700),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final size = MediaQuery.of(context).size;

      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return ClipPath(
            clipper: CircularRevealClipper(
              fraction: animation.value,
              centerAlignment: center,
              minRadius: 0,
              maxRadius: size.longestSide * 1.2,
            ),
            child: child,
          );
        },
      );
    },
  );
}


  static Route slideRightToLeft(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ============================
  // Slide Left → Right
  // ============================
  static Route slideLeftToRight(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ============================
  // Slide Bottom → Top
  // ============================
  static Route slideBottomToTop(Widget page, {Duration? transitionDuration}) {
    return PageRouteBuilder(
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutBack));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ============================
  // Slide Top → Bottom
  // ============================
  static Route slideTopToBottom(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutBack));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ============================
  // Fade Transition
  //================
  static Route fade(Widget page, {Duration? transitionDuration}) {
    return PageRouteBuilder(
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 700),
      reverseTransitionDuration:
          transitionDuration ?? const Duration(milliseconds: 700),

      pageBuilder: (_, animation, __) => page,

      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic, // SUPER SMOOTH
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ============================
  // Scale (Zoom In)
  // ============================
  static Route scale(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final scaleAnim = Tween(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return ScaleTransition(scale: scaleAnim, child: child);
      },
    );
  }

  // ============================
  // Rotation
  // ============================
  static Route rotate(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final rotate = Tween(begin: 0.5, end: 1.0).animate(animation);
        return RotationTransition(turns: rotate, child: child);
      },
    );
  }

  // ============================
  // Fade + Slide Combo
  // ============================
  static Route fadeSlide(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  // ============================
  // 3D Flip Animation
  // ============================
  static Route flip(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final rotate = Tween(
          begin: -1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (_, child) {
            final angle = rotate.value * 3.14;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(angle),
              child: child,
            );
          },
        );
      },
    );
  }

  // ============================
  // Zoom Out Transition
  // ============================
  static Route zoomOut(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final scale = Tween(begin: 1.3, end: 1.0).animate(animation);
        final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  // ============================
  //Zoom in
  static Route zoomIn(Widget page, {Duration? transitionDuration}) {
    return PageRouteBuilder(
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 500),
      reverseTransitionDuration:
          transitionDuration ?? const Duration(milliseconds: 500),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final scale = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // smooth zoom-in
          ),
        );

        final fade = Tween(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  // ============================
  // iOS Cupertino Style
  // ============================
  static Route cupertino(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: slide, child: child);
      },
    );
  }
}
