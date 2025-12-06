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

  final BitmapDescriptor? driverIcon;
  final BitmapDescriptor? pickupIcon;
  final BitmapDescriptor? destinationIcon;

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
    required this.driverIcon,
    required this.pickupIcon,
    required this.destinationIcon,
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
          height: 260,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pickup, zoom: 11),
        
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
