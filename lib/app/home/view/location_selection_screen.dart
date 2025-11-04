import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  String currentCity = "Use Current Location";
  String currentStreet = "";
  bool isLoading = false;

  List<String> recentLocations = [
    // "Chennai, Tamil Nadu",
    // "Hyderabad, Telangana",
    // "Bangalore, Karnataka",
    // "Coimbatore, Tamil Nadu",
    // "Madurai, Tamil Nadu",
  ];

  /// ✅ Get Current Location and return both City + Street
  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      currentCity = "Fetching location...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentCity = "Location disabled";
        isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentCity = "Permission denied";
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentCity = "Permission permanently denied";
        isLoading = false;
      });
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final city =
          place.subLocality ?? place.subAdministrativeArea ?? "Unknown";
      final street =
          "${place.street ?? ""} ${place.locality ?? ""}, ${place.administrativeArea ?? ""}, ${place.country ?? ""}";

      setState(() {
        currentCity = city;
        currentStreet = street;
        isLoading = false;
      });

      Get.back(result: {'city': city, 'street': street});
    } else {
      setState(() {
        currentCity = "Unable to fetch location";
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('calling init');
    getAllLocation();
  }

  bool allLocationLoading = true;
  Future<void> getAllLocation() async {

    try {
      
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/locations/all",
        headers: await buildHeader(),
      );
      print('============');
      print("${NetworkConfig.baseURL}/farmer/locations/all");
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          recentLocations = List.generate(
            data['locations'].length,
            (index) => data['locations'][index]['location_name'].toString(),
          );
        } catch (e) {
          print(e.toString());
        }

        print('========all locaitons=======');
        print(data.toString());
      } else {
        print('else error');
      }
    } catch (e, s) {
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      allLocationLoading = false;
      setState(() {
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Select Location",
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 📍 Use Current Location
            InkWell(
              onTap: _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      const Icon(Icons.my_location, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentCity,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Locations",
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // 🏙️ List of Recent Locations
            if(recentLocations.isEmpty)Padding(
              padding:  EdgeInsets.only(top: MediaQuery.of(context).size.height*.2),
              child: Center(
                child: SizedBox(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
            else
            Expanded(
              child: ListView.separated(
                itemCount: recentLocations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      final selectedCity = recentLocations[index];
                      // Dummy street for demo
                      final selectedStreet = "Main Road";

                      Get.back(
                        result: {
                          'city': selectedCity,
                          'street': selectedStreet,
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recentLocations[index],
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
