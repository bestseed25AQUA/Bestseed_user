import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_loading_box.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/home/controller/filter_controller.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/all_screen.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';
import 'package:seedsuser/app/home/view/home_appbar_widget.dart';
import 'package:seedsuser/app/home/widget/home_loading.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController? _tabController;
  final HomeController _homeController = Get.find<HomeController>();
  final FilterController filterController = Get.put(FilterController());
  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );
  final ProfileController profileController = Get.put(ProfileController());
  final newsSpecificController = Get.put(NewsSpecificController());
  final _homeBannerController = Get.put(HomeBannerController());
  final DashboardController _dashboardController =
      Get.put(DashboardController());

  /// Re-fetches home data when the Home tab is reopened. Needed because the
  /// dashboard keeps tabs alive in an IndexedStack, so initState never re-runs.
  Worker? _homeTabWorker;
  /// Builds the tab bar the moment categories arrive (cache, then network) so
  /// the shimmer doesn't linger through the full network call on first login.
  Worker? _catWorker;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTabController();
    if (_locationController.selectedLocationId.value.isEmpty) {
      getDefaultLocation();
    }
    _homeController.selectedCategoryId.value = '';
    _homeController.getHatcheries('');
    // Price/broodstock are fetched on their own screens now, not on home.

    // When the user comes back to the Home tab, refresh anything that didn't
    // load (e.g. the first fetch failed or raced ahead of the location).
    _homeTabWorker = ever(_dashboardController.currentIndex, (int index) {
      if (index == 0) _refreshHomeIfEmpty();
    });
  }

  /// Refreshes the important home sections only when they're currently empty,
  /// so a transient failure doesn't leave the screen blank until a manual pull.
  Future<void> _refreshHomeIfEmpty() async {
    if (_refreshing) return;

    // Price/broodstock are no longer part of the home, so they're not in this
    // "is the home empty?" check anymore.
    final bool coreEmpty = _homeController.categories.isEmpty ||
        _homeController.hatcheries.isEmpty;
    if (!coreEmpty) return;

    _refreshing = true;
    try {
      if (_homeController.categories.isEmpty) {
        await _homeController.getCategories();
        _initTabController();
      }
      _homeBannerController.fetchBannersTop();
      _homeBannerController.fetchHomeBanner();
      await _homeController.changeHomeData(
        _homeController.selectedCategoryId.value,
        _locationController.selectedLocationId.value,
      );
    } finally {
      _refreshing = false;
    }
  }

  fetchData() async {
    await _homeController.getCategories();
    _initTabController();
    _homeController.changeHomeData('', '');
  }

  void getDefaultLocation() async {
    await profileController.getProfile();
    await _locationController.fetchDefaultLocation(
      profileController.profile.value?.id.toString() ?? '',
    );

    // If no default location found, auto-detect current location
    if (_locationController.selectedLocationId.value.isEmpty) {
      final farmerId = profileController.profile.value?.id.toString() ?? '';
      if (farmerId.isNotEmpty) {
        await _locationController.autoDetectCurrentLocation(farmerId: farmerId);
      }
    }

    _homeController.changeHomeData(
      '',
      _locationController.selectedLocationId.value,
    );
  }

  int currentTabIndex = 0;
  void _initTabController() {
    // Build the tabs as soon as categories are available — and again if the
    // network refresh changes them. getCategories() fills the list from cache
    // first (instant) and only then awaits the network; reacting to the list
    // here means the shimmer disappears the moment data is loaded instead of
    // waiting for the full network round-trip (the long first-login shimmer).
    _catWorker ??= ever(_homeController.categories, (_) => _buildTabs());

    if (_homeController.categories.isNotEmpty) {
      _buildTabs();
    } else {
      _homeController.getCategories();
    }
  }

  void _buildTabs() {
    if (!mounted) return;
    if (_homeController.categories.isEmpty) return;
    final newLength = _homeController.categories.length + 1; // All + categories
    // Already built for this exact set — don't recreate (avoids flicker).
    if (_tabController != null && _tabController!.length == newLength) return;

    _tabController?.dispose();
    _tabController = TabController(length: newLength, vsync: this);
    _tabController?.addListener(() {
      currentTabIndex = (_tabController?.index ?? 0);
      _homeController.selectedCategoryId.value = (currentTabIndex == 0)
          ? ''
          : _homeController.categories[currentTabIndex - 1].id.toString();

      _homeController.selectedCateogryName.value = (currentTabIndex == 0)
          ? ''
          : _homeController.categories[currentTabIndex - 1].categoryName
                .toString();

      if ((_tabController?.index ?? 0) == 0) {
        _homeController.selectedCateogryName.value = '';
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeTabWorker?.dispose();
    _catWorker?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    // User may have just enabled location / granted permission in device
    // settings and returned. Re-detect if we still have no coordinates —
    // autoDetectCurrentLocation self-guards on permission + GPS, and on success
    // bumps locationUpdatedCount which makes the weather widget refresh too.
    final haveLoc = _locationController.selectedLatiude.value.isNotEmpty &&
        _locationController.selectedLongitude.value.isNotEmpty;
    if (!haveLoc) {
      final farmerId = profileController.profile.value?.id.toString() ?? '';
      if (farmerId.isNotEmpty) {
        _locationController.autoDetectCurrentLocation(farmerId: farmerId);
      }
    }
    // Retry any home section that didn't load on a transient first-load failure.
    _refreshHomeIfEmpty();
  }

  List<Widget> buildLoadingTabs(int length) {
    return List.generate(length, (index) {
      return Tab(
        iconMargin: EdgeInsets.zero,
        child: ShimmerLoadingBox(width: 80, height: 20),
      );
    });
  }

  final _locationController = Get.put(LocationController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          HomeAppBar(
            bottom: Builder(
              builder: (context) {
                final categories = _homeController.categories;
                if (categories.isEmpty || _tabController == null) {
                  return DefaultTabController(
                    length: 5,
                    child: TabBar(
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,

                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.black,
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      tabs: buildLoadingTabs(5),
                      overlayColor: WidgetStateProperty.all(Colors.white),
                      dividerColor: Colors.black,
                    ),
                  );
                }
                return TabBar(
                  tabAlignment: TabAlignment.start,
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  onTap: (index) {
                    _tabController?.index = 0;
                    String catName = categories[index - 1].categoryName
                        .toString();
                    filterHatcheryController.selectedCategoryIds.clear();
                    filterHatcheryController.query = catName;
                    filterHatcheryController.applyFilter();
                    Navigator.push(
                      context,
                      zoomOutFadeRoute(HatcheryFilterScreen()),
                    );
                  },
                  tabs: _tabController == null || (categories.isEmpty)
                      ? [SizedBox()]
                      : [
                          const Tab(text: "All", iconMargin: EdgeInsets.only()),
                          ...categories.map((e) => Tab(text: e.categoryName)),
                        ],
                );
              },
            ),
          ),
        ],

        body: Builder(
          builder: (context) {
            final categories = _homeController.categories;
            // Don't wait for banners — let home page show immediately once
            // categories + tabController are ready. Each banner section has
            // its own shimmer/loading state so they appear as they arrive.
            final showShimmer = _tabController == null || categories.isEmpty;
            debugPrint('📱 [HOME] tabController=${_tabController != null}, categories=${categories.length} → ${showShimmer ? "SHIMMER" : "HOME PAGE"}');
            return showShimmer
                ? CustomRefereshIndicator(
                    onRefresh: () async {
                      _homeBannerController.fetchBannersTop();
                      _homeBannerController.fetchHomeBanner();
                      await _homeController.changeHomeData('', '');
                    },
                    child: homeShimmer(context),
                  )
                : TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      CustomRefereshIndicator(
                        onRefresh: () async {
                          _homeBannerController.fetchBannersTop();
                          await _homeController.changeHomeData('', '');
                          // Refresh booking list for Live Tracking count
                          try {
                            Get.find<MyBookingController>().fetchBookings();
                          } catch (_) {}
                        },
                        child: const HomePage(),
                      ),
                      ...categories
                          .map(
                            (e) => CustomRefereshIndicator(
                              onRefresh: () async {
                                _homeBannerController.fetchBannersTop();
                                await _homeController.changeHomeData(
                                  _homeController.selectedCategoryId.value,
                                _locationController.selectedLocationId.value,
                                );
                              },
                              child: const HomePage(),
                            ),
                          ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

/// Custom Delegate for Sticky TabBar
// ignore: unused_element
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent =>
      _tabBar is TabBar ? (_tabBar).preferredSize.height : 48;

  @override
  double get maxExtent =>
      _tabBar is TabBar ? (_tabBar).preferredSize.height : 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.centerLeft,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

class _Dot extends StatefulWidget {
  const _Dot();

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        height: 10,
        width: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
    );
  }
}
