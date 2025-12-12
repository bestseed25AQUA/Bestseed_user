// first_screen.dart
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/contact_us_dialog.dart';

class InitialFarmScreen extends StatelessWidget {
  const InitialFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary color used in the image's app bar/button
    const Color primaryBlue = Color(0xFF007BFF); // Example blue

    return Scaffold(
      // CustomAppBar as seen in the image (blue background)
      appBar: CustomAppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Farmer', style: GoogleFonts.roboto(color: Colors.white)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ), // The hamburger menu icon
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.headset_mic_outlined,
                color: Colors.black,
                size: 20,
              ), // Headset icon for Help
              onPressed: () {
                showContactUsDialog(context);
              },
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

            // Bottom button
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
          ],
        ),
      ),
    );
  }
}
