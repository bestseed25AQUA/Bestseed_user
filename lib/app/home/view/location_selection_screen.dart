import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  bool isLoading = false;

  final _locationController = Get.put(LocationController());
  final _profileController = Get.put(ProfileController());
  final _homeController = Get.put(HomeController());

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CustomToast.show(message: 'location is not enabled');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomToast.show(message: 'Permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      CustomToast.show(message: 'Permission Permanently denied');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('====current location get successfully=======');
    return position;
  }

  Future<void> _addCurrentLocation() async {
    setState(() => isLoading = true);

    Position position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks.first;
    String fullAddress =
        "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
    fullAddress = fullAddress
        .replaceAll(RegExp(r', ,'), ',')
        .replaceAll(RegExp(r',,'), ',')
        .trim();
    if (fullAddress.endsWith(',')) {
      fullAddress = fullAddress.substring(0, fullAddress.length - 1);
    }
    setState(() {
      addLocationLoading = true;
    });
    final city = placemarks.first.locality ?? "Unknown";

    await _locationController.addLocation(
      latitude: position.latitude.toString(),
      longitude: position.longitude.toString(),
      locationName: city,
      farmerId: _profileController.profile.value?.id.toString() ?? "",
      fullAddress: fullAddress,
    );

    Get.back(result: city);
    setState(() => isLoading = false);
  }

  Position? currentPosition;
  bool addLocationLoading = false;
  bool isCurrentLocationLoading = false;

  getCurrentLocation() async {
    currentPosition = await _getCurrentLocation();
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text("Select Location"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Obx(() {
        return Column(
          children: [
            SizedBox(height: 16),

            // InkWell(
            //   onTap: isLoading ? null : _addCurrentLocation,
            //   child: ListTile(
            //     leading: isLoading
            //         ? CircularProgressIndicator(strokeWidth: 2)
            //         : Icon(Icons.my_location, color: AppColors.primary),
            //     title: Text("Fetch Current Location"),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: InkWell(
                onTap: () async {
                  if (isCurrentLocationLoading) return;

                  setState(() => isCurrentLocationLoading = true);

                  Position? position = await _getCurrentLocation();
                  if (position == null) {
                    setState(() => isCurrentLocationLoading = false);
                    return;
                  }

                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    position.latitude,
                    position.longitude,
                  );

                  Placemark place = placemarks.first;
                  String fullAddress =
                      "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
                  fullAddress = fullAddress
                      .replaceAll(RegExp(r', ,'), ',')
                      .replaceAll(RegExp(r',,'), ',')
                      .trim();
                  if (fullAddress.endsWith(',')) {
                    fullAddress = fullAddress.substring(
                      0,
                      fullAddress.length - 1,
                    );
                  }
                  setState(() {
                    addLocationLoading = true;
                  });

                  // Build location name with proper context
                  List<String> locationParts = [];
                  if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                    locationParts.add(place.subLocality!);
                  }
                  if (place.locality != null && place.locality!.isNotEmpty) {
                    locationParts.add(place.locality!);
                  }
                  if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                    locationParts.add(place.administrativeArea!);
                  }
                  String locationName = locationParts.toSet().join(', ');
                  if (locationName.startsWith(', ')) {
                    locationName = locationName.substring(2);
                  }

                  Map response = await _locationController.addLocation(
                    latitude: position.latitude.toString(),
                    longitude: position.longitude.toString(),
                    locationName: locationName,
                    fullAddress: fullAddress,
                    farmerId:
                        _profileController.profile.value?.id.toString() ?? "",
                  );
                  // Map response = {
                  //   "status": true,
                  //   "message": "Location added successfully",
                  //   "data": {
                  //     "id": 95,
                  //     "title": "Andhra Pradesh",
                  //     "subtitle": "Andhra Pradesh, India",
                  //     "latitude": 15.9129,
                  //     "longitude": 79.74,
                  //     "is_default": false,
                  //   },
                  // };
                  print('==============done===================');
                  print('after fetch succssfully');
                  try {
                    _locationController.selectedLocationId.value =
                        response['data']["id"]?.toString() ?? '';
                    print(_locationController.selectedLocationId.value);
                    _locationController.selectedCity.value =
                        response['data']["title"]?.toString() ?? '';
                    // Update coordinates for accurate weather
                    _locationController.selectedLatiude.value =
                        position.latitude.toString();
                    _locationController.selectedLongitude.value =
                        position.longitude.toString();

                    print('location selected successfully');
                    print(_locationController.selectedCity.value);
                  } catch (e) {
                    print('error at select');
                    print(e.toString());
                  }
                  _homeController.changeHomeData(
                    _homeController.selectedCategoryId.value,
                    _locationController.selectedLocationId.value,
                  );

                  setState(() => isCurrentLocationLoading = false);
                  Get.back();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  // height: 50,width: 50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 9,
                    ),
                    child: Row(
                      children: [
                        isCurrentLocationLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(Icons.my_location, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text(
                          "Use Current Location",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                onTap: () async {
                  print(currentPosition?.latitude);
                  print(currentPosition?.longitude);
                  if (addLocationLoading) {
                    return;
                  }
                  // return;
                  if (currentPosition == null ||
                      currentPosition?.latitude == null ||
                      currentPosition?.longitude == null) {
                    setState(() => addLocationLoading = true);
                    currentPosition = await _getCurrentLocation();
                    setState(() => addLocationLoading = false);
                  }

                  if (currentPosition == null) {
                    CustomToast.show(
                      message: 'Unable to fetch current location',
                    );
                    return;
                  }

                  if (currentPosition?.latitude != null &&
                      currentPosition?.longitude != null) {
                    await Get.to(
                      () => GoogleMapSearchPlacesScreen(
                        latitude: currentPosition!.latitude,
                        longitude: currentPosition!.longitude,
                        ontapSelectLocation: (location, fullAddress) async {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                                location.latitude,
                                location.longitude,
                              );
                          Placemark place = placemarks.first;
                          List<String> parts = [];

                          if (place.name != null && place.name!.isNotEmpty) {
                            parts.add(place.name!);
                          }

                          if (place.street != null &&
                              place.street!.isNotEmpty &&
                              place.street != place.name) {
                            parts.add(place.street!);
                          }

                          if (place.subLocality != null &&
                              place.subLocality!.isNotEmpty) {
                            parts.add(place.subLocality!);
                          }

                          if (place.locality != null &&
                              place.locality!.isNotEmpty) {
                            parts.add(place.locality!);
                          }

                          if (place.subAdministrativeArea != null &&
                              place.subAdministrativeArea!.isNotEmpty) {
                            parts.add(place.subAdministrativeArea!);
                          }

                          if (place.administrativeArea != null &&
                              place.administrativeArea!.isNotEmpty) {
                            parts.add(place.administrativeArea!);
                          }

                          if (place.postalCode != null &&
                              place.postalCode!.isNotEmpty) {
                            parts.add(place.postalCode!);
                          }

                          if (place.country != null &&
                              place.country!.isNotEmpty) {
                            parts.add(place.country!);
                          }

                          String fullAddress = parts.toSet().join(', ');

                          fullAddress = fullAddress
                              .replaceAll(RegExp(r', ,'), ',')
                              .replaceAll(RegExp(r',,'), ',')
                              .trim();
                          if (fullAddress.endsWith(',')) {
                            fullAddress = fullAddress.substring(
                              0,
                              fullAddress.length - 1,
                            );
                          }
                          setState(() {
                            addLocationLoading = true;
                          });

                          // Build location name with proper context
                          List<String> locationParts = [];
                          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                            locationParts.add(place.subLocality!);
                          }
                          if (place.locality != null && place.locality!.isNotEmpty) {
                            locationParts.add(place.locality!);
                          }
                          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                            locationParts.add(place.administrativeArea!);
                          }
                          String locationName = locationParts.toSet().join(', ');
                          if (locationName.startsWith(', ')) {
                            locationName = locationName.substring(2);
                          }

                          Map response = await _locationController.addLocation(
                            latitude: location.latitude.toString(),
                            longitude: location.longitude.toString(),
                            locationName: locationName,
                            fullAddress: fullAddress,
                            farmerId:
                                _profileController.profile.value?.id
                                    .toString() ??
                                "",
                          );
                          try {
                            _locationController.selectedLocationId.value =
                                response['data']["id"]?.toString() ?? '';
                            _locationController.selectedCity.value =
                                response['data']["title"]?.toString() ?? '';
                            // Update coordinates for accurate weather
                            _locationController.selectedLatiude.value =
                                location.latitude.toString();
                            _locationController.selectedLongitude.value =
                                location.longitude.toString();
                          } catch (e) {
                            print(e.toString());
                          }
                          _homeController.changeHomeData(
                            _homeController.selectedCategoryId.value,
                            _locationController.selectedLocationId.value,
                          );

                          setState(() {
                            addLocationLoading = false;
                          });
                          Get.back();
                        },
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.2),
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 9,
                    ),
                    child: Row(
                      children: [
                        isCurrentLocationLoading
                            ? Icon(Icons.add_location, color: Colors.white)
                            : (addLocationLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_location,
                                      color: Colors.white,
                                    )),
                        SizedBox(width: 10),
                        Text(
                          "Add New Location",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Show current selected location if available
            if (_locationController.selectedCity.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Current Location",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _locationController.selectedCity.value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
