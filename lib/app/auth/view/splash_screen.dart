import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/notification/notification_service.dart';
import 'package:seedsuser/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _rotate;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // ------------------------- ANIMATION SETUP -------------------------
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade in
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale (pop-in effect)
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Rotation (premium feel)
    _rotate = Tween<double>(begin: -0.5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Drop-in from top
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );

    _controller.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkLoginStatus() async {
    // Started as early as possible (parallel with app init): loads the
    // above-the-fold banner data + downloads the home banner video to a local
    // file so Home shows real data with the video ready to play from disk.
    Future<void>? preloadFuture;
    try {
      // Kick off banner + media prefetch as EARLY as possible (in parallel with
      // app init) so the logo, vehicle availability video, best deals, spot
      // hatchery and farm management are warmed before Home renders.
      try {
        final earlyToken = await AuthLocalStorage.getToken();
        if (earlyToken != null &&
            earlyToken.isNotEmpty &&
            Get.isRegistered<HomeBannerController>()) {
          preloadFuture = Get.find<HomeBannerController>().preloadEssential();
        }
      } catch (e) {
        debugPrint('Splash early banner prefetch skipped: $e');
      }

      // Request App Tracking Transparency permission on iOS
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(const Duration(milliseconds: 500));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }

      // Run heavy init with 5s timeout — never block splash forever
      try {
        await initializeApp().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Splash initializeApp error/timeout (non-fatal): $e');
      }
      final token = await AuthLocalStorage.getToken();

      debugPrint("Splash token check: ${token != null && token.isNotEmpty ? 'Token found (${token.substring(0, token.length > 10 ? 10 : token.length)}...)' : 'No token'}");

      if (token != null && token.isNotEmpty) {
        // Fire-and-forget — don't block splash.
        NotificationService().registerToken();

        // Wait for Home essentials (data + cached banner video) so Home shows
        // populated instead of shimmering — bounded so the splash never hangs.
        // On timeout/error we navigate anyway; Home falls back to its own
        // loading states and streams the video.
        if (preloadFuture != null) {
          try {
            await preloadFuture.timeout(const Duration(seconds: 4));
          } catch (e) {
            debugPrint('Splash preload not finished in time (non-fatal): $e');
          }
        }

        if (!mounted) return;
        Get.off(() => DashboardScreen());
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationService.handlePendingNotification();
        });
      } else {
        Get.off(() => const LoginWithMobileScreen());
      }
    } catch (e) {
      debugPrint('Splash _checkLoginStatus error: $e');
      // Safety fallback — never leave the user stuck on the splash screen
      try {
        final token = await AuthLocalStorage.getToken();
        if (token != null && token.isNotEmpty) {
          Get.off(() => DashboardScreen());
        } else {
          Get.off(() => const LoginWithMobileScreen());
        }
      } catch (_) {
        Get.off(() => const LoginWithMobileScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          Center(
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: RotationTransition(
                  turns: _rotate,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/logo.png",
                          width: 180,
                          height: 180,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077C8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
