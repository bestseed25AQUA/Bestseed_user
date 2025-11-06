import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/filter_bottom_sheet.dart';
import 'package:seedsuser/app/home/view/home_screen.dart';
import 'package:seedsuser/app/home/view/search_screen.dart';
import 'package:seedsuser/app/home/view/location_selection_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';

// ignore: must_be_immutable
class HomeAppBar extends StatefulWidget {
  String currentCity;
  String currentStreet;

  HomeAppBar({
    super.key,
    required this.currentCity,
    required this.currentStreet,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  String? temperature; // 🌡️ Holds temperature value
  String? weatherIconUrl; // ☁️ Holds weather icon

  // 🔑 Replace with your OpenWeatherMap API key
  final String apiKey = "795e8d7e804a07ee8a5b617e45bac8e4";

  @override
  void initState() {
    super.initState();

    // Run after first frame (ensures widget.currentCity is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentCity.isNotEmpty) {
        fetchWeather(widget.currentCity);
      } else {
        print("City name empty — waiting for location selection");
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCity != widget.currentCity &&
        widget.currentCity.isNotEmpty) {
      fetchWeather(widget.currentCity);
    }
  }

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
      print("Weather fetch error: $e");
    }
  }

  final _locationController = Get.put(LocationController());
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      title: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🌦️ Weather section
                    if (temperature != null && weatherIconUrl != null)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Weather icon (from OpenWeatherMap)
                          InkWell(
                            onTap: () {
                              print(_locationController.selectedLatiude.value);
                              print(
                                _locationController.selectedLongitude.value,
                              );
                            },
                            child: Image.network(
                              weatherIconUrl!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.contain,
                              colorBlendMode: BlendMode.modulate,
                            ),
                          ),

                          // Temperature text overlay
                          Positioned(
                            bottom: 6,
                            child: Text(
                              "$temperature°C",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Image.asset(
                        'assets/images/wheather.png',
                        height: 40,
                        width: 47,
                      ),

                    const SizedBox(width: 4),
                    // 📍 Location display
                    Obx(() {
                      return Expanded(
                        child: InkWell(
                          onTap: () async {
                            final result = await Get.to(
                              () => const LocationSelectionScreen(),
                            );

                            // if (result != null) {
                            //   setState(() {
                            //     widget.currentCity = result['city'];
                            //     widget.currentStreet = result['street'];
                            //   });

                            // }
                            fetchWeather(
                              _locationController.selectedCity.value,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _locationController.selectedCity.value,
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                // widget.currentStreet.isNotEmpty
                                //     ? widget.currentStreet
                                //     : "Fetching current area...",
                                _locationController.selectedStreet.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
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
                  InkWell(
                    onTap: () => Get.to(() => LanguageSelectionScreen()),
                    child: Image.asset(
                      'assets/images/lan_image.png',
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => Get.to(() => const NotificationsScreen()),
                    child: Image.asset(
                      'assets/images/notification.png',
                      height: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => Get.to(() => const ProfileScreen()),
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
              child: _buildSearchBar(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              readOnly: true,
              onTap: () => Get.to(() => const SearchScreen()),
              decoration: InputDecoration(
                hintText: 'Search for Hatcheries, locations, seeds',
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showFilterBottomSheet(context),
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterBottomSheet(),
    );
  }
}
