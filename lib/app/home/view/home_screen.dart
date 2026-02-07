import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_loading_box.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/home/controller/filter_controller.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
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
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final HomeController _homeController = Get.find<HomeController>();
  final FilterController filterController = Get.put(FilterController());
  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );
  final ProfileController profileController = Get.put(ProfileController());
  final newsSpecificController = Get.put(NewsSpecificController());
  final _homeBannerController = Get.put(HomeBannerController());

  @override
  void initState() {
    super.initState();
    _initTabController();
    if (_locationController.selectedLocationId.value.isEmpty) {
      getDefaultLocation();
    }
    _homeController.selectedCategoryId.value = '';
    _homeController.getHatcheries('');
    _homeController.getPricesForHome();
    // ever(_homeController.categories, (_) {
    //   _initTabController();
    //   if (mounted) setState(() {});
    // });
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
  void _initTabController() async {
    print('=====++1+++');
    if (_homeController.categories.isEmpty) {
      await _homeController.getCategories();
    }
    print('+++++2+++++');
    if (_homeController.categories.isNotEmpty) {
      print('+++++3+ is not empty++++');
      _tabController?.dispose();
      _tabController = TabController(
        length: _homeController.categories.length + 1, // All + categories
        vsync: this,
      );
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
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
                    length: categories.length,
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
            return _tabController == null || (categories.isEmpty)
                ? CustomRefereshIndicator(
                    onRefresh: () async {
                      _homeBannerController.fetchBannersTop();
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
                        },
                        child: const HomePage(),
                      ),
                      ...categories
                          .take(4)
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
