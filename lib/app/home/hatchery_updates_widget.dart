import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

class HatcheryUpdatesWidget extends StatelessWidget {
  const HatcheryUpdatesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hatchery updates",
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 204, // Set a fixed height for the horizontal scrollable list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // Number of hatchery cards to display
            itemBuilder: (context, index) {
              return _buildHatcheryCard(
                imagePath: 'assets/images/rama.png',
                hatcheryName: "Rama Hatchery",
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHatcheryCard({
    required String imagePath,
    required String hatcheryName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the column take minimum space
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: AssetImage(
              imagePath,
            ), // Use AssetImage for local assets
            // If using network image:
            // backgroundImage: NetworkImage(imagePath),
          ),
          const SizedBox(height: 10),
          Text(
            hatcheryName,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              // Handle "View Profile" action
            },
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
