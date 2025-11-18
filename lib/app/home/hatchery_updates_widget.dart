import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/updates/view/hatchery_details_screen.dart';

class HatcheryUpdatesWidget extends StatelessWidget {
  HatcheryUpdatesWidget({super.key});

  final hatcheryController = Get.put(HatcheryUpdatesController());
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());
  final dashboardCtrl = Get.find<DashboardController>();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hatchery updates",
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                hatcheryUpdatesController.fetchHatcheryUpdates();
                dashboardCtrl.changeIndex(4);
              },
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
        const SizedBox(height: 10),
        Obx(() {
          return (hatcheryController.hatcheryHomeData.value?.data.length ??
                      0) ==
                  0
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'No hathcery updates found',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                )
              : SizedBox(
                  height: 224,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        (hatcheryController
                                    .hatcheryHomeData
                                    .value
                                    ?.data
                                    .length ??
                                0) <=
                            4
                        ? (hatcheryController
                                  .hatcheryHomeData
                                  .value
                                  ?.data
                                  .length ??
                              0)
                        : 4,
                    itemBuilder: (context, index) {
                      final data = hatcheryController
                          .hatcheryHomeData
                          .value
                          ?.data[index];
                      return _buildHatcheryCard(
                        imagePath: data?.profileImage ?? '',
                        hatcheryName: data?.hatcheryName ?? '',
                        viewProfileTap: () {
                          hatcheryUpdatesController.fetchHatcheryUpdatesSingle(
                            id: data?.hatcheryId ?? '',
                          );
                          Get.to(HatcheryDetailsScreen());
                        },
                      );
                    },
                  ),
                );
        }),
      ],
    );
  }

  Widget _buildHatcheryCard({
    required String imagePath,
    required String hatcheryName,
    required VoidCallback viewProfileTap,
  }) {
    print(imagePath);
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xff000000).withOpacity(.16),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the column take minimum space
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(100),
            child: Image.network(
              imagePath,
              width: 72,
              height: 72,
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(width: 72, height: 72, child: CustomShimmer());
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: Text(
              hatcheryName,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: viewProfileTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: Text(
              "View Profile",
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
