import 'dart:async';
import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
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

class _HomeAppBarState extends State<HomeAppBar> {
  String? temperature;
  String? weatherIconUrl;
  final String apiKey = "795e8d7e804a07ee8a5b617e45bac8e4";

  final _locationController = Get.find<LocationController>();
  final _homeController = Get.find<HomeController>();
  final _homeBannerController = Get.put(HomeBannerController());
  final _profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();

    // Listen for location changes
    ever(_locationController.selectedCity, (city) {
      if (city.isNotEmpty) {
        fetchWeather(city);
      }
    });

    // Fetch weather for current city if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_locationController.selectedCity.value.isNotEmpty) {
        fetchWeather(_locationController.selectedCity.value);
      }
    });
  }

  // Remove didUpdateWidget since we're not using widget parameters anymore

  /// 🌤️ Fetch weather based on city name
  Future<void> fetchWeather(String cityName) async {
    print('===========fetchWeather==========');
    print(cityName);
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data["main"]["temp"].toStringAsFixed(1);
        final icon = data["weather"][0]["icon"];

        setState(() {
          temperature = temp;
          weatherIconUrl = "https://openweathermap.org/img/wn/$icon@2x.png";
        });
      } else {
        print("Weather fetch failed: ${response.body}");
      }
    } catch (e) {
      print("Weather fetch error  ");
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
      // backgroundColor: AppColors.primary,
      backgroundColor: Colors.transparent,

      // bottom: PreferredSize(`      //   preferredSize: Size(double.infinity, 100),
      //   child: Container(
      //     color: Colors.black
      //   ),
      // ),
      // title: Column(
      //   children: [
      //     const SizedBox(height: 12),
      //     Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //       children: [
      //         Expanded(
      //           child: Row(
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: [
      //               // 🌦️ Weather section
      //               if (temperature != null && weatherIconUrl != null)
      //                 Stack(
      //                   alignment: Alignment.center,
      //                   children: [
      //                     // Weather icon (from OpenWeatherMap)
      //                     InkWell(
      //                       onTap: () async {
      //                         print(_homeController.selectedCateogryName.value);
      //                         return;
      //                         print(_locationController.selectedLocationId);
      //                         print(_locationController.selectedLatiude.value);
      //                         final _hatcheryController = Get.put(
      //                           HatcheryUpdatesController(),
      //                         );
      //                         return;
      //                         await _hatcheryController.fetchHatcheryHomeUpdate(
      //                           // categoryId: categoryId,
      //                           // locationId: locationId
      //                           categoryId: '25',
      //                           locationId: '191',
      //                         );
      //                         // print(
      //                         //   _locationController.selectedLongitude.value,
      //                         // );
      //                         // _locationController.fetchDefaultLocation( profileController.profile.value?.id.toString() ?? '',);
      //                       },
      //                       child: Image.network(
      //                         weatherIconUrl!,
      //                         height: 60,
      //                         width: 60,
      //                         fit: BoxFit.contain,
      //                         colorBlendMode: BlendMode.modulate,
      //                       ),
      //                     ),

      //                     // Temperature text overlay
      //                     Positioned(
      //                       bottom: 6,
      //                       child: Text(
      //                         "$temperature°C",
      //                         style: GoogleFonts.roboto(
      //                           color: Colors.black,
      //                           fontSize: 14,
      //                           fontWeight: FontWeight.bold,
      //                           shadows: [
      //                             Shadow(
      //                               blurRadius: 4,
      //                               color: Colors.black.withOpacity(0.3),
      //                               offset: const Offset(1, 1),
      //                             ),
      //                           ],
      //                         ),
      //                       ),
      //                     ),
      //                   ],
      //                 )
      //               else
      //                 InkWell(
      //                   onTap: () {
      //                     print('=================');
      //                     print(
      //                       'location id = ${_locationController.selectedLocationId}',
      //                     );
      //                     print(
      //                       'category id = ${_homeController.selectedCategoryId.value}',
      //                     );
      //                     print(
      //                       'farmer id = ${_profileController.profile.value?.id.toString() ?? ''}',
      //                     );
      //                   },
      //                   child: Image.asset(
      //                     'assets/images/wheather.png',
      //                     height: 40,
      //                     width: 47,
      //                   ),
      //                 ),

      //               const SizedBox(width: 4),
      //               Obx(() {
      //                 String? raw = _locationController.selectedCity.value;

      //                 // Default fallback when null or empty
      //                 if (raw == null || raw.trim().isEmpty) {
      //                   raw = "Select Location";
      //                 }

      //                 // Safe split without crash
      //                 List<String> parts = raw
      //                     .split(",")
      //                     .map((e) => e.trim())
      //                     .where((e) => e.isNotEmpty)
      //                     .toList();
      //                 String line1 = parts.isNotEmpty ? parts[0] : raw;
      //                 String line2 = parts.length > 1 ? parts[1] : "";

      //                 return Expanded(
      //                   child: InkWell(
      //                     onTap: () async {
      //                       await Get.to(() => const LocationSelectionScreen());

      //                       //  Safe API call
      //                       if (_locationController.selectedCity.value
      //                           .trim()
      //                           .isNotEmpty) {
      //                         fetchWeather(
      //                           _locationController.selectedCity.value,
      //                         );
      //                       }
      //                     },
      //                     child: Column(
      //                       crossAxisAlignment: CrossAxisAlignment.start,
      //                       children: [
      //                         Row(
      //                           children: [
      //                             const Icon(
      //                               Icons.location_on_outlined,
      //                               color: Colors.black,
      //                               size: 15,
      //                             ),
      //                             const SizedBox(width: 4),

      //                             //  Two line safe text
      //                             Expanded(
      //                               child: Column(
      //                                 crossAxisAlignment:
      //                                     CrossAxisAlignment.start,
      //                                 children: [
      //                                   Text(
      //                                     line1,
      //                                     style: GoogleFonts.roboto(
      //                                       color: Colors.black,
      //                                       fontSize: 16,
      //                                       fontWeight: FontWeight.bold,
      //                                     ),
      //                                     maxLines: 1,
      //                                     overflow: TextOverflow.ellipsis,
      //                                   ),

      //                                   if (line2.isNotEmpty)
      //                                     Text(
      //                                       line2,
      //                                       style: GoogleFonts.roboto(
      //                                         color: Colors.black,
      //                                         fontSize: 14,
      //                                         fontWeight: FontWeight.w500,
      //                                       ),
      //                                       maxLines: 1,
      //                                       overflow: TextOverflow.ellipsis,
      //                                     ),
      //                                 ],
      //                               ),
      //                             ),
      //                           ],
      //                         ),
      //                       ],
      //                     ),
      //                   ),
      //                 );
      //               }),
      //             ],
      //           ),
      //         ),
      //         Row(
      //           children: [
      //             InkWell(
      //               onTap: () => Get.to(() => LanguageSelectionScreen()),
      //               child: Image.asset(
      //                 'assets/images/lan_image.png',
      //                 height: 32,
      //               ),
      //             ),
      //             const SizedBox(width: 16),
      //             InkWell(
      //               onTap: () => Get.to(() => const NotificationsScreen()),
      //               child: Image.asset(
      //                 'assets/images/notification.png',
      //                 height: 32,
      //               ),
      //             ),
      //             const SizedBox(width: 16),
      //             InkWell(
      //               onTap: () => Get.to(() => const ProfileScreen()),
      //               child: Image.asset('assets/images/person.png', height: 32),
      //             ),
      //             const SizedBox(width: 16),
      //           ],
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // final maxHeight = constraints.biggest.height;
          return Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
                String image = _homeBannerController.bannersTop.isEmpty
                    ? ''
                    : _homeBannerController.bannersTop[0].url;
                return Image.network(
                  _homeBannerController.bannersTop.isEmpty ? image : image,
                  // _homeBannerController.bannersTop.isEmpty
                  //     ? ''
                  //     : _homeBannerController.bannersTop[0].url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    return Image.asset(
                      "assets/images/home_top.png",
                      fit: BoxFit.cover,
                    );
                  },
                  errorBuilder: (context, child, loadingProgress) {
                    return Image.asset(
                      "assets/images/home_top.png",
                      fit: BoxFit.cover,
                    );
                  },
                );
              }),
              // Image.asset("assets/images/home_top.png", fit: BoxFit.cover),
              FlexibleSpaceBar(
                // titlePadding: EdgeInsets.only(top: 100),
                // title: widget.bottom,
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
                                    if (temperature != null &&
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
                                              // print(
                                              //   _locationController
                                              //       .selectedLocationId,
                                              // );
                                              // print(
                                              //   _locationController
                                              //       .selectedLatiude
                                              //       .value,
                                              // );
                                              // final _hatcheryController =
                                              //     Get.put(
                                              //       HatcheryUpdatesController(),
                                              //     );
                                              // return;
                                              // await _hatcheryController
                                              //     .fetchHatcheryHomeUpdate(
                                              //       // categoryId: categoryId,
                                              //       // locationId: locationId
                                              //       categoryId: '25',
                                              //       locationId: '191',
                                              //     );
                                              // print(
                                              //   _locationController.selectedLongitude.value,
                                              // );
                                              // _locationController.fetchDefaultLocation( profileController.profile.value?.id.toString() ?? '',);
                                            },
                                            child: Image.network(
                                              weatherIconUrl!,
                                              height: 60,
                                              width: 60,
                                              fit: BoxFit.contain,
                                              colorBlendMode:
                                                  BlendMode.modulate,
                                            ),
                                          ),

                                          // Temperature text overlay
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
                                      InkWell(
                                        onTap: () {
                                          print('=================');
                                          print(
                                            'location id = ${_locationController.selectedLocationId}',
                                          );
                                          print(
                                            'category id = ${_homeController.selectedCategoryId.value}',
                                          );
                                          print(
                                            'farmer id = ${_profileController.profile.value?.id.toString() ?? ''}',
                                          );
                                        },
                                        child: Image.asset(
                                          'assets/images/wheather.png',
                                          height: 40,
                                          width: 47,
                                        ),
                                      ),

                                    const SizedBox(width: 4),
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

                                            //  Safe API call
                                            if (_locationController
                                                .selectedCity
                                                .value
                                                .trim()
                                                .isNotEmpty) {
                                              fetchWeather(
                                                _locationController
                                                    .selectedCity
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
                                  // InkWell(
                                  //   onTap: () {
                                  //     Navigator.push(
                                  //       context,
                                  //       AppAnimations.circularRevealRoute(
                                  //         const ProfileScreen(),
                                  //         center: Alignment.topCenter,
                                  //       ),
                                  //     );
                                  //   },
                                  //   child: Image.asset(
                                  //     'assets/images/person.png',
                                  //     height: 32,
                                  //   ),
                                  // ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      // _buildSearchBar(context),
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
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Opacity(
              //     // hide smoothly when collapsing
              //     opacity: (maxHeight - kToolbarHeight) / (maxHeight),
              //     child: Padding(
              //       padding: const EdgeInsets.only(
              //         left: 16,
              //         right: 16,
              //         bottom: 8,
              //       ),
              //       child: _buildSearchBar(context),
              //     ),
              //   ),
              // ),
            ],
          );
        },
      ),

      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 48),
        child: widget.bottom,
        //  Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [widget.bottom, SizedBox(height: 00)]),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: Hero(
              tag: 'homeAppBarSearch',
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    Navigator.push(context, zoomOutFadeRoute(SearchScreen()));
                  },
                  decoration: InputDecoration(
                    // hintText: 'Search for Hatcheries, locations, seeds',
                    hintText: 'Search for Hatcher...',
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    contentPadding: EdgeInsets.only(bottom: 20),
                    suffixIcon: Icon(Icons.mic, color: AppColors.primary),
                    // suffix: Column(
                    //   children: [
                    //     SizedBox(height: 00,),
                    //     Padding(
                    //       padding: const EdgeInsets.only(top: 0),
                    //       child: Icon(Icons.mic,color: AppColors.primary),
                    //     ),

                    //     SizedBox(height: 10,),
                    //   ],
                    // ),
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          // onTap: () => _showFilterBottomSheet(context),
          onTap: () => Get.to(() => const SearchScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(child: const Icon(Icons.tune, color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}

Route zoomOutFadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      // Zoom out (scale from 0.8 → 1.0)
      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      // Fade animation (0 → 1)
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
