import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/view/best_deals_screen.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/common/safe_network_image.dart';
import 'package:seedsuser/app/utils/video_file_cache.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/farm_management/coming_soon_screen.dart';
import 'package:seedsuser/app/home/contact_us.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/hatchery_suppliers_widget.dart';
import 'package:seedsuser/app/home/hatchery_updates_widget.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';
import 'package:seedsuser/app/home/today_price_widget.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/utils/app_animations.dart';
import 'package:seedsuser/app/utils/app_size.dart';
import 'package:seedsuser/app/common/full_image_screen.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _leftAnimation;
  late Animation<Offset> _rightAnimation;

  final dashboardCtrl = Get.find<DashboardController>();
  final _newsSpecificController = Get.put(NewsSpecificController());
  final _homeController = Get.put(HomeController());
  final _homeBannerController = Get.find<HomeBannerController>();
  final _hatcheryController = Get.put(HatcheryUpdatesController());

  @override
  void initState() {
    super.initState();

    // Spot Hatchery & Farm Management: always refresh on every Home open. This
    // (1) loads them reliably on first login/open — the old `if (empty)`
    // gate could leave them blank when the duplicated startup request burst
    // starved them — and (2) clears any stale icon from earlier in the session
    // so the user never sees an OLD banner (cards shimmer, then show today's
    // banner or the static fallback).
    _homeBannerController.refreshSpotAndFarm();

    // Other banners (vehicle/home, best deals, background) — fetch once if
    // missing; fine to keep for the session.
    if (_homeBannerController.bannersMedicine.isEmpty ||
        _homeBannerController.bannersHome.isEmpty) {
      print('📱 [HOME] Fetching banners — some are missing');
      _homeBannerController.fetchAll();
    }

    if (_hatcheryController.hatcheryHomeData.value == null ||
        (_hatcheryController.hatcheryHomeData.value?.data.isEmpty ?? true)) {
      _hatcheryController.fetchHatcheryHomeUpdate();
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _leftAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Banner ──────────────────────────────────────────
              _heroBanner(),

              // ── Quick Actions Grid ───────────────────────────────────
              _quickActionsSection(),

              const SizedBox(height: 8),

              // ── Contact Us ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ContactUsPage(),
              ),

              const SizedBox(height: 16),

              // ── Hatcheries ───────────────────────────────────────────
              _sectionCard(
                child: Column(
                  children: [
                    HatcheryWidget(
                      onViewAllTap: () {
                        filterHatcheryController.selectedCategoryIds.clear();
                        filterHatcheryController.selectedCategoryIds.add(
                          _homeController.selectedCategoryId.value,
                        );
                        filterHatcheryController.query = '';
                        filterHatcheryController.applyFilter();
                        Navigator.push(
                          context,
                          AppAnimations.fade(
                            HatcheryFilterScreen(
                              title:
                                  _homeController
                                      .selectedCateogryName
                                      .value
                                      .isEmpty
                                  ? "Hatchery"
                                  : _homeController.selectedCateogryName.value,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _seedRequestCard(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Today's Prices + Suppliers ────────────────────────────
              _sectionCard(
                child: Column(
                  children: [
                    TodayPricesWidget(),
                    const SizedBox(height: 8),
                    HatcherySuppliersWidget(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Medicine News + Hatchery Updates ─────────────────────
              _sectionCard(
                child: Column(
                  children: [
                    _medicineNewsSection(),
                    const SizedBox(height: 16),
                    HatcheryUpdatesWidget(),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HERO BANNER — full-width top banner
  // ═══════════════════════════════════════════════════════════════════════
  Widget _heroBanner() {
    return Obx(() {
      final bgBanners = _homeBannerController.bannersBackGround;
      if (bgBanners.isEmpty) {
        if (_homeBannerController.isBgLoading.value) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: AppSize.height * .08,
              color: Colors.white,
            ),
          );
        }
        return Image.asset(
          'assets/images/best_seed_bottom.png',
          width: double.infinity,
          fit: BoxFit.contain,
          height: AppSize.height * .08,
        );
      }
      final banner = bgBanners[0];
      if (banner.type == 'video') {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: _AutoLoopBannerVideo(
            url: banner.url,
            height: 73,
            thumbnailUrl: banner.thumbnail,
          ),
        );
      }
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullImageScreen(imageUrl: banner.url),
            ),
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: AppSize.height * .08,
          child: SafeNetworkImage(
            imageUrl: banner.url,
            width: double.infinity,
            height: AppSize.height * .08,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                _shimmerBox(double.infinity, AppSize.height * .08),
            onFinalError: (context, url, error) => Image.asset(
              'assets/images/best_seed_bottom.png',
              width: double.infinity,
              fit: BoxFit.cover,
              height: AppSize.height * .08,
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS — Vehicle banner + 3 feature cards
  // ═══════════════════════════════════════════════════════════════════════
  Widget _quickActionsSection() {
    return Obx(() {
      final section1Bg = _homeBannerController.bannersSection1Bg;
      return Stack(
        children: [
          if (section1Bg.isNotEmpty && section1Bg.first.type == 'image')
            Positioned.fill(
              child: SafeNetworkImage(
                imageUrl: section1Bg.first.url,
                fit: BoxFit.cover,
              ),
            )
          else
            Positioned.fill(child: Container(color: const Color(0xFFF5F7FA))),
          Column(
            children: [
              const SizedBox(height: 14),
              // Vehicle Banner
              _vehicleBanner(),
              const SizedBox(height: 14),
              // Feature Grid
              _featureGrid(),
              const SizedBox(height: 14),
            ],
          ),
        ],
      );
    });
  }

  Widget _vehicleBanner() {
    return Obx(() {
      final homeBanners = _homeBannerController.bannersHome;
      if (homeBanners.isNotEmpty) {
        debugPrint(
          '🎬 Vehicle banner: type=${homeBanners.first.type}, url=${homeBanners.first.url}',
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              AppAnimations.fade(VehicleAvailabilityScreen()),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: homeBanners.isNotEmpty
                ? homeBanners.first.type == 'video'
                      ? _AutoLoopBannerVideo(
                          key: ValueKey('home_${homeBanners.first.url}'),
                          url: homeBanners.first.url,
                          height: AppSize.height * .15,
                          width: double.infinity,
                          initDelay: 0,
                          thumbnailUrl: homeBanners.first.thumbnail,
                        )
                      : Builder(
                          builder: (ctx) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _homeBannerController.isVideoReady.value = true;
                            });
                            return SizedBox(
                              width: double.infinity,
                              height: AppSize.height * .15,
                              child: Image(
                                image: CachedNetworkImageProvider(
                                  homeBanners.first.url,
                                ),
                                width: double.infinity,
                                height: AppSize.height * .15,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _shimmerBox(
                                        double.infinity,
                                        AppSize.height * .15,
                                      );
                                    },
                                frameBuilder:
                                    (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded ||
                                          frame != null)
                                        return child;
                                      return _shimmerBox(
                                        double.infinity,
                                        AppSize.height * .15,
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      'assets/images/logo.png',
                                      width: double.infinity,
                                      height: AppSize.height * .15,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            );
                          },
                        )
                : _shimmerBox(double.infinity, AppSize.height * .15),
          ),
        ),
      );
    });
  }

  Widget _featureGrid() {
    final double cardHeight = AppSize.height * .22;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Best Deals card
          SizedBox(
            height: cardHeight,
            width: MediaQuery.of(context).size.width * .35,
            child: _bestDealsCard(),
          ),

          const SizedBox(width: 10),

          // Spot Hatcheries + Farm Management
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: Column(
                children: [
                  // 🔹 Spot Hatcheries
                  Expanded(
                    child: Obx(() {
                      final spotIcons =
                          _homeBannerController.bannersSpotHatcheries;

                      final loading = _homeBannerController.isSpotLoading.value;

                      return Column(
                        children: [
                          // 🔥 IMPORTANT: Expanded here
                          Expanded(
                            child: _featureCard(
                              'Spot Hatcheries',
                              'assets/images/hatchery_icon.png',
                              () => Navigator.push(
                                context,
                                AppAnimations.fade(SpotHatcheryScreen()),
                              ),
                              networkImageUrl: spotIcons.isNotEmpty
                                  ? spotIcons.first.url
                                  : null,
                              networkMediaType: spotIcons.isNotEmpty
                                  ? spotIcons.first.type
                                  : null,
                              networkThumbnailUrl: spotIcons.isNotEmpty
                                  ? spotIcons.first.thumbnail
                                  : null,
                              videoInitDelay: 1000,
                              isLoading: loading,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 Farm Management
                  Expanded(
                    child: Obx(() {
                      final farmIcons =
                          _homeBannerController.bannersFarmManagement;

                      final loading = _homeBannerController.isFarmLoading.value;

                      return _featureCard(
                        'Farm Management',
                        'assets/images/farm.png',
                        () {
                          Navigator.push(
                            context,
                            AppAnimations.fade(
                              const FarmManagementComingSoonScreen(),
                            ),
                          );
                        },
                        networkImageUrl: farmIcons.isNotEmpty
                            ? farmIcons.first.url
                            : null,
                        networkMediaType: farmIcons.isNotEmpty
                            ? farmIcons.first.type
                            : null,
                        networkThumbnailUrl: farmIcons.isNotEmpty
                            ? farmIcons.first.thumbnail
                            : null,
                        videoInitDelay: 2000,
                        isLoading: loading,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BEST DEALS CARD — left column with carousel
  // ═══════════════════════════════════════════════════════════════════════
  Widget _bestDealsCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () =>
          Navigator.push(context, AppAnimations.fade(const BestDealsScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // gradient: const LinearGradient(
          //   colors: Colors.transparent,
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
          color: Colors.transparent,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Best Deals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final banners = _homeBannerController.bannersMedicine;
                debugPrint(
                  '🟣 _medicineBanners: count=${banners.length}'
                  '${banners.isNotEmpty ? ", urls=${banners.map((b) => b.url).toList()}" : ""}',
                );
                if (banners.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/fc_prawn.png',
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FC Farm Medicine',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                return CarouselSlider.builder(
                  itemCount: banners.length,
                  options: CarouselOptions(
                    height: double.infinity,
                    autoPlay: true,
                    enlargeCenterPage: false,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: banners.length > 1,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 800,
                    ),
                  ),
                  itemBuilder: (context, index, _) {
                    final banner = banners[index];
                    return Column(
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          banner.title.isNotEmpty
                              ? banner.title
                              : 'FC Farm Medicine',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SafeNetworkImage(
                                imageUrl: banner.url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => _shimmerBox(
                                  double.infinity,
                                  double.infinity,
                                ),
                                onFinalError: (_, __, ___) => Image.asset(
                                  'assets/images/fc_prawn.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FEATURE CARD — Spot Hatcheries / Farm Management
  // ═══════════════════════════════════════════════════════════════════════
  Widget _featureCard(
    String text,
    String iconPath,
    VoidCallback onTap, {
    String? networkImageUrl,
    String? networkMediaType,
    String? networkThumbnailUrl,
    int videoInitDelay = 0,
    bool isLoading = false,
  }) {
    final normalizedUrl = networkImageUrl?.trim();
    final hasNetworkMedia = normalizedUrl != null && normalizedUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: hasNetworkMedia
              ? networkMediaType == 'video'
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return _AutoLoopBannerVideo(
                            key: ValueKey(normalizedUrl),
                            url: normalizedUrl,
                            height: constraints.maxHeight,
                            width: constraints.maxWidth,
                            initDelay: videoInitDelay,
                            thumbnailUrl: networkThumbnailUrl,
                          );
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SafeNetworkImage(
                            imageUrl: normalizedUrl,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => _shimmerBox(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            onFinalError: (_, url, error) {
                              debugPrint(
                                'Feature card image failed for "$text": '
                                'url=$normalizedUrl, error=$error',
                              );
                              return _featureCardFallback(iconPath, text);
                            },
                          );
                        },
                      )
              : isLoading
              ? _shimmerBox(double.infinity, double.infinity)
              : _featureCardFallback(iconPath, text),
        ),
      ),
    );
  }

  Widget _featureCardFallback(
    String iconPath,
    String text, {
    String? fallbackText,
  }) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, height: 36, fit: BoxFit.contain),
          const SizedBox(height: 4),
          Text(
            (fallbackText ?? text).replaceAll('\n', ' '),
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEED REQUEST CARD — gradient CTA
  // ═══════════════════════════════════════════════════════════════════════
  Widget _seedRequestCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppAnimations.slideLeftToRight(SeedRequestsFormScreen()),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.primary.withOpacity(0.12),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.spa_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seed Request',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Request seeds from hatcheries',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MEDICINE NEWS SECTION
  // ═══════════════════════════════════════════════════════════════════════
  Widget _medicineNewsSection() {
    return Obx(() {
      final newsData = _newsSpecificController.newsSpecificHomeData.value?.data;
      if (newsData == null || newsData.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          _sectionHeader('Medicine News', () {
            dashboardCtrl.changeIndex(3);
          }),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              newsData.length <= 2 ? newsData.length : 2,
              (index) {
                final data = newsData[index];
                return Expanded(
                  child: _newsCard(
                    data.medicineName ?? "",
                    data.subtitle ?? data.curesFor ?? "",
                    data.mediaPath ?? "",
                    'medicine$index',
                    () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 600),
                          reverseTransitionDuration: const Duration(
                            milliseconds: 600,
                          ),
                          pageBuilder: (_, __, ___) => MedicineDetailScreen(
                            id: data.id.toString(),
                            title: data.medicineName.toString(),
                            subtitle: data.subtitle ?? data.curesFor ?? "",
                            imageUrl: data.mediaPath ?? "",
                            tag: 'medicine$index',
                          ),
                        ),
                      );
                    },
                    mediaFiles: data.mediaFiles,
                    mediaTypes: data.mediaTypes,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        AnimatedViewAllBadge(onTap: onTap),
      ],
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m3u8') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');
  }

  Widget _newsCard(
    String title,
    String? subtitle,
    String imageUrl,
    String tag,
    VoidCallback onTap, {
    List<String>? mediaFiles,
    List<String>? mediaTypes,
  }) {
    final urls = (mediaFiles != null && mediaFiles.isNotEmpty)
        ? mediaFiles
        : (imageUrl.isNotEmpty ? [imageUrl] : <String>[]);
    final types = (mediaTypes != null && mediaTypes.isNotEmpty)
        ? mediaTypes
        : [_isVideoUrl(imageUrl) ? 'video' : 'image'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey.shade100,
                ),
                child: MiniMediaCarousel(
                  mediaUrls: urls,
                  mediaTypes: types,
                  height: double.infinity,
                  borderRadius: 14,
                  onTap: onTap,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xff7D7272),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-looping video widget that plays like a GIF (muted, looping, no controls)
class _AutoLoopBannerVideo extends StatefulWidget {
  final String url;
  final double height;
  final double? width;
  final int initDelay;
  final String? thumbnailUrl; // API-provided thumbnail image URL

  const _AutoLoopBannerVideo({
    super.key,
    required this.url,
    required this.height,
    this.width,
    this.initDelay = 0,
    this.thumbnailUrl,
  });

  @override
  State<_AutoLoopBannerVideo> createState() => _AutoLoopBannerVideoState();
}

class _AutoLoopBannerVideoState extends State<_AutoLoopBannerVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  // True only once a real video frame has been decoded & presented. Until then
  // the poster thumbnail stays on top so the user never sees a black flash
  // (on first load AND on app-resume, where the decoder surface is recreated).
  bool _videoVisible = false;
  // Playback position when we (re)started waiting for a frame. The video is
  // revealed only once position moves past this — proof a fresh frame rendered.
  Duration _frameWaitBaseline = Duration.zero;
  // App foreground state — the heartbeat only auto-resumes while foregrounded.
  bool _appForeground = true;
  Timer? _heartbeat;
  int _retryCount = 0;
  static const _maxRetries = 3;

  // Tab-awareness: pause video when user switches away from home tab (index 0)
  // to free up the hardware decoder for other screens' videos.
  Worker? _tabWorker;
  bool _pausedForTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to tab changes via DashboardController
    try {
      final dashCtrl = Get.find<DashboardController>();
      debugPrint(
        '🎥 [WIDGET] tab listener attached — current tab=${dashCtrl.currentIndex.value}',
      );
      _pausedForTab = dashCtrl.currentIndex.value != 0;
      _tabWorker = ever(dashCtrl.currentIndex, (int idx) {
        if (idx != 0) {
          // Not on home tab — pause to free decoder
          if (!_pausedForTab) {
            debugPrint('🎥 [WIDGET] tab switched away (idx=$idx) — pausing');
            _pausedForTab = true;
          }
          if (_isInitialized && _videoController != null) {
            _videoController?.pause();
            _heartbeat?.cancel();
          }
        } else {
          // Back on home tab — resume
          if (_pausedForTab) {
            debugPrint('🎥 [WIDGET] tab switched back to home — resuming');
            _pausedForTab = false;
          }
          if (_isInitialized && _videoController != null) {
            _videoController?.play();
            _startHeartbeat();
          }
        }
      });
    } catch (e) {
      debugPrint(
        '🎥 [WIDGET] tab listener FAILED: $e — video will always play',
      );
    }

    if (_pausedForTab) {
      debugPrint(
        '🎥 [WIDGET] initState — tab not visible, skipping video init',
      );
    } else if (widget.initDelay > 0) {
      Future.delayed(Duration(milliseconds: widget.initDelay), () {
        if (mounted && !_pausedForTab) _initializeVideo();
      });
    } else {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    debugPrint(
      '🎥 [WIDGET] init — loading: ${widget.url} (pausedForTab=$_pausedForTab)',
    );
    File? cachedFile; // declared here so the catch can clean up a bad file
    try {
      // Dispose previous controller if retrying
      try {
        _videoController?.dispose();
      } catch (_) {}
      _videoController = null;
      _videoVisible = false; // show poster until the new first frame renders
      _frameWaitBaseline = Duration.zero;

      // Prefer a locally cached file (preloaded on splash) — initializes fast
      // with no network streaming. Fall back to the network and cache it for
      // next time. The poster shows until the first frame renders either way.
      cachedFile = await VideoFileCache.instance.get(widget.url);
      if (!mounted) return;

      final VideoPlayerController controller;
      if (cachedFile != null) {
        debugPrint('🎥 [WIDGET] init — playing from cached file');
        controller = VideoPlayerController.file(
          cachedFile,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        debugPrint('🎥 [WIDGET] init — streaming (no cache yet), caching for next time');
        VideoFileCache.instance.ensure(widget.url); // background, for next launch
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.url),
          httpHeaders: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
            'Connection': 'keep-alive',
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }
      _videoController = controller;
      debugPrint(
        '🎥 [WIDGET] init — initializing (poster shows meanwhile)...',
      );
      // NO timeout — let ExoPlayer download at its own pace.
      // Shimmer/thumbnail shows in the meantime. If there's a real error,
      // ExoPlayer reports it via hasError which heartbeat catches.
      await controller.initialize();
      debugPrint(
        '🎥 [WIDGET] init — ✅ initialized size=${controller.value.size}',
      );
      if (!mounted) {
        try {
          controller.dispose();
        } catch (_) {}
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      controller.addListener(_onVideoUpdate);
      _retryCount = 0;
      _startHeartbeat();
      debugPrint('🎥 [WIDGET] init — ✅ VIDEO PLAYING');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint(
        '🎥 [WIDGET] init — ❌ FAILED: $e (retry ${_retryCount + 1}/$_maxRetries)',
      );
      // If a cached file failed to initialize it may be corrupt/incomplete —
      // delete it so the retry streams from network instead of looping on it.
      if (cachedFile != null) {
        try {
          if (await cachedFile.exists()) await cachedFile.delete();
          debugPrint('🎥 [WIDGET] init — removed bad cached file');
        } catch (_) {}
      }
      try {
        _videoController?.dispose();
      } catch (_) {}
      _videoController = null;
      _scheduleRetry();
    }
  }

  /// Periodic check — recovers errors AND keeps the muted banner looping.
  /// The banner is muted, so there's no audio focus to respect: if it pauses
  /// unexpectedly while on the Home tab and foregrounded, resume it so it keeps
  /// auto-looping smoothly. (Tab-switch / background pauses are handled
  /// elsewhere and excluded via _pausedForTab / _appForeground.)
  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkHealth();
    });
  }

  void _checkHealth() {
    try {
      final vc = _videoController;
      if (vc == null || !mounted) return;
      final v = vc.value;

      if (v.hasError) {
        debugPrint('🎥 [PING] ❌ Error detected — re-initializing...');
        _disposeController();
        _isInitialized = false;
        if (mounted) setState(() {});
        _scheduleRetry();
        return;
      }

      // Muted banner should always be looping while visible. If it paused
      // unexpectedly (not for tab/background) and isn't buffering, resume it.
      if (!v.isPlaying &&
          v.isInitialized &&
          _isInitialized &&
          !_pausedForTab &&
          _appForeground &&
          !v.isBuffering) {
        debugPrint(
          '🎥 [PING] paused (pos=${v.position.inMilliseconds}ms) — resuming muted banner loop',
        );
        if (!v.isLooping) vc.setLooping(true);
        vc.play();
      }
    } catch (e) {
      debugPrint('🎥 [PING] Error: $e');
    }
  }

  bool _lastPlayingState = false;
  void _onVideoUpdate() {
    // Track every play→stop or stop→play transition from ExoPlayer
    final vc = _videoController;
    if (vc == null || !_isInitialized) return;
    final v = vc.value;

    // Reveal the video only once a fresh frame is actually on the surface,
    // detected by playback position ADVANCING past the wait-baseline while
    // playing and not buffering. Using advancement (not just position>0) keeps
    // this correct on resume too — there position is already >0 but no new
    // frame has rendered yet, so we must wait for it to move again.
    if (!_videoVisible &&
        v.isInitialized &&
        !v.hasError &&
        v.isPlaying &&
        !v.isBuffering &&
        v.position > _frameWaitBaseline) {
      if (mounted) setState(() => _videoVisible = true);
    }

    final playing = v.isPlaying;
    if (playing != _lastPlayingState) {
      debugPrint(
        '🎥 [BANNER] ${playing ? "▶ PLAYING" : "⏸ STOPPED"} reason=EXOPLAYER_INTERNAL '
        'pos=${v.position.inMilliseconds}ms '
        'buffering=${v.isBuffering} '
        'hasError=${v.hasError} '
        'pausedForTab=$_pausedForTab',
      );
      _lastPlayingState = playing;
    }
    // Do NOT force play() here — listener fires every frame (60fps).
    // Heartbeat handles recovery.
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries || !mounted) {
      debugPrint('🎥 [RETRY] Max retries reached ($_maxRetries) — giving up');
      return;
    }
    _retryCount++;
    final delaySec = 2 * _retryCount;
    debugPrint('🎥 [RETRY] Retry $_retryCount/$_maxRetries in ${delaySec}s...');
    Future.delayed(Duration(seconds: delaySec), () {
      if (mounted) _initializeVideo();
    });
  }

  bool _wasPlayingBeforeBackground = false;
  bool _hideVideoSurface = false;
  bool _alreadyBackgrounded =
      false; // guard against duplicate lifecycle events on OPPO

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track foreground state always (even before the controller is ready) so
    // the heartbeat never auto-resumes the loop while the app is backgrounded.
    _appForeground = state == AppLifecycleState.resumed;
    try {
      final vc = _videoController;
      if (vc == null || !_isInitialized) return;
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        // Only capture wasPlaying on the FIRST background event.
        // OPPO fires paused/inactive multiple times — second time video
        // is already paused so wasPlaying=false overwrites the real value.
        if (!_alreadyBackgrounded) {
          _wasPlayingBeforeBackground = vc.value.isPlaying;
          _alreadyBackgrounded = true;
        }
        debugPrint(
          '🎥 [BANNER] LIFECYCLE → background (wasPlaying=$_wasPlayingBeforeBackground, duplicate=${_alreadyBackgrounded})',
        );
        _hideVideoSurface = true;
        if (mounted) setState(() {});
        vc.pause();
      } else if (state == AppLifecycleState.resumed) {
        _alreadyBackgrounded = false; // reset for next background cycle
        // Hide the (now stale/black) surface and show the poster again until a
        // fresh frame is decoded. _onVideoUpdate re-reveals once position moves
        // past this baseline.
        _videoVisible = false;
        _frameWaitBaseline = vc.value.position;
        if (_wasPlayingBeforeBackground && !_pausedForTab) {
          debugPrint(
            '🎥 [BANNER] LIFECYCLE → resumed — seeking to force frame render',
          );
          // Seek to current position to force ExoPlayer to decode a frame
          // before we show the video surface again
          final pos = vc.value.position;
          vc.seekTo(pos).then((_) {
            vc.play();
            // Unblock the surface; opacity stays 0 (poster shown) until
            // _videoVisible flips when a real frame advances in.
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _hideVideoSurface = false;
                setState(() {});
                debugPrint('🎥 [BANNER] LIFECYCLE → video surface restored');
              }
            });
          });
        } else {
          // Not resuming playback — still show thumbnail, unhide after delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _hideVideoSurface = false;
              setState(() {});
            }
          });
          debugPrint(
            '🎥 [BANNER] LIFECYCLE → resumed — NOT resuming (wasPlaying=$_wasPlayingBeforeBackground, pausedForTab=$_pausedForTab)',
          );
        }
      }
    } catch (e) {
      debugPrint('🎥 [BANNER] LIFECYCLE error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant _AutoLoopBannerVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _isInitialized = false;
      _retryCount = 0;

      _initializeVideo();
    }
  }

  void _disposeController() {
    _heartbeat?.cancel();
    try {
      _videoController?.removeListener(_onVideoUpdate);
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
    _videoVisible = false; // re-show poster until the next first frame
    _frameWaitBaseline = Duration.zero;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabWorker?.dispose();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final vc = _videoController;
      final videoReady = _isInitialized && vc != null && vc.value.isInitialized;

      // Stack: thumbnail always behind video.
      // If video goes black (pause, resume, error, buffering) → thumbnail shows through instantly.
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Thumbnail/shimmer — always present behind video so any
            // black/empty frame (before first frame, buffering, resume) shows
            // the poster through instead of black.
            _thumbnail(),

            // Layer 2: Video — mounted as soon as initialized so it can decode
            // its first frame, but kept transparent until that frame is
            // actually presented (_videoVisible) and the surface is valid.
            // AnimatedOpacity cross-fades it in for a smooth swap.
            if (videoReady)
              AnimatedOpacity(
                opacity: (_videoVisible && !_hideVideoSurface) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                // The video texture is YUV 4:2:0; on some GPUs the right/bottom
                // border texel samples undefined chroma and renders as a 1px
                // green seam after BoxFit.cover scaling. ClipRect + a tiny
                // over-scale pushes that border texel just outside the visible
                // box so the seam is clipped away on every device.
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.03,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: vc.value.size.width,
                        height: vc.value.size.height,
                        child: VideoPlayer(vc),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('🎥 [WIDGET] Build error: $e');
      return _thumbnail();
    }
  }

  /// Thumbnail image from API, or shimmer fallback.
  /// Always rendered behind the video so any black frame is instantly covered.
  Widget _thumbnail() {
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      // CachedNetworkImage so it hits the same cache warmed on the splash/OTP
      // preload — the poster paints instantly instead of re-downloading.
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        width: widget.width ?? double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        placeholder: (_, __) => _shimmerPlaceholder(),
        errorWidget: (_, __, ___) => _shimmerPlaceholder(),
      );
    }
    return _shimmerPlaceholder();
  }

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
