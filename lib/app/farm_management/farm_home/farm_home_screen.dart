import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farm_home/notify_us_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/initial_farmer_screen.dart';
import 'package:seedsuser/app/farm_management/manager/view/manager_screen.dart';

class FarmHomeScreen extends StatelessWidget {
  const FarmHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine screen height for proportional background
    // final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // The background color is a gradient from dark blue to a lighter blue
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0076BE),
              Color.fromARGB(255, 64, 103, 128),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.3, 1.0], // Adjust stops for gradient effect
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Title and Subtitle Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Farm Management',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset("assets/images/farm_line.png", width: 210),
                    SizedBox(height: 8),
                    Text(
                      'Add your farm and tank details to track feed usage easily and keep records updated.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards Section - Expanded to take remaining space but centered
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _UserCard(
                      title: 'Farmer',
                      imageAsset: 'assets/images/farmer.png',
                      onTap: () {
                        Get.to(() => const NotifyUsScreen());
                      },
                    ),
                    const SizedBox(height: 20),
                    _UserCard(
                      title: 'Manager',
                      onTap: () {
                        Get.to(() =>   ManagerScreen());
                      },

                      imageAsset: 'assets/images/manager.png',
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Notification/Footer Section
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ), // Adjusted for the "BEST SEED.." text below
                child: Column(
                  children: [
                    Text(
                      "Can't add it? Tap below to tell us — we'll add it for you",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                            ), // Border is transparent, just text/icon color
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Home',
                                style: GoogleFonts.roboto(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              const Icon(
                                Icons
                                    .home, // Using a standard icon as an example
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10,),
                        OutlinedButton(
                          onPressed: () {
                            Get.to(() => const NotifyUsScreen());
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                            ), // Border is transparent, just text/icon color
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Notify us',
                                style: GoogleFonts.roboto(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              const Icon(
                                Icons
                                    .arrow_circle_right, // Using a standard icon as an example
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 54),
                    // Center(
                    //   child: Text(
                    //     'BEST SEED..',
                    //     style: GoogleFonts.roboto(
                    //       color: Color(0xFFF1F1F1),
                    //       fontSize: 54,
                    //       fontWeight: FontWeight.w900,
                    //       letterSpacing: 2,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A reusable widget for the Farmer/Manager card
class _UserCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  const _UserCard({
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      50.0,
                    ), // Makes it look circular
                    child: Image.asset(
                      imageAsset, // Replace with your actual asset path
                      width: 137,
                      height: 137,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_circle_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
