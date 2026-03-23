import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotHatcheryDetailScreen extends StatefulWidget {
  final SpotHatchery spotHatchery;

  const SpotHatcheryDetailScreen({
    super.key,
    required this.spotHatchery,
  });

  @override
  State<SpotHatcheryDetailScreen> createState() =>
      _SpotHatcheryDetailScreenState();
}

class _SpotHatcheryDetailScreenState extends State<SpotHatcheryDetailScreen> {
  bool _isViewMoreExpanded = false;

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
  }

  @override
  Widget build(BuildContext context) {
    final hatchery = widget.spotHatchery;
    final validImages = hatchery.images;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: Text(
          hatchery.hatcheryName,
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
                    mediaTypes: validImages.map((url) => _isVideo(url) ? 'video' : 'image').toList(),
                    height: 180,
                    borderRadius: 14,
                    title: hatchery.hatcheryName,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hatchery name and available date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hatchery.hatcheryName,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hatchery.availableOn != null)
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
                                "Available on ${_formatDate(hatchery.availableOn ?? '')}",
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
                  if (hatchery.categoryName != null)
                    Text(
                      hatchery.categoryName!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Description
                  if (hatchery.description != null &&
                      hatchery.description!.isNotEmpty) ...[
                    Text(
                      "Description",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hatchery.description!,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info cards grid - Row 1: Broodstock + Price
                  Row(
                    children: [
                      if (hatchery.broodstock != null)
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.water_drop_outlined,
                            iconColor: const Color(0xFF0077C8),
                            label: 'Broodstock',
                            value: '${hatchery.broodstock}',
                          ),
                        ),
                      if (hatchery.broodstock != null && hatchery.price != null)
                        const SizedBox(width: 10),
                      if (hatchery.price != null)
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.currency_rupee,
                            iconColor: const Color(0xFF25A652),
                            label: 'Price',
                            value: '\u20B9${hatchery.price}',
                          ),
                        ),
                    ],
                  ),

                  // Row 2: No of Pieces
                  if (hatchery.noOfPieces != null && hatchery.noOfPieces! > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFFF4A100),
                            label: 'No of Pieces',
                            value: '${hatchery.noOfPieces} Pieces',
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],

                  // Branch (fallback to location)
                  if ((hatchery.branchName?.isNotEmpty ?? false) ||
                      (hatchery.locationName?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.business,
                      iconColor: const Color(0xFF6F42C1),
                      label: 'Branch',
                      value: (hatchery.branchName?.isNotEmpty ?? false)
                          ? hatchery.branchName!
                          : hatchery.locationName!,
                    ),
                  ],

                  // Available on date - prominent
                  if (hatchery.availableOn != null &&
                      hatchery.availableOn!.isNotEmpty) ...[
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
                                _formatDate(hatchery.availableOn!),
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
                                  categoryId: hatchery.categoryId.toString(),
                                  isSpotHatchery: true,
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

                  // View more about hatchery section
                  if (hatchery.selectedHatchery != null) ...[
                    const SizedBox(height: 24),
                    _buildViewMoreSection(hatchery.selectedHatchery!),
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

  /// Build the "View more about hatchery" expandable section
  Widget _buildViewMoreSection(SelectedHatchery selectedHatchery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isViewMoreExpanded = !_isViewMoreExpanded;
            });
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
  Widget _buildSelectedHatcheryContent(SelectedHatchery selectedHatchery) {
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
          // Hatchery name
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
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey[600],
              ),
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

          // Info rows
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot launch URL")),
      );
    }
  }
}
