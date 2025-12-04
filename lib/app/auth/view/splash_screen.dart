import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';
import 'package:seedsuser/app/updates/view/hatchery_details_screen.dart';
import 'package:app_links/app_links.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
     initDeepLinks();
    _checkLoginStatus();
  }
 
late final AppLinks _appLinks;
StreamSubscription<Uri>? _linkSubscription;

void initDeepLinks() async {
  _appLinks = AppLinks();

  // 🔹 1. App opened from terminated state
  final initialUri = await _appLinks.getInitialLink();
  if (initialUri != null) {
    _handleUri(initialUri);
  }

  // 🔹 2. App already running (background/foreground)
  _linkSubscription = _appLinks.uriLinkStream.listen(
    (uri) => _handleUri(uri),
    onError: (err) => print("Deep link error: $err"),
  );
}

void _handleUri(Uri uri) {
  print("DEEP LINK ➜ $uri");


  if (uri.pathSegments.contains("hatchery")) {
    final hid = uri.pathSegments.last;
    Get.to(() => HatcheryDetailsScreen(id: hid));
  }
}

@override
void dispose() {
  _linkSubscription?.cancel();
  super.dispose();
}
  

  void _checkLoginStatus() async {
    // Splash screen delay
    await Future.delayed(const Duration(seconds: 3));

    // Get saved token
    String? token = await AuthLocalStorage.getToken();

    print('Token $token');

    if (token != null && token.isNotEmpty) {
      Get.off(() => DashboardScreen());
    } else {
      Get.off(() => const LoginWithMobileScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo.png", width: 219, height: 219),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
