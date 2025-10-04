import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/harchery_card_widget.dart';

class SpotHatcheryScreen extends StatelessWidget {
  const SpotHatcheryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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
      body: ListView(
        children: [
          // Promotional Banner
          _buildPromotionalBanner(),
          const SizedBox(height: 20),

          // Hatchery Item 1
          HarcheryCardWidget(
            hatcheryName: "Syqua",
            videoUrl: "assets/images/video_20250921_103246.mp4",
            unit1: "Kakinada",
            imageUrl: "assets/images/Frame 1984080433 (1).png",
            unit2: "Vizag",
            broadstock: "1200 Pieces",
            availableDate: "27 Sep 2024",
            pricePerPiece: "₹0.36",
            status: "Available",
            statusColor: Colors.green,
          ),
          const SizedBox(height: 20),

          // Hatchery Item 2
          HarcheryCardWidget(
            hatcheryName: "SIS Hardline",
            videoUrl: "assets/images/video_20250921_103157.mp4",
            imageUrl: "assets/images/Frame 1984080433.png",
            unit1: "Bapatla",
            unit2: "Vizag",
            broadstock: "1200 Pieces",
            availableDate: "27 Sep 2024",
            pricePerPiece: "₹0.36",
            status: "Closed",
            statusColor: Colors.red,

            // nextAvailable: "Next available at 30/08/2025",
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Image.asset('assets/images/Frame 1984080519.png'),
    );
  }
}
