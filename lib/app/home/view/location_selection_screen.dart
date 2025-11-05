import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/map_screen.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  String currentCity = "Add Current Location";
  String currentStreet = "";
  bool isLoading = false;

  final _locationController = Get.put(LocationController());
  final _profileController = Get.put(ProfileController());
  Future<void> _addCorrentLocation() async {
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
      // ignore: deprecated_member_use
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

      _locationController.addAllLocation(
        latitude: position.longitude.toString(),
        longitude: position.latitude.toString(),
        locationName: city,
        farmerId: _profileController.profile.value?.id.toString() ?? '',
      );

      // Get.back(result: {'city': city, 'street': street});
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
    _locationController.getAllLocation();
    print('calling init');
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
              onTap: _addCorrentLocation,
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
            // TextButton(
            //   onPressed: () async {
            //     final position = await Geolocator.getCurrentPosition(
            //       // ignore: deprecated_member_use
            //       desiredAccuracy: LocationAccuracy.high,
            //     );
            //     Get.to(
            //       GoogleMapSearchPlacesScreen(
            //         latitude: position.latitude,
            //         longitude: position.longitude,
            //         ontapSelectLocation: (LatLng latLong) {},
            //       ),
            //     );
            //   },
            //   child: Text('Add Location'),
            // ),
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
            Obx(() {
              if (_locationController.allLocations.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * .2,
                  ),
                  child: Center(
                    child: SizedBox(child: CircularProgressIndicator()),
                  ),
                );
              }
              return Expanded(
                child: ListView.separated(
                  itemCount: _locationController.allLocations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        // final selectedCity =
                        //     _locationController.recentLocations[index];
                        // // Dummy street for demo
                        // final selectedStreet = "Main Road";

                        // Get.back(
                        //   result: {
                        //     'city': selectedCity,
                        //     'street': selectedStreet,
                        //   },
                        // );

                        try{
                          print(_locationController.selectedLocation['id']);
                        print( _locationController.allLocations[index]);
                        }catch(e,s){
                          print(e.toString());
                          print(s.toString());
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            // color:
                            //     _locationController.selectedLocation['id'].toString() ==
                            //         _locationController.allLocations[index]['id'].toString()
                            //     ? Colors.black
                            //     : Colors.transparent,
                          ),
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
                                _locationController.allLocations[index]['location_name'],
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
              );
            }),
          ],
        ),
      ),
    );
  }
}
