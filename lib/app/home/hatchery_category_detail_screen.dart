import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HatcheryCategoryDetailScreen extends StatefulWidget {
  final String videoUrl;
  final String hatcheryId;
  final String categoryId;
  final String hatcheryName;

  const HatcheryCategoryDetailScreen({
    super.key,
    required this.videoUrl,
    required this.hatcheryId,
    required this.categoryId,
    required this.hatcheryName,
  });

  @override
  State<HatcheryCategoryDetailScreen> createState() =>
      _HatcheryCategoryDetailScreenState();
}

class _HatcheryCategoryDetailScreenState
    extends State<HatcheryCategoryDetailScreen> {
  bool videoStarted = false;
  late ScrollController _unitScrollController;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.mkv');
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Available';
      case 2:
        return 'Coming Soon';
      case 3:
        return 'Upcoming';
      case 4:
        return 'Shortly Available';
      default:
        return 'Closed';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xff25A652);
      case 2:
        return const Color(0xff007DFE);
      case 3:
        return const Color(0xff6F42C1);
      case 4:
        return const Color(0xffF4A100);
      default:
        return const Color(0xffE31B1B);
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.schedule;
      case 3:
        return Icons.upcoming_outlined;
      case 4:
        return Icons.hourglass_bottom;
      default:
        return Icons.block;
    }
  }

  final hatcheryCategoryController = Get.put(HatcheryCategoryController());

  @override
  void initState() {
    super.initState();
    _unitScrollController = ScrollController();
    hatcheryCategoryController.getHatcheryCategoryDetail(
      widget.hatcheryId,
      widget.categoryId,
    );
  }

  @override
  void dispose() {
    _unitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: Text(
          widget.hatcheryName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (hatcheryCategoryController.detailLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final detail =
            hatcheryCategoryController.hatcheryCategoryDetailData.value.data;

        if (detail == null) {
          return const Center(child: Text("No data found"));
        }

        final List<String> validImages = detail.images ?? [];
        final statusCode = detail.status ?? 5;
        final statusText = _getStatusText(statusCode);
        final statusColor = _getStatusColor(statusCode);
        final statusIcon = _getStatusIcon(statusCode);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel
              if (validImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      child: MediaCarouselWidget(
                        mediaUrls: validImages,
                        mediaTypes: validImages
                            .map((url) => _isVideo(url) ? 'video' : 'image')
                            .toList(),
                        height: 180,
                        borderRadius: 16,
                        title: widget.hatcheryName,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Hatchery name + status badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.hatcheryName ?? "",
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          if (detail.category != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              detail.category!.name ?? "",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (detail.location?.name != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  detail.location!.name!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Description
              if (detail.description != null &&
                  detail.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    detail.description!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info cards grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFF0077C8),
                        label: 'Broodstock',
                        value: '${detail.broodstock ?? 0} Pcs',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.currency_rupee,
                        iconColor: const Color(0xFF25A652),
                        label: 'Price',
                        value: '\u20B9${detail.price ?? 'N/A'}',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFF6F42C1),
                        label: 'Available Date',
                        value: detail.availableOn != null
                            ? formatDate(detail.availableOn!)
                            : 'N/A',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoCard(
                        icon: statusIcon,
                        iconColor: statusColor,
                        label: 'Status',
                        value: statusText,
                        valueColor: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Units section
              if (detail.units != null && detail.units!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
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
                            Image.asset(
                              'assets/images/unit_icon.png',
                              width: 18,
                              height: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Units',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: detail.units!
                              .where((u) =>
                                  u.branch?.name != null &&
                                  u.branch!.name!.isNotEmpty)
                              .map((u) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      u.branch!.name!,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Hatchery Report
              if (detail.report != null && detail.report!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () => _launchUrl(detail.report!, context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hatchery Report',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Tap to view full report',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _actionButton(
                      label: "Call Now",
                      icon: 'assets/images/phone.png',
                      color: AppColors.primary,
                      onTap: () => _makePhoneCall(detail.callUrl),
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
                          _launchUrl(detail.whatsappUrl ?? '', context),
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
                                  price: detail.price?.toString() ?? '',
                                  categoryId: widget.categoryId,
                                  hatcheryId: detail.id.toString(),
                                  hatcheryName: detail.hatcheryName ?? '',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
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
              color: valueColor ?? const Color(0xFF1A1A2E),
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
          height: 44,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cannot launch URL")));
    }
  }
}

String formatDate(DateTime date) {
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  String day = date.day.toString().padLeft(2, '0');
  String month = months[date.month - 1];
  String year = date.year.toString();
  return "$day $month $year";
}

Future<void> _makePhoneCall(String phoneNumber) async {
  final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleanedNumber.isEmpty) return;
  final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint("Error making phone call");
  }
}

Widget _buildGalleryImage({required String imageUrl}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16.0),
    child: Image.asset(imageUrl, fit: BoxFit.cover, height: 108, width: 104),
  );
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

class HatcheryGalleryCarousel extends StatefulWidget {
  final List<String> images;

  const HatcheryGalleryCarousel({super.key, required this.images});

  @override
  State<HatcheryGalleryCarousel> createState() =>
      _HatcheryGalleryCarouselState();
}

class _HatcheryGalleryCarouselState extends State<HatcheryGalleryCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(child: Text("No images available"));
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            final img = widget.images[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                img,
                height: 1500,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.withOpacity(.3),
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            autoPlay: false,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.images.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 10 : 8,
              height: _currentIndex == entry.key ? 10 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentIndex == entry.key ? Colors.blue : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
