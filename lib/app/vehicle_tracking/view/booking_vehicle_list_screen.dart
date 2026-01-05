import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_bottom_sheet.dart';
import 'package:seedsuser/app/vehicle_tracking/view/widgets/vehicle_availability_card.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_booking_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final VehicleTrackingController controller = Get.put(
    VehicleTrackingController(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchVehicleList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Text(
          'Vehicle tracking',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: CustomRefereshIndicator(
          onRefresh: () async {
            await controller.fetchVehicleList();
          },
        child: Obx(() {
          if (controller.isLoading.value) {
            return ListView.builder(
              shrinkWrap: true,
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemCount: 3,
              itemBuilder: (context, index) {
                return vehicleAvailabilityCardShimmer();
              },
            );
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
            padding: EdgeInsets.symmetric(horizontal: 7),
            itemBuilder: (context, index) {
              final item = controller.vehicleList[index];
              return VehicleAvaibalityCard(
                statusColor: (item.status.toLowerCase() == 'pending')
                    ? Colors.orange
                    : (item.status.toLowerCase() == 'cancelled')
                    ? Colors.red
                    : Colors.green,
                ontapViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingDetailsScreen(
                        status: item.status.toLowerCase(),
                        id: item.id,
                        hatcheryName: item.hatcheryName
                      ),
                    ),
                  );
                },
        
                id: item.bookingId?.toString() ?? "",
                time: item.time?.toString() ?? "",
                date: item.date?.toString() ?? "",
                title: item.hatcheryName?.toString() ?? "",
                subTitle: item.categoryName?.toString() ?? "",
                status: item.status?.toString() ?? "",
                pickupLocation: item.pickupLocation?.toString() ?? "",
                dropLocation: item.dropLocation?.toString() ?? "",
                quantity: item.quantity?.toString() ?? "",
              );
            },
          );
        }),
      ),
    );
  }
} 

Widget vehicleAvailabilityCardShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration( 
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
        border: Border.all(width: 1)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- ID ----------
          _shimmerBox(width: 100, height: 14),

          const SizedBox(height: 6),

          // -------- TIME + DATE ----------
          Align(
            alignment: Alignment.centerRight,
            child: _shimmerBox(width: 120, height: 12),
          ),

          const SizedBox(height: 14),

          // -------- TITLE + STATUS ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: double.infinity, height: 16),
                    const SizedBox(height: 6),
                    _shimmerBox(width: 140, height: 13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _shimmerBox(width: 70, height: 26, radius: 20),
            ],
          ),

          const SizedBox(height: 18),

          // -------- PICKUP / DROP ----------
          Row(
            children: [
              Column(
                children: [
                  _shimmerCircle(size: 12),
                  const SizedBox(height: 4),
                  _shimmerLine(height: 14),
                  const SizedBox(height: 4),
                  _shimmerLine(height: 28),
                  const SizedBox(height: 4),
                  _shimmerLine(height: 14),
                  const SizedBox(height: 4),
                  _shimmerCircle(size: 12),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 120, height: 12),
                    const SizedBox(height: 6),
                    _shimmerBox(width: double.infinity, height: 14),
                    const SizedBox(height: 22),
                    _shimmerBox(width: 120, height: 12),
                    const SizedBox(height: 6),
                    _shimmerBox(width: double.infinity, height: 14),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // -------- QUANTITY ----------
          Row(
            children: [
              _shimmerCircle(size: 20),
              const SizedBox(width: 8),
              _shimmerBox(width: 80, height: 14),
            ],
          ),

          const SizedBox(height: 18),

          // -------- VIEW DETAILS BUTTON ----------
          _shimmerBox(
            width: double.infinity,
            height: 40,
            radius: 20,
          ),
        ],
      ),
    ),
  );
}
Widget _shimmerBox({
  double width = 100,
  double height = 12,
  double radius = 8,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget _shimmerCircle({double size = 16}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

Widget _shimmerLine({double height = 16}) {
  return Container(
    width: 2,
    height: height,
    color: Colors.white,
  );
}
