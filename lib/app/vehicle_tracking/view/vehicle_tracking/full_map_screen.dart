import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenMapPage extends StatefulWidget {
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
  final String lastUpdateTime;
  final String lastUpdateAddress;

  const FullScreenMapPage({
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
    required this.lastUpdateTime,
    required this.lastUpdateAddress,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  GoogleMapController? mapCtrl;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (mapCtrl == null) return;

    final pickup = LatLng(widget.pickupLat, widget.pickupLng);
    final drop = LatLng(widget.dropLat, widget.dropLng);
    final driver = LatLng(widget.driverLat, widget.driverLng);

    final points = <LatLng>[pickup, drop, driver];
    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );

    mapCtrl!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(widget.pickupLat, widget.pickupLng);
    final drop = LatLng(widget.dropLat, widget.dropLng);
    final driver = LatLng(widget.driverLat, widget.driverLng);

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text("Vehicle tracking"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 12),
            onMapCreated: (controller) {
              mapCtrl = controller;
              _fitBounds();
            },
            markers: {
              Marker(
                markerId: const MarkerId("pickup"),
                position: pickup,
                icon: widget.pickupIcon ?? BitmapDescriptor.defaultMarker,
              ),
              Marker(
                markerId: const MarkerId("drop"),
                position: drop,
                icon:
                    widget.destinationIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(200),
              ),
              if (widget.driverIcon != null)
                Marker(
                  markerId: const MarkerId("driver"),
                  position: driver,
                  icon: widget.driverIcon!,
                  anchor: const Offset(0.5, 0.5),
                  rotation: widget.driverBearing,
                  flat: true,
                ),
            },
            polylines: {
              if (widget.routePoints.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: widget.routePoints,
                  color: Colors.blue,
                  width: 5,
                ),
              if (widget.completedRoutePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId("completed_route"),
                  points: widget.completedRoutePoints,
                  color: const Color(0xFF34A853),
                  width: 6,
                ),
            },
          ),

          Positioned(left: 20, right: 20, bottom: 30, child: _lastUpdateCard()),
        ],
      ),
    );
  }

  Widget _lastUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(blurRadius: 8, spreadRadius: 2, color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last Update",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.lastUpdateTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            widget.lastUpdateAddress,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
