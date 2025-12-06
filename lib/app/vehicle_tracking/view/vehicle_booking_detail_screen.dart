// booking_details_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Seven Star Hatchery",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: w * 0.045,
          ),
        ),
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

              _buildStatusBox(data.status, data.statusDescription, w, h),

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

              if (status == "confirmed")
                _bookingStatusTimeline(data.bookingStatus, w, () {
                  Get.to(
                    VehicleTrackingScreen(vehicleId: data.driverId.toString()),
                  );
                }),

              if (status == "pending") ...[
                SizedBox(height: 20),
                _cancelButton(w),
              ],

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
    String description,
    double w,
    double h,
  ) {
    final isConfirm = status.toLowerCase() == "confirmed";

    return Container(
      padding: EdgeInsets.symmetric(vertical: h * 0.02),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isConfirm ? const Color(0xFFE7F7EB) : const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: w * 0.047,
              fontWeight: FontWeight.w600,
              color: isConfirm ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: w * 0.034,
              color: isConfirm ? Colors.green.shade700 : Colors.orange.shade700,
            ),
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
                    Text(
                      "Pickup location\n${data.pickupDetails.location}",
                      style: GoogleFonts.poppins(fontSize: w * 0.035),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .25,
                      child: Text(
                        "${data.pickupDetails.date}, ${data.pickupDetails.time}",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
                    Text(
                      "Drop location\n${data.dropDetails.location}",
                      style: GoogleFonts.poppins(fontSize: w * 0.035),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .25,
                      child: Text(
                        "${data.dropDetails.date}, ${data.dropDetails.time}",
                        style: GoogleFonts.poppins(
                          fontSize: w * 0.033,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
                  s.status == 1
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
                      color: s.status == 1 ? Colors.green : Colors.grey,
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

  Widget _cancelButton(double w) {
    return Center(
      child: Container(
        width: w * 0.55,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.red),
        ),
        child: Center(
          child: Text(
            "Cancel",
            style: GoogleFonts.poppins(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ),
      ),
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
}
