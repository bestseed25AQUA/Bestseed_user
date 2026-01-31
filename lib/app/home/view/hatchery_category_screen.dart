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
  });
  final String hatcheryId;
  final String hatcheryName;
  final String? tag;
  @override
  State<HatcheryCateogryScreen> createState() => _HatcheryCateogryScreenState();
}

class _HatcheryCateogryScreenState extends State<HatcheryCateogryScreen> {
  final HatcheryCategoryController hatcheryCategoryController = Get.put(
    HatcheryCategoryController(),
  );

  final HomeController _homeController = Get.find<HomeController>();
  @override
  void initState() {
    initCall();
    super.initState();
  }

  initCall() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await hatcheryCategoryController.fetchHetcheryCategory(widget.hatcheryId);
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
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.hatcheryName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 17,
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
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (context, index) =>
                          hatcheryCardFullShimmer(),
                    );
                  }

                  // Check if there are no categories but there are similar hatcheries
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
                    // Only show "no categories" if there are also no similar hatcheries
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * .7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
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
                              'This hatchery has no categories at the moment',
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
                    // If no direct categories but there are similar hatcheries, show a message
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
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
                  return AnimatedAppearance(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 6,
                        top: 0,
                        left: 2,
                        right: 2,
                      ),
                      child: Column(
                        children: List.generate(
                          hatcheryCategoryController
                              .hatcheryCateogoryData
                              .value
                              .data
                              .length,
                          (index) {
                            final item = hatcheryCategoryController
                                .hatcheryCateogoryData
                                .value
                                .data[index];
                            return InkWell(
                              onTap: () {
                                print(widget.hatcheryId);
                                print(
                                  hatcheryCategoryController
                                          .hatcheryCategoryDetailData
                                          .value
                                          .data
                                          ?.category
                                          ?.id
                                          ?.toString() ??
                                      '',
                                );
                                // return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HatcheryCategoryDetailScreen(
                                          hatcheryName: widget.hatcheryName,
                                          videoUrl: 'assets/videos/sample.mp4',
                                          hatcheryId: widget.hatcheryId,
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

                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 0,
                                  bottom: 10,
                                ),
                                child: HarcheryCardWidget(
                                  categoryId:
                                      item.category?.id.toString() ?? "",
                                  hatcheryName: item.hatcheryName,
                                  categoryName: item.category?.name ?? "",
                                  imageUrl: item.images,

                                  /// units safe parsing
                                  units: item.units,
                                  broodstockCount: item.broodstock.toString(),

                                  price: item.price,
                                  availableDate: item.availableOn,
                                  callUrl: item.callUrl,
                                  whatsappUrl: item.whatsappUrl,
                                  hatcheryId: item.id.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20),
                Obx(() {
                  final similarList = hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .similarHatcheries;

                  if (similarList.isEmpty) return SizedBox();

                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Similar Hatcheries',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(similarList.length, (index) {
                            final hatchery = similarList[index];

                            // ⭐ PRE-COMPUTE SAFE VALUES
                            final String categoryName = resolvedCategoryName(
                              hatchery,
                            ); // your helper function
                            final String locationName =
                                hatchery.location ?? ''; // your helper function

                            // ⭐ IMAGE SAFE
                            final String image = hatchery.image ?? "";

                            // ⭐ DATE SAFE
                            final String? availableDate =
                                hatchery.availableOn != null &&
                                    hatchery.availableOn!.trim().isNotEmpty
                                ? hatchery.availableOn
                                : null;

                            // ⭐ STATUS COLOR SAFE
                            final String statusLower = hatchery.status
                                .toLowerCase();

                            final Color statusColor = statusLower == "open"
                                ? const Color(0xff25A652)
                                : statusLower == "coming soon"
                                ? const Color(0xff007DFE)
                                : const Color(0xffE31B1B);

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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HatcheryCateogryScreen(
                                              hatcheryId: hatchery.id
                                                  .toString(),
                                              hatcheryName: hatchery
                                                  .hatcheryName
                                                  .toString(),
                                            ),
                                      ),
                                    );
                                  },

                                  /// ⭐ No nullable — model is safe
                                  id: hatchery.id.toString(),
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

  @override
  Widget build(BuildContext context) {
    final validImages = widget.imageUrl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
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
                                  title: widget.hatcheryName,
                                )
                              : Image.network(
                                  validImages.first,
                                  width: double.infinity,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    color: Colors.grey.withOpacity(.2),
                                  ),
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
                                  title: widget.hatcheryName,
                                );
                              }

                              return Image.network(
                                url,
                                width: double.infinity,
                                height: 110,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;

                                      return Container(
                                        color: Colors.grey.withOpacity(.15),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.withOpacity(.2),
                                ),
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

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME + (removed badge same as original)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.hatcheryName,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // CATEGORY NAME
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.categoryName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[900],
                      ),
                    ),

                    _buildInfoRow(
                      "assets/images/MoneyWavy.png",
                      "Price",
                      "₹ ${widget.price}",
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // BROODSTOCK + DATE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow(
                      "assets/images/broadstock.png",
                      "Broodstock",
                      "${widget.broodstockCount} Pieces",
                    ),

                    if (widget.availableDate != null)
                      _buildInfoRow(
                        "assets/images/CalendarBlank.png",
                        "Available Date",
                        widget.availableDate!,
                      ),
                  ],
                ),

                const SizedBox(height: 3),

                // PRICE
                const SizedBox(height: 3),

                // LOCATION ROWS
                if (widget.units.isNotEmpty)
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.9, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SizedBox(
                      height: 50,
                      width: double.infinity, // ✅ important
                      child: SingleChildScrollView(
                        controller: _unitScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildInfoUnitRow(
                            "assets/images/unit_icon.png",
                            "Unit",
                            widget.units
                                .where((u) => u.branch.name.isNotEmpty)
                                .map((u) => u.branch.name)
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 5),

                // ACTION BUTTONS
                Row(
                  children: [
                    _actionButton(
                      label: "Call Now",
                      icon: "assets/images/phone.png",
                      color: AppColors.primary,
                      onTap: () => _makePhoneCall(widget.callUrl),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
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
                                isSpotHatchery: false,
                                price: widget.price,
                                categoryId: widget.categoryId,
                                hatcheryId: widget.hatcheryId,
                                hatcheryName: widget.hatcheryName,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(width: 5),
                  ],
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoUnitRow(
    String assetPath,
    String label,
    List<String> branches,
  ) {
    if (branches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 16,
              height: 16,
              color: Colors.grey, // optional
            ),
            const SizedBox(width: 6),
            Text(
              branches.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String assetPath, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
            ),
            Row(
              children: [
                Image.asset(
                  assetPath,
                  width: 18,
                  height: 18,
                  color: AppColors.primary, // remove if image already colored
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: MediaQuery.of(context).size.width * .3,
                  child: Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
