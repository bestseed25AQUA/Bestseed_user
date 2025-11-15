import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/filter_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/all_screen.dart';
import 'package:seedsuser/app/home/view/home_appbar_widget.dart';
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
  final HomeController _homeController = Get.put(HomeController());
  final FilterController filterController = Get.put(FilterController());
  final ProfileController profileController = Get.put(ProfileController());

  final newsSpecificController = Get.put(NewsSpecificController());

  @override
  void initState() {
    super.initState();

    if (_locationController.selectedLocationId.value.isEmpty) {
      getDefaultLocation();
    }
    _homeController.selectedCategoryId.value = '';
    _homeController.getHatcheries();
    _homeController.getPricesForHome();
    ever(_homeController.categories, (_) {
      _initTabController();
      if (mounted) setState(() {});
    });
  }

  void getDefaultLocation() async {
    await profileController.getProfile();
    await _locationController.fetchDefaultLocation(
      profileController.profile.value?.id.toString() ?? '',
    );
    _homeController.changeHomeData(
      '',
      _locationController.selectedLocationId.value,
    );
  }

  int currentTabIndex = 0;
  void _initTabController() {
    if (_homeController.categories.isNotEmpty){
      _tabController?.dispose();
      _tabController = TabController(
        length: 4 + 1, //
        vsync: this,
      );
      _tabController?.addListener((){
        currentTabIndex = (_tabController?.index ?? 0);
        _homeController.selectedCategoryId.value = currentTabIndex == 0
            ? ''
            : _homeController.categories[currentTabIndex - 1].id.toString();
        _homeController.changeHomeData(
          _homeController.selectedCategoryId.value,
          _locationController.selectedLocationId.value,
        );
      });
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_homeController.categories.isNotEmpty) {
      _initTabController();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  final _locationController = Get.put(LocationController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          HomeAppBar(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Obx(() {
                final categories = _homeController.categories;

                if (categories.isEmpty || _tabController == null) {
                  return const DefaultTabController(
                    length: 1,
                    child: TabBar(isScrollable: true, tabs: [Tab(text: "All")]),
                  );
                }
                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  tabs: [
                    const Tab(text: "All"),
                    ...categories
                        .take(4)
                        .map((cat) => Tab(text: cat.categoryName)),
                  ],
                );
              }),
            ),
          ),
        ],
        body: Obx(() {
          final cats = _homeController.categories.take(4).toList();
          if (_homeController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_tabController == null) {
            return const Center(child: Text("Loading categories..."));
          }

          return TabBarView(
            key: ValueKey(cats.length),
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await _homeController.changeHomeData(
                    _homeController.selectedCategoryId.value,
                    _locationController.selectedLocationId.value,
                  );
                },
                child: const HomePage(),
              ),
              ...cats.map(
                (cat) => RefreshIndicator(
                  onRefresh: () async {
                    await _homeController.changeHomeData(
                      cat.id.toString(),
                      _locationController.selectedLocationId.value,
                    );
                  },
                  child: const HomePage(),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Custom Delegate for Sticky TabBar
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
      color: AppColors.primary,
      alignment: Alignment.centerLeft,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}
