import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/splash_screen.dart'; 
import 'package:seedsuser/app/language/controller/language_controller.dart';
import 'package:seedsuser/app/notification/notification_service.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Subscribe to broadcast topic for admin notifications
  await notificationService.subscribeToTopic('all_users');
  

  Get.put(LanguageController());
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: AppColors.primary,
  //     statusBarIconBrightness: Brightness.light,
  //   ),
  // );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context){
    AppSize.init(context);
    return GetBuilder<LanguageController>(
      builder: (languageController) {
        return LayoutBuilder(
          builder: (context, constraints){
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
                  GlobalCupertinoLocalizations.delegate,
                ],
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
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                  useMaterial3: true,
                ),
                home: const SplashScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
