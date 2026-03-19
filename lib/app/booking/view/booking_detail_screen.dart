import 'package:flutter/material.dart';
import 'package:seedsuser/app/booking/view/widgets/booking_detail_shimmer.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/model/booking_detail_model.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_best_seed_background.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_map_screen.dart';
import 'package:url_launcher/url_launcher.dart';
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

  bool isPending(int status) => status == 1;
  bool isConfirmed(int status) => status == 2;
  bool isDriverAssigned(int status) => status == 3;
  bool isInProgress(int status) => status == 4;
  bool isDelivered(int status) => status == 5;
  bool isCancelled(int status) => status == 6;

  Color _statusColor(int status) {
    if (isCancelled(status)) return const Color(0xFFEF4444);
    if (isPending(status)) return const Color(0xFFF97316);
    if (isDelivered(status)) return const Color(0xFF10B981);
    return const Color(0xFF0076BE);
  }

  Color _statusBgColor(int status) {
    if (isCancelled(status)) return const Color(0xFFFEE2E2);
    if (isPending(status)) return const Color(0xFFFFF7ED);
    if (isDelivered(status)) return const Color(0xFFD1FAE5);
    return const Color(0xFFDBEAFE);
  }

  IconData _statusIcon(int status) {
    if (isCancelled(status)) return Icons.cancel_rounded;
    if (isPending(status)) return Icons.schedule_rounded;
    if (isConfirmed(status)) return Icons.check_circle_outline_rounded;
    if (isDriverAssigned(status)) return Icons.local_shipping_outlined;
    if (isInProgress(status)) return Icons.route_rounded;
    if (isDelivered(status)) return Icons.task_alt_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: Text(
          widget.hatcheryName ?? 'Booking Details',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          RefreshButton(
            onTap: () => controller.fetchBookingDetail(widget.bookingId),
          ),
          SizedBox(width: w * 0.03),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const BookingDetailShimmer();
        }

        final data = controller.bookingDetail.value;
        if (data == null) return const Center(child: Text("No data"));

        return CustomRefereshIndicator(
          onRefresh: () => controller.fetchBookingDetail(widget.bookingId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                _statusHeader(data, w),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Cancel button for pending
                      if (isPending(data.statusValue)) ...[
                        _cancelButton(w),
                        const SizedBox(height: 16),
                      ],

                      // Timeline section
                      if (!isPending(data.statusValue) &&
                          !isCancelled(data.statusValue))
                        _timelineCard(
                          data.bookingStatus,
                          data.statusValue,
                          w,
                          data.bookingDescription,
                          () {
                            Get.to(
                              VehicleTrackingMapScreen(
                                bookingId: data.bookingId.toString(),
                              ),
                            );
                          },
                        ),

                      // Cancellation reason
                      if (isCancelled(data.statusValue) &&
                          data.cancellationReason != null)
                        _cancellationReasonCard(data.cancellationReason!, w),

                      // Driver details
                      if (data.driver != null &&
                          data.statusValue >= 3 &&
                          data.statusValue != 5 &&
                          data.statusValue != 6)
                        _driverCard(data.driver!, w),

                      // Booking Info Card
                      _bookingInfoCard(data, w),

                      // Locations Card
                      _locationsCard(data, w),

                      // Note section
                      if (data.note.isNotEmpty) _noteCard(data.note, w),

                      // Help section
                      _helpCard(w, data.vendorMobile),

                      const SizedBox(height: 16),
                      CustomBestSeedBackground(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Status Header ───────────────────────────────────────────────
  Widget _statusHeader(BookingDetailModel data, double w) {
    final color = _statusColor(data.statusValue);
    final bgColor = _statusBgColor(data.statusValue);
    final icon = _statusIcon(data.statusValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            data.status,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.statusDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: color.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Booking #${data.bookingUId}",
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cancel Button ───────────────────────────────────────────────
  Widget _cancelButton(double w) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _openCancelReasonSheet(widget.bookingId),
        icon: const Icon(Icons.close_rounded, size: 20),
        label: Text(
          "Cancel Booking",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Cancellation Reason Card ─────────────────────────────────────
  Widget _cancellationReasonCard(CancellationReasonModel reason, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cancellation Reason",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timeline Card ───────────────────────────────────────────────
  Widget _timelineCard(
    List<BookingStatusStep> steps,
    int statusValue,
    double w,
    String? bookingDescription,
    VoidCallback onTapCheckVehicleStatus,
  ) {
    final bool showVehicleButton = statusValue == 4;
    final String descriptionText =
        (bookingDescription != null && bookingDescription.isNotEmpty)
            ? bookingDescription
            : "We've received your booking. Within a few days, we will assign your vehicle.";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Booking Status",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              descriptionText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              final bool done = s.status;
              final bool isLast = index == steps.length - 1;
              final activeColor =
                  done ? const Color(0xFF10B981) : Colors.grey.shade300;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor,
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: activeColor,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight:
                                      done ? FontWeight.w600 : FontWeight.w500,
                                  color: done
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                ),
                              ),
                              if (s.label.toLowerCase() == "in progress" &&
                                  showVehicleButton)
                                InkWell(
                                  onTap: onTapCheckVehicleStatus,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Track",
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (s.time.isNotEmpty)
                            Text(
                              s.time,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            )
                          else if (!done)
                            Text(
                              "Pending",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade400,
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
        ),
      ),
    );
  }

  // ─── Driver Card ─────────────────────────────────────────────────
  Widget _driverCard(DriverDetailModel driver, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Driver Details",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE8F4FD),
                    backgroundImage:
                        driver.image != null && driver.image!.isNotEmpty
                            ? NetworkImage(driver.image!)
                            : null,
                    child: driver.image == null || driver.image!.isEmpty
                        ? Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (driver.name != null && driver.name!.isNotEmpty)
                        Text(
                          driver.name!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (driver.vehicleNumber != null &&
                          driver.vehicleNumber!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            driver.vehicleNumber!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (driver.mobile != null && driver.mobile!.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final uri = Uri(scheme: 'tel', path: driver.mobile);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
            if (driver.vehicleStartedDate != null &&
                driver.vehicleStartedDate!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _driverInfoChip(
                    Icons.schedule_rounded,
                    driver.vehicleStartedDate!,
                  ),
                ],
              ),
            ],
            if (driver.vehicleStartAddress != null &&
                driver.vehicleStartAddress!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _driverInfoChip(
                    Icons.location_on_outlined,
                    driver.vehicleStartAddress!,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _driverInfoChip(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Booking Info Card ───────────────────────────────────────────
  Widget _bookingInfoCard(BookingDetailModel data, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Booking Details",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.tag_rounded, "Booking ID", "#${data.bookingId}"),
            _infoDivider(),
            _infoRow(Icons.category_outlined, "Category", data.categoryName),
            _infoDivider(),
            _infoRow(
              Icons.calendar_today_rounded,
              "Delivery Date",
              data.bookingDateTime,
            ),
            _infoDivider(),
            _infoRow(
              Icons.event_outlined,
              "Packing Date",
              data.preferredDate,
            ),
            _infoDivider(),
            _infoRow(Icons.inventory_2_outlined, "No. of Pieces", data.pieces),
            _infoDivider(),
            _infoRow(Icons.water_drop_outlined, "Salinity",
                "${data.salinity} PPT"),
            _infoDivider(),
            _infoRow(
              Icons.currency_rupee_rounded,
              "Estimated Price",
              data.estimatedPrice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }

  Widget _infoDivider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }

  // ─── Locations Card ──────────────────────────────────────────────
  Widget _locationsCard(BookingDetailModel data, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Locations",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFFEF4444),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup Location",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.unitLocation,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Drop Location",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.droppingLocation,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Note Card ───────────────────────────────────────────────────
  Widget _noteCard(String note, double w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 20, color: const Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Note",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Help Card ───────────────────────────────────────────────────
  Widget _helpCard(double w, String? vendorMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.support_agent_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need Help?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Contact us for any queries",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (vendorMobile != null && vendorMobile.isNotEmpty)
            InkWell(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: vendorMobile);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Call",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helper Methods ──────────────────────────────────────────────
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return "${dateTime.day.toString().padLeft(2, '0')}-${months[dateTime.month - 1]}-${dateTime.year}";
    } catch (e) {
      return str;
    }
  }

  // ─── Cancel Reason Bottom Sheet ──────────────────────────────────
  void _openCancelReasonSheet(String bookingId) {
    final List<String> reasons = [
      "Delay in processing",
      "Incorrect order details",
      "Wrong quantity requested",
      "Stock quality issues",
      "Other",
    ];

    String selectedReason = reasons[0];
    final otherReasonController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          final w = MediaQuery.sizeOf(context).width;
          final isOther = selectedReason == "Other";

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Reason for Cancellation",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        otherReasonController.dispose();
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...reasons.map((r) {
                  final isSelected = selectedReason == r;
                  return GestureDetector(
                    onTap: () => setState(() => selectedReason = r),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFEE2E2)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Text field for "Other" reason
                if (isOther) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherReasonController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: "Please describe your reason...",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isOther &&
                          otherReasonController.text.trim().isEmpty) {
                        return; // Don't submit without reason text
                      }
                      Navigator.pop(context);
                      controller.cancelBooking(
                        bookingId,
                        (reasons.indexOf(selectedReason) + 1).toString(),
                        otherReason: isOther
                            ? otherReasonController.text.trim()
                            : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Confirm Cancellation",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
