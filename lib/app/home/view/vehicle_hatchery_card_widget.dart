import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_detail_screen.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final hatchery = widget.vehicleAvailability;
    final validImages = hatchery.images;
    // Use branch if available, otherwise fall back to location
    final String? displayBranch = (hatchery.branchName?.isNotEmpty ?? false)
        ? hatchery.branchName
        : hatchery.locationName;
    final bool hasBranch = displayBranch?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => VehicleAvailabilityDetailScreen(
            vehicleAvailability: hatchery,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with available date badge
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: validImages.isEmpty
                          ? Container(
                              color: Colors.grey.withOpacity(.08),
                              child: Center(
                                child: Icon(Icons.image_outlined,
                                    size: 40, color: Colors.grey[300]),
                              ),
                            )
                          : validImages.length == 1
                          ? (_isVideo(validImages.first))
                              ? InlineVideoPlayer(
                                  url: validImages.first,
                                  title: hatchery.vehicleName,
                                )
                              : Image.network(
                                  validImages.first,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.grey.withOpacity(.08),
                                    child: Center(
                                      child: Icon(Icons.broken_image,
                                          size: 40, color: Colors.grey[300]),
                                    ),
                                  ),
                                )
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
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
                                  height: 140,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.withOpacity(.08),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.withOpacity(.08),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  // Available date badge on image
                  if (hatchery.availableOn != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff25A652),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              formatDate(hatchery.availableOn ?? ''),
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

            // Content section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location routing visualization for vehicle
                  if (hatchery.locations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildLocationRouting(
                        hatchery.locations.cast<VehicleLocation>(),
                      ),
                    ),

                  // Vehicle name
                  Text(
                    hatchery.vehicleName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Category name + Branch
                  Row(
                    children: [
                      if (hatchery.categoryName != null)
                        Text(
                          hatchery.categoryName!,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (hatchery.categoryName != null && hasBranch)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.circle,
                              size: 4, color: Colors.grey[400]),
                        ),
                      if (hasBranch)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  displayBranch!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Available on date - prominent display
                  if (hatchery.availableOn != null &&
                      hatchery.availableOn!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff25A652).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xff25A652).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available,
                                size: 16, color: Color(0xff25A652)),
                            const SizedBox(width: 8),
                            Text(
                              'Available on ',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: const Color(0xff25A652),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatDate(hatchery.availableOn!),
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: const Color(0xff25A652),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Info chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (hatchery.availableSpace != null &&
                          hatchery.availableSpace! > 0)
                        _buildLabeledChip(
                          'Space Available',
                          '${hatchery.availableSpace} seeds',
                          Icons.inventory_2_outlined,
                        ),
                      if (hatchery.locationName?.isNotEmpty ?? false)
                        _buildLabeledChip(
                          'Location',
                          hatchery.locationName!,
                          Icons.location_on,
                        ),
                      if (hatchery.startDate != null)
                        _buildLabeledChip(
                          'Start Date',
                          _formatFullDate(hatchery.startDate!),
                          Icons.calendar_today,
                        ),
                      if (hatchery.endDate != null)
                        _buildLabeledChip(
                          'End Date',
                          _formatFullDate(hatchery.endDate!),
                          Icons.calendar_today,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      _actionButton(
                        label: "Call Now",
                        icon: 'assets/images/phone.png',
                        color: AppColors.primary,
                        onTap: () => _makePhoneCall(hatchery.callUrl),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
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
                          topRight: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            useSafeArea: true,
                            builder: (BuildContext context) {
                              return SafeArea(
                                top: false,
                                child: Container(
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

  Widget _buildLocationRouting(List<VehicleLocation> locations) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.local_shipping,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            ...List.generate(locations.length, (index) {
              final location = locations[index];
              final isLast = index == locations.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
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
    );
  }

  Widget _buildLabeledChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
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

  String _formatFullDate(String dateString) {
    try {
      DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (e) {
      return dateString;
    }
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
}

String formatDate(String dateString) {
  try {
    DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
    return DateFormat("dd MMM").format(date);
  } catch (e) {
    return dateString;
  }
}
