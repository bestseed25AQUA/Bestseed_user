import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/splash_screen.dart';
import 'package:seedsuser/app/common/app_globals.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/language/controller/language_controller.dart';
import 'package:seedsuser/app/notification/notification_service.dart';
import 'package:seedsuser/app/rating/rating_prompt_service.dart';
import 'package:seedsuser/app/utils/app_size.dart';
import 'package:seedsuser/l10n/app_localizations.dart';
import 'package:get_storage/get_storage.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
  }
}

@override
void main() async {
  HttpOverrides.  global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Note: previously forced useAndroidViewSurface = true for Adreno GPU
  // blank-tile workaround. Removed because it forces the OLD hybrid-composition
  // backend, which causes the GoogleMap to stay blank for several minutes after
  // the screen opens (polylines render but tiles never load until much later).
  // The default TLHC SurfaceProducer backend in google_maps_flutter_android 2.18+
  // is significantly faster and is now correct on Adreno devices.
  // Initialize GetStorage here so LanguageController.onInit() can read saved locale.
  await GetStorage.init();
  Get.put(LanguageController());
  Get.put(HomeBannerController(), permanent: true);
  runApp(const MyApp());
}

/// Called from SplashScreen to finish heavy async initialization.
Future<void> initializeApp() async {
  await Firebase.initializeApp();
  await GetStorage.init();
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.subscribeToTopic('all_users');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Only treat `resumed` as a background→foreground return if the app was
  // actually paused first. This avoids firing during the cold-start splash
  // transition (where showing a dialog over Splash would get dropped).
  bool _wasPaused = false;

  @override
  void initState() { 
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start / terminated → open is covered by the Dashboard landing
    // check (it runs once the home screen is actually mounted), so we don't
    // race the splash here.
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      // Genuine background → foreground (incl. opening from recents): re-check
      // so a delivery that happened while away shows its rating popup.
      debugPrint('⭐[RATING] trigger: app RESUMED → checkPending');
      RatingPromptService.instance.checkPending();
    }
  }

  @override
  Widget build(BuildContext context){
    return GetBuilder<LanguageController>(
      builder: (languageController){
        return LayoutBuilder(
          builder: (context, constraints){
            AppSize.init(context);
            final mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(textScaler: TextScaler.linear(1.0)),
              child: GetMaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'Bestseed',
                locale: languageController.currentLocale.value,
                fallbackLocale: const Locale('en', 'US'),
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate],
                supportedLocales: const [
                  Locale('en', 'US'),
                  Locale('te', 'IN'),
                  Locale('hi', 'IN'),
                  Locale('ta', 'IN'),
                  Locale('kn', 'IN'),
                  Locale('ml', 'IN'),
                  Locale('mr', 'IN'),
                  Locale('gu', 'IN'),
                  Locale('pa', 'IN'),
                  Locale('bn', 'IN'),
                  Locale('or', 'IN'),
                  Locale('ur', 'IN'),
                ],
                ///
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                  useMaterial3: true,
                ),
                // Force-update is handled by [AppVersionManager.checkForceUpdate]
                // + [ForceUpdateScreen] driven from the splash screen — that
                // route has the Bestseed logo, single "Update Now" button, and
                // no dismiss/skip. The `upgrader` package's `UpgradeAlert`
                // was previously wrapped here but it fell back to a plain-text
                // "Deprecated Version" screen on Play Store installs when its
                // scraper couldn't fetch the listing — the custom screen is
                // strictly better on every path.
                home: const SplashScreen(),
              ),
            );
          },
        );
      },
    );    
  }
}