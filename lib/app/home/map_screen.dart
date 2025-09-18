import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;

const String kGoogleApiKey = "AIzaSyA111b89Exrm83RRWF-2hP1EPeUxvos87I";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmap.GoogleMapController? _mapController;
  gmap.LatLng? _pickedLocation;
  String _selectedAddress = "";
  final TextEditingController _searchController = TextEditingController();

  late final places.FlutterGooglePlacesSdk _places;

  @override
  void initState() {
    super.initState();
    _places = places.FlutterGooglePlacesSdk(kGoogleApiKey);
    _getCurrentLocation();
  }

  /// Get Current Location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _pickedLocation = gmap.LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      gmap.CameraUpdate.newLatLngZoom(_pickedLocation!, 15),
    );

    _getAddressFromLatLng(_pickedLocation!);
  }

  /// Reverse Geocoding
  Future<void> _getAddressFromLatLng(gmap.LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      setState(() {
        _selectedAddress =
            "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}";
      });
    }
  }

  /// On Tap Select Location
  void _onMapTapped(gmap.LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
    _getAddressFromLatLng(position);
  }

  /// Handle Place Search
  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) return;

    final result = await _places.findAutocompletePredictions(query);

    if (result.predictions.isNotEmpty) {
      final prediction = result.predictions.first;

      final details = await _places.fetchPlace(
        prediction.placeId,
        fields: [places.PlaceField.Location, places.PlaceField.Address],
      );

      if (details.place != null && details.place!.latLng != null) {
        final lat = details.place!.latLng!.lat;
        final lng = details.place!.latLng!.lng;

        final newPosition = gmap.LatLng(lat, lng);

        setState(() {
          _pickedLocation = newPosition;
          _selectedAddress = details.place!.address ?? "";
          _searchController.text = _selectedAddress;
        });

        _mapController?.animateCamera(
          gmap.CameraUpdate.newLatLngZoom(newPosition, 15),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Delivery Address")),
      body: Stack(
        children: [
          // Google Map
          _pickedLocation == null
              ? const Center(child: CircularProgressIndicator())
              : gmap.GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: gmap.CameraPosition(
                    target: _pickedLocation!,
                    zoom: 14,
                  ),
                  onTap: _onMapTapped,
                  markers: {
                    gmap.Marker(
                      markerId: const gmap.MarkerId("selected"),
                      position: _pickedLocation!,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: "Search location",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Address Display
          if (_selectedAddress.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedAddress,
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),

      // Confirm Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _selectedAddress);
        },
        label: const Text("Confirm"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
