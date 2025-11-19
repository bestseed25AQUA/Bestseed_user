import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';

class HatcheryWidget extends StatelessWidget {
  final VoidCallback onViewAllTap;

  HatcheryWidget({super.key, required this.onViewAllTap});

  final HomeController _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2); // Responsive width
    final cardHeight = cardWidth * 1.35; // auto height

    return Obx(() {
      if (_homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_homeController.hatcheries.isEmpty) {
        return const SizedBox();
      }

      final list = _homeController.hatcheries.length > 6
          ? _homeController.hatcheries.sublist(0, 6)
          : _homeController.hatcheries;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 10),
                TextButton(
                  onPressed: onViewAllTap,
                  child: Text(
                    "View all",
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: List.generate((list.length / 2).ceil(), (rowIndex) {
              final i1 = rowIndex * 2;
              final i2 = i1 + 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // LEFT CARD
                    Expanded(
                      child: HatcheryCard(
                        width: cardWidth,
                        height: cardHeight,
                        imagePath: list[i1].imagePath,
                        title: list[i1].title,
                        location: list[i1].location,
                        type: list[i1].type,
                        id: list[i1].id.toString(),
                        status: list[i1].status,
                        statusColor: list[i1].status.toLowerCase() == "open"
                            ? const Color(0xff25A652)
                            : list[i1].status.toLowerCase() == "coming soon"
                            ? const Color(0xff007DFE)
                            : const Color(0xffE31B1B),
                        availableUntil: list[i1].availableUntil,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // RIGHT CARD (only if exists)
                    Expanded(
                      child: i2 < list.length
                          ? HatcheryCard(
                              width: cardWidth,
                              height: cardHeight,
                              id: list[i1].id.toString(),
                              imagePath: list[i2].imagePath,
                              title: list[i2].title,
                              location: list[i2].location,
                              type: list[i2].type,
                              status: list[i2].status,
                              statusColor:
                                  list[i2].status.toLowerCase() == "open"
                                  ? const Color(0xff25A652)
                                  : list[i2].status.toLowerCase() ==
                                        "coming soon"
                                  ? const Color(0xff007DFE)
                                  : const Color(0xffE31B1B),
                              availableUntil: list[i2].availableUntil,
                            )
                          : const SizedBox(), // If odd number of items
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}

class HatcheryCard extends StatelessWidget {
  final double width;
  final double height;
  final String imagePath;
  final String title;
  final String location;
  final String type;
  final String status;
  final Color statusColor;
  final String? availableUntil;
  final String? id;
  final VoidCallback? ontap;

  const HatcheryCard({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.type,
    required this.status,
    required this.statusColor,
    this.availableUntil,
    this.id,
    this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive image height based on screen size
    final imgHeight = (height * 0.45).clamp(90.0, screenHeight * 0.22);

    // Text font dynamic scaling
    double scaleText(double size) {
      return size * (screenWidth / 390); // 390 = base width (iPhone 12)
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // onTap: () => Get.to(() => HatcheryDetailScreen()),
      onTap:
          ontap ??
          () {
            print('ontap ok');
            Get.to(HatcheryCateogryScreen(hatcheryId: id.toString()));

            print('ontap on');
          },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(.16),
              blurRadius: 22,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        // ⭐ FULL RESPONSIVE PADDING
        padding: EdgeInsets.all(screenWidth * 0.025),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imagePath,
                    width: double.infinity,
                    height: imgHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(height: imgHeight, child: CustomShimmer()),
                  ),
                ),

                // STATUS BADGE
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    height: screenHeight * 0.027,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.015,
                      ),
                      child: Center(
                        child: Text(
                          status.length <= 15
                              ? status
                              : status.substring(0, 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: scaleText(13),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.012),

            // Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: scaleText(15),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: screenHeight * 0.006),

            // Location Row
            Row(
              children: [
                Image.asset(
                  'assets/images/location_icon.png',
                  height: scaleText(16),
                  width: scaleText(16),
                  color: const Color(0xff525050),
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.location_on,
                      size: scaleText(14),
                      color: Colors.grey,
                    );
                  },
                ),
                SizedBox(width: screenWidth * 0.015),

                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: scaleText(12),
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.006),

            // Type Row
            Row(
              children: [
                Image.asset(
                  'assets/images/category_icon.png',
                  height: scaleText(16),
                  width: scaleText(16),
                  color: const Color(0xff525050),
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.shopping_bag,
                      size: scaleText(14),
                      color: Colors.grey,
                    );
                  },
                ),
                SizedBox(width: screenWidth * 0.015),

                Expanded(
                  child: Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: scaleText(12),
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
