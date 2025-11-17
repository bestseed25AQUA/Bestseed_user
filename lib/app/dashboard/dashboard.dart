// import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:get/get.dart';
// import 'package:seedsuser/app/broadstock/view/broad_stock_screen.dart';
// import 'package:seedsuser/app/common/app_color.dart';
// import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
// import 'package:seedsuser/app/home/view/home_screen.dart';
// import 'package:seedsuser/app/news%20&%20ads/view/news_ads_screen.dart';
// import 'package:seedsuser/app/seed_price/view/seed_price_screen.dart';
// import 'package:seedsuser/app/updates/view/update_screen.dart';
// import 'package:seedsuser/l10n/app_localizations.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   final DashboardController controller = Get.put(DashboardController());

//   final List<Widget> pages = [
//     HomeScreen(),
//     SeedPricesScreen(),
//     BroodStockScreen(),
//     NewsAdsScreen(),
//     UpdatesScreen(),
//   ];

//   final List<IconData> icons = [
//     Icons.home_outlined,
//     Icons.local_offer_outlined,
//     Icons.store_outlined,
//     Icons.article_outlined,
//     Icons.location_on_outlined,
//   ];

//   late StreamSubscription subscription;
//   bool isDeviceConnected = false;
//   bool isAlertSet = false;

//   @override
//   void initState() {
//     super.initState();
//     getConnectivity();
//   }

//   void getConnectivity() {
//     subscription = Connectivity().onConnectivityChanged.listen((
//       List<ConnectivityResult> results,
//     ) async {
//       bool currentStatus =
//           await InternetConnectionChecker.createInstance().hasConnection;

//       if (!currentStatus && !isAlertSet) {
//         showDialogBox();
//         setState(() => isAlertSet = true);
//       } else if (currentStatus && isAlertSet) {
//         if (mounted) {
//           Navigator.pop(context);
//         }
//         setState(() => isAlertSet = false);
//       }
//     });
//   }

//   showDialogBox() => showCupertinoDialog<String>(
//     context: context,
//     builder: (BuildContext context) => CupertinoAlertDialog(
//       title: const Text('No Connection'),
//       content: const Text('Please check your internet connectivity'),
//       actions: <Widget>[
//         TextButton(
//           onPressed: () async {
//             Navigator.pop(context, 'Cancel');
//             setState(() => isAlertSet = false);
//             isDeviceConnected =
//                 await InternetConnectionChecker.createInstance().hasConnection;
//             if (!isDeviceConnected && isAlertSet == false) {
//               showDialogBox();
//               setState(() => isAlertSet = true);
//             }
//           },
//           child: const Text('OK'),
//         ),
//       ],
//     ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     final List<String> labels = [
//       AppLocalizations.of(context).home,
//       AppLocalizations.of(context).price,
//       AppLocalizations.of(context).broadstock,
//       AppLocalizations.of(context).news_ads,
//       AppLocalizations.of(context).updates,
//     ];

//     return WillPopScope(
//       onWillPop: () async {
//         // Show confirmation dialog
//         if (controller.currentIndex.value != 0) {
//           controller.changeIndex(0);
//         } else {
//           final result = await showDialog<bool>(
//             context: context,
//             barrierDismissible: false, // user must choose
//             builder: (context) => Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 4,
//               backgroundColor: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.exit_to_app, size: 50, color: AppColors.primary),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Exit App',
//                       style: GoogleFonts.roboto(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Are you sure you want to close the app?',
//                       textAlign: TextAlign.center,
//                       style: GoogleFonts.roboto(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.grey[300],
//                               elevation: 0,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: const EdgeInsets.symmetric(vertical: 14),
//                             ),
//                             onPressed: () => Navigator.of(context).pop(false),
//                             child: Text(
//                               'No',
//                               style: GoogleFonts.roboto(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.primary,
//                               elevation: 0,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: const EdgeInsets.symmetric(vertical: 14),
//                             ),
//                             onPressed: () => Navigator.of(context).pop(true),
//                             child: Text(
//                               'Yes',
//                               style: GoogleFonts.roboto(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );

//           return result ?? false;
//         }
//         return false;

//         // Return true to exit, false to stay
//       },
//       child: Scaffold(
//         body: Obx(() => pages[controller.currentIndex.value]),
//         bottomNavigationBar: Obx(
//           () => ClipRRect(
//             borderRadius: const BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16),
//             ),
//             child: BottomNavigationBar(
//               currentIndex: controller.currentIndex.value,
//               selectedItemColor: Colors.white,
//               unselectedItemColor: Colors.white70,
//               backgroundColor: AppColors.primary,
//               type: BottomNavigationBarType.fixed,
//               selectedFontSize: 12,
//               unselectedFontSize: 12,
//               selectedLabelStyle: GoogleFonts.roboto(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//               unselectedLabelStyle: GoogleFonts.roboto(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w400,
//               ),
//               onTap: (index) => controller.changeIndex(index),
//               items: List.generate(
//                 icons.length,
//                 (index) => BottomNavigationBarItem(
//                   icon: Icon(icons[index]),
//                   label: labels[index],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class DashboardScreen extends StatelessWidget {
//   DashboardScreen({super.key});

//   final DashboardController controller = Get.put(DashboardController());

//   final List<IconData> icons = [
//     Icons.home_outlined,
//     Icons.local_offer_outlined,
//     Icons.store_outlined,
//     Icons.article_outlined,
//     Icons.location_on_outlined,
//   ];

//   final List<Widget> bottomBarPages = [
//     HomeScreen(),
//     SeedPricesScreen(),
//     BroodStockScreen(),
//     NewsAdsScreen(),
//     UpdatesScreen(),
//   ];

//   final List<String> labels = [
//     "Home",
//     "Price",
//     "Broadstock",
//     "News & Ads",
//     "Updates",
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Obx(() => bottomBarPages[controller.currentIndex.value]),

//       extendBody: true,
//       bottomNavigationBar: Obx(
//         () => AnimatedNotchBottomBar(
//           notchBottomBarController: NotchBottomBarController(
//             index: controller.currentIndex.value,
//           ),
//           color: AppColors.primary,
//           showLabel: true,
//           textOverflow: TextOverflow.visible,
//           maxLine: 1,
//           shadowElevation: 5,
//           kBottomRadius: 28.0,
//           notchColor: AppColors.primary,
//           removeMargins: false,
//           bottomBarWidth: 500,
//           showShadow: false,
//           durationInMilliSeconds: 300,
//           itemLabelStyle: GoogleFonts.roboto(
//             fontSize: 10,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//           elevation: 1,

//           /// Build bottom bar items dynamically
//           bottomBarItems: List.generate(
//             icons.length,
//             (index) => BottomBarItem(
//               inActiveItem: Icon(icons[index], color: Colors.white),
//               activeItem: Icon(icons[index], color: Colors.white),
//               itemLabel: labels[index],
//             ),
//           ),

//           onTap: (index) {
//             log('current selected index $index');
//             controller.changeIndex(index); // 👈 Update index via GetX
//           },
//           kIconSize: 24.0,
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../home/view/home_screen.dart';
import '../seed_price/view/seed_price_screen.dart';
import '../broadstock/view/broad_stock_screen.dart';
import '../news & ads/view/news_ads_screen.dart';
import '../updates/view/update_screen.dart';
import 'dashboard_controller.dart';
import '../../l10n/app_localizations.dart';

import 'package:seedsuser/app/common/app_color.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());

  final PageController _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _notchController = NotchBottomBarController(
    index: 0,
  );

  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  final List<Widget> pages = [
    HomeScreen(),
    SeedPricesScreen(),
    BroodStockScreen(),
    NewsAdsScreen(),
    UpdatesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    getConnectivity();

    //
    ever(controller.currentIndex, (index) {
      _pageController.jumpToPage(index);
      _notchController.jumpTo(index);
    });
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
        if (mounted) Navigator.pop(context);
        setState(() => isAlertSet = false);
      }
    });
  }

  showDialogBox() => showCupertinoDialog<String>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('No Connection'),
      content: const Text('Please check your internet connectivity'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            setState(() => isAlertSet = false);
            isDeviceConnected =
                await InternetConnectionChecker.createInstance().hasConnection;
            if (!isDeviceConnected && !isAlertSet) {
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppLocalizations.of(context).home,
      AppLocalizations.of(context).price,
      AppLocalizations.of(context).broadstock,
      AppLocalizations.of(context).news_ads,
      AppLocalizations.of(context).updates,
    ];

    final icons = [
      Icons.home_outlined,
      Icons.local_offer_outlined,
      Icons.store_outlined,
      Icons.article_outlined,
      Icons.location_on_outlined,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: true
            ? Brightness.light
            : Brightness.dark,
      ),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (controller.currentIndex.value != 0) {
              controller.changeIndex(0);
              // _notchController.jumpTo(0);
              // _pageController.jumpToPage(0);
            } else {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "No",
                                  style: GoogleFonts.roboto(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Yes"),
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
            return false;
          },
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages,
                );
              },
            ),
            extendBody: true,
            bottomNavigationBar: SafeArea(
              child: Builder(
                builder: (context) {
                  return Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        child: SizedBox(
                          child: Container(
                            color: Colors.white,
                            width: 500,
                            height: 83,
                          ),
                        ),
                      ),
                      AnimatedNotchBottomBar(
                        notchBottomBarController: _notchController,
                        color: AppColors.primary,
                        showLabel: true,
                        notchColor: AppColors.primary,
                        bottomBarWidth: 500,
                        bottomBarHeight: 70,
                        kBottomRadius: 20,
                        itemLabelStyle: GoogleFonts.roboto(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                        durationInMilliSeconds: 300,
                        bottomBarItems: List.generate(
                          icons.length,
                          (index) => BottomBarItem(
                            inActiveItem: Icon(
                              icons[index],
                              color: Colors.white70,
                            ),
                            activeItem: Icon(icons[index], color: Colors.white),
                            itemLabel: labels[index],
                          ),
                        ),
                        onTap: (index) {
                          log("Tab changed to $index");
                          controller.changeIndex(index);
                        },
                        kIconSize: 20,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}