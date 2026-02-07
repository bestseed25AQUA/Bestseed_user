import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class GoogleMapSearchPlacesScreen extends StatefulWidget {
  const GoogleMapSearchPlacesScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.ontapSelectLocation,
  });

  final double latitude;
  final double longitude;
  final Function(LatLng latLong, String fullAddress) ontapSelectLocation;
  @override
  // ignore: library_private_types_in_public_api
  _GoogleMapSearchPlacesScreenState createState() =>
      _GoogleMapSearchPlacesScreenState();
}

class _GoogleMapSearchPlacesScreenState
    extends State<GoogleMapSearchPlacesScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  var uuid = const Uuid();
  String _sessionToken = '';
  List<dynamic> _placeList = [];
  Timer? _debounce;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.latitude, widget.longitude);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _onChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => _placeList.clear());
      return;
    }
    // Debounce: wait 400ms after user stops typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      getSuggestion(value);
    });
  }

  void getSuggestion(String input) async {
    if (_sessionToken == '') {
      _sessionToken = uuid.v4();
    }
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=${NetworkConfig.googleApiKey2}&sessiontoken=$_sessionToken';
      print('url+++++++++++++++++++');
      print(request);
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);
      if (kDebugMode) {
        print('mydata');
        print(data);
      }
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>> getLatLng(String placeId) async {
    final apiKey = 'AIzaSyAAzpePCxZ8fp-habEMV2EcXfd9mU-vDRM';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final latLng = data['result']['geometry']['location'];
        final double latitude = latLng['lat'];
        final double longitude = latLng['lng'];
        return {'latitude': latitude, 'longitude': longitude};
      } else {
        throw Exception('Failed to fetch place details');
      }
    } else {
      throw Exception('Failed to load place details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.latitude,
                  widget.longitude,
                ), // Default to San Francisco's coordinates
                zoom: 12.0,
              ),
              onTap: (LatLng location) {
                _addMarker(location);
              },
              markers: _selectedLocation == null
                  ? Set<Marker>()
                  : {
                      Marker(
                        markerId: MarkerId("SelectedLocation"),
                        position: _selectedLocation!,
                        infoWindow: InfoWindow(title: "Selected Location"),
                      ),
                    },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(top: 18, left: 18, right: 18),
                  child: Builder(
                    builder: (context) {
                      double radius = 30;
                      Color borderColor = Colors.white;
                      return Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.transparent.withOpacity(.53),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            focusNode: _focusNode,
                            onChanged: (value) {
                              _onChanged(value);
                            },
                            controller: _textController,
                            onTapOutside: (event) {
                              _focusNode.unfocus();
                            },

                            decoration: InputDecoration(
                              fillColor: AppColors.primary.withOpacity(1),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radius),
                                borderSide: BorderSide(
                                  width: 1,
                                  color: borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radius),
                                borderSide: BorderSide(
                                  width: 1,
                                  color: borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(radius),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: borderColor,
                                ),
                              ),
                              hintText: "Search your location here",
                              hintStyle: TextStyle(color: Colors.white),
                              focusColor: Colors.white,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _textController.clear();
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_placeList.isNotEmpty && _textController.text.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _placeList.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () async {
                                  final description = _placeList[index]["description"];
                                  final placeId = _placeList[index]['place_id'];
                                  _textController.text = description;
                                  _focusNode.unfocus();
                                  setState(() => _placeList.clear());

                                  Map<String, dynamic> data = await getLatLng(placeId);
                                  var latLng = getLatLongFromMap(data);
                                  _addMarkerAnimateCameraPosition(latLng);
                                  _selectedLocation = latLng;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: .1,
                                      color: AppColors.primary,
                                    ),
                                  ),

                                  child: ListTile(
                                    title: Text(
                                      _placeList[index]["description"],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(AppColors.primary),
                ),
                onPressed: _isConfirming
                    ? null
                    : () async {
                        if (_selectedLocation == null) return;

                        setState(() => _isConfirming = true);

                        try {
                          List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            _selectedLocation!.latitude,
                            _selectedLocation!.longitude,
                          );
                          Placemark place = placemarks.first;

                          // Build full address with all available components
                          List<String> addressParts = [];

                          if (place.name != null &&
                              place.name!.isNotEmpty &&
                              place.name != place.subLocality) {
                            addressParts.add(place.name!);
                          }
                          if (place.street != null &&
                              place.street!.isNotEmpty &&
                              place.street != place.name) {
                            addressParts.add(place.street!);
                          }
                          if (place.subLocality != null &&
                              place.subLocality!.isNotEmpty) {
                            addressParts.add(place.subLocality!);
                          }
                          if (place.locality != null &&
                              place.locality!.isNotEmpty) {
                            addressParts.add(place.locality!);
                          }
                          if (place.subAdministrativeArea != null &&
                              place.subAdministrativeArea!.isNotEmpty) {
                            addressParts.add(place.subAdministrativeArea!);
                          }
                          if (place.administrativeArea != null &&
                              place.administrativeArea!.isNotEmpty) {
                            addressParts.add(place.administrativeArea!);
                          }
                          if (place.postalCode != null &&
                              place.postalCode!.isNotEmpty) {
                            addressParts.add(place.postalCode!);
                          }
                          if (place.country != null &&
                              place.country!.isNotEmpty) {
                            addressParts.add(place.country!);
                          }

                          // Remove duplicates while preserving order
                          List<String> uniqueParts = [];
                          for (var part in addressParts) {
                            if (!uniqueParts.contains(part)) {
                              uniqueParts.add(part);
                            }
                          }

                          String fullAddress = uniqueParts.join(', ');

                          if (!mounted) return;
                          setState(() => _isConfirming = false);

                          final selectedLoc = _selectedLocation!;

                          showSelectedLocationPopup(
                            location: fullAddress,
                            onConfirm: () {
                              widget.ontapSelectLocation(
                                  selectedLoc, fullAddress);
                              Navigator.of(context).pop(true);
                            },
                          );
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isConfirming = false);
                          }
                          print('Error getting address: $e');
                        }
                      },
                child: Row(
                  children: [
                    if (_isConfirming)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      _isConfirming ? 'Loading...' : 'Confirm Location',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSelectedLocationPopup({
    required String location,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(18),
              title: const Center(
                child: Text(
                  "Selected Location",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              content: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // Close dialog first, then wait for it to finish before popping map
                      Navigator.pop(dialogContext);
                      // Use a short delay to let dialog animation complete
                      Future.delayed(const Duration(milliseconds: 150), () {
                        onConfirm();
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Add Location",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.add_location_alt_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              top:
                  MediaQuery.of(dialogContext).size.height *
                  0.27,
              right: 35,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 22, color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _addMarkerAnimateCameraPosition(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 10.0),
      ),
    );
  }
}

LatLng getLatLongFromMap(Map<String, dynamic> coordinates) {
  double latitude = coordinates['latitude'] ?? 0.0;
  double longitude = coordinates['longitude'] ?? 0.0;

  print('Latitude: $latitude, Longitude: $longitude');
  return LatLng(latitude, longitude);
}

Future<String> getAddress(LatLng latLong) async {
  String address = '';
  await placemarkFromCoordinates(latLong.latitude, latLong.longitude)
      .then((placemarks) {
        print('getted address');
        int index = placemarks.length - 1;
        print(placemarks[index].toString());
        String street = placemarks[index].street ?? '';
        String subLocality = placemarks[index].subLocality ?? '';
        String subAdministrativeArea =
            placemarks[index].subAdministrativeArea ?? '';
        String administrativeArea = placemarks[index].administrativeArea ?? '';
        String postalCode = placemarks[index].postalCode ?? '';
        print('returning address');
        address =
            "$street, $subLocality, $subAdministrativeArea, $administrativeArea, $postalCode";
      })
      .onError((error, stackTrace) {
        print('=================return  no');
      });
  print('=================return  no');
  return address;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Radius of the earth in kilometers

  // Convert degrees to radians
  double dLat = _degreesToRadians(lat2 - lat1);
  double dLon = _degreesToRadians(lon2 - lon1);

  // Haversine formula
  double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c; // Distance in kilometers

  return distance;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
