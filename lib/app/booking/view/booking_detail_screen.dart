import 'package:flutter/material.dart';
import 'package:seedsuser/app/booking/view/widgets/booking_detail_shimmer.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/model/booking_detail_model.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_best_seed_background.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/vehicle_tracking_screen.dart';
import '../controller/my_booking_controller.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String? hatcheryName;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.hatcheryName,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final controller = Get.put(MyBookingController());

  @override
  void initState() {
    super.initState();
    controller.fetchBookingDetail(widget.bookingId);
  }

  String getStatusString(int status) {
    final statusStrings = {
      1: 'Pending',
      2: 'Confirmed',
      3: 'Driver Assigned',
      4: 'In Progress',
      5: 'Delivered',
      6: 'Cancelled',
    };

    return statusStrings[status] ?? 'Unknown';
  }

  bool isPending(int status) {
    return status == 1;
  }

  bool isConfirmed(int status) {
    return status == 2;
  }

  bool isDriverAssigned(int status) {
    return status == 3;
  }

  bool isInProgress(int status) {
    return status == 4;
  }

  bool isDelivered(int status) {
    return status == 5;
  }

  bool isCancelled(int status) {
    return status == 6;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Text(
          widget.hatcheryName ?? 'Detail',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const BookingDetailShimmer();
        }

        final data = controller.bookingDetail.value;
        if (data == null) return const Center(child: Text("No data"));

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _statusBox(
                data.statusValue,
                data.status,
                data.statusDescription,
                w,
              ),

              const SizedBox(height: 20),
              if (isPending(data.statusValue))
                Center(
                  child: InkWell(
                    onTap: () => _openCancelReasonSheet(widget.bookingId),
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
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                )
              // else if (isCancelled(data.statusValue))
              //   Container(
              //     width: w * 0.9,
              //     height: 48,
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.red),
              //       borderRadius: BorderRadius.circular(25),
              //       color: Color(0xffF87171).withOpacity(.1),
              //     ),
              //     child: const Center(
              //       child: Text(
              //         "Cancelled",
              //         style: TextStyle(color: Colors.red, fontSize: 16),
              //       ),
              //     ),
              //   )
              else
                _timelineSection(data.bookingStatus, w, () {
                  Get.to(
                    VehicleTrackingScreen(bookingId: data.bookingId.toString()),
                  );
                }),

              const SizedBox(height: 20),

              Text(
                "Booking Details",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              _detail("ID", data.bookingId.toString(), w),
              _detail("Date & Time", data.bookingDateTime, w),
              _detail("Unit location", data.unitLocation, w),
              _detail("No. of pieces", data.pieces, w),
              _detail("Estimated Price", data.estimatedPrice, w),
              _detail("Dropping location", data.droppingLocation, w),
              _detail("Preferred Date", data.preferredDate, w),
              SizedBox(height: 10),
              Text(
                "Note : ${data.note}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 20),
              _helpSection(w),
              SizedBox(height: 30),
              CustomBestSeedBackground(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _detail(String key, String value, double w) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox(int value, String status, String description, double w) {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isCancelled(value)
            ? Colors.red.withOpacity(.1)
            : isPending(value)
            ? Color(0xffFFF7ED)
            : const Color(0xFFE7F7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            status,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isCancelled(value)
                  ? Colors.red.withOpacity(.9)
                  : isPending(value)
                  ? Color(0xffF97316)
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isCancelled(value)
                  ? Colors.red.withOpacity(1)
                  : isPending(value)
                  ? Color(0xffF97316)
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineSection(
    List<BookingStatusStep> steps,
    double w,
    VoidCallback ontapCheckVehicleStatus,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Booking Status",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "We've received your booking. Within a few days, we will assign your vehicle.",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
        ),

        const SizedBox(height: 20),

        ...steps.map((s) {
          final bool done = s.status;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.circle,
                    size: 26,
                    color: done ? Colors.green : Colors.grey,
                  ),
                  if (s.label.toLowerCase() != "Delivered".toLowerCase())
                    Container(
                      width: 2,
                      height: 40,
                      color: done ? Colors.green : Colors.grey,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTime(s.label),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (s.label.toLowerCase() ==
                              "In Progress".toLowerCase())
                            InkWell(
                              onTap: ontapCheckVehicleStatus,
                              child: Text(
                                "Check vehicle status",
                                style: GoogleFonts.roboto(
                                  color: Colors.blue,
                                  fontWeight: done ? FontWeight.bold : null,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        s.time,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String getTime(String str) {
    try {
      final dateTime = DateTime.parse(str);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      return str;
    }
  }

  String getDate(String str) {
    try {
      final dateTime = DateTime.parse(str);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${dateTime.day.toString().padLeft(2, '0')}-${months[dateTime.month - 1]}-${dateTime.year}";
    } catch (e) {
      return str;
    }
  }

  Widget _helpSection(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text("Have a question? ", style: GoogleFonts.poppins(fontSize: 14)),
        Text(
          "Contact us",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                ...reasons.asMap().entries.map((entry) {
                  int index = entry.key;
                  String r = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(r, style: const TextStyle(fontSize: 14)),
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
                        style: TextStyle(color: Colors.red, fontSize: 14),
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
