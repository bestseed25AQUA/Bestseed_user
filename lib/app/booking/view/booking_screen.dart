import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/vehicle_tracking_screen.dart';

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

    controller.fetchBookings();
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

      controller.fetchBookings();
      // ignore: use_build_context_synchronously
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
                        controller.fetchBookings();
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
        controller.fetchBookings();
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
        controller.fetchBookings();
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

  String selectedFilter = "";
  Widget buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });

        // CALL YOUR FILTER LOGIC HERE
        if (label == "All") {
          controller.filterType.value = "";
        } else if (label == "Hatchery") {
          controller.filterType.value = "hatchery";
        } else if (label == "Spot Hatchery") {
          controller.filterType.value = "spot";
        }

        controller.fetchBookings(); // refresh bookings
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
          'My Bookings',
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
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              // Inside your build() Widget
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    buildFilterChip("All"),
                    const SizedBox(width: 10),
                    buildFilterChip("Hatchery"),
                    const SizedBox(width: 10),
                    buildFilterChip("Spot Hatchery"),
                  ],
                ),
              ),

              Obx(() {
                if (controller.isLoading.value) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .3,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (controller.bookingList.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .3,
                    ),
                    child: Center(
                      child: Text(
                        "No bookings found",
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ),
                  );
                }
                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: controller.bookingList.length,
                    itemBuilder: (context, index) {
                      final booking = controller.bookingList[index];
                      return _buildBookingCard(booking, () {
                        Get.to(BookingDetailScreen(bookingId: booking.bookingId.toString(),));
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
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
  Widget _buildBookingCard(BookingData data, VoidCallback ontap) {
    // Status color
    Color statusColor = Colors.green;
    final String status = data.status?['label']?.toString() ?? '';
    if (status.toLowerCase() == "pending") {
      statusColor = Colors.orange;
    } else if (status.toLowerCase() == "cancelled") {
      statusColor = Colors.red;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------- TOP ROW --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.isSpot?.value == 1 ? "Spot Hatchery" : 'Hatchery',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    print(data.status.toString());
                  },
                  child: Text(
                    (status.toString()).capitalizeFirst ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // -------------------- ID + DATETIME --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ID:",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .3,
                    child: Text(
                      data.bookingUid,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                data.deliveryDatetime,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // -------------------- HATCHERY NAME --------------------
          Text(
            data.hatcheryName,
            style: GoogleFonts.roboto(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            data.categoryName,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          // -------------------- PIECES + DATE --------------------
          Row(
            children: [
              Image.asset(
                'assets/images/pieces_icon.png',
                height: 25,
                width: 25,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(height: 20, width: 20);
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "${data.noOfPieces} Pieces",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                data.packingDate,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -------------------- ADDRESS --------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 22, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.droppingLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -------------------- VIEW DETAILS BUTTON --------------------
          InkWell(
            onTap: ontap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                "View Details",
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Always placeholder (API has no image field)
  Widget _buildImageSection(String url) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[300],
          child: CustomNetworkImage(imageUrl: url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  // 🔹 Info Section

  Widget _iconText(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
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
