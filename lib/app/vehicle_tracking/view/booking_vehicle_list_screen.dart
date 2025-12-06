import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_bottom_sheet.dart';
import 'package:seedsuser/app/vehicle_tracking/view/widgets/vehicle_availability_card.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_booking_detail_screen.dart';

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
        // actions: [
        //   GestureDetector(
        //     onTap: () => showFilterSheet(),
        //     child: Container(
        //       margin: const EdgeInsets.only(right: 16),
        //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(8),
        //         border: Border.all(color: Colors.grey.shade300),
        //       ),
        //       child: Row(
        //         children: [
        //           Text(
        //             "Filters",
        //             style: GoogleFonts.roboto(
        //               fontSize: 14,
        //               color: Colors.black,
        //               fontWeight: FontWeight.w500,
        //             ),
        //           ),
        //           const SizedBox(width: 6),
        //           const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        //         ],
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
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
              return VehicleAvaibalityCard(
                ontapViewDetails: () {
                  print(item.status.toLowerCase());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingDetailsScreen(
                        // status: item.status.toLowerCase(),
                        status: 'confiremd',
                        id: item.id,
                      ),
                    ),
                  );
                },
                id: item.bookingId,
                time: item.time,
                date: item.date,
                title: item.hatcheryName,
                subTitle: item.categoryName,
                status: item.status,
                pickupLocation: item.pickupLocation,
                dropLocation: item.dropLocation,
                quantity: item.quantity,
              );
            },
          );
        }),
      ),
    );
  }
}
