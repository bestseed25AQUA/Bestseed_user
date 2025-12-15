import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
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
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------
          //        IMAGE CAROUSEL
          // ---------------------------
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: widget.vehicle.vehicleImages.isEmpty
                  // ignore: deprecated_member_use
                  ? Container(color: Colors.grey.withOpacity(.2))
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: widget.vehicle.vehicleImages.length,
                      onPageChanged: (i) => _currentIndex.value = i,
                      itemBuilder: (_, index) {
                        return Image.network(
                          widget.vehicle.vehicleImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              // ignore: deprecated_member_use
                              Container(color: Colors.grey.withOpacity(.2)),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // ---------------------------
          //      ROUTE SECTION
          // ---------------------------
          Container(
            width: MediaQuery.of(context).size.width * .8,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: const Color(0xffEFF9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Image.asset('assets/images/truck.png', height: 20),
                  const SizedBox(width: 10),
                  if (widget.vehicle.vechileLocationTracking.isNotEmpty)
                    Row(
                      children:
                          List.generate(
                            widget.vehicle.vechileLocationTracking.length - 1,
                            (index) => Padding(
                              padding: const EdgeInsets.only(left: 5, right: 5),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  Text(
                                    widget
                                        .vehicle
                                        .vechileLocationTracking[index],
                                    style: GoogleFonts.roboto(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    ' ----->',
                                    style: GoogleFonts.roboto(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ) +
                          [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.vehicle.vechileLocationTracking[widget
                                        .vehicle
                                        .vechileLocationTracking
                                        .length -
                                    1],
                                style: GoogleFonts.roboto(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                    ),
                  // Expanded(
                  //   child: Wrap(
                  //     spacing: 6,
                  //     runSpacing: 6,
                  //     children: List.generate(
                  //       widget.vehicle.vechileLocationTracking.length,
                  //       (i) => Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Text(
                  //             widget.vehicle.vechileLocationTracking[i],
                  //             style: GoogleFonts.roboto(
                  //               color: Colors.blue[800],
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //           ),
                  //           if (i !=
                  //               widget.vehicle.vechileLocationTracking.length - 1)
                  //             const Text(
                  //               " → ",
                  //               style: TextStyle(color: Colors.grey),
                  //             ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),

          // ---------------------------
          //      HATCHERY NAME
          // ---------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(
              widget.vehicle.hatcheryName,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // LOCATION ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 17, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.vehicle.hatcheryLocation ?? "Unknown location",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---------------------------
          //     START - END DATE
          // ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dateColumn("Starting date", widget.vehicle.startDate),
                _dateColumn("Ending date", widget.vehicle.endDate),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---------------------------
          //    AVAILABLE SPACE
          // ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No.of space available",
                  style: GoogleFonts.roboto(color: Colors.grey),
                ),
                Text(
                  "${(widget.vehicle.availableSpace / 100000).toStringAsFixed(0)} Lakhs seeds",
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------------------
          //        ACTION BUTTONS
          // ---------------------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // CALL NOW
                Expanded(
                  child: InkWell(
                    onTap: () => _makePhoneCall(widget.vehicle.driverMobile),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          topLeft: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/phone.png', height: 18),
                          const SizedBox(width: 6),
                          const Text(
                            "Call Now",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // WHATSAPP
                Expanded(
                  child: InkWell(
                    onTap: () => _openWhatsApp(context, widget.vehicle),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/whatsApp.png', height: 18),
                          const SizedBox(width: 6),
                          const Text(
                            "WhatsApp",
                            style: TextStyle(color: Colors.green, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // BOOK NOW
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.to(
                        () => BookingVehicleScreen(vehicle: widget.vehicle),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Lightning.png',
                            height: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Book Now",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateColumn(String title, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.roboto(color: Colors.grey)),
        Text(
          date != null ? "${date.day}/${date.month}/${date.year}" : "",
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
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
