import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void showDeleteConfirmation(String locationId) {
    Get.dialog(
      AlertDialog(
        title: Text("Delete Location"),
        content: Text("Are you sure you want to remove this location?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Get.back();
              _locationController.deleteLocation(locationId);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _locationController.getAllLocation();
  }

  TextEditingController textEditingController = TextEditingController();
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
        final list = _locationController.isSearching.value
            ? _locationController.searchedLocations
            : _locationController.allLocations;

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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

                  final locationName =
                      (placemarks.first.subLocality ?? "Unknown") +
                      ', ' +
                      (placemarks.first.locality ?? "Unknown");
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

                  Map response = await _locationController.addLocation(
                    latitude: position.latitude.toString(),
                    longitude: position.longitude.toString(),
                    locationName:
                        '${place.subLocality ?? ''}, ${place.locality ?? ''}',
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
              padding: const EdgeInsets.all(8.0),
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
                    currentPosition = await getCurrentLocation();
                  }
                  if(currentPosition?.latitude != null && currentPosition?.longitude != null) {
                    await Get.to(
                    () => GoogleMapSearchPlacesScreen(
                      latitude: currentPosition!.latitude,
                      longitude: currentPosition!.longitude,
                      ontapSelectLocation: (location) async {
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                              location.latitude,
                              location.longitude,
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
                        Map response = await _locationController.addLocation(
                          latitude: location.latitude.toString(),
                          longitude: location.longitude.toString(),
                          locationName:
                              '${place.subLocality ?? ''}, ${place.locality ?? ''}',
                          fullAddress: fullAddress,
                          farmerId:
                              _profileController.profile.value?.id.toString() ??
                              "",
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

                        setState(() {
                          addLocationLoading = false;
                        });
                        Get.back();
                        // await _locationController.getAllLocation();
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
                            :( addLocationLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.add_location, color: Colors.white)),
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
            Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 43,
                child: TextField(
                  controller: textEditingController,
                  onChanged: (v) => _locationController.searchLocation(v),
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                      onTap: () {
                        textEditingController.clear();
                        _locationController.isSearching.value = false;
                        _locationController.searchedLocations.clear();
                      },
                      child: Icon(Icons.close),
                    ),
                    hintText: "Search location...",
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _locationController.allLocationLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : list.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * .2,
                      ),
                      child: Text('Location not found'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(top: 0, bottom: 30),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final item = list[i];
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: item["is_default"] == true
                                ? Border.all(color: AppColors.primary, width: 2)
                                : Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: item["is_default"] == 1
                                ? AppColors.primary.withOpacity(.1)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              _locationController.selectedCity.value =
                                  item["title"]?.toString() ?? '';
                              _locationController.selectedLocationId.value =
                                  item["id"]?.toString() ?? '';
                              _homeController.changeHomeData(
                                _homeController.selectedCategoryId.value,
                                _locationController.selectedLocationId.value,
                              );
                              Get.back();
                            },
                            onLongPress: () {
                              _locationController.setDefaultLocation(
                                item["id"].toString(),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item["subtitle"].toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      Get.to(
                                        () => GoogleMapSearchPlacesScreen(
                                          latitude: double.parse(
                                            item["latitude"],
                                          ),
                                          longitude: double.parse(
                                            item["longitude"],
                                          ),
                                          ontapSelectLocation: (location) async {
                                            List<Placemark> placemarks =
                                                await placemarkFromCoordinates(
                                                  location.latitude,
                                                  location.longitude,
                                                );
                                            Placemark place = placemarks.first;
                                            String fullAddress =
                                                "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
                                            fullAddress = fullAddress
                                                .replaceAll(RegExp(r', ,'), ',')
                                                .replaceAll(RegExp(r',,'), ',')
                                                .trim();
                                            if (fullAddress.endsWith(',')) {
                                              fullAddress = fullAddress
                                                  .substring(
                                                    0,
                                                    fullAddress.length - 1,
                                                  );
                                            }
                                            await _locationController
                                                .updateLocation(
                                                  fullAddress: fullAddress,
                                                  id: item["id"].toString(),
                                                  latitude: location.latitude
                                                      .toString(),
                                                  longitude: location.longitude
                                                      .toString(),
                                                  locationName:
                                                      '${placemarks.first.subLocality ?? "Unknown"}, ${placemarks.first.locality ?? "Unknown"}',
                                                );
                                            await _locationController
                                                .getAllLocation();
                                          },
                                        ),
                                      );
                                    },

                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 1,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // IconButton(
                                  // icon: Icon(
                                  //   Icons.star,
                                  //   color: item["is_default"] == 1
                                  //     ? Colors.orange
                                  //     : Colors.grey,
                                  //   size: 20,
                                  // ),
                                  // onPressed: () => _locationController
                                  //   .setDefaultLocation(item["id"].toString()),
                                  // ),
                                  InkWell(
                                    onTap: () {
                                      showDeleteConfirmation(
                                        item["id"].toString(),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 1,
                                          color: Colors.red,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
