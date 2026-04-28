import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

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

// Pill-badge style — matches the _sectionHeader design in all_screen.dart
class AnimatedViewAllBadge extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedViewAllBadge({super.key, required this.onTap});

  @override
  State<AnimatedViewAllBadge> createState() => _AnimatedViewAllBadgeState();
}

class _AnimatedViewAllBadgeState extends State<AnimatedViewAllBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _arrowSlide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _arrowSlide = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View all",
                  style: GoogleFonts.roboto(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Transform.translate(
                  offset: Offset(_arrowSlide.value, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedViewAllButton extends StatefulWidget {
  final VoidCallback onTap;

  const AnimatedViewAllButton({super.key, required this.onTap});

  @override
  State<AnimatedViewAllButton> createState() => _AnimatedViewAllButtonState();
}

class _AnimatedViewAllButtonState extends State<AnimatedViewAllButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arrowOffset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _arrowOffset = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View all",
                  style: GoogleFonts.roboto(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Transform.translate(
                  offset: Offset(_arrowOffset.value, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
