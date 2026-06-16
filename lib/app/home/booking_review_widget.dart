import 'package:flutter/material.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/common/custom_button.dart';

class BookingReviewContent extends StatelessWidget {
  final String name,
      phone,
      unit,
      salinity,
      pieces,
      location,
      date,
      deliveryDate,
      hatcheryId,
      hatcheryName,
      locationId,
      categoryId,
      categoryName,
      estimatedPrice;
  final BuildContext bottomSheetContext;
  final bool isSpotHatchery;
  final bool isVehicleHatchery;
  final double? dropLat;
  final double? dropLng;
  const BookingReviewContent({
    super.key,
    required this.name,
    required this.phone,
    required this.unit,
    required this.salinity,
    required this.pieces,
    required this.location,
    this.dropLat,
    this.dropLng,
    required this.date,
    required this.deliveryDate,
    required this.hatcheryId,
    required this.hatcheryName,
    required this.locationId,
    required this.isSpotHatchery,
    required this.isVehicleHatchery,
    required this.categoryId,
    required this.categoryName,
    required this.estimatedPrice,
    required this.bottomSheetContext,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyBookingController());

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Review Bookings',
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (categoryName.isNotEmpty) ...[
                        _buildInfoRow('Category', categoryName),
                        const Divider(),
                      ],
                      if (name.trim().isNotEmpty) ...[
                        _buildInfoRow('Name', name),
                        const Divider(),
                      ],
                      _buildInfoRow('Phone Number', phone),
                      const Divider(),
                      _buildInfoRow('Unit', unit),
                      const Divider(),
                      _buildInfoRow('Salinity', salinity.isNotEmpty ? salinity : '-'),
                      const Divider(),
                      _buildInfoRow('No.of Pieces', "$pieces Pieces"),
                      const Divider(),
                      _buildInfoRow('Estimated Price', '₹$estimatedPrice'),
                      const Divider(),
                      _buildInfoRow('Dropping location', location),
                      const Divider(),
                      _buildInfoRow('Packing Date', date),
                      if (deliveryDate.toString().isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow('Preferred Delivery Date', deliveryDate),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // PROCEED BUTTON - pinned at bottom
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: Obx(
            () => CustomButton(
              onPressed: controller.isCreateLoading.value
                  ? () {}
                  : () async {
                      String? isBookingId = await controller
                          .createHatcheryBooking(
                            categoryId: categoryId,
                            isSpotHatchery: isSpotHatchery,
                            isVehicleHatchery: isVehicleHatchery,
                            hatcheryId: hatcheryId,
                            hatcheryName: hatcheryName,
                            customerName: name,
                            customerMobile: phone,
                            unit: unit,
                            salinity: salinity,
                            noOfPieces: pieces,
                            price: estimatedPrice,
                            droppingLocation: location,
                            dropLat: dropLat,
                            dropLng: dropLng,
                            packingDate: date,
                            deliveryDate: deliveryDate,
                            locationId: '3', // locationId,
                          );
                      if (isBookingId != null) {
                        Get.back();
                        showSuccess(context, isBookingId);
                      }
                    },
              verticalPadding: 9,
              textStyle: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              text: controller.isCreateLoading.value ? "Loading..." : "Proceed",
            ),
          ),
        ),
      ],
    );
  }

  // ✅ SUCCESS DIALOG (Your Original Design)

  // ✅ Info Row UI (Same as your design)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSuccess(BuildContext context, String bookingId) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        contentPadding: EdgeInsets.all(10),
        backgroundColor: Colors.white,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Container()),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 1, color: Colors.grey),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(4),
                      child: const Icon(Icons.close),
                    ),
                    onTap: () => Navigator.pop(dialogContext),
                  ),
                ),
              ],
            ),
            Image.asset('assets/images/SealCheck.png', height: 80, width: 80),
            const SizedBox(height: 16),
            Text(
              'Booking request\nsent',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We will notify your booking status \nwithin 24 Hours',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: CustomButton(
                verticalPadding: 8,
                borderRadius: 20,
                text: 'Review Booking',
                textStyle: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () async {
                  Get.back();
                  await Future.delayed(Duration(seconds: 1));
                  Get.to(BookingDetailScreen(bookingId: bookingId));
                },
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                'Skip',
                style: GoogleFonts.roboto(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
