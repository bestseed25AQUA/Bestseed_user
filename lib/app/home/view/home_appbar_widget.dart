import 'dart:async';
import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/filter_bottom_sheet.dart';
import 'package:seedsuser/app/home/view/search_screen.dart';
import 'package:seedsuser/app/home/view/location_selection_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/utils/app_animations.dart';

// ignore: must_be_immutable
class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key, required this.bottom});
  final Widget bottom;

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar>
    with WidgetsBindingObserver {
  String? temperature;
  String? weatherIconUrl;
  bool _weatherFetched = false; // Only show weather after fresh fetch
  final String apiKey = "795e8d7e804a07ee8a5b617e45bac8e4";

  final _locationController = Get.find<LocationController>();
  final _homeController = Get.find<HomeController>();
  final _homeBannerController = Get.put(HomeBannerController());
  final _profileController = Get.find<ProfileController>();

  Worker? _locationWorker;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    debugPrint('🌤️ [WEATHER] initState called');
    debugPrint('🌤️ [WEATHER] Current state: temperature=$temperature, _weatherFetched=$_weatherFetched');
    debugPrint('🌤️ [WEATHER] Saved location: lat=${_locationController.selectedLatiude.value}, lng=${_locationController.selectedLongitude.value}, city=${_locationController.selectedCity.value}');
    _fetchWeatherFromGPS();

    // Re-fetch weather when location is updated (e.g. after granting permission)
    _locationWorker = ever(_locationController.locationUpdatedCount, (_) {
      debugPrint('🌤️ [WEATHER] locationUpdatedCount changed — refreshing weather');
      final lat = _locationController.selectedLatiude.value;
      final lng = _locationController.selectedLongitude.value;
      if (lat.isNotEmpty && lng.isNotEmpty) {
        debugPrint('🌤️ [WEATHER] Using detected coordinates: lat=$lat, lng=$lng');
        fetchWeatherByCoordinates(lat, lng);
      } else {
        debugPrint('🌤️ [WEATHER] No coordinates yet — fetching from GPS');
        _fetchWeatherFromGPS();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationWorker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // The user may have just enabled location / granted permission in the
    // device settings and returned. If we never got a temperature, retry now —
    // _fetchWeatherFromGPS re-checks permission + GPS and fetches if available.
    if (state == AppLifecycleState.resumed && !_weatherFetched) {
      debugPrint('🌤️ [WEATHER] App resumed & not fetched — retrying weather');
      _fetchWeatherFromGPS();
    }
  }

  Future<void> _fetchWeatherFromGPS() async {
    debugPrint('🌤️ [WEATHER] Step 1: Checking location permission...');
    try {
      final permission = await Geolocator.checkPermission();
      debugPrint('🌤️ [WEATHER] Step 2: Permission=$permission');

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('🌤️ [WEATHER] ❌ Location permission denied — showing nothing');
        return;
      }
      debugPrint('🌤️ [WEATHER] Step 3: checking isLocationServiceEnabled (timeout 3s)...');
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('🌤️ [WEATHER] ⚠️ isLocationServiceEnabled TIMED OUT — GPS likely OFF');
          return false;
        });
      } catch (e) {
        debugPrint('🌤️ [WEATHER] ⚠️ isLocationServiceEnabled error: $e');
        serviceEnabled = false;
      }
      debugPrint('🌤️ [WEATHER] Step 3: GPS service enabled=$serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('🌤️ [WEATHER] ❌ GPS OFF — skipping weather (will retry when locationUpdatedCount changes)');
        return;
      }

      debugPrint('🌤️ [WEATHER] Step 4: Requesting GPS position (timeout=10s)...');
      final stopwatch = Stopwatch()..start();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      stopwatch.stop();
      debugPrint('🌤️ [WEATHER] Step 5: GPS position received in ${stopwatch.elapsedMilliseconds}ms: lat=${position.latitude}, lng=${position.longitude}, accuracy=${position.accuracy}m');

      if (!mounted) {
        debugPrint('🌤️ [WEATHER] ❌ Widget not mounted after GPS, skipping');
        return;
      }

      debugPrint('🌤️ [WEATHER] Step 6: Calling weather API...');
      await fetchWeatherByCoordinates(
        position.latitude.toString(),
        position.longitude.toString(),
      );
      debugPrint('🌤️ [WEATHER] Step 7: Done. _weatherFetched=$_weatherFetched, temperature=$temperature');
    } catch (e) {
      debugPrint('🌤️ [WEATHER] ❌ Failed at some step: $e — showing nothing');
    }
  }

  /// 🌤️ Fetch weather — only called with real coordinates, result shown only once
  Future<void> fetchWeatherByCoordinates(String lat, String lon) async {
    try {
      debugPrint('🌤️ [WEATHER] Calling API: lat=$lat, lon=$lon');
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      debugPrint('🌤️ [WEATHER] API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data["main"]["temp"].toStringAsFixed(1);
        final icon = data["weather"][0]["icon"];
        final city = data["name"];
        debugPrint('🌤️ [WEATHER] ✅ Result: city=$city, temp=$temp°C, icon=$icon');
        debugPrint('🌤️ [WEATHER] Setting _weatherFetched=true, showing widget');

        if (mounted) {
          setState(() {
            temperature = temp;
            weatherIconUrl = "https://openweathermap.org/img/wn/$icon@2x.png";
            _weatherFetched = true;
          });
        }
      } else {
        debugPrint('🌤️ [WEATHER] ❌ API failed: ${response.body}');
      }
    } catch (e) {
      debugPrint("🌤️ [WEATHER] ❌ Error: $e");
    }
  }

  final ProfileController profileController = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 0,
      expandedHeight: 160,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
                // Show fallback asset if no banners available
                if (_homeBannerController.bannersTop.isEmpty) {
                  return Image.asset(
                    "assets/images/home_top.png",
                    fit: BoxFit.cover,
                  );
                }

                final imageUrl = _homeBannerController.bannersTop[0].url;
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    // When loading is complete, loadingProgress is null - show the loaded image
                    if (loadingProgress == null) {
                      return child;
                    }
                    // Still loading - show placeholder
                    return Image.asset(
                      "assets/images/home_top.png",
                      fit: BoxFit.cover,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/images/home_top.png",
                      fit: BoxFit.cover,
                    );
                  },
                );
              }),
              FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.only(top: 5, left: 16, right: 16),
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 🌦️ Weather section
                                    if (_weatherFetched &&
                                        temperature != null &&
                                        weatherIconUrl != null)
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Weather icon (from OpenWeatherMap)
                                          InkWell(
                                            onTap: () async {
                                              print(
                                                _homeController
                                                    .selectedCateogryName
                                                    .value,
                                              );
                                              return;
                                            },
                                            child: Image.network(
                                              weatherIconUrl!,
                                              height: 60,
                                              width: 60,
                                              fit: BoxFit.contain,
                                              colorBlendMode:
                                                  BlendMode.modulate,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.cloud, size: 30, color: Colors.white),
                                            ),
                                          ),

                                          // Temperature text overlay
                                          if(_weatherFetched)
                                          Positioned(
                                            bottom: 6,
                                            child: Text(
                                              "$temperature°C",
                                              style: GoogleFonts.roboto(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: const Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                    SizedBox(width: 30,height: 60,)
                                      // InkWell(
                                      //   onTap: () {
                                      //     print('=================');
                                      //     print(
                                      //       'location id = ${_locationController.selectedLocationId}',
                                      //     );
                                      //     print(
                                      //       'category id = ${_homeController.selectedCategoryId.value}',
                                      //     );
                                      //     print(
                                      //       'farmer id = ${_profileController.profile.value?.id.toString() ?? ''}',
                                      //     );
                                      //   },
                                      //   child: Image.asset(
                                      //     'assets/images/wheather.png',
                                      //     height: 60,
                                      //     width: 60,
                                      //   ),
                                      // ),

                                   , const SizedBox(width: 4),
                                    Obx(() {
                                      String? raw = _locationController
                                          .selectedCity
                                          .value;

                                      // Default fallback when null or empty
                                      if (raw.trim().isEmpty) {
                                        raw = "Select Location";
                                      }

                                      // Safe split without crash
                                      List<String> parts = raw
                                          .split(",")
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty)
                                          .toList();
                                      String line1 = parts.isNotEmpty
                                          ? parts[0]
                                          : raw;
                                      String line2 = parts.length > 1
                                          ? parts[1]
                                          : "";

                                      return Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            await Get.to(
                                              () =>
                                                  const LocationSelectionScreen(),
                                            );

                                            //  Safe API call using coordinates for accurate weather
                                            if (_locationController
                                                    .selectedLatiude
                                                    .value
                                                    .isNotEmpty &&
                                                _locationController
                                                    .selectedLongitude
                                                    .value
                                                    .isNotEmpty) {
                                              fetchWeatherByCoordinates(
                                                _locationController
                                                    .selectedLatiude
                                                    .value,
                                                _locationController
                                                    .selectedLongitude
                                                    .value,
                                              );
                                            }
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    color: Colors.black,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 4),

                                                  //  Two line safe text
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          line1,
                                                          style:
                                                              GoogleFonts.roboto(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),

                                                        if (line2.isNotEmpty)
                                                          Text(
                                                            line2,
                                                            style:
                                                                GoogleFonts.roboto(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  OpenContainer(
                                    closedElevation: 0,
                                    openElevation: 0,
                                    closedShape: const CircleBorder(),
                                    transitionDuration: const Duration(
                                      milliseconds: 700,
                                    ),
                                    transitionType:
                                        ContainerTransitionType.fadeThrough,
                                    closedBuilder: (context, action) {
                                      return Image.asset(
                                        'assets/images/lan_image.png',
                                        height: 25,
                                      );
                                    },
                                    openBuilder: (context, action) {
                                      return LanguageSelectionScreen();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  OpenContainer(
                                    closedElevation: 0,
                                    openElevation: 0,
                                    closedShape: const CircleBorder(),
                                    transitionDuration: const Duration(
                                      milliseconds: 700,
                                    ),
                                    transitionType:
                                        ContainerTransitionType.fadeThrough,
                                    closedBuilder: (context, action) {
                                      return Image.asset(
                                        'assets/images/notification.png',
                                        height: 25,
                                      );
                                    },
                                    openBuilder: (context, action) {
                                      return const NotificationsScreen();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  OpenContainer(
                                    closedElevation: 0,
                                    openElevation: 0,
                                    closedShape: const CircleBorder(),
                                    transitionDuration: const Duration(
                                      milliseconds: 700,
                                    ),
                                    transitionType:
                                        ContainerTransitionType.fadeThrough,
                                    closedBuilder: (context, action) {
                                      return Image.asset(
                                        'assets/images/person.png',
                                        height: 25,
                                      );
                                    },
                                    openBuilder: (context, action) {
                                      return const ProfileScreen();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      AnimatedSearchBar(
                        titles: const [
                          'Search "Hatchery Name"',
                          'Search "Category Name"',
                          'Search "Medicine"',
                        ],
                        onMicTap: () {
                          print("Mic tapped");
                          Get.to(() => const SearchScreen());
                        },
                        onTap: () {
                          print("Search tapped");
                          Get.to(() => const SearchScreen());
                        },
                      ),
                      // SizedBox(height: 10)
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 48),
        child: widget.bottom,
      ),
    );
  }
}

Route zoomOutFadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

      return Transform.scale(
        scale: scaleAnimation.value,
        child: FadeTransition(opacity: fadeAnimation, child: child),
      );
    },
  );
}

class AnimatedSearchBar extends StatefulWidget {
  final List<String> titles;
  final VoidCallback? onMicTap;
  final VoidCallback? onTap;

  const AnimatedSearchBar({
    super.key,
    required this.titles,
    this.onMicTap,
    this.onTap,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _outAnimation;
  late Animation<Offset> _inAnimation;

  int _currentIndex = 0;
  int _nextIndex = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _outAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _inAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _controller.forward().then((_) {
        setState(() {
          _currentIndex = _nextIndex;
          _nextIndex = (_nextIndex + 1) % widget.titles.length;
        });
        _controller.reset();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Hero(
        tag: 'homeAppBarSearch',
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),

                const SizedBox(width: 10),

                /// 🔹 Animated Title
                Expanded(
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        SlideTransition(
                          position: _outAnimation,
                          child: Text(
                            widget.titles[_currentIndex],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SlideTransition(
                          position: _inAnimation,
                          child: Text(
                            widget.titles[_nextIndex],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🔹 Vertical Divider
                Container(height: 22, width: 1, color: Colors.grey.shade300),

                const SizedBox(width: 10),

                /// 🔹 Mic Icon
                InkWell(
                  onTap: widget.onMicTap,
                  child: const Icon(Icons.mic, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
