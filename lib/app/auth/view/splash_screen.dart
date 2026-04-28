import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
    try {
      // Run heavy init (Firebase, notifications, storage) while splash animates
      await initializeApp();
      final token = await AuthLocalStorage.getToken();

      debugPrint("Splash token check: ${token != null && token.isNotEmpty ? 'Token found (${token.substring(0, token.length > 10 ? 10 : token.length)}...)' : 'No token'}");

      if (token != null && token.isNotEmpty) {
        NotificationService().registerToken();

        // Fetch all home banners in parallel. Future.any guarantees we move on
        // once either all banners finish loading OR the 8-second timer fires —
        // whichever comes first — so the splash never blocks indefinitely.
        final bannerCtrl = Get.find<HomeBannerController>();
        await Future.any([
          bannerCtrl.fetchAll(),
          Future.delayed(const Duration(seconds: 8)),
        ]);

        if (!mounted) return;

        // Pre-cache all banner images so the home screen renders them
        // instantly with no shimmer or fallback flash.
        final imageUrls = [
          ...bannerCtrl.bannersHome,
          ...bannerCtrl.bannersSection1Bg,
          ...bannerCtrl.bannersSpotHatcheries,
          ...bannerCtrl.bannersFarmManagement,
          ...bannerCtrl.bannersMedicine,
          ...bannerCtrl.bannersBackGround,
          ...bannerCtrl.bannersTop,
        ]
            .where((b) => b.type == 'image' && b.url.trim().isNotEmpty)
            .map((b) => b.url.trim())
            .toSet()
            .toList();

        if (imageUrls.isNotEmpty && mounted) {
          await Future.any([
            Future.wait(
              imageUrls
                  .map((url) => precacheImage(CachedNetworkImageProvider(url), context)
                      .catchError((_) {}))
                  .toList(),
            ),
            Future.delayed(const Duration(seconds: 5)),
          ]);
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
