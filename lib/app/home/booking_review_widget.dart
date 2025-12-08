import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/common/custom_button.dart';

class BookingReviewContent extends StatelessWidget {
  final String name,
      phone,
      unit,
      pieces,
      location,
      date,
      hatcheryId,
      hatcheryName,
      locationId,categoryId, estimatedPrice;
  final bool isSpotHatchery;
  const BookingReviewContent({
    super.key,
    required this.name,
    required this.phone,
    required this.unit,
    required this.pieces,
    required this.location,
    required this.date,
    required this.hatcheryId,
    required this.hatcheryName,
    required this.locationId,
    required this.isSpotHatchery, required this.categoryId, required this.estimatedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyBookingController());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review Bookings',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // UI CARD
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.star_border, color: Colors.green),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hatcheryName,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildInfoRow('Name', name),
                const Divider(),
                _buildInfoRow('Phone Number', phone),
                const Divider(),
                _buildInfoRow('Unit', unit),
                const Divider(),
                _buildInfoRow('No.of Pieces', "$pieces Pieces"),
                const Divider(),
                _buildInfoRow('Estimated Price','₹$estimatedPrice'),
                const Divider(),
                _buildInfoRow('Dropping location', location),
                const Divider(),
                _buildInfoRow('Preferred Date', date),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PROCEED BUTTON
          Obx(
            () => CustomButton(
              onPressed: controller.isCreateLoading.value
                  ? () {}
                  : () async {
                      bool isBookingSuccess = await controller
                          .createHatcheryBooking(
                            categoryId: categoryId,
                            isSpotHatchery: isSpotHatchery,
                            hatcheryId: hatcheryId,
                            hatcheryName: hatcheryName,
                            customerName: name,
                            customerMobile: phone,
                            unit: unit,
                            noOfPieces: pieces,
                            droppingLocation: location,
                            packingDate: date,
                            locationId: '3', // locationId,
                          );

                      if (isBookingSuccess) {
                        Get.back();
                        _showSuccess(context);
                      }
                    },
              text: controller.isCreateLoading.value ? "Loading..." : "Proceed",
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SUCCESS DIALOG (Your Original Design)
  void _showSuccess(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/SealCheck.png',
                height: 109,
                width: 109,
              ),
              const SizedBox(height: 16),
              Text(
                'Your \nrequest was sent',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We will notify your booking status \nwithin 24 Hours',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Info Row UI (Same as your design)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 16),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
