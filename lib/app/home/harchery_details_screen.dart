import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/harchery_card_widget.dart';

class HatcheryDetailScreen extends StatelessWidget {
  const HatcheryDetailScreen({super.key});

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
          "Seven star Hatcheries",
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
            videoUrl:
                "assets/images/WhatsApp Video 2025-10-04 at 11.11.46 AM.mp4",
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

          // Similar Hatcheries Section
          _buildSimilarHatcheriesSection(),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Image.asset('assets/images/banner.png'),
    );
  }

  Widget _buildSimilarHatcheriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Similar Hatcheries",
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 175, // Fixed height for horizontal scrolling
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Example count
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 10,
                    right: index == 4
                        ? 0
                        : 10, // Add right padding for the last item
                  ),
                  child: _buildSimilarHatcheryCard(
                    hatcheryName: "Gayethri hatchery",
                    location: "Vizag",
                    seedType: "Syqua",
                    imageUrl: "assets/images/fish_swimming.png", // Replace
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarHatcheryCard({
    required String hatcheryName,
    required String location,
    required String seedType,
    required String imageUrl,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              imageUrl,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hatcheryName,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                location,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                seedType,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
