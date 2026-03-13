import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_detail_screen.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/utils/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleHatcheryCardWidget extends StatefulWidget {
  const VehicleHatcheryCardWidget({
    super.key,
    required this.vehicleAvailability,
  });

  final VehicleAvailability vehicleAvailability;

  @override
  State<VehicleHatcheryCardWidget> createState() =>
      _VehicleHatcheryCardWidgetState();
}

class _VehicleHatcheryCardWidgetState extends State<VehicleHatcheryCardWidget> {
  bool isPressed = false;
  late PageController _pageController;
  int _currentPage = 0;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final SeedsPriceController controller = Get.put(SeedsPriceController());

  @override
  Widget build(BuildContext context) {
    final hatchery = widget.vehicleAvailability;
    final validImages =
        hatchery.images; // Images are already filtered in the model

      print("Valid Images: $validImages");

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      onTap: () {
        Get.to(
          () => VehicleAvailabilityDetailScreen(
            vehicleAvailability: hatchery,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              spreadRadius: 1,
              offset: const Offset(1, 1),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with auto-scroll
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: validImages.isEmpty
                          ? Container(color: Colors.grey.withOpacity(.2))
                          : validImages.length == 1
                          ? (_isVideo(validImages.first))
                              ? InlineVideoPlayer(
                                  url: validImages.first,
                                  title: hatchery.vehicleName,
                                )
                              : Image.network(
                                  validImages.first,
                                  width: double.infinity,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) =>
                                      Container(color: Colors.grey.withOpacity(.2)),
                                )
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemCount: validImages.length,
                              itemBuilder: (context, index) {
                                final url = validImages[index];
                                if (_isVideo(url)) {
                                  return InlineVideoPlayer(
                                    url: url,
                                    title: hatchery.vehicleName,
                                  );
                                }
                                return Image.network(
                                  url,
                                  width: double.infinity,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) {
                                    return Container(
                                      color: Colors.grey.withOpacity(.2),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  // Image indicator dots
                  if (validImages.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          validImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ✅ Details Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location routing visualization for vehicle
                  if (hatchery.locations.isNotEmpty)
                    _buildLocationRouting(
                      hatchery.locations.cast<VehicleLocation>(),
                    ),

                  const SizedBox(height: 8),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          hatchery.hatcheryName,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xff3A7D51),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .4,
                              child: Text(
                                "Available on ${formatDate(hatchery.availableOn ?? '')}",
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location & Branch
                  Row(
                    children: [
                      if (hatchery.locationName?.isNotEmpty ?? false)
                        Expanded(
                          child: _buildInfoRow(
                            Icons.location_on,
                            hatchery.locationName ?? '',
                          ),
                        ),
                      if (hatchery.branchName?.isNotEmpty ?? false)
                        Expanded(
                          child: _buildInfoRow(
                            Icons.business,
                            hatchery.branchName ?? '',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (hatchery.availableSpace != null)
                    _buildAvailableSpace(hatchery.availableSpace),
                  const SizedBox(height: 8),
                  if (hatchery.availableOn != null) ...[
                    const SizedBox(height: 4),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final fontScale = screenWidth < 360 ? 11.0 : 12.5;

                        return Row(
                          children: [
                            // START DATE (no border)
                            SizedBox(
                              width: constraints.maxWidth * 0.49,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Start Date ${_getStartDate(hatchery.availableOn)}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: fontScale,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // END DATE (with border)
                            SizedBox(
                              width: constraints.maxWidth * 0.48,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "End Date ${_getEndDate(hatchery.availableOn, days: 3)}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: fontScale - 0.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _actionButton(
                        label: "Call Now",
                        icon: 'assets/images/phone.png',
                        color: AppColors.primary,
                        onTap: () => _makePhoneCall(hatchery.callUrl),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        label: "WhatsApp",
                        icon: 'assets/images/whatsApp.png',
                        color: Colors.white,
                        textColor: Colors.green,
                        borderColor: Colors.green,
                        onTap: () =>
                            _launchUrl(hatchery.whatsappUrl ?? '', context),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        label: "Book Now",
                        icon: 'assets/images/Lightning.png',
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20.0),
                                  ),
                                ),
                                child: BookingBottomSheet(
                                  price: hatchery.price ?? '',
                                  categoryId: widget
                                      .vehicleAvailability
                                      .categoryId
                                      .toString(),
                                  isSpotHatchery: false,
                                  isVehicleHatchery: true,
                                  hatcheryId: hatchery.hatcheryId.toString(),
                                  hatcheryName: hatchery.hatcheryName,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  String _getStartDate(String? availableOn) {
    final date = _parseDate(availableOn);
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getEndDate(String? availableOn, {int days = 3}) {
    final date = _parseDate(availableOn);
    if (date == null) return '';
    final endDate = date.add(Duration(days: days));
    return DateFormat('dd/MM/yyyy').format(endDate);
  }

  Widget _buildLocationRouting(List<VehicleLocation> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Build rows dynamically based on how locations wrap
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                // Truck icon at the start
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                // Generate location chips with arrows
                ...List.generate(locations.length, (index) {
                  final location = locations[index];
                  final isLast = index == locations.length - 1;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arrow before location (except for first one)
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      // Location chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLast
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLast
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isLast
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location.name,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: isLast
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isLast
                                    ? AppColors.primary
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required String icon,
    required Color color,
    Color? textColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, height: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String? url) async {
    if (url == null) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot launch URL")));
    }
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSpace(int? space) {
    if (space == null || space <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inventory_2, size: 18, color: Colors.green),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$space seeds",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "No. of Space available",
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String formatDate(String dateString) {
  try {
    DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
    return DateFormat("dd MMM").format(date);
  } catch (e) {
    return dateString; // fallback (no crash)
  }
}
