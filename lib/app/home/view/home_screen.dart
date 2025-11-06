import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/filter_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/all_screen.dart';
import 'package:seedsuser/app/home/view/home_appbar_widget.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_ads_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';

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
  final newsSpecificController = Get.put(NewsSpecificController());

  String currentCity = "Fetching...";
  String currentState = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _homeController.changeHomeData('', '10'); /////
    // _homeController.getCategories();

    // React to category updates
    ever(_homeController.categories, (_) {
      _initTabController();
      if (mounted) setState(() {});
    });
  }

  int currentTabIndex = 0;
  void _initTabController() {
    if (_homeController.categories.isNotEmpty) {
      _tabController?.dispose();
      _tabController = TabController(
        length: _homeController.categories.length + 1, //
        vsync: this,
      );
      _tabController?.addListener(() {
        currentTabIndex = (_tabController?.index ?? 0);
        _homeController.changeHomeData(
          currentTabIndex == 0
              ? ''
              : _homeController.categories[currentTabIndex - 1].id.toString(),
          '10',
        );
      });
    }
  }

  // final _broodStockController = Get.put(BroodStockController());
  // final _newsSpecificController = Get.put(NewsSpecificController());
  // final _seedsPriceController = Get.put(SeedsPriceController());

  // changeHomeData(
  //   String categoryId,
  //   String locationId, {
  //   double? latitude,
  //   double? longitude
  // }) async {
  //   print('========calling for the======');
  //   print('categoryId - $categoryId, locationId $locationId');
  //   // hatcheries api
  //   // price api
  //   await _seedsPriceController.getPricesForHome(
  //     categoryId: categoryId,
  //     locationId: locationId,
  //   );
  //   //brood stocks api
  //   await _broodStockController.getBroodStockForHome(
  //     categoryId: categoryId,
  //     locationId: '20',
  //   );
  //   // medicine home api
  //   await _newsSpecificController.fetch(
  //     'medicine news',
  //     categoryId: categoryId,
  //     locationId: locationId,
  //     isHome: true,
  //   );
  //   // hatchery updates
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reinitialize TabController safely whenever widget becomes active again
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
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => currentCity = "Location disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => currentCity = "Permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => currentCity = "Permission permanently denied");
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _locationController.selectedLatiude.value = position.latitude.toString();
    _locationController.selectedLongitude.value = position.longitude.toString();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      // setState(() {
      //   currentCity = place.subLocality ?? place.locality ?? "Unknown";
      //   currentState =
      //       "${place.street ?? ""}, ${place.locality ?? ""}, ${place.administrativeArea ?? ""}";
      // });
      _locationController.selectedCity.value =
          place.subLocality ?? place.locality ?? "Unknown";
      _locationController.selectedStreet.value =
          "${place.street ?? ""}, ${place.locality ?? ""}, ${place.administrativeArea ?? ""}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          HomeAppBar(currentCity: currentCity, currentStreet: currentState),
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
                    ...categories.map((cat) => Tab(text: cat.categoryName)),
                  ],
                );
              }),
            ),
          ),
        ],
        body: Obx(() {
          if (_homeController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_tabController == null) {
            return const Center(child: Text("Loading categories..."));
          }

          return TabBarView(
            key: ValueKey(_homeController.categories.length),
            controller: _tabController,
            children: [
              const HomePage(),
              ..._homeController.categories.map((cat) => HomePage()),
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
      _tabBar is TabBar ? (_tabBar as TabBar).preferredSize.height : 48;

  @override
  double get maxExtent =>
      _tabBar is TabBar ? (_tabBar as TabBar).preferredSize.height : 48;

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
