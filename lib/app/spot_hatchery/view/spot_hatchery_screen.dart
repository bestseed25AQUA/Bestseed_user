import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/spot_hatchery/controller/spot_hatchery_controller.dart';
import 'package:seedsuser/app/spot_hatchery/view/harchery_card_widget.dart';
import 'package:seedsuser/app/spot_hatchery/widget/spot_hatchery_banner_widget.dart';

class SpotHatcheryScreen extends StatelessWidget {
  const SpotHatcheryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SpotHatcheryController controller = Get.put(SpotHatcheryController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Spot Hatcheries",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.banners.isEmpty) {
          return Center(
            child: Text(
              "No hatcheries found.",
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 2),
          itemCount: controller.banners.length + 1, // +1 for promo banner
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  SizedBox(height: 16),
                  SpotHatcheryBannerWidget(),
                  SizedBox(height: 8),
                ],
              );
            } 
            final hatchery = controller.banners[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 20),
              child: HarcheryCardWidget(spotHatchery: hatchery),
            );
          },
        );
      }),
    );
  }
}
