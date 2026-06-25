import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Live snapshot the tracking screen pushes into the full-screen map every poll
/// / glide frame, so the vehicle marker + green/blue lines keep updating while
/// the full map is open (instead of freezing at the position it had on open).
class TrackingLiveFrame {
  final LatLng? driver;
  final double bearing;
  final List<LatLng> completed; // green (travelled)
  final List<LatLng> remaining; // blue (remaining)
  const TrackingLiveFrame({
    this.driver,
    this.bearing = 0,
    this.completed = const [],
    this.remaining = const [],
  });
}

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

  /// Live updates from the tracking screen. When provided, the vehicle marker
  /// and green/blue lines follow it (so the map stays live); when null, the
  /// static values above are used.
  final ValueListenable<TrackingLiveFrame>? live;

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
    this.live,
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

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text("Vehicle tracking"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Rebuild the map's vehicle + lines whenever the tracking screen
          // pushes a new live frame, so the icon follows the driver live.
          widget.live == null
              ? _map(pickup, _staticDriver(), widget.driverBearing,
                  widget.routePoints, widget.completedRoutePoints)
              : ValueListenableBuilder<TrackingLiveFrame>(
                  valueListenable: widget.live!,
                  builder: (_, frame, __) {
                    final driver = frame.driver ?? _staticDriver();
                    final route = frame.remaining.isNotEmpty
                        ? frame.remaining
                        : widget.routePoints;
                    final completed = frame.completed.isNotEmpty
                        ? frame.completed
                        : widget.completedRoutePoints;
                    return _map(pickup, driver, frame.bearing, route, completed);
                  },
                ),

          Positioned(left: 20, right: 20, bottom: 30, child: _lastUpdateCard()),
        ],
      ),
    );
  }

  LatLng _staticDriver() => LatLng(widget.driverLat, widget.driverLng);

  Widget _map(LatLng pickup, LatLng driver, double bearing,
      List<LatLng> route, List<LatLng> completed) {
    final drop = LatLng(widget.dropLat, widget.dropLng);
    return GoogleMap(
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
          icon: widget.destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(200),
        ),
        if (widget.driverIcon != null)
          Marker(
            markerId: const MarkerId("driver"),
            position: driver,
            icon: widget.driverIcon!,
            anchor: const Offset(0.5, 0.5),
            rotation: bearing,
            flat: true,
          ),
      },
      polylines: {
        if (route.isNotEmpty)
          Polyline(
            polylineId: const PolylineId("route"),
            points: route,
            color: Colors.blue,
            width: 5,
          ),
        if (completed.length >= 2)
          Polyline(
            polylineId: const PolylineId("completed_route"),
            points: completed,
            color: const Color(0xFF34A853),
            width: 6,
          ),
      },
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
