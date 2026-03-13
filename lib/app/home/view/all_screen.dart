import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/view/best_deals_screen.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  // final MyBookingController bookingController = Get.put(
  //   MyBookingController(),
  //   permanent: true,
  // );
  late AnimationController _controller;
  late Animation<Offset> _leftAnimation;
  late Animation<Offset> _rightAnimation;

  final dashboardCtrl = Get.find<DashboardController>();
  final _broodStockController = Get.put(BroodStockController());
  final _newsSpecificController = Get.put(NewsSpecificController());
  final _seedsPriceController = Get.put(SeedsPriceController());
  final _homeController = Get.put(HomeController());
  final _homeBannerController = Get.put(HomeBannerController());
  final _hatcheryController = Get.put(HatcheryUpdatesController());
  final _farmListController = Get.put(FarmListController());
  // late Animation<Offset> _fishAnimation;

  @override
  void initState() {
    super.initState();

    // Ensure hatchery updates are fetched for home screen
    if (_hatcheryController.hatcheryHomeData.value == null ||
        (_hatcheryController.hatcheryHomeData.value?.data.isEmpty ?? true)) {
      _hatcheryController.fetchHatcheryHomeUpdate();
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // _fishAnimation = Tween<Offset>(
    //   begin: const Offset(0, 0), // start at original position
    //   end: const Offset(0, -0.5), // move upward (negative Y)
    // ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _leftAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, 0), // move slightly to right
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0), // move slightly to left
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
      backgroundColor: Colors.white,
      // floatingActionButton: Obx(() {
      //   if (!bookingController.hasInProgressBooking) {
      //     return const SizedBox.shrink();
      //   }

      //   return FloatingActionButton.extended(
      //     onPressed: () {
      //       Get.to(() => const MyBookingScreen());
      //     },
      //     backgroundColor: Colors.green,
      //     icon: const Icon(Icons.local_shipping),
      //     label: const Text("Pickup Started"),
      //   );
      // }),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Column(
              children: [
                Obx(() {
                  if (_homeBannerController.bannersBackGround.isEmpty) {
                    if (_homeBannerController.isLoading.value) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: double.infinity,
                          height: AppSize.height * .09,
                          color: Colors.white,
                        ),
                      );
                    }
                    return Image.asset(
                      'assets/images/best_seed_bottom.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      height: AppSize.height * .09,
                    );
                  }
                  final banner = _homeBannerController.bannersBackGround[0];
                  if (banner.type == 'video') {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _AutoLoopBannerVideo(url: banner.url, height: 73),
                    );
                  }
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullImageScreen(imageUrl: banner.url),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: AppSize.height * .08,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Image.network(
                              banner.url,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/best_seed_bottom.png',
                                  width: double.infinity,
                                  fit: BoxFit.fill,
                                  height: AppSize.height * .08,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            // ── Section 1: Vehicle Banner + Menu Items + Contact Us ──
            Obx(() {
              final section1Bg = _homeBannerController.bannersSection1Bg;
              return Container(
                decoration: section1Bg.isNotEmpty && section1Bg.first.type == 'image'
                    ? BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(section1Bg.first.url),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const BoxDecoration(
                        color: Colors.white,
                      ),
                child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Vehicle Availability Banner
                  Obx(() {
                    final homeBanners = _homeBannerController.bannersHome;
                    return Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(context, AppAnimations.fade(VehicleAvailabilityScreen()));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: homeBanners.isNotEmpty
                              ? homeBanners.first.type == 'video'
                                  ? _AutoLoopBannerVideo(
                                      key: ValueKey('home_${homeBanners.first.url}'),
                                      url: homeBanners.first.url,
                                      height: AppSize.height * .15,
                                      width: AppSize.width * .9,
                                      initDelay: 0,
                                    )
                                  : Image.network(
                                      homeBanners.first.url,
                                      width: AppSize.width * .9,
                                      height: AppSize.height * .15,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Shimmer.fromColors(
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100,
                                          child: Container(
                                            width: AppSize.width * .9,
                                            height: AppSize.height * .15,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/home_banner.jpeg',
                                        width: AppSize.width * .9,
                                        height: AppSize.height * .15,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                              : _homeBannerController.isHomeLoading.value
                                  ? Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        width: AppSize.width * .9,
                                        height: AppSize.height * .15,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/home_banner.jpeg',
                                      width: AppSize.width * .9,
                                      height: AppSize.height * .15,
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                  // Menu Items
                  Builder(
                    builder: (context) {
                      final double boxesHeight = AppSize.height * .19;
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              height: boxesHeight,
                              width: MediaQuery.of(context).size.width * .35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black.withOpacity(.1), width: 1),
                              ),
                              child: _buildMenuItemMedicine(
                                'FC Farm Medicine for fishes ',
                                'assets/images/fc_prawn.png',
                                () {
                                  Navigator.push(context, AppAnimations.fade(const BestDealsScreen()));
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: boxesHeight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Obx(() {
                                        final spotIcons = _homeBannerController.bannersSpotHatcheries;
                                        final loading = _homeBannerController.isSpotLoading.value;
                                        return _buildMenuItem(
                                          'Spot \nHatcheries',
                                          'assets/images/hatchery_icon.png',
                                          () {
                                            Navigator.push(context, AppAnimations.fade(SpotHatcheryScreen()));
                                          },
                                          networkImageUrl: spotIcons.isNotEmpty ? spotIcons.first.url : null,
                                          networkMediaType: spotIcons.isNotEmpty ? spotIcons.first.type : null,
                                          videoInitDelay: 1000,
                                          isLoading: loading,
                                        );
                                      }),
                                    ),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: Obx(() {
                                        final farmIcons = _homeBannerController.bannersFarmManagement;
                                        final loading = _homeBannerController.isFarmLoading.value;
                                        return _buildMenuItem(
                                          'Farm \nManagement',
                                          'assets/images/farm.png',
                                          () {
                                            final farmData = _farmListController.farmList.value?.data;
                                            if (farmData != null && farmData.isNotEmpty) {
                                              Navigator.push(context, AppAnimations.fade(const FarmManagementScreen()));
                                            } else {
                                              Navigator.push(context, AppAnimations.fade(const InitialFarmScreen()));
                                            }
                                          },
                                          networkImageUrl: farmIcons.isNotEmpty ? farmIcons.first.url : null,
                                          networkMediaType: farmIcons.isNotEmpty ? farmIcons.first.type : null,
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
                    },
                  ),
                  // Contact Us
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 0, right: 16),
                    child: ContactUsPage(),
                  ),
                ],
              ),
            );
            }),

            // ── Section 2: Hatcheries + Seed Request ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                            title: _homeController.selectedCateogryName.value.isEmpty
                                ? "Hatchery"
                                : _homeController.selectedCateogryName.value,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(1, 2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          color: Colors.grey.withOpacity(.4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seed Request',
                          style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            Navigator.push(context, AppAnimations.slideLeftToRight(SeedRequestsFormScreen()));
                          },
                          icon: Icon(Icons.arrow_forward, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),

            // ── Section 3: Today Prices + Suppliers ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TodayPricesWidget(),
                  HatcherySuppliersWidget(),
                ],
              ),
            ),

            // ── Section 4: Medicine News + Updates ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Obx(() {
                    return Column(
                      children: [
                        if ((_newsSpecificController.newsSpecificHomeData.value?.data?.length ?? 0) != 0)
                          _buildSectionHeader('Medicine News', () {
                            dashboardCtrl.changeIndex(3);
                          }),
                        if ((_newsSpecificController.newsSpecificHomeData.value?.data?.length ?? 0) != 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                (_newsSpecificController.newsSpecificHomeData.value?.data?.length ?? 0) <= 2
                                    ? (_newsSpecificController.newsSpecificHomeData.value?.data?.length ?? 0)
                                    : 2,
                                (index) {
                                  final data = _newsSpecificController.newsSpecificHomeData.value?.data?[index];
                                  return Expanded(
                                    child: _buildNewsCard(
                                      data?.medicineName ?? "",
                                      data?.subtitle ?? data?.curesFor ?? "",
                                      data?.mediaPath ?? "",
                                      'medicine$index',
                                      () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            transitionDuration: const Duration(milliseconds: 600),
                                            reverseTransitionDuration: const Duration(milliseconds: 600),
                                            pageBuilder: (_, __, ___) => MedicineDetailScreen(
                                              id: data?.id.toString() ?? '',
                                              title: data?.medicineName.toString() ?? '',
                                              subtitle: data?.subtitle ?? data?.curesFor ?? "",
                                              imageUrl: data?.mediaPath ?? "",
                                              tag: 'medicine$index',
                                            ),
                                          ),
                                        );
                                      },
                                      mediaFiles: data?.mediaFiles,
                                      mediaTypes: data?.mediaTypes,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 16),
                  HatcheryUpdatesWidget(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required String title,
    required String icon,
    String? overlayIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_circle_right, color: Colors.black, size: 24),
            const SizedBox(width: 10),
            overlayIcon != null
                ? Stack(
                    children: [
                      Image.asset(icon, height: 80),
                      Positioned(
                        top: 28,
                        left: 32,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(overlayIcon, height: 20),
                        ),
                      ),
                    ],
                  )
                : Image.asset(icon, height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String text,
    String iconPath,
    VoidCallback onTap, {
    String? networkImageUrl,
    String? networkMediaType,
    int videoInitDelay = 0,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(.1),
              blurRadius: 1,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: networkImageUrl != null
              ? networkMediaType == 'video'
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return _AutoLoopBannerVideo(
                          key: ValueKey(networkImageUrl),
                          url: networkImageUrl,
                          height: constraints.maxHeight,
                          width: constraints.maxWidth,
                          initDelay: videoInitDelay,
                        );
                      },
                    )
                  : Image.network(
                      networkImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.fill,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(iconPath, height: 40, fit: BoxFit.contain),
                            const SizedBox(height: 6),
                            Text(
                              text.replaceAll('\n', ' '),
                              style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    if (isLoading)
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.white,
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            iconPath,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text.replaceAll('\n', ' '),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMenuItemMedicine(
    String defaultText,
    String iconPath,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white, Color(0xff6AD7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
              child: Text(
                'Best Deals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: Obx(() {
                final banners = _homeBannerController.bannersMedicine;
                if (banners.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        defaultText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      Expanded(
                        child: Image.asset(iconPath, fit: BoxFit.cover),
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
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    scrollDirection: Axis.horizontal,
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final banner = banners[index];
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          banner.title.isNotEmpty ? banner.title : defaultText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                banner.url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    Image.asset(iconPath, fit: BoxFit.cover),
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

  Widget _buildSectionHeader(String title, VoidCallback ontap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        TextButton(
          onPressed: ontap,
          child: Text(
            "View all",
            style: GoogleFonts.roboto(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
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

  Widget _buildNewsCard(
    String title,
    String? subtitle,
    String imageUrl,
    String tag,
    VoidCallback ontap, {
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
      padding: EdgeInsetsGeometry.only(right: 6, left: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.85),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(.7),
                  border: Border.all(width: .1, color: Colors.grey),
                  boxShadow: [BoxShadow(color: Colors.grey)],
                ),
                child: MiniMediaCarousel(
                  mediaUrls: urls,
                  mediaTypes: types,
                  height: double.infinity,
                  borderRadius: 12,
                  onTap: ontap,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 5),
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
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Color(0xff7D7272),
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

  const _AutoLoopBannerVideo({super.key, required this.url, required this.height, this.width, this.initDelay = 0});

  @override
  State<_AutoLoopBannerVideo> createState() => _AutoLoopBannerVideoState();
}

class _AutoLoopBannerVideoState extends State<_AutoLoopBannerVideo> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

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

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      // Auto-resume if system pauses the video
      controller.addListener(_autoResume);
      if (mounted) {
        setState(() { _isInitialized = true; });
      }
    } catch (e) {
      debugPrint('Video init failed: $e');
    }
  }

  void _autoResume() {
    final vc = _videoController;
    if (vc != null && _isInitialized && mounted) {
      if (!vc.value.isPlaying && vc.value.isInitialized && !vc.value.isBuffering) {
        vc.play();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
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
