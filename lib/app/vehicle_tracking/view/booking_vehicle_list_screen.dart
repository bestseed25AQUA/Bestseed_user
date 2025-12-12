import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
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
