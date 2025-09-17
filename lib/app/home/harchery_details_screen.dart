import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/hatchery_details.dart';

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
          _buildHatcheryItem(
            hatcheryName: "Syqua",
            imageUrl: "assets/images/royalu.png",
            unit1: "Kakinada",
            unit2: "Vizag",
            broadstock: "1200 Pieces",
            availableDate: "27 Sep 2024",
            pricePerPiece: "₹0.36",
            status: "Available",
            statusColor: Colors.green,
            context: context,
          ),
          const SizedBox(height: 20),

          // Hatchery Item 2
          _buildHatcheryItem(
            hatcheryName: "SIS Hardline",
            imageUrl: "assets/images/royalu.png",
            unit1: "Bapatla",
            unit2: "Vizag",
            broadstock: "1200 Pieces",
            availableDate: "27 Sep 2024",
            pricePerPiece: "₹0.36",
            status: "Closed",
            statusColor: Colors.red,
            context: context,
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

  Widget _buildHatcheryItem({
    required String hatcheryName,
    required String imageUrl,
    required String unit1,
    required String unit2,
    required String broadstock,
    required String availableDate,
    required String pricePerPiece,
    required String status,
    required Color statusColor,
    String? nextAvailable,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: () {
        Get.to(() => HatcheryDetail());
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Status Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  child: Image.asset(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Play Video",
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (nextAvailable != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        nextAvailable,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hatcheryName,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.location_on, "Unit - 1", unit1),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.water_drop_outlined,
                              "Broadstock",
                              broadstock,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.timer, "Price", pricePerPiece),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,

                          children: [
                            _buildInfoRow(Icons.location_on, "Unit - 2", unit2),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              "Available Date",
                              availableDate,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset('assets/images/phone.png', height: 20),
                            Text(
                              'Call Now',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/whatsApp.png',
                              height: 20,
                            ),
                            Text(
                              'WhatsApp',
                              style: GoogleFonts.roboto(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showBookingBottomSheet(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),

                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/Lightning.png',
                                height: 20,
                              ),
                              Text(
                                'Book Now',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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
