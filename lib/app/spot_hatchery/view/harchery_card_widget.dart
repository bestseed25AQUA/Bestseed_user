import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_detail_screen.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/utils/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class HarcheryCardWidget extends StatefulWidget {
  const HarcheryCardWidget({super.key, required this.spotHatchery});

  final SpotHatchery spotHatchery;

  @override
  State<HarcheryCardWidget> createState() => _HarcheryCardWidgetState();
}

class _HarcheryCardWidgetState extends State<HarcheryCardWidget> {
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
    final hatchery = widget.spotHatchery;
    final validImages = hatchery.images;
    print("Spot Hatchery Images: $validImages");
    final bool hasLocation = hatchery.locationName?.isNotEmpty ?? false;
    final bool hasStock =
        hatchery.broodstock != null && hatchery.broodstock! > 0;

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
          () => SpotHatcheryDetailScreen(
            spotHatchery: hatchery,
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
                                  title: hatchery.hatcheryName,
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
                                    title: hatchery.hatcheryName,
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

                  const SizedBox(height: 4),

                  Text(
                    hatchery.categoryName!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 3),

                  // // Location
                  if (hasLocation || hasStock)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📍 Location
                            if (hasLocation)
                              Expanded(
                                flex: 3,
                                child: Builder(
                                  builder: (context) {
                                    Location? location;
                                    try {
                                      location = controller.locations
                                          .firstWhere(
                                            (e) =>
                                                e.id.toString() ==
                                                hatchery.locationId.toString(),
                                          );
                                    } catch (_) {}

                                    return _buildCompactInfoRow(
                                      Icons.location_on,
                                      location?.title ?? '',
                                    );
                                  },
                                ),
                              ),

                            // spacing only when both exist
                            if (hasLocation && hasStock)
                              const SizedBox(width: 8),

                            // 📦 Broodstock
                            if (hasStock)
                              Expanded(
                                flex: 2,
                                child: _buildCompactInfoRow(
                                  Icons.inventory_2,
                                  'Stock: ${hatchery.broodstock}',
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                  // if (hatchery.locationName?.isNotEmpty ?? false)
                  const SizedBox(height: 5),
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
                                  price: widget.spotHatchery.price ?? '',
                                  categoryId: widget.spotHatchery.categoryId
                                      .toString(),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // ✅ NO OVERFLOW EVER
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
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
}

String formatDate(String dateString) {
  try {
    DateTime date = DateFormat("yyyy-MM-dd").parse(dateString);
    return DateFormat("dd MMM").format(date);
  } catch (e) {
    return dateString; // fallback (no crash)
  }
}
