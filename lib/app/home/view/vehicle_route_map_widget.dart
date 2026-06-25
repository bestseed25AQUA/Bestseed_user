import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
import 'package:seedsuser/app/utils/custom_marker_helper.dart';

/// A compact map that shows a vehicle's route through its stops and a truck
/// marker that continuously MOVES along that route — the same moving-truck look
/// as the vendor/booking tracking map. These are *available* vehicles (no live
/// GPS), so the truck is animated stop-to-stop along the listed route rather
/// than driven by a real position feed. Self-contained: drop it anywhere with a
/// list of [VehicleLocation]s.
class VehicleRouteMapWidget extends StatefulWidget {
  final List<VehicleLocation> locations;
  final double height;

  const VehicleRouteMapWidget({
    super.key,
    required this.locations,
    this.height = 200,
  });

  @override
  State<VehicleRouteMapWidget> createState() => _VehicleRouteMapWidgetState();
}

class _VehicleRouteMapWidgetState extends State<VehicleRouteMapWidget> {
  GoogleMapController? _mapController;

  // Ordered route points that actually have coordinates.
  late final List<LatLng> _points;
  // Cumulative distance (km) at each point, used for even-speed interpolation.
  late final List<double> _cumKm;
  double _totalKm = 0;

  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _dropIcon;

  Timer? _timer;
  double _progress = 0; // 0..1 along the whole route
  LatLng? _truckPos;
  double _truckBearing = 0;

  // One full loop of the route takes this long, regardless of distance, so the
  // truck is always visibly moving even on short or long routes.
  static const Duration _loopDuration = Duration(seconds: 16);
  static const Duration _tick = Duration(milliseconds: 80);

  @override
  void initState() {
    super.initState();

    _points = [
      for (final loc in widget.locations)
        if (loc.latitude != null && loc.longitude != null)
          LatLng(loc.latitude!, loc.longitude!),
    ];

    // Build cumulative distances for even-speed movement.
    _cumKm = List<double>.filled(_points.length, 0);
    for (var i = 1; i < _points.length; i++) {
      _totalKm += _haversineKm(_points[i - 1], _points[i]);
      _cumKm[i] = _totalKm;
    }

    if (_points.isNotEmpty) {
      _truckPos = _points.first;
      _loadMarkersAndStart();
    }
  }

  Future<void> _loadMarkersAndStart() async {
    final truck = await CustomMarkerHelper.getTruckMarker(size: 64);
    final start = await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 30);
    final drop = await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 30);
    if (!mounted) return;
    setState(() {
      _truckIcon = truck;
      _startIcon = start;
      _dropIcon = drop;
    });

    // Only animate when there's an actual path between two or more stops.
    if (_points.length >= 2 && _totalKm > 0) {
      final step = _tick.inMilliseconds / _loopDuration.inMilliseconds;
      _timer = Timer.periodic(_tick, (_) {
        _progress += step;
        if (_progress >= 1) _progress = 0; // loop back to the start
        _updateTruck();
      });
    }
  }

  /// Map [_progress] (0..1 of total route distance) to a LatLng + heading.
  void _updateTruck() {
    final target = _progress * _totalKm;
    // Find the segment that contains `target`.
    var seg = 0;
    while (seg < _points.length - 2 && _cumKm[seg + 1] < target) {
      seg++;
    }
    final segStartKm = _cumKm[seg];
    final segLenKm = _cumKm[seg + 1] - segStartKm;
    final t = segLenKm <= 0 ? 0.0 : ((target - segStartKm) / segLenKm).clamp(0.0, 1.0);

    final a = _points[seg];
    final b = _points[seg + 1];
    final pos = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );

    if (!mounted) return;
    setState(() {
      _truckPos = pos;
      _truckBearing = _bearing(a, b);
    });
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Stop markers: first = pickup style, last = drop style, middle = dots.
    for (var i = 0; i < _points.length; i++) {
      final isFirst = i == 0;
      final isLast = i == _points.length - 1;
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: _points[i],
          icon: isFirst
              ? (_startIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))
              : isLast
                  ? (_dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    // Moving truck.
    if (_truckPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _truckPos!,
          icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          rotation: _truckBearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 5,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _points,
        color: AppColors.primary,
        width: 4,
        geodesic: true,
      ),
    };
  }

  void _fitRoute() {
    final c = _mapController;
    if (c == null || _points.isEmpty) return;
    if (_points.length == 1) {
      c.moveCamera(CameraUpdate.newLatLngZoom(_points.first, 12));
      return;
    }
    double minLat = _points.first.latitude, maxLat = _points.first.latitude;
    double minLng = _points.first.longitude, maxLng = _points.first.longitude;
    for (final p in _points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _points.first, zoom: 11),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              liteModeEnabled: false,
              // Let the map handle drags even inside the scrolling detail page.
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              onMapCreated: (c) {
                _mapController = c;
                // Fit once the first frame is laid out.
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
              },
            ),
            // Small "Live route" badge to mirror the vendor tracking look.
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _points.length >= 2 ? 'Vehicle moving' : 'Vehicle location',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

  // ── geo helpers ──
  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _bearing(LatLng a, LatLng b) {
    double rad(double d) => d * math.pi / 180.0;
    final dLng = rad(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(rad(b.latitude));
    final x = math.cos(rad(a.latitude)) * math.sin(rad(b.latitude)) -
        math.sin(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
