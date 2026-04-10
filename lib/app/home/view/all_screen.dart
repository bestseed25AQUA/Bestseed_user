import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/view/best_deals_screen.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/common/safe_network_image.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/farm_management/farm_home/farm_home_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/initial_farmer_screen.dart';
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
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
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
  final _broodStockController = Get.put(BroodStockController());
  final _newsSpecificController = Get.put(NewsSpecificController());
  final _seedsPriceController = Get.put(SeedsPriceController());
  final _homeController = Get.put(HomeController());
  final _homeBannerController = Get.find<HomeBannerController>();
  final _hatcheryController = Get.put(HatcheryUpdatesController());
  final _farmListController = Get.put(FarmListController());

  @override
  void initState() {
    super.initState();

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
      body: SingleChildScrollView(
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
                            title: _homeController
                                    .selectedCateogryName.value.isEmpty
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HERO BANNER — full-width top banner
  // ═══════════════════════════════════════════════════════════════════════
  Widget _heroBanner() {
    return Obx(() {
      final bgBanners = _homeBannerController.bannersBackGround;
      if (bgBanners.isEmpty) {
        if (_homeBannerController.isLoading.value) {
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
          child: _AutoLoopBannerVideo(url: banner.url, height: 73),
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
            placeholder: (context, url) => _shimmerBox(
                double.infinity, AppSize.height * .08),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
                context, AppAnimations.fade(VehicleAvailabilityScreen()));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                        )
                      : SafeNetworkImage(
                          imageUrl: homeBanners.first.url,
                          width: double.infinity,
                          height: AppSize.height * .15,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _shimmerBox(
                              double.infinity, AppSize.height * .15),
                          onFinalError: (_, __, ___) => Image.asset(
                            'assets/images/home_banner.jpeg',
                            width: double.infinity,
                            height: AppSize.height * .15,
                            fit: BoxFit.cover,
                          ),
                        )
                  : _homeBannerController.isHomeLoading.value
                      ? _shimmerBox(double.infinity, AppSize.height * .15)
                      : Image.asset(
                          'assets/images/home_banner.jpeg',
                          width: double.infinity,
                          height: AppSize.height * .15,
                          fit: BoxFit.cover,
                        ),
            ),
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

                    final loading =
                        _homeBannerController.isSpotLoading.value;

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

                    final loading =
                        _homeBannerController.isFarmLoading.value;

                    return _featureCard(
                      'Farm Management',
                      'assets/images/farm.png',
                      () {
                        final farmData =
                            _farmListController.farmList.value?.data;

                        if (farmData != null && farmData.isNotEmpty) {
                          Navigator.push(
                            context,
                            AppAnimations.fade(
                                const FarmManagementScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            AppAnimations.fade(
                                const InitialFarmScreen()),
                          );
                        }
                      },
                      networkImageUrl: farmIcons.isNotEmpty
                          ? farmIcons.first.url
                          : null,
                      networkMediaType: farmIcons.isNotEmpty
                          ? farmIcons.first.type
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                debugPrint('🟣 _medicineBanners: count=${banners.length}'
                    '${banners.isNotEmpty ? ", urls=${banners.map((b) => b.url).toList()}" : ""}');
                if (banners.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/fc_prawn.png',
                          height: 50, fit: BoxFit.contain),
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
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
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
                                placeholder: (context, url) =>
                                    _shimmerBox(double.infinity, double.infinity),
                                onFinalError: (_, __, ___) => Image.asset(
                                    'assets/images/fc_prawn.png',
                                    fit: BoxFit.cover),
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
    int videoInitDelay = 0,
    bool isLoading = false,
  }) {
    final normalizedUrl = networkImageUrl?.trim();
    final hasNetworkMedia = normalizedUrl != null && normalizedUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                              constraints.maxWidth, constraints.maxHeight),
                          onFinalError: (_, url, error) {
                            debugPrint(
                              'Feature card image failed for "$text": '
                              'url=$normalizedUrl, error=$error',
                            );
                            return _featureCardFallback(
                              iconPath,
                              text,
                              fallbackText: 'hello',
                            );
                          },
                        );
                      },
                    )
              : isLoading
                  ? _shimmerBox(double.infinity, double.infinity)
                  : _featureCardFallback(
                      iconPath,
                      text,
                      fallbackText: 'hello',
                    ),
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
          context, AppAnimations.slideLeftToRight(SeedRequestsFormScreen())),
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
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.spa_outlined,
                  color: AppColors.primary, size: 22),
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
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
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
                          transitionDuration:
                              const Duration(milliseconds: 600),
                          reverseTransitionDuration:
                              const Duration(milliseconds: 600),
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
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "View all",
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
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

  const _AutoLoopBannerVideo(
      {super.key,
      required this.url,
      required this.height,
      this.width,
      this.initDelay = 0});

  @override
  State<_AutoLoopBannerVideo> createState() => _AutoLoopBannerVideoState();
}

class _AutoLoopBannerVideoState extends State<_AutoLoopBannerVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  ModalRoute? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initDelay > 0) {
      Future.delayed(Duration(milliseconds: widget.initDelay), () {
        if (mounted) _initializeVideo();
      });
    } else {
      _initializeVideo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  Future<void> _initializeVideo() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      controller.addListener(_autoResume);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init failed: $e');
    }
  }

  void _autoResume() {
    final vc = _videoController;
    if (vc != null &&
        _isInitialized &&
        mounted &&
        (_route?.isCurrent ?? false)) {
      if (!vc.value.isPlaying &&
          vc.value.isInitialized &&
          !vc.value.isBuffering) {
        vc.play();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isInitialized &&
        (_route?.isCurrent ?? false)) {
      _videoController?.play();
    }
  }

  @override
  void didUpdateWidget(covariant _AutoLoopBannerVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _videoController?.removeListener(_autoResume);
      _videoController?.dispose();
      _isInitialized = false;
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.removeListener(_autoResume);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Image.asset(
        'assets/images/best_seed_bottom.png',
        width: double.infinity,
        fit: BoxFit.cover,
        height: widget.height,
      );
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }
}
