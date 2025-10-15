import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final MyBookingController controller = Get.put(MyBookingController());
  String selected = "Filter";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'My Bookings',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          SizedBox(
            width: 110,
            height: 36,
            child: _buildDropdownButton(selected, ["Filter"], (newValue) {
              setState(() => selected = newValue!);
            }),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.bookingList.isEmpty) {
          return Center(
            child: Text(
              "No bookings found",
              style: GoogleFonts.roboto(fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: controller.bookingList.length,
            itemBuilder: (context, index) {
              final booking = controller.bookingList[index];
              return _buildBookingCard(context, booking);
            },
          ),
        );
      }),
    );
  }

  // 🔹 Dropdown for filters
  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // 🔹 Each booking card
  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(booking),
          const SizedBox(height: 12),
          _buildInfoSection(booking),
        ],
      ),
    );
  }

  // 🔹 Image or placeholder
  Widget _buildImageSection(Booking booking) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: booking.mediaUrl != null && booking.mediaUrl!.isNotEmpty
            ? Image.network(
                booking.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text(
          'No Image',
          style: GoogleFonts.roboto(color: Colors.black54),
        ),
      ),
    );
  }

  // 🔹 Info layout
  Widget _buildInfoSection(Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking.hatcheryName,
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (booking.categories != null && booking.categories!.isNotEmpty)
          Text(
            booking.categories!,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildInfoRow(Icons.person, "Customer", booking.customerName),
                  // const SizedBox(height: 12),
                  // _buildInfoRow(Icons.phone, "Mobile", booking.customerMobile),
                  // const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.water_drop_outlined,
                    "Quantity",
                    "${booking.noOfPieces} pcs",
                  ),

                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    "Delivery",
                    booking.deliveryLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Expanded(
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       // _buildInfoRow(
            //       //   Icons.calendar_today,
            //       //   "Packing Date",
            //       //   booking.packingDate,
            //       // ),
            //       // const SizedBox(height: 12),
            //       _buildInfoRow(
            //         Icons.location_on,
            //         "Delivery",
            //         booking.deliveryLocation,
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
