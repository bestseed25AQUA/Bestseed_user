import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';

import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_detail_screen.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';

import 'package:seedsuser/app/utils/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class HarcheryCardWidget extends StatefulWidget {
  const HarcheryCardWidget({super.key, required this.spotHatchery});

  final SpotHatchery spotHatchery;

  @override
  State<HarcheryCardWidget> createState() => _HarcheryCardWidgetState();
}

class _HarcheryCardWidgetState extends State<HarcheryCardWidget> {
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
    final hatchery = widget.spotHatchery;
    final validImages = hatchery.images;
    // Use branch if available, otherwise fall back to location
    final String? displayBranch = (hatchery.branchName?.isNotEmpty ?? false)
        ? hatchery.branchName
        : hatchery.locationName;
    final bool hasBranch = displayBranch?.isNotEmpty ?? false;
    final bool hasStock =
        hatchery.broodstock != null && hatchery.broodstock! > 0;

    return GestureDetector(
      onTap: () {
        Get.to(() => SpotHatcheryDetailScreen(spotHatchery: hatchery));
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
                                  title: hatchery.hatcheryName,
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
                                    title: hatchery.hatcheryName,
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
                  // Hatchery name
                  Text(
                    hatchery.hatcheryName,
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
                          child: Icon(Icons.circle, size: 4, color: Colors.grey[400]),
                        ),
                      if (hasBranch)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business, size: 13, color: Colors.grey[500]),
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

                  // Info chips row: Broodstock + No of Pieces + Price
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (hasStock)
                        _buildLabeledChip(
                          'Broodstock',
                          '${hatchery.broodstock}',
                          Icons.water_drop_outlined,
                        ),
                      if (hatchery.noOfPieces != null && hatchery.noOfPieces! > 0)
                        _buildLabeledChip(
                          'No of Pieces',
                          '${hatchery.noOfPieces}',
                          Icons.inventory_2_outlined,
                        ),
                      if (hatchery.price != null)
                        _buildLabeledChip(
                          'Price',
                          '\u20B9${hatchery.price}',
                          Icons.currency_rupee,
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
                        // Nothing left to sell — the admin can restock by
                        // raising "No. of Pieces", which re-enables this.
                        enabled: (hatchery.noOfPieces ?? 0) > 0,
                        disabledLabel: "Sold Out",
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
                                    price: widget.spotHatchery.price ?? '',
                                    categoryId: widget.spotHatchery.categoryId
                                        .toString(),
                                    isSpotHatchery: true,
                                    availablePieces: hatchery.noOfPieces,
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

  Widget _buildInfoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    bool enabled = true,
    String? disabledLabel,
  }) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: enabled ? color : Colors.grey.shade300,
            borderRadius: borderRadius,
            border: borderColor != null
                ? Border.all(
                    color: enabled ? borderColor : Colors.grey.shade400,
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                height: 18,
                color: enabled ? null : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                enabled ? label : (disabledLabel ?? label),
                style: GoogleFonts.roboto(
                  color: enabled
                      ? (textColor ?? Colors.white)
                      : Colors.grey.shade600,
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
}

String formatDate(String dateString) {
  try {
    DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
    return DateFormat("dd MMM").format(date);
  } catch (e) {
    return dateString;
  }
}
