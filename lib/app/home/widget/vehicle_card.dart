import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/booking_vehicle_screen.dart';
import 'package:seedsuser/app/model/vehicle_availability_model.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  final RxInt _currentIndex = 0.obs;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.vehicle.vehicleImages.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.vehicle.vehicleImages.length,
                    onPageChanged: (index) => _currentIndex.value = index,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          widget.vehicle.vehicleImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/vehicle_image.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Current index indicator
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentIndex.value + 1}/${widget.vehicle.vehicleImages.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: Image.asset(
                'assets/images/vehicle_image.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteTimelineCard(
                  routes: widget.vehicle.vechileLocationTracking,
                ),
                // Hatchery Name
                Text(
                  widget.vehicle.hatcheryName,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.vehicle.hatcheryLocation ?? 'Unknown location',
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Start and End Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting date',
                          style: GoogleFonts.roboto(color: Colors.grey),
                        ),
                        Text(
                          "${widget.vehicle.startDate.day}/${widget.vehicle.startDate.month}/${widget.vehicle.startDate.year}",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ending date',
                          style: GoogleFonts.roboto(color: Colors.grey),
                        ),
                        Text(
                          widget.vehicle.endDate != null
                              ? "${widget.vehicle.endDate!.day}/${widget.vehicle.endDate!.month}/${widget.vehicle.endDate!.year}"
                              : 'N/A',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Available Space
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No. of space available',
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                    Text(
                      '${(widget.vehicle.availableSpace / 100000).toStringAsFixed(0)} Lakhs seeds',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Call Now
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _makePhoneCall(widget.vehicle.driverMobile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              topLeft: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/phone.png',
                                height: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Call Now',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // WhatsApp
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openWhatsApp(context, widget.vehicle),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/whatsApp.png',
                                height: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'WhatsApp',
                                style: GoogleFonts.roboto(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Book Now
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Get.to(
                            () => BookingVehicleScreen(vehicle: widget.vehicle),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/Lightning.png',
                                height: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Book Now',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  // Phone call function
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Open WhatsApp
  Future<void> _openWhatsApp(BuildContext context, Vehicle vehicle) async {
    final Uri whatsappUri = Uri.parse(vehicle.whatsapp);
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}

class RouteTimelineCard extends StatelessWidget {
  final List<String> routes;
  const RouteTimelineCard({super.key, required this.routes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dots and lines
          Column(
            children: List.generate(routes.length, (index) {
              return Column(
                children: [
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors
                                .green // Start point
                          : index == routes.length - 1
                          ? Colors
                                .red // End point
                          : Colors.blue, // Intermediate
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Line (skip for last item)
                  if (index != routes.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.blue.withOpacity(0.5),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(width: 12),

          // Route names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(routes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    routes[index],
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 8),
          // // Optional: vehicle or success icon
          // Image.asset('assets/images/success.png', height: 28),
        ],
      ),
    );
  }
}
