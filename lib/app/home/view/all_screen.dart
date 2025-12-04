import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/farm_management/farm_home/farm_home_screen.dart';
import 'package:seedsuser/app/home/contact_us.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/hatchery_suppliers_widget.dart';
import 'package:seedsuser/app/home/hatchery_updates_widget.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_ads_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_news_screen.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';
import 'package:seedsuser/app/home/today_price_widget.dart';
import 'package:seedsuser/app/home/widget/home_banner_carousel.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              color: AppColors.primary,
              // padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: .0,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SlideTransition(
                            position: _leftAnimation,
                            child: Image.asset(
                              'assets/images/fish_icon.png',
                              height: 50,
                            ),
                          ),
                        ),

                        // Center text
                        SizedBox(
                          width: 240,
                          child: Column(
                            children: [
                              Text(
                                '"Grow More with the Best Seeds –\nQuality, Variety, and Trust"',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // 👉 Right image moves right→left
                        Expanded(
                          child: SlideTransition(
                            position: _rightAnimation,
                            child: Image.asset(
                              'assets/images/roya.png',
                              height: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // CarouselCardsScreen(),
                  HomeBannerCarousel(),
                ],
              ),
            ),
            // Menu Items Section
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildMenuItem(
                      'Farm Management',
                      'assets/images/farm.png',
                      () {
                        Get.to(() => FarmHomeScreen());
                        // Fluttertoast.showToast(
                        //   msg: "Working on it...",
                        //   toastLength: Toast.LENGTH_SHORT,
                        //   gravity: ToastGravity.BOTTOM,
                        //   backgroundColor: Colors.black54,
                        //   textColor: Colors.red,
                        //   fontSize: 16.0,
                        // );
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildMenuItem(
                      'Spot Hatcheries',
                      'assets/images/hatchery_icon.png',
                      () {
                        Get.to(() => const SpotHatcheryScreen());
                      },
                    ),
                  ),
                  // SizedBox(width: 8),
                  // Expanded(
                  //   child: _buildMenuItem(
                  //     'Seeds Requests',
                  //     'assets/images/seeds.png',
                  //     () {
                  //       Get.to(() => const SeedRequestsFormScreen());
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16, right: 16),
              // height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ContactUsPage(),
            ),

            // Hatcheries Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        "assets/images/seeds.png",
                        width: MediaQuery.of(context).size.width * .17,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // SlideTransition(
                            //   position: _fishAnimation,
                            //   child: Image.asset("assets/images/fish.png", height: 50),
                            // ),
                            Text(
                              'Hatcheries',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0076BE),
                              ),
                            ),
                            SizedBox(height: 10),
                            Image.asset(
                              "assets/images/redline.png",
                              width: MediaQuery.of(context).size.width * .3,
                            ),
                            Text(
                              'Find nearby hatcheries for fish or shrimp seeds.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),

                      Image.asset(
                        "assets/images/fish.png",
                        width: MediaQuery.of(context).size.width * .17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HatcheryWidget(
                    onViewAllTap: () {
                      filterHatcheryController.selectedCategoryIds.clear();
                      filterHatcheryController.selectedCategoryIds.add(_homeController.selectedCategoryId.value);
                      filterHatcheryController.applyFilter();
                      Get.to(() => HatcheryFilterScreen(title: _homeController.selectedCateogryName.value));
                    },
                  ),
                  SizedBox(height: 20),
                  Material(
                    elevation: 4,
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(1, 2),
                            spreadRadius: 1,
                            blurRadius: 0,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
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
                              onPressed: () {
                                Get.to(() => SeedRequestsFormScreen());
                              },
                              icon: Icon(
                                Icons.arrow_forward,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TodayPricesWidget(),
                  SizedBox(height: 16),
                  HatcherySuppliersWidget(),
                  SizedBox(height: 16),
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
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.width * .38 + 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
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
                                  return _buildNewsCard(
                                    data?.medicineName ?? "",
                                    data?.curesFor ?? "",
                                    data?.mediaPath ?? "",
                                    () {
                                      Get.to(
                                        () => MedicineDetailScreen(
                                          id: data?.id.toString() ?? '',
                                          title:
                                              data?.medicineName.toString() ??
                                              '',
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 16),
                  if(_hatcheryController.hatcheryHomeData.value?.data.isNotEmpty??false)
                  HatcheryUpdatesWidget(),
                  SizedBox(height: 100)
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.5), // soft shadow
              blurRadius: 12, // smooth blur
              spreadRadius: 2, // light spread
              offset: const Offset(0, 6), // shadow below the card
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(iconPath, height: 50),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),

                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(Icons.arrow_circle_right, color: Colors.black),
              ],
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
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        TextButton(
          onPressed: ontap,
          child: Text(
            "View all",
            style: GoogleFonts.roboto(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(
    String title,
    String? subtitle,
    String imageUrl,
    VoidCallback ontap,
  ) {
    return Padding(
      padding: EdgeInsetsGeometry.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: ontap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.85),
              child: Container(
                height: MediaQuery.of(context).size.width * .38,
                width: MediaQuery.of(context).size.width * .38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(.7),
                  border: Border.all(width: .1, color: Colors.grey),
                  boxShadow: [BoxShadow(color: Colors.grey)],
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      height: 120,
                      width: 150,
                      child: CustomShimmer(),
                    );
                  },
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
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
