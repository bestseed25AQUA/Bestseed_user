import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final MyBookingController controller = Get.put(MyBookingController());
  final ProfileController profileController = Get.put(ProfileController());
  String selected = "Filter";

  @override
  void initState() {
    super.initState();
    controller.fetchBookings();
  }

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
          // SizedBox(
          //   width: 110,
          //   height: 36,
          //   child: _buildDropdownButton(selected, ["Filter"], (newValue) {
          //     setState(() => selected = newValue!);
          //   }),
          // ),
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

  // 🔹 Booking Card UI
  Widget _buildBookingCard(BuildContext context, BookingData booking) {
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
          _buildImageSection(), // No image in API, using placeholder
          const SizedBox(height: 12),
          _buildInfoSection(booking),
        ],
      ),
    );
  }

  // 🔹 Always placeholder (API has no image field)
  Widget _buildImageSection() {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(color: Colors.grey[300]),
      ),
    );
  }

  // 🔹 Info Section
  Widget _buildInfoSection(BookingData booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking.hatcheryName ?? "",
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.person,
                    "Customer",
                    booking.customerName ?? "",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone,
                    "Mobile",
                    booking.customerMobile ?? "",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.water_drop_outlined,
                    "Quantity",
                    "${booking.noOfPieces} pcs",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Packing Date",
                    formatDateDMY(booking.packingDate),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.location_city,
                    "Unit",
                    booking.unit ?? "",
                  ),
                  const SizedBox(height: 12),
                  // _buildInfoRow(
                  //   Icons.location_pin,
                  //   "Hatchery Location",
                  //   booking.hatcheryLocation ?? "",
                  // ),
                  // const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.pin_drop,
                    "Dropping Location",
                    booking.droppingLocation ?? "",
                  ),
                  // const SizedBox(height: 12),
                  // _buildInfoRow(
                  //   Icons.access_time,
                  //   "Created At",
                  //   booking.createdAt ?? "",
                  // ),
                ],
              ),
            ),
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
            value.isNotEmpty ? value : "",
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

String formatDateDMY(String dateString) {
  try {
    DateTime date = DateTime.parse(dateString);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  } catch (e) {
    return ""; // return empty if error
  }
}
