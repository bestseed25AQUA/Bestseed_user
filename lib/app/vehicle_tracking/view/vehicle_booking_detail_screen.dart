// booking_details_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_booking_detail_model.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/vehicle_tracking_screen.dart';
import '../controller/vehicle_tracking_controller.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String id; // API booking id

  const BookingDetailsScreen({
    super.key,
    required this.id,
    required String status,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final controller = Get.put(VehicleTrackingController());

  @override
  void initState() {
    super.initState();
    controller.fetchVehicleBookingDetail(widget.id); // API call
  }

  String getStatusString(String status) {
    final statusStrings = {
      "1": 'Pending',
      "2": 'In Progress',
      "3": 'Confirmed',
      "4": 'Driver Assigned',
      "5": 'Delivered',
      "6": 'Cancelled',
      "Pending": 'Pending',
      "In_progress": 'In Progress',
      "Confirmed": 'Confirmed',
      "Driver_assigned": 'Driver Assigned',
      "Delivered": 'Delivered',
      "Cancelled": 'Cancelled',
    };

    return statusStrings[status] ?? '';
  }

  bool isPending(String status) {
    return status == "1";
  }

  bool isInProgress(String status) {
    return status == "2";
  }

  bool isConfirmed(String status) {
    return status == "3";
  }

  bool isDriverAssigned(String status) {
    return status == "4";
  }

  bool isDelivered(String status) {
    return status == "5";
  }

  bool isCancelled(String status) {
    return status == "6";
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Seven Star Hatchery',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.bookingDetail.value;
        if (data == null) {
          return const Center(child: Text("No Booking Data Found"));
        }

        final status = data.status.toLowerCase();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.01),
              _buildStatusBox(
                getStatusString(data.status),
                data.status,
                data.statusDescription,
                w,
                h,
              ),

              SizedBox(height: h * 0.02),

              _buildLocationCard(data, w),

              SizedBox(height: 25),

              _title("Vehicle Booking Details", w),

              _detail("Hatchery Name", data.vehicleDetails.hatchery, w),
              _detail("Brand type", data.vehicleDetails.brand, w),
              _detail("Seed Qty", data.vehicleDetails.qty, w),
              _detail(
                "Booking Date & time",
                "${data.vehicleDetails.bookingDate}, ${data.vehicleDetails.bookingTime}",
                w,
              ),
              SizedBox(height: 20),

              if (status == "pending" || status == '1') ...[
                SizedBox(height: 20),
                Center(
                  child: InkWell(
                    onTap: () => _openCancelReasonSheet(widget.id),
                    child: Container(
                      width: w * 0.9,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          "Cancel Booking",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                _bookingStatusTimeline(data.bookingStatus, w, () {
                  Get.to(
                    VehicleTrackingScreen(bookingId: data.bookingId.toString()),
                  );
                }),
              SizedBox(height: 40),

              _helpSection(w),

              SizedBox(height: 50),
            ],
          ),
        );
      }),
    );
  }

  // ------------------------ WIDGETS ------------------------

  Widget _title(String text, double w) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: w * 0.04, fontWeight: FontWeight.w600),
  );

  Widget _detail(String title, String value, double w) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: w * 0.035,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(
    String status,
    String statusValue,
    String description,
    double w,
    double h,
  ) {
    Color statusColor =
        (isPending(statusValue) || status.toLowerCase() == 'pending')
        ? Colors.orange
        : (isCancelled(statusValue) || status.toLowerCase() == 'cancelled')
        ? Colors.red
        : Colors.green;

    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.02),
      width: double.infinity,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: statusColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: w * 0.047,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Booking Status: $status',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: w * 0.034, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(VehicleBookingDetailModel data, double w) {
    return Container(
      width: MediaQuery.of(context).size.width * .9,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 3),
            color: Colors.grey.shade300,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              double height = 14;
              double width = 2;
              double gap = 3;
              return Column(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(height: gap),
                  Container(height: height, color: Colors.black, width: width),
                  SizedBox(height: gap),
                  Container(
                    height: height + 15,
                    color: Colors.black,
                    width: width,
                  ),
                  SizedBox(height: gap),
                  Container(height: height, color: Colors.black, width: width),
                  SizedBox(height: gap),
                  Icon(Icons.circle, color: Colors.red, size: 12),
                ],
              );
            },
          ),
          SizedBox(width: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width * .7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup location",
                          style: GoogleFonts.poppins(fontSize: w * 0.035),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .4,
                          child: Text(
                            data.pickupDetails.location,
                            style: GoogleFonts.poppins(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .25,
                      child: Text(
                        "${data.pickupDetails.date}, ${data.pickupDetails.time}",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w200,
                          fontSize: w * 0.033,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Drop location",
                          style: GoogleFonts.poppins(fontSize: w * 0.035),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .4,
                          child: Text(
                            data.dropDetails.location,
                            style: GoogleFonts.poppins(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .25,
                      child: Text(
                        "${data.dropDetails.date}, ${data.dropDetails.time}",
                        style: GoogleFonts.poppins(
                          fontSize: w * 0.033,
                          color: Colors.black,
                          fontWeight: FontWeight.w200,
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
    );
  }

  Widget _bookingStatusTimeline(
    List<BookingStatusStep> steps,
    double w,
    VoidCallback ontapCheckVehicleStatus,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Vehicle Booking Status", w),
        SizedBox(height: 5),
        Text(
          "We've received your booking. Within a few days, we will assign your vehicle.",
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: w * 0.032),
        ),
        SizedBox(height: 20),

        ...steps.map((s) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  s.completed
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: w * 0.07,
                        )
                      : Icon(Icons.circle, color: Colors.grey),
                  if (s.title != 'delivered')
                    Container(
                      width: 2,
                      height: s.title.contains('progress') ? 45 : 30,
                      color: s.completed == 1 ? Colors.green : Colors.grey,
                    ),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title.replaceAll("_", " ").toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${s.date}, ${s.time}",
                      style: GoogleFonts.poppins(
                        fontSize: w * 0.033,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 5),
                    if (s.title.contains('progress'))
                      InkWell(
                        onTap: ontapCheckVehicleStatus,
                        child: Text(
                          'Check vehicle status',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Color(0xff3B82F6),
                          ),
                        ),
                      ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _helpSection(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Have a question ? ",
          style: GoogleFonts.poppins(fontSize: w * 0.035),
        ),
        Text(
          "Reach out to us.",
          style: GoogleFonts.poppins(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  void _openCancelReasonSheet(String bookingId) {
    final List<String> reasons = [
      "Delay in processing",
      "Incorrect order details",
      "Wrong quantity requested",
      "Stock quality issues",
      "Other",
    ];

    String selectedReason = reasons[0];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          final w = MediaQuery.sizeOf(context).width;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Reason for cancel",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ...reasons.asMap().entries.map((entry) {
                  int index = entry.key;
                  String r = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(r, style: const TextStyle(fontSize: 15)),
                    trailing: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        boxShadow: selectedReason == r
                            ? [BoxShadow(color: Colors.green, blurRadius: 7)]
                            : [],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedReason == r
                              ? Colors.green
                              : Colors.grey,
                          width: 2,
                        ),
                        color: selectedReason == r
                            ? Colors.green
                            : Colors.transparent,
                      ),
                    ),
                    onTap: () {
                      setState(() => selectedReason = r);
                    },
                  );
                }),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    controller.cancelBooking(
                      bookingId,
                      (reasons.indexOf(selectedReason) + 1).toString(),
                    );
                  },
                  child: Container(
                    width: w * 0.8,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
