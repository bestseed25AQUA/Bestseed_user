import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSectionWidget extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;

  final double dropLat;
  final double dropLng;

  final double driverLat;
  final double driverLng;
  final String driverName;

  final List<LatLng> routePoints;
  final List<LatLng> completedRoutePoints;

  final BitmapDescriptor? driverIcon;
  final BitmapDescriptor? pickupIcon;
  final BitmapDescriptor? destinationIcon;

  final double driverBearing;

  // Added callback to return map controller to parent
  final Function(GoogleMapController controller) onMapCreated;

  const MapSectionWidget({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.driverLat,
    required this.driverLng,
    required this.driverName,
    required this.routePoints,
    this.completedRoutePoints = const [],
    required this.driverIcon,
    required this.pickupIcon,
    required this.destinationIcon,
    this.driverBearing = 0,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(pickupLat, pickupLng);
    final drop = LatLng(dropLat, dropLng);
    final driver = LatLng(driverLat, driverLng);

    return Stack(
      children: [
        Container(
          height: 170,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GoogleMap(
              // IMPORTANT: do NOT use lite mode here.
              // Lite mode renders a static snapshot and does not support live
              // updates or programmatic camera moves. This preview is rebuilt on
              // every 10s tracking poll (the driver marker moves) and we call
              // animateCamera via fitMapBounds — both crash the native lite
              // renderer ("app crashes while just sitting on the tracking
              // screen"). It also crashed when tapping through to the full-screen
              // (normal) map, because mixing a lite map and a normal map in the
              // same app is unstable on many Android devices.
              //
              // So this is a NORMAL map with all gestures disabled — it behaves
              // as a non-interactive preview (tap opens FullScreenMapPage) but
              // safely handles the live driver-marker updates and camera fit.
              liteModeEnabled: false,
              initialCameraPosition: CameraPosition(target: pickup, zoom: 11),
              // Disable interactions — this is a preview, not an interactive map.
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,

              onMapCreated: (controller) {
                onMapCreated(controller);
              },

              markers: {
                Marker(
                  markerId: const MarkerId("pickup"),
                  position: pickup,
                  icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
                  infoWindow: const InfoWindow(title: "Pickup"),
                ),
                Marker(
                  markerId: const MarkerId("drop"),
                  position: drop,
                  icon:
                      destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(200),
                  infoWindow: const InfoWindow(title: "Destination"),
                ),
                if (driverIcon != null)
                  Marker(
                    markerId: const MarkerId("driver"),
                    position: driver,
                    icon: driverIcon!,
                    anchor: const Offset(0.5, 0.5),
                    rotation: driverBearing,
                    flat: true,
                    infoWindow: InfoWindow(title: driverName),
                  ),
              },
        
              polylines: {
                if (routePoints.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: routePoints,
                    color: Colors.blue,
                    width: 5,
                  ),
                if (completedRoutePoints.length >= 2)
                  Polyline(
                    polylineId: const PolylineId("completed_route"),
                    points: completedRoutePoints,
                    color: const Color(0xFF34A853),
                    width: 6,
                  ),
              },
            ),
          ),
        ),
        Positioned(
          top:30,right: 30,
          child: Icon(Icons.zoom_out_map,size: 25))
        
      ],
    );
  }
}
