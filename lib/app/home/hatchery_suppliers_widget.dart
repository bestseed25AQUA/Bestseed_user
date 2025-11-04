import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';

class HatcherySuppliersWidget extends StatelessWidget {
  const HatcherySuppliersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hatchery & Suppliers",
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                dashboardCtrl.changeIndex(2);
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
        _buildHatcheryCard(
          imageUrl:
              'assets/images/hatchery.png', // Replace with actual image URL
          availableDate: "23/06/2025",
          packingStartDate: "25/06/2025",
          hatcheryName: "NSR hatcheries",
          location: "Prakasam,Anakapalli",
          availableQuantity: "600 Pieces",
          supplierName: "Syaqua Americas Inc, Florida",
          importedDate: "20/06/2025",
        ),
        const SizedBox(height: 16),
        _buildHatcheryCard(
          imageUrl:
              'assets/images/hatchery.png', // Replace with actual image URL
          availableDate: "23/06/2025",
          packingStartDate: "25/06/2025",
          hatcheryName: "NSR hatcheries",
          location: "Prakasam,Anakapalli",
          availableQuantity: "600 Pieces",
          supplierName: "Syaqua Americas Inc, Florida",
          importedDate: "20/06/2025",
        ),
      ],
    );
  }

  Widget _buildHatcheryCard({
    required String imageUrl,
    required String availableDate,
    required String packingStartDate,
    required String hatcheryName,
    required String location,
    required String availableQuantity,
    required String supplierName,
    required String importedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 120,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Available on $availableDate",
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Packing Start From $packingStartDate",
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hatcheryName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: GoogleFonts.roboto(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Available Quantity",
                    style: GoogleFonts.roboto(color: Colors.grey),
                  ),
                  Text(
                    availableQuantity,
                    style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            supplierName,
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Imported Date on $importedDate",
            style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
