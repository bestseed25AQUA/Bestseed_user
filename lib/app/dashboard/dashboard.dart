import 'dart:developer';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/broadstock/broad_stock_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/home_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/news_ads_screen.dart';
import 'package:seedsuser/app/seed_price/seed_price_screen.dart';
import 'package:seedsuser/app/updates/update_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  final List<IconData> icons = [
    Icons.home_outlined,
    Icons.local_offer_outlined,
    Icons.store_outlined,
    Icons.article_outlined,
    Icons.location_on_outlined,
  ];

  final List<Widget> bottomBarPages = [
    HomeScreen(),
    SeedPricesScreen(),
    BroodStockScreen(),
    NewsAdsScreen(),
    UpdatesScreen(),
  ];

  final List<String> labels = [
    "Home",
    "Price",
    "Broadstock",
    "News & Ads",
    "Updates",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => bottomBarPages[controller.currentIndex.value]),

      extendBody: true,
      bottomNavigationBar: Obx(
        () => AnimatedNotchBottomBar(
          notchBottomBarController: NotchBottomBarController(
            index: controller.currentIndex.value,
          ),
          color: AppColors.primary,
          showLabel: true,
          textOverflow: TextOverflow.visible,
          maxLine: 1,
          shadowElevation: 5,
          kBottomRadius: 28.0,
          notchColor: AppColors.primary,
          removeMargins: false,
          bottomBarWidth: 500,
          showShadow: false,
          durationInMilliSeconds: 300,
          itemLabelStyle: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          elevation: 1,

          /// Build bottom bar items dynamically
          bottomBarItems: List.generate(
            icons.length,
            (index) => BottomBarItem(
              inActiveItem: Icon(icons[index], color: Colors.white),
              activeItem: Icon(icons[index], color: Colors.white),
              itemLabel: labels[index],
            ),
          ),

          onTap: (index) {
            log('current selected index $index');
            controller.changeIndex(index); // 👈 Update index via GetX
          },
          kIconSize: 24.0,
        ),
      ),
    );
  }
}
