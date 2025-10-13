import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/all_screen.dart';
import 'package:seedsuser/app/home/filter_bottom_sheet.dart';
import 'package:seedsuser/app/home/search_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Syaqua"),
                  Tab(text: "SIS Hardline"),
                  Tab(text: "Hardline Plus"),
                  Tab(text: "SIS Hardline"),
                  Tab(text: "Hardline Plus"),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            HomePage(),
            HomePage(),
            HomePage(),
            HomePage(),
            HomePage(),
            HomePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      title: Column(
        children: [
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // ✅ prevents overflow
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/wheather.png',
                      height: 40,
                      width: 47,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      // ✅ text will ellipsize instead of overflowing
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kakinada',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '9-135 Kakinada, Andhra Pradesh',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Get.to(() => LanguageSelectionScreen());
                    },
                    child: Image.asset(
                      'assets/images/lan_image.png',
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      Get.to(() => NotificationsScreen());
                    },
                    child: Image.asset(
                      'assets/images/notification.png',
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      Get.to(() => ProfileScreen());
                    },
                    child: Image.asset('assets/images/person.png', height: 32),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primary],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSearchBar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              readOnly: true,
              onTap: () {
                Get.to(() => const SearchScreen());
              },
              decoration: InputDecoration(
                hintText: 'Search for Hatcheries, locationseeds',
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,

                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {
            showFilterBottomSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to take full height
      builder: (BuildContext context) {
        return const FilterBottomSheet();
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.centerLeft,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
