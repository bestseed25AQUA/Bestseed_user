// first_screen.dart
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/farm_home/farm_home_screen.dart';
import 'package:seedsuser/app/farm_management/farm_home/notify_us_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';

class InitialFarmScreen extends StatelessWidget {
  const InitialFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Farmer',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top content: Image and text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/image 76.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Add Farm Details',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your farm's details to get started.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    onPressed: () {
                      Get.to(() => AddFarmerDetailsFormScreen());
                    },
                    text: 'Add Farm Details',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Get.to(() => const NotifyUsScreen());
                  },
                  child: Text(
                    'Contact Us',
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
