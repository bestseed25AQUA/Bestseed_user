import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/broadstock/view/broad_stock_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/view/home_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/news_ads_screen.dart';
import 'package:seedsuser/app/seed_price/view/seed_price_screen.dart';
import 'package:seedsuser/app/updates/view/update_screen.dart';
import 'package:seedsuser/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final HomeController _homeController = Get.put(HomeController());

  final List<Widget> pages = [
    HomeScreen(),
    SeedPricesScreen(),
    BroodStockScreen(),
    NewsAdsScreen(),
    UpdatesScreen(),
  ];

  final List<String> icons = [
    'assets/images/home.png',
    'assets/images/price.png',
    'assets/images/broodstock.png',
    'assets/images/news.png',
    'assets/images/updates.png',
  ];

  final List<String> filledIcon = [
    'assets/images/home_filled.png',
    'assets/images/price_filled.png',
    'assets/images/broodstock_filled.png',
    'assets/images/news_filled.png',
    'assets/images/updates_filled.png',
  ];

  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  @override
  void initState() {
    super.initState();
    getConnectivity();
  }

  void getConnectivity() {
    subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      bool currentStatus =
          await InternetConnectionChecker.createInstance().hasConnection;

      if (!currentStatus && !isAlertSet) {
        showDialogBox();
        setState(() => isAlertSet = true);
      } else if (currentStatus && isAlertSet) {
        if (mounted) {
          Navigator.pop(context);
        }
        setState(() => isAlertSet = false);
      }
    });
  }

  showDialogBox() => showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('No Connection'),
      content: const Text('Please check your internet connectivity'),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context, 'Cancel');
            setState(() => isAlertSet = false);
            isDeviceConnected =
                await InternetConnectionChecker.createInstance().hasConnection;
            if (!isDeviceConnected && isAlertSet == false) {
              showDialogBox();
              setState(() => isAlertSet = true);
            }
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<String> labels = [
      AppLocalizations.of(context).home,
      AppLocalizations.of(context).price,
      AppLocalizations.of(context).broadstock,
      AppLocalizations.of(context).news_ads,
      AppLocalizations.of(context).updates,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () async { 
          print('++++++++++++++++++++++++');
          print(controller.currentIndex);
          // Show confirmation dialog 
          if (controller.currentIndex.value != 0) {
            controller.changeIndex(0);
            return false;
          } else {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false, // user must choose
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
                elevation: 4,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        size: 50,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exit App',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to close the app?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'No',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Yes',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            return result ?? false;
          }

          // Return true to exit, false to stay
        },
        child: Scaffold(
          body: Obx(() => pages[controller.currentIndex.value]),
          bottomNavigationBar: Obx(
            () => ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              child: BottomNavigationBar(
                currentIndex: controller.currentIndex.value,
                selectedItemColor: Color(0xff0076BE),
                unselectedItemColor: Colors.black,
                backgroundColor: Colors.white, // AppColors.primary,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                onTap: (index) => controller.changeIndex(index),
                items: List.generate(
                  icons.length,
                  (index) => BottomNavigationBarItem(
                    icon: Image.asset(
                      index == controller.currentIndex.value
                          ? filledIcon[index]
                          : icons[index],

                      color: !(2 == controller.currentIndex.value)
                          ? Color(0xff0076BE)
                          : null,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox();
                      },  
                      height: index == controller.currentIndex.value? 30:25,
                      width:  index == controller.currentIndex.value? 30:25,
                    ),
                    label: labels[index],
                    backgroundColor: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
