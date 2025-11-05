import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final Function(LatLng latLong) ontapSelectLocation;
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

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.latitude, widget.longitude);
    // _textController.addListener(() {
    //   _onChanged();
    // });
  }

  @override
  void dispose() {
    _mapController!.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  _onChanged(String value) {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(value);
  }

  void getSuggestion(String input) async {
    if (_sessionToken == '') {
      _sessionToken = uuid.v4();
    }
    // const String PLACES_API_KEY = "AIzaSyCkJAN-adqehEBHP4McDbwZlFJ4yqI4A0M";
    // const String PLACES_API_KEY = "AIzaSyBCOw0Ds4dQ3KuD-ab0pOoLP_AyFChamms";
    // const String PLACES_API_KEY = "AIzaSyAatarUnfCi0opdn9JPy6GNuwf0q3r6RBg";
    // const String PLACES_API_KEY = "AIzaSyDQ2c_p0S0FYSjxGMwkFvCVWKjY0M9siow";
    // const String PLACES_API_KEY = "AIzaSyCkJAN-adqehEBHP4McDbwZlFJ4yqI4A0M";

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
        // appBar: AppBar(
        //   elevation: 0,
        //   title: const Text(
        //     'Search places Api',
        //   ),
        // ),
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
                Container(
                  color: Colors.white,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: TextField(
                      focusNode: _focusNode,
                      onChanged: (value) {
                        _onChanged(value);
                      },
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Search your location here",
                        focusColor: Colors.white,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        prefixIcon: const Icon(Icons.map),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            _textController.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (_placeList.length != 0)
                  Expanded(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _placeList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            Map<String, dynamic> data = await getLatLng(
                              _placeList[index]['place_id'],
                            );
                            var _latLng = getLatLongFromMap(data);
                            print(_latLng);
                            _addMarkerAnimateCameraPosition(_latLng);
                            _selectedLocation = _latLng;
                            _textController.text =
                                _placeList[index]["description"];
                            _focusNode.unfocus();
                            _placeList.clear();
                          },
                          child: Container(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(_placeList[index]["description"]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton(
                child: Text('Select Locatiion'),
                onPressed: () async {
                  print(_selectedLocation);
                  Navigator.pop(context);
                  print('done');
                  widget.ontapSelectLocation(_selectedLocation!);
                },
              ),
            ),
          ],
        ),
      ),
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
