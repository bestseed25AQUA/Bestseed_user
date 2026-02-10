import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/common/infinite_image_scroll.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/farm_management/farm_home/farm_home_screen.dart';
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
import 'package:seedsuser/app/utils/video_player.dart';
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
  // late Animation<Offset> _fishAnimation;

  @override
  void initState() {
    super.initState();

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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Obx(() {
                    if (_homeBannerController.bannersBackGround.isEmpty) {
                      return Image.asset(
                        'assets/images/best_seed_bottom.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        height: AppSize.height * .08,
                      );
                    }
                    final banner = _homeBannerController.bannersBackGround[0];
                    if (banner.type == 'video') {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _AutoLoopBannerVideo(
                          url: banner.url,
                          height: 73,
                        ),
                      );
                    }
                    return Image.network(
                      banner.url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      height: AppSize.height * .08,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/best_seed_bottom.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          height: AppSize.height * .08,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          AppAnimations.fade(VehicleAvailabilityScreen()),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/home_banner.jpeg',
                          width: AppSize.width * .9,
                          height: AppSize.height * .15,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              // ignore: deprecated_member_use
                              Container(
                                width: AppSize.width * .9,
                                height: AppSize.height * .15,
                                color: Colors.grey.withOpacity(.1),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items Section
            Builder(
              builder: (context) {
                final double boxesHeight = AppSize.height * .19;
                return Container(
                  // color: AppColors.primary,
                  padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Expanded(
                      //   child: _buildMenuItem(
                      //     'Farm Management',
                      //     'assets/images/farm.png',
                      //     () {
                      //       Get.to(() => FarmHomeScreen());
                      //       // Fluttertoast.showToast(
                      //       //   msg: "Working on it...",
                      //       //   toastLength: Toast.LENGTH_SHORT,
                      //       //   gravity: ToastGravity.BOTTOM,
                      //       //   backgroundColor: Colors.black54,
                      //       //   textColor: Colors.red,
                      //       //   fontSize: 16.0,
                      //       // );
                      //     },
                      //   ),
                      // ),
                      SizedBox(
                        height: boxesHeight,
                        width: MediaQuery.of(context).size.width * .35,
                        child: _buildMenuItemMedicine(
                          'FC Farm Medicine for fishes ',
                          'assets/images/fc_prawn.png',
                          () {
                            // Get.to(() => FarmHomeScreen());
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        height: boxesHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .52,
                              child: _buildMenuItem(
                                'Spot \nHatcheries',
                                'assets/images/hatchery_icon.png',
                                () {
                                  Navigator.push(
                                    context,
                                    AppAnimations.fade(SpotHatcheryScreen()),
                                  );
                                },
                              ),
                            ),
                            // SizedBox(height: 10),
                            Spacer(),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .52,
                              child: _buildMenuItem(
                                'Farm \nManagement',
                                'assets/images/farm.png',
                                () {
                                  Navigator.push(
                                    context,
                                    AppAnimations.fade(FarmHomeScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.only(left: 16.0, bottom: 0, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ContactUsPage(),
            ),
            // Hatcheries Section
            Padding(
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
                  SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 0,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
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
                            Navigator.push(
                              context,
                              AppAnimations.slideLeftToRight(
                                SeedRequestsFormScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TodayPricesWidget(),
                  HatcherySuppliersWidget(),
                  Obx(() {
                    return Column(
                      children: [
                        if ((_newsSpecificController
                                    .newsSpecificHomeData
                                    .value
                                    ?.data
                                    ?.length ??
                                0) !=
                            0)
                          _buildSectionHeader('Medicine News', () {
                            dashboardCtrl.changeIndex(3);
                          }),
                        if ((_newsSpecificController
                                    .newsSpecificHomeData
                                    .value
                                    ?.data
                                    ?.length ??
                                0) !=
                            0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                (_newsSpecificController
                                                .newsSpecificHomeData
                                                .value
                                                ?.data
                                                ?.length ??
                                            0) <=
                                        2
                                    ? (_newsSpecificController
                                              .newsSpecificHomeData
                                              .value
                                              ?.data
                                              ?.length ??
                                          0)
                                    : 2,
                                (index) {
                                  final data = _newsSpecificController
                                      .newsSpecificHomeData
                                      .value
                                      ?.data?[index];
                                  return Expanded(
                                    child: _buildNewsCard(
                                      data?.medicineName ?? "",
                                      data?.curesFor ?? "",
                                      data?.mediaPath ?? "",
                                      'medicine$index',
                                      () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            transitionDuration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            reverseTransitionDuration:
                                                const Duration(milliseconds: 600),
                                            pageBuilder: (_, __, ___) =>
                                                MedicineDetailScreen(
                                                  id: data?.id.toString() ?? '',
                                                  title:
                                                      data?.medicineName
                                                          .toString() ??
                                                      '',
                                                  subtitle: data?.curesFor ?? "",
                                                  imageUrl: data?.mediaPath ?? "",
                                                  tag: 'medicine$index',
                                                ),
                                          ),
                                        );
                                      },
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
                  if (_hatcheryController
                          .hatcheryHomeData
                          .value
                          ?.data
                          .isNotEmpty ??
                      false)
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

  Widget _buildMenuItem(String text, String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSize.height * .017),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          // border: Border.all(color: Colors.black.withOpacity(.1), width: 1),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(.1), // soft shadow
              blurRadius: 1, // smooth blur
              spreadRadius: 0, // light spread
              offset: const Offset(0, 1), // shadow below the card
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white, Color(0xff6AD7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            SizedBox(height: AppSize.height * .005),
            SizedBox(
              width: MediaQuery.of(context).size.width * .23,
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Spacer(),
            Image.asset(iconPath, height: AppSize.height * .055),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemMedicine(
    String text,
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
          // border: Border.all(color: Colors.black.withOpacity(.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1), // soft shadow
              blurRadius: 1, // smooth blur
              spreadRadius: 1, // light spread
              offset: const Offset(0, 1), // shadow below the card
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
            const SizedBox(height: 10),
            SizedBox(
              // width: MediaQuery.of(context).size.width * .2,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 0),
                child: InkWell(
                  onTap: () {
                    _homeBannerController.fetchBannersBackground();
                  },
                  child: Obx(() {
                    return ImageCarousel(
                      placeHolder: 'assets/images/fc_prawn.png',
                      images: _homeBannerController.bannersMedicine.isEmpty
                          ? [iconPath]
                          : List.generate(
                              _homeBannerController.bannersMedicine.length,
                              (index) => _homeBannerController
                                  .bannersMedicine[index]
                                  .url,
                            ),
                      height: 160,
                      isNetwork: _homeBannerController.bannersMedicine.isEmpty
                          ? false
                          : true,
                      // imageWidth: 70,
                    );
                  }),
                ),
              ),
            ),
            // Expanded(child: Image.asset(iconPath, fit: BoxFit.cover)),
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
    VoidCallback ontap,
  ) {
    final isVideo = _isVideoUrl(imageUrl);
    return Padding(
      padding: EdgeInsetsGeometry.only(right: 6, left: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: ontap,
            child: Hero(
              tag: tag,
              child: ClipRRect(
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
                    child: isVideo
                        ? InlineVideoPlayer(
                            url: imageUrl,
                            title: title,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return CustomShimmer();
                            },
                          ),
                  ),
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

  const _AutoLoopBannerVideo({
    required this.url,
    required this.height,
  });

  @override
  State<_AutoLoopBannerVideo> createState() => _AutoLoopBannerVideoState();
}

class _AutoLoopBannerVideoState extends State<_AutoLoopBannerVideo> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..setVolume(0) // Muted like a GIF
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _videoController.play();
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
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
      width: double.infinity,
      height: widget.height,
      child: VideoPlayer(_videoController),
    );
  }
}
