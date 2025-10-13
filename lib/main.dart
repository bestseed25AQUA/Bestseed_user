import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/splash_screen.dart';
import 'package:seedsuser/app/language/controller/language_controller.dart';
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

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize GetX LanguageController
  Get.put(LanguageController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (languageController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Seeds User',

          // Localization setup
          locale: languageController.currentLocale.value,
          fallbackLocale: const Locale('en', 'US'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'), // English
            Locale('te', 'IN'), // Telugu
            Locale('hi', 'IN'), // Hindi
            Locale('ta', 'IN'), // Tamil
            Locale('kn', 'IN'), // Kannada
            Locale('ml', 'IN'), // Malayalam
            Locale('mr', 'IN'), // Marathi
            Locale('gu', 'IN'), // Gujarati
            Locale('pa', 'IN'), // Punjabi
            Locale('bn', 'IN'), // Bengali
            Locale('or', 'IN'), // Odia
            Locale('ur', 'IN'), // Urdu
          ],

          // Theme setup
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
