import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';
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
    // Run heavy init (Firebase, notifications, storage) while splash animates
    await initializeApp();
    String? token = await AuthLocalStorage.getToken();

    debugPrint("Splash token check: ${token != null && token.isNotEmpty ? 'Token found (${token.substring(0, token.length > 10 ? 10 : token.length)}...)' : 'No token'}");

    if (token != null && token.isNotEmpty) {
      // Re-register FCM token on every app launch to keep it fresh
      NotificationService().registerToken();
      Get.off(() => DashboardScreen());
      // Navigate to notification detail if app was opened via notification tap
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationService.handlePendingNotification();
      });
    } else {
      Get.off(() => const LoginWithMobileScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
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
    );
  }
}
