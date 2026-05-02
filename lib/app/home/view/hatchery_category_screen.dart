import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/full_image_screen.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/hatchery_category_detail_screen.dart';
import 'package:seedsuser/app/home/model/hatchery_category_model.dart';
import 'package:seedsuser/app/home/widget/hachery_category_banner_widget.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';
import 'package:seedsuser/app/utils/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class HatcheryCateogryScreen extends StatefulWidget {
  const HatcheryCateogryScreen({
    super.key,
    required this.hatcheryId,
    required this.hatcheryName,
    this.tag,
    this.useHatcheryId = false,
  });
  final String hatcheryId;
  final String hatcheryName;
  final String? tag;

  /// If true, uses database id endpoint (/hatchery-by-id) - for search flow
  /// If false, uses unique_id endpoint (/hatchery-all-category) - for home screen flow
  final bool useHatcheryId;
  @override
  State<HatcheryCateogryScreen> createState() => _HatcheryCateogryScreenState();
}

class _HatcheryCateogryScreenState extends State<HatcheryCateogryScreen> {
  final HatcheryCategoryController hatcheryCategoryController = Get.put(
    HatcheryCategoryController(),
  );

  final HomeController _homeController = Get.find<HomeController>();
  bool _showSimilar = false;
  final GlobalKey _similarKey = GlobalKey();

  @override
  void initState() {
    initCall();
    super.initState();
  }

  initCall() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await hatcheryCategoryController.fetchHetcheryCategory(
        widget.hatcheryId,
        useHatcheryId: widget.useHatcheryId,
      );
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   hatcheryCategoryController.fetchHetcheryCategory(widget.hatcheryId);
    // });
  }

  // Resolve category name from HomeController.categories (Category.id)
  String resolvedCategoryName(SimilarHatchery hatchery) {
    try {
      final cat = _homeController.categories.firstWhere(
        (c) => c.id == (hatchery.categoryId),
      );
      return cat.id == -1 ? '' : cat.categoryName;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.hatcheryName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Obx(() {
                  if (hatcheryCategoryController.isLoading.value) {
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (context, index) =>
                          hatcheryCardFullShimmer(),
                    );
                  }

                  final hasNoCategories = hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .data
                      .isEmpty;

                  final hasSimilarHatcheries = hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .similarHatcheries
                      .isNotEmpty;

                  if (hasNoCategories && !hasSimilarHatcheries) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * .7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No categories available',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This hatchery has no categories\nat the moment',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (hasNoCategories && hasSimilarHatcheries) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This hatchery has no direct categories available. Check out similar hatcheries below.',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final categories = hatcheryCategoryController
                      .hatcheryCateogoryData.value.data;

                  return AnimatedAppearance(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category count header
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              '${categories.length} ${categories.length == 1 ? 'Category' : 'Categories'} Available',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...List.generate(
                            categories.length,
                            (index) {
                              final item = categories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HatcheryCategoryDetailScreen(
                                              hatcheryName: widget.hatcheryName,
                                              videoUrl: 'assets/videos/sample.mp4',
                                              hatcheryId: item.id.toString(),
                                              categoryId: hatcheryCategoryController
                                                  .hatcheryCateogoryData
                                                  .value
                                                  .data[index]
                                                  .categories
                                                  .id
                                                  .toString(),
                                            ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: HarcheryCardWidget(
                                    categoryId:
                                        item.category?.id.toString() ?? "",
                                    hatcheryName: item.hatcheryName,
                                    categoryName: item.category?.name ?? "",
                                    imageUrl: item.images,
                                    units: item.units,
                                    broodstockCount: item.broodstock.toString(),
                                    price: item.price,
                                    availableDate: item.availableOn,
                                    status: item.status,
                                    callUrl: item.callUrl,
                                    whatsappUrl: item.whatsappUrl,
                                    hatcheryId: item.id.toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  final similarList = hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .similarHatcheries;

                  if (similarList.isEmpty) return SizedBox();

                  return Column(
                    key: _similarKey,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showSimilar = !_showSimilar;
                              });
                              if (!_showSimilar) return;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Scrollable.ensureVisible(
                                  _similarKey.currentContext!,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "View More Similar Hatcheries",
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _showSimilar
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_showSimilar)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(similarList.length, (index) {
                              final hatchery = similarList[index];
                              final String categoryName = resolvedCategoryName(hatchery);
                              final String locationName = hatchery.location ?? '';
                              final String image = hatchery.image ?? "";
                              final String? availableDate =
                                  hatchery.availableOn != null &&
                                          hatchery.availableOn!.trim().isNotEmpty
                                      ? hatchery.availableOn
                                      : null;
                              final Color statusColor = _getSimilarStatusColor(hatchery.status);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 16,
                                ),
                                child: SizedBox(
                                  height: 230,
                                  width: 160,
                                  child: HatcheryCard(
                                    index: index,
                                    width: 160,
                                    height: 295,
                                    ontap: () {
                                      final hatcheryIdForApi =
                                          hatchery.uniqueId.isNotEmpty
                                              ? hatchery.uniqueId
                                              : hatchery.id.toString();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HatcheryCateogryScreen(
                                                hatcheryId: hatcheryIdForApi,
                                                hatcheryName: hatchery.hatcheryName.toString(),
                                              ),
                                        ),
                                      );
                                    },
                                    id: hatchery.id.toString(),
                                    uniqueId: hatchery.uniqueId,
                                    imagePath: image,
                                    title: hatchery.hatcheryName,
                                    location: locationName,
                                    type: categoryName,
                                    status: hatchery.status,
                                    statusColor: statusColor,
                                    availableUntil: availableDate,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getSimilarStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == 'available' || lower == 'open') return const Color(0xff25A652);
    if (lower == 'coming soon') return const Color(0xff007DFE);
    if (lower == 'upcoming') return const Color(0xff6F42C1);
    if (lower == 'shortly available') return const Color(0xffF4A100);
    return const Color(0xffE31B1B);
  }

}

class HarcheryCardWidget extends StatefulWidget {
  final String hatcheryName;
  final String categoryName;
  final List<UnitModel> units;
  final List<String> imageUrl;
  final String categoryId;

  final String? availableDate;
  final String broodstockCount;
  final String price;
  final String? status; // Hatchery status
  final String? callUrl;
  final String? whatsappUrl;
  final String hatcheryId;

  const HarcheryCardWidget({
    super.key,
    required this.hatcheryName,
    required this.categoryName,
    required this.units,
    required this.imageUrl,
    required this.broodstockCount,
    required this.price,
    required this.hatcheryId,
    this.availableDate,
    this.status,
    this.callUrl,
    this.whatsappUrl,
    required this.categoryId,
  });

  @override
  State<HarcheryCardWidget> createState() => _HarcheryCardWidgetState();
}

class _HarcheryCardWidgetState extends State<HarcheryCardWidget> {
  VideoPlayerController? _controller;
  bool videoStarted = false;
  bool isPressed = false;
  late PageController _pageController;
  int _currentPage = 0;
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

  String _getStatusText(String status) {
    // Convert status code to readable text
    switch (status) {
      case '1':
        return 'Available';
      case '2':
        return 'Coming Soon';
      case '3':
        return 'Upcoming';
      case '4':
        return 'Shortly Available';
      default:
        return 'Closed';
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _unitScrollController = ScrollController();

    debugPrint('Hatchery Image URLs:');
    for (int i = 0; i < widget.imageUrl.length; i++) {
      debugPrint('checking fir image url [$i] ${widget.imageUrl[i]}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xff25A652);
      case '2':
        return const Color(0xff007DFE);
      case '3':
        return const Color(0xff6F42C1);
      case '4':
        return const Color(0xffF4A100);
      default:
        return const Color(0xffE31B1B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validImages = widget.imageUrl;
    final statusText = _getStatusText(widget.status ?? '');
    final statusColor = _getStatusColor(widget.status ?? '');

    return Container(
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
          // Image section with status badge overlay
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
                            color: Colors.grey.withOpacity(.1),
                            child: Center(
                              child: Icon(Icons.image_outlined,
                                  size: 40, color: Colors.grey[300]),
                            ),
                          )
                        : validImages.length == 1
                        ? (_isVideo(validImages.first))
                              ? InlineVideoPlayer(
                                  url: validImages.first,
                                  title: widget.hatcheryName,
                                )
                              : Image.network(
                                  validImages.first,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.grey.withOpacity(.1),
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
                                  title: widget.hatcheryName,
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
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.withOpacity(.1),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                // Status badge on image
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                // Category name
                Text(
                  widget.categoryName,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),

                // Info row: Broodstock + Price
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        "assets/images/broadstock.png",
                        "${widget.broodstockCount} Pcs",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        "assets/images/MoneyWavy.png",
                        "\u20B9 ${widget.price}",
                      ),
                    ),
                    if (widget.availableDate != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          "assets/images/CalendarBlank.png",
                          _formatAvailableDate(widget.availableDate!),
                        ),
                      ),
                    ],
                  ],
                ),

                // Units
                if (widget.units.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.units
                        .where((u) => u.branch.name.isNotEmpty)
                        .map((u) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                u.branch.name,
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    _actionButton(
                      label: "Call Now",
                      icon: "assets/images/phone.png",
                      color: AppColors.primary,
                      onTap: () => _makePhoneCall(widget.callUrl),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      label: "WhatsApp",
                      icon: "assets/images/whatsApp.png",
                      color: Colors.white,
                      textColor: Colors.green,
                      borderColor: Colors.green,
                      onTap: () =>
                          _launchUrl(widget.whatsappUrl ?? '', context),
                    ),
                    const SizedBox(width: 4),
                    _actionButton(
                      label: "Book Now",
                      icon: "assets/images/Lightning.png",
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
                                  isSpotHatchery: false,
                                  price: widget.price,
                                  categoryId: widget.categoryId,
                                  hatcheryId: widget.hatcheryId,
                                  hatcheryName: widget.hatcheryName,
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
    );
  }

  Widget _buildInfoChip(String assetPath, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 14, height: 14, color: AppColors.primary),
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
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 35,
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

  String _formatAvailableDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd-MM-yyyy').format(parsed);
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

String formatDate(DateTime date) {
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  String day = date.day.toString().padLeft(2, '0');
  String month = months[date.month - 1];
  String year = date.year.toString();

  return "$day $month $year";
}

class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String hatcheryName;

  const _InlineVideoPlayer({required this.url, required this.hatcheryName});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenVideo(
          url: widget.url,
          hatcheryName: widget.hatcheryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayer(_controller),

        // 🔹 Center Play / Pause
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),

        // 🔹 Bottom-right Fullscreen icon
        Positioned(
          bottom: 6,
          right: 6,
          child: IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
            onPressed: _openFullscreen,
          ),
        ),
      ],
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  final String url;
  final String hatcheryName;

  const _FullScreenVideo({required this.url, required this.hatcheryName});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: controller.value.isInitialized
          ? Stack(
              children: [
                // 🔹 Video
                GestureDetector(
                  onTap: _togglePlay,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),

                // 🔹 Center Play / Pause Icon
                Center(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 🔹 Top Bar: Back + Hatchery Name
                Positioned(
                  top: 40,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.hatcheryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Bottom Progress Bar
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
