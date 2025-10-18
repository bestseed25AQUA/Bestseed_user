import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/contact_us.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/hatchery_suppliers_widget.dart';
import 'package:seedsuser/app/home/hatchery_updates_widget.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';
import 'package:seedsuser/app/home/today_price_widget.dart';
import 'package:seedsuser/app/home/widget/home_banner_carousel.dart';

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

  // late Animation<Offset> _fishAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true); // 👈 keeps looping back and forth

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

  @override
  Widget build(BuildContext context) {
    final hatcheryList = [
      {
        "imagePath": "assets/images/fish_swimming.png",
        "title": "Gayathri Hatchery Pri...",
        "location": "Bapatla",
        "type": "Syqua",
        "status": "Coming Soon",
        "statusColor": Colors.orange,
        "availableUntil": null,
      },
      {
        "imagePath": "assets/images/fish_swimming.png",
        "title": "Seven Star",
        "location": "Bapatla",
        "type": "Syqua",
        "status": "Closed",
        "statusColor": Colors.red,
        "availableUntil": "Next available at \n30/06/2025",
      },
      {
        "imagePath": "assets/images/fish_swimming.png",
        "title": "Seven Star",
        "location": "Bapatla",
        "type": "Syqua",
        "status": "Closed",
        "statusColor": Colors.red,
        "availableUntil": "Next available at \n30/06/2025",
      },
    ];
    return SingleChildScrollView(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 👈 Left image moves left→right
                      SlideTransition(
                        position: _leftAnimation,
                        child: Image.asset(
                          'assets/images/fish_icon.png',
                          height: 50,
                        ),
                      ),

                      // Center text
                      Text(
                        '"Grow More with the Best Seeds –\nQuality, Variety, and Trust”',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // 👉 Right image moves right→left
                      SlideTransition(
                        position: _rightAnimation,
                        child: Image.asset(
                          'assets/images/roya.png',
                          height: 50,
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
                      Fluttertoast.showToast(
                        msg: "Working on it...",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.black54,
                        textColor: Colors.red,
                        fontSize: 16.0,
                      );
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
            child: // Contact Us Section
                ContactUsPage(),
          ),

          // Hatcheries Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
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
                    Image.asset("assets/images/redline.png", width: 121),
                    // Text(
                    //   'Find nearby hatcheries for fish \nor shrimp seeds.',
                    //   textAlign: TextAlign.center,
                    //   style: GoogleFonts.roboto(
                    //     fontSize: 16,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildHatcheryCard(
                        imagePath: hatcheryList[0]["imagePath"] as String,
                        title: hatcheryList[0]["title"] as String,
                        location: hatcheryList[0]["location"] as String,
                        type: hatcheryList[0]["type"] as String,
                        status: hatcheryList[0]["status"] as String,
                        statusColor: hatcheryList[0]["statusColor"] as Color,
                        availableUntil:
                            hatcheryList[0]["availableUntil"] as String?,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildHatcheryCard(
                        imagePath: hatcheryList[1]["imagePath"] as String,
                        title: hatcheryList[1]["title"] as String,
                        location: hatcheryList[1]["location"] as String,
                        type: hatcheryList[1]["type"] as String,
                        status: hatcheryList[1]["status"] as String,
                        statusColor: hatcheryList[1]["statusColor"] as Color,
                        availableUntil:
                            hatcheryList[1]["availableUntil"] as String?,
                      ),
                    ),
                  ],
                ),

                // Hatchery Cards
                SizedBox(height: 16),
                TodayPricesWidget(),
                SizedBox(height: 16),
                HatcherySuppliersWidget(),
                SizedBox(height: 16),
                _buildSectionHeader('Medicine news'),
                _buildMedicineNewsSection(),
                SizedBox(height: 16),
                HatcheryUpdatesWidget(),
                SizedBox(height: 80),

                // Add more hatchery cards as needed
              ],
            ),
          ),
        ],
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
                      fontSize: 12,
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

  Widget _buildHatcheryCard({
    required String imagePath,
    required String title,
    required String location,
    required String type,
    required String status,
    required Color statusColor,
    String? availableUntil,
  }) {
    return InkWell(
      onTap: () {
        Get.to(() => HatcheryDetailScreen());
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on the left
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    imagePath,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (availableUntil != null)
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Text(
                      availableUntil,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            // 👈 adds visibility on bright images
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Details on the right
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(type, style: GoogleFonts.roboto(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        TextButton(
          onPressed: () {
            dashboardCtrl.changeIndex(3);
          },
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

  Widget _buildMedicineNewsSection() {
    return SizedBox(
      height: 190, // Adjust height to accommodate content
      child: ListView(
        scrollDirection: Axis.horizontal,

        children: [
          _buildNewsCard(
            'Probiotic Powder',
            'Gutwell, Vibract',
            'https://picsum.photos/200/300?random=2', // Placeholder image
          ),
          _buildNewsCard(
            'Immuno Boosters',
            'ImmuGuard, Immuno',
            'https://picsum.photos/200/300?random=3', // Placeholder image
          ),
          _buildNewsCard(
            'Immuno Boosters',
            'ImmuGuard, Immuno',
            'https://picsum.photos/200/300?random=4', // Placeholder image
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String? subtitle, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
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
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
