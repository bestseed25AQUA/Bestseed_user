import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final VehicleTrackingController controller = Get.put(
    VehicleTrackingController(),
  );

  String selected = "Filter";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Vehicle tracking',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          SizedBox(
            width: 100,
            height: 36,
            child: _buildDropdownButton(selected, ["Filter"], (newValue) {
              setState(() {
                selected = newValue!;
              });
            }),
          ),
        ],
      ),

      // ------------------------------
      // 🔥 LIST VIEW INTEGRATED HERE
      // ------------------------------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.vehicleList.isEmpty) {
            return Center(
              child: Text(
                "No vehicle data found",
                style: GoogleFonts.roboto(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.vehicleList.length,
            itemBuilder: (context, index) {
              final item = controller.vehicleList[index];
              return _buildVehicleDetailsCard(context, item);
            },
          );
        }),
      ),
    );
  }

  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
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

  // -----------------------------------------
  // 🔥 CARD WITH FULL API INTEGRATION
  // -----------------------------------------
  Widget _buildVehicleDetailsCard(BuildContext context, item) {
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
          _buildImageSection(item),
          _buildInfoSection(item),
          const SizedBox(height: 16),
          _buildDriverDetails(item),
          CustomButton(
            text: 'Tracking your vehicle',
            onPressed: () {
              // show bottom sheet
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You will receive SMS TO ${item.smsTo}',
              style: GoogleFonts.roboto(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // 🔥 IMAGES FROM API (using first image only)
  // -------------------------------------------------------
  Widget _buildImageSection(VehicleTrackingModel item) {
    final imageUrl = (item.images.isNotEmpty) ? item.images.first : null;

    return SizedBox(
      height: 135,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                height: 135,
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
      height: 135,
      color: Colors.grey[300],
      child: Center(
        child: Text('', style: GoogleFonts.roboto(color: Colors.black54)),
      ),
    );
  }

  // -------------------------------------------------------
  // 🔥 INFO SECTION BOUND WITH API
  // -------------------------------------------------------
  Widget _buildInfoSection(VehicleTrackingModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        Text(
          item.hatcheryName,
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        Text(
          item.categoryName,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Available date from booking details
        _buildInfoRow(
          Icons.calendar_today,
          "Available Date",
          item.bookingDetails.availableDate,
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // 🔥 DRIVER DETAILS INTEGRATED
  // -------------------------------------------------------
  Widget _buildDriverDetails(VehicleTrackingModel item) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE9F7FF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Driver Details',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    Text(item.driverDetails.driverName),
                  ],
                ),

                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.call_outlined),
                    Text(item.driverDetails.driverMobile),
                  ],
                ),

                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined),
                    Text(item.driverDetails.vehicleNumber),
                  ],
                ),
              ],
            ),
          ),
        ],
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
}
