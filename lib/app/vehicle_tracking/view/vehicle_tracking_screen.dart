import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_bottom_sheet.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchVehicleList();
    });
  }

  void applyFilter(String filter) async {
    DateTime now = DateTime.now();

    if (filter == "Today") {
      controller.selectedDate.value =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";
    } else if (filter == "This Month") {
      controller.selectedMonth.value = now.month.toString();
      controller.selectedYear.value = now.year.toString();
      controller.selectedDate.value = "";
    } else if (filter == "This Year") {
      controller.selectedMonth.value = "";
      controller.selectedYear.value = now.year.toString();
      controller.selectedDate.value = "";
    } else if (filter == "Custom Date") {
      pickDate();
      return;
    } else if (filter == "Clear Filters") {
      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";
      controller.selectedDate.value = "";
    }

    controller.fetchVehicleList();
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.selectedDate.value =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";

      controller.fetchVehicleList();
      Navigator.pop(context);
    }
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------- DRAG HANDLE -------
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // ------- TITLE -------
                  Text(
                    "Filter Bookings",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ------- MONTH PICKER -------
                  Text(
                    "Select Month",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      return _monthChip(month);
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ------- YEAR PICKER -------
                  Text(
                    "Select Year",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 45,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(15, (index) {
                        final year = 2018 + index;
                        return _yearChip(year);
                      }),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------- CUSTOM DATE -------
                  Text(
                    "Custom Date",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            controller.selectedDate.value.isNotEmpty
                                ? controller.selectedDate.value
                                : "Select date",
                            style: GoogleFonts.roboto(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------- CLEAR FILTER -------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        controller.selectedMonth.value = "";
                        controller.selectedYear.value = "";
                        controller.selectedDate.value = "";
                        controller.fetchVehicleList();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Clear Filters",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _monthChip(int month) {
    return InkWell(
      onTap: () {
        controller.selectedMonth.value = month.toString();
        controller.selectedYear.value = "";
        controller.selectedDate.value = "";
        controller.fetchVehicleList();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Text(
          _monthName(month),
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  String _monthName(int m) {
    return [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ][m - 1];
  }

  Widget _yearChip(int year) {
    return InkWell(
      onTap: () {
        controller.selectedMonth.value = "";
        controller.selectedDate.value = "";
        controller.selectedYear.value = year.toString();
        controller.fetchVehicleList();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Text(
          "$year",
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }

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
          GestureDetector(
            onTap: () => showFilterSheet(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    "Filters",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                ],
              ),
            ),
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
            onPressed: () async {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: VehicleTrackingBottomSheet(vehicleId: ''),
                  );
                },
              );
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
