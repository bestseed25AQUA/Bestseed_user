import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/app_animations.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/best_deals/view/best_deals_screen.dart';

import 'package:seedsuser/app/news & ads/view/climate_news_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';

import 'package:seedsuser/app/news & ads/view/medicine_news_screen.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';

import 'package:seedsuser/app/news & ads/view/trending_updates_screen.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';
import 'package:seedsuser/app/seed_price/view/seed_wanted_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String? image;
  final String? module;

  const NotificationDetailScreen({
    super.key,
    required this.title,
    required this.body,
    this.image,
    this.module,
  });

  @override
  Widget build(BuildContext context) {
    // Build the full image URL
    String? imageUrl;
    if (image != null && image!.isNotEmpty) {
      if (image!.startsWith('http')) {
        imageUrl = image;
      } else {
        imageUrl = '${NetworkConfig.imageURL}/$image';
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => _openFullScreenImage(context, imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (module != null && module!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () => _navigateToModule(context, module!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                module!,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, String moduleName) {
    Widget? screen;
    switch (moduleName) {
      case 'Best Deals':
        Navigator.push(context, AppAnimations.fade(const BestDealsScreen()));
        return;
      case 'Broodstock':
        final dashboardCtrl3 = Get.find<DashboardController>();
        dashboardCtrl3.changeIndex(2);
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Climate News':
        screen = const ClimateNewsScreen();
        break;
      case 'Farm Management':
        screen = const FarmManagementScreen();
        break;
      case 'Hatchery':
        screen = const HatcheryFilterScreen();
        break;
      case 'Hatchery Updates':
        final dashboardCtrl = Get.find<DashboardController>();
        dashboardCtrl.changeIndex(4);
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Medicine News':
      case 'Medical News':
        screen = const MedicineNewsScreen();
        break;
      case 'Seed Request':
        Navigator.push(context, AppAnimations.slideLeftToRight(SeedRequestsFormScreen()));
        return;
      case 'Spot Hatchery':
        screen = const SpotHatcheryScreen();
        break;
      case "Today's Market Prices":
        final dashboardCtrl2 = Get.find<DashboardController>();
        dashboardCtrl2.changeIndex(1);
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Trending Updates':
        screen = const TrendingUpdatesScreen();
        break;
      case 'Vehicle Availability':
        screen = const VehicleAvailabilityScreen();
        break;
      case 'Wanted Stock':
        screen = const SeedWantedScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white54,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
