import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';
import 'package:seedsuser/app/vehicle_tracking/view/widgets/vehicle_availability_card.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_booking_detail_screen.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_map_screen.dart';
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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchVehicleList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<VehicleTrackingModel> _getFilteredList() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return controller.vehicleList;
    }
    return controller.vehicleList.where((item) {
      return item.hatcheryName.toLowerCase().contains(query) ||
          item.bookingId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onTapOutside: (event) => _focusNode.unfocus(),
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search for hatcherie...',
                  hintStyle: GoogleFonts.roboto(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: CustomRefereshIndicator(
              onRefresh: () async {
                await controller.fetchVehicleList();
              },
              child: Obx(() {
                if (controller.isLoading.value) {
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return vehicleAvailabilityCardShimmer();
                    },
                  );
                }

                final filteredList = _getFilteredList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      "No vehicle data found",
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return VehicleAvaibalityCard(
                      statusColor: (item.status.toLowerCase() == 'pending')
                          ? Colors.orange
                          : (item.status.toLowerCase() == 'cancelled')
                          ? Colors.red
                          : const Color(0xff25A652),
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
                      onTapTracking: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleTrackingMapScreen(
                              bookingId: item.id,
                            ),
                          ),
                        );
                      },
                      id: item.id,
                      bookingId: item.id,
                      time: item.time,
                      date: item.date,
                      title: item.hatcheryName,
                      subTitle: item.categoryName,
                      status: item.status,
                      isSpot: item.isSpot,
                      pickupLocation: item.pickupLocation,
                      dropLocation: item.dropLocation,
                      quantity: item.quantity,
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
} 

Widget vehicleAvailabilityCardShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spot Hatchery Label
          _shimmerBox(width: 100, height: 26, radius: 8),

          const SizedBox(height: 12),

          // ID + Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 80, height: 16),
              _shimmerBox(width: 90, height: 28, radius: 20),
            ],
          ),

          const SizedBox(height: 8),

          // Time and Date
          Align(
            alignment: Alignment.centerRight,
            child: _shimmerBox(width: 120, height: 14),
          ),

          const SizedBox(height: 12),

          // Hatchery Name
          _shimmerBox(width: double.infinity, height: 18),

          const SizedBox(height: 8),

          // Category
          _shimmerBox(width: 100, height: 14),

          const SizedBox(height: 12),

          // Pieces Row
          Row(
            children: [
              _shimmerCircle(size: 22),
              const SizedBox(width: 8),
              _shimmerBox(width: 80, height: 14),
            ],
          ),

          const SizedBox(height: 8),

          // Date Row
          Row(
            children: [
              _shimmerCircle(size: 18),
              const SizedBox(width: 8),
              _shimmerBox(width: 100, height: 14),
            ],
          ),

          const SizedBox(height: 8),

          // Location Row
          Row(
            children: [
              _shimmerCircle(size: 20),
              const SizedBox(width: 8),
              Expanded(child: _shimmerBox(height: 14)),
            ],
          ),

          const SizedBox(height: 16),

          // Tracking Button
          _shimmerBox(
            width: double.infinity,
            height: 46,
            radius: 25,
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
