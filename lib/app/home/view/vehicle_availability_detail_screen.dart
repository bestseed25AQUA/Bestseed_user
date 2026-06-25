import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
import 'package:seedsuser/app/home/view/vehicle_route_map_widget.dart';
import 'package:seedsuser/app/utils/video_thumbnail_cache.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleAvailabilityDetailScreen extends StatefulWidget {
  final VehicleAvailability vehicleAvailability;

  const VehicleAvailabilityDetailScreen({
    super.key,
    required this.vehicleAvailability,
  });

  @override
  State<VehicleAvailabilityDetailScreen> createState() =>
      _VehicleAvailabilityDetailScreenState();
}

class _VehicleAvailabilityDetailScreenState
    extends State<VehicleAvailabilityDetailScreen> {
  bool _isViewMoreExpanded = false;
  final GlobalKey _viewMoreKey = GlobalKey();

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
    // Prefetch posters for every video so swiping the carousel is instant.
    VideoThumbnailCache.instance
        .warm(widget.vehicleAvailability.images.where(_isVideo));
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicleAvailability;
    final validImages = vehicle.images;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: Text(
          vehicle.vehicleName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Images carousel
            if (validImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 180,
                  child: MediaCarouselWidget(
                    mediaUrls: validImages,
                    mediaTypes: validImages
                        .map((url) => _isVideo(url) ? 'video' : 'image')
                        .toList(),
                    height: 180,
                    borderRadius: 14,
                    title: vehicle.vehicleName,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle name and available date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.vehicleName,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (vehicle.availableOn != null)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xff3A7D51),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Available on ${_formatDate(vehicle.availableOn ?? '')}",
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category name
                  if (vehicle.categoryName != null)
                    Text(
                      vehicle.categoryName!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Live moving-vehicle map (truck animates along the route).
                  if (vehicle.locations.any(
                      (l) => l.latitude != null && l.longitude != null)) ...[
                    VehicleRouteMapWidget(locations: vehicle.locations),
                    const SizedBox(height: 12),
                  ],

                  // Location routing
                  if (vehicle.locations.isNotEmpty)
                    _buildLocationRouting(vehicle.locations),

                  const SizedBox(height: 12),

                  // Description
                  if (vehicle.description != null &&
                      vehicle.description!.isNotEmpty) ...[
                    Text(
                      "Description",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.description!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info cards grid - Row 1: Available Space + Price
                  Row(
                    children: [
                      if (vehicle.availableSpace != null)
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFFF4A100),
                            label: 'Available Space',
                            value: '${vehicle.availableSpace} seeds',
                          ),
                        ),
                      if (vehicle.availableSpace != null &&
                          vehicle.price != null)
                        const SizedBox(width: 10),
                      if (vehicle.price != null)
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.currency_rupee,
                            iconColor: const Color(0xFF25A652),
                            label: 'Price',
                            value: '\u20B9${vehicle.price}',
                          ),
                        ),
                    ],
                  ),

                  // Start and End dates
                  if (vehicle.startDate != null || vehicle.endDate != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (vehicle.startDate != null)
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today,
                              iconColor: const Color(0xFF0077C8),
                              label: 'Start Date',
                              value: _formatFullDate(vehicle.startDate!),
                            ),
                          ),
                        if (vehicle.startDate != null &&
                            vehicle.endDate != null)
                          const SizedBox(width: 10),
                        if (vehicle.endDate != null)
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today,
                              iconColor: const Color(0xFFE53935),
                              label: 'End Date',
                              value: _formatFullDate(vehicle.endDate!),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Branch (fallback to location)
                  if ((vehicle.branchName?.isNotEmpty ?? false) ||
                      (vehicle.locationName?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.business,
                      iconColor: const Color(0xFF6F42C1),
                      label: 'Branch',
                      value: (vehicle.branchName?.isNotEmpty ?? false)
                          ? vehicle.branchName!
                          : vehicle.locationName!,
                    ),
                  ],

                  // Available on date - prominent
                  if (vehicle.availableOn != null &&
                      vehicle.availableOn!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xff25A652).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xff25A652).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xff25A652).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available,
                                size: 18, color: Color(0xff25A652)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available On',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: const Color(0xff25A652),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(vehicle.availableOn!),
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: const Color(0xff25A652),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      _actionButton(
                        label: "Call Now",
                        icon: 'assets/images/phone.png',
                        color: AppColors.primary,
                        onTap: () => _makePhoneCall(vehicle.callUrl),
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
                            _launchUrl(vehicle.whatsappUrl ?? '', context),
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
                                    price: vehicle.price ?? '',
                                    categoryId: vehicle.categoryId.toString(),
                                    isVehicleHatchery: true,
                                    hatcheryId: vehicle.vehicleId.toString(),
                                    hatcheryName: vehicle.vehicleName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  // View more about hatchery section
                  if (vehicle.selectedHatchery != null) ...[
                    const SizedBox(height: 24),
                    _buildViewMoreSection(vehicle.selectedHatchery!),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build location routing visualization
  Widget _buildLocationRouting(List<VehicleLocation> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Route",
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  Icon(Icons.arrow_forward, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
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
                          color: isLast ? AppColors.primary : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.name,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
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
        ),
      ],
    );
  }

  /// Build the "View more about hatchery" expandable section
  Widget _buildViewMoreSection(SelectedVehicleHatchery selectedHatchery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isViewMoreExpanded = !_isViewMoreExpanded;
            });
            if (_isViewMoreExpanded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final context = _viewMoreKey.currentContext;
                if (context != null) {
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "View more about hatchery",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Icon(
                  _isViewMoreExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          key: _viewMoreKey,
          firstChild: const SizedBox.shrink(),
          secondChild: _buildSelectedHatcheryContent(selectedHatchery),
          crossFadeState: _isViewMoreExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  /// Build the selected/parent hatchery content
  Widget _buildSelectedHatcheryContent(
    SelectedVehicleHatchery selectedHatchery,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedHatchery.hatcheryName,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (selectedHatchery.categoryName != null) ...[
            const SizedBox(height: 4),
            Text(
              selectedHatchery.categoryName!,
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey[600]),
            ),
          ],

          if (selectedHatchery.description != null &&
              selectedHatchery.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              selectedHatchery.description!,
              style: GoogleFonts.roboto(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey[800],
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (selectedHatchery.locationName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedHatchery.locationName!,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (selectedHatchery.price != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    "Price: ₹${selectedHatchery.price}",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          if (selectedHatchery.broodstockCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    "Broodstock: ${selectedHatchery.broodstockCount} Pieces",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Images
          if (selectedHatchery.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedHatchery.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        selectedHatchery.images[index],
                        height: 80,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          width: 100,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Contact buttons
          if (selectedHatchery.callUrl != null ||
              selectedHatchery.whatsappUrl != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (selectedHatchery.callUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(selectedHatchery.callUrl),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text("Call"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (selectedHatchery.callUrl != null &&
                    selectedHatchery.whatsappUrl != null)
                  const SizedBox(width: 12),
                if (selectedHatchery.whatsappUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _launchUrl(selectedHatchery.whatsappUrl!, context),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text("WhatsApp"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  String _formatDate(String dateString) {
    try {
      DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
      return DateFormat("dd MMM").format(date);
    } catch (e) {
      return dateString;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot launch URL")));
      }
    }
  }
}
