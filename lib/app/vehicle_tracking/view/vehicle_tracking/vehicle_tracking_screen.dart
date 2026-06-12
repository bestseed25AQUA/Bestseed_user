import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:seedsuser/app/common/custom_best_seed_background.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/full_map_screen.dart';
import 'package:seedsuser/app/vehicle_tracking/service/passed_stops_service.dart';

import 'widgets/map_section_widget.dart';
import 'widgets/driver_section_widget.dart';
import 'widgets/delivery_update_widget.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/widgets/time_line_section_widget.dart';
import 'package:seedsuser/app/utils/google_maps_service.dart';

class VehicleTrackingScreen extends StatefulWidget {
  final String bookingId;
  const VehicleTrackingScreen({super.key, required this.bookingId});

  @override
  State<VehicleTrackingScreen> createState() => _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState extends State<VehicleTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final VehicleTrackingController controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GoogleMapController? mapController;

  LatLng? pickup;
  LatLng? drop;
  LatLng? driverLoc;

  List<LatLng> routePoints = [];
  List<LatLng> completedRoutePoints = [];
  List<LatLng> remainingRoutePoints = [];

  BitmapDescriptor? driverIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? destinationIcon;

  double _driverBearing = 0;

  bool _isLoading = true;
  TrackingData? _trackingData;
  List<Map<String, dynamic>> _clientStops = [];

  // ── Passed stops persistence ──
  List<Map<String, dynamic>> _savedPassedStops = [];

  // ── 10-second polling timer ──
  Timer? _pollTimer;

  // ── Arriving time ──
  String _arrivingText = '';
  int _arrivingMinutes = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VehicleTrackingController());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initialLoad();
  }

  Future<void> _initialLoad() async {
    // Load saved passed stops first
    _savedPassedStops = await PassedStopsService.load(widget.bookingId);
    debugPrint('🗺️ [TRACK] Loaded ${_savedPassedStops.length} saved passed stops for booking ${widget.bookingId}');

    await _fetchAndProcess(isInitial: true);

    // Start polling every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAndProcess(isInitial: false);
    });
  }

  /// Fetch tracking data from API and process stops.
  Future<void> _fetchAndProcess({required bool isInitial}) async {
    if (!mounted) return;
    if (isInitial) setState(() => _isLoading = true);

    try {
      debugPrint('🗺️ [TRACK] ${isInitial ? "Initial load" : "Poll"} for booking ${widget.bookingId}');
      await controller.fetchSpecificVehicleTracking(widget.bookingId, silent: !isInitial);

      final d = controller.specificVehicle.value?.data;
      if (d == null) {
        debugPrint('🗺️ [TRACK] ❌ No tracking data');
        return;
      }

      _trackingData = d;
      pickup = LatLng(d.pickup.lat, d.pickup.lng);
      drop = LatLng(d.drop.lat, d.drop.lng);
      // Remember the previous fix BEFORE overwriting, so we can derive the
      // vehicle's real heading from how it actually moved.
      final LatLng? previousDriverLoc = driverLoc;

      driverLoc = (d.driverLocation.lat != 0 && d.driverLocation.lng != 0)
          ? LatLng(d.driverLocation.lat, d.driverLocation.lng)
          : null;

      // Orient the truck to its ACTUAL direction of travel: the bearing from
      // the previous driver position to the current one. This makes the icon
      // face forward while advancing and turn around when the vehicle reverses,
      // instead of always pointing at the destination.
      if (driverLoc != null) {
        if (previousDriverLoc != null) {
          final movedMeters = _distMeters(
            previousDriverLoc.latitude,
            previousDriverLoc.longitude,
            driverLoc!.latitude,
            driverLoc!.longitude,
          );
          // Only re-orient on real movement (>= 5 m). Below that it's GPS
          // jitter — keep the last heading so a stationary truck doesn't spin.
          if (movedMeters >= 5) {
            _driverBearing = _calculateBearing(previousDriverLoc, driverLoc!);
          }
        } else if (drop != null) {
          // First fix — no prior point yet; face the destination to start.
          _driverBearing = _calculateBearing(driverLoc!, drop!);
        }
      } else if (pickup != null && drop != null) {
        _driverBearing = _calculateBearing(pickup!, drop!);
      }

      debugPrint('🗺️ [TRACK] driver=(${d.driverLocation.lat},${d.driverLocation.lng}) updatedAt=${d.driverLocation.updatedAt} speed=${d.driverLocation.speedKmh}');

      // On poll updates, re-split the polyline at driver's new position
      // so green (completed) and blue (remaining) lines follow the road
      if (!isInitial && routePoints.isNotEmpty) {
        _splitRouteAtDriver();
      }

      // Print full timeline from API
      debugPrint('🗺️ [TIMELINE] ── Backend timeline: ${d.timeline.length} items ──');
      for (int i = 0; i < d.timeline.length; i++) {
        final t = d.timeline[i];
        debugPrint('🗺️ [TIMELINE]   [$i] title="${t.title}" time="${t.time}" date="${t.date}" status="${t.status}" lat=${t.lat} lng=${t.lng}');
      }
      debugPrint('🗺️ [TIMELINE] ── passed_stops from DB: ${d.passedStops.length} items ──');
      for (int i = 0; i < d.passedStops.length; i++) {
        final pt = d.passedStops[i];
        debugPrint('🗺️ [TIMELINE]   [$i] name="${pt['name']}" passed_at=${pt['passed_at']} lat=${pt['lat']} lng=${pt['lng']}');
      }

      // Load markers only once
      if (isInitial) {
        try {
          driverIcon = await _loadTruckMarker(70);
          pickupIcon = await loadMarker("assets/images/pickup_vehicle_icon.png", 70);
          destinationIcon = await loadMarker("assets/images/drop_vehicle_icon.png", 70);
        } catch (e) {
          debugPrint('🗺️ [TRACK] ❌ Marker error: $e');
        }

        try {
          await loadPolyline();
        } catch (e) {
          debugPrint('🗺️ [TRACK] ❌ Polyline error: $e');
        }

        // Client-side fallback stops (always generate upcoming from driver position)
        if (pickup != null && drop != null) {
          try {
            final result = await GoogleMapsService.getRouteWithStops(
              origin: pickup!,
              destination: drop!,
              driverPosition: driverLoc,
              maxStops: 6,
            );
            final stops = result['stops'] as List?;
            if (stops != null) _clientStops = stops.cast<Map<String, dynamic>>();
          } catch (e) {
            debugPrint('🗺️ [TRACK] ❌ Client stops error: $e');
          }
        }
      }

      // ── Process passed stops ──
      _processPassedStops(d);

      // ── Calculate arriving time ──
      _calculateArrivingTime(d);

    } catch (e) {
      debugPrint('🗺️ [TRACK] ❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Compare driver's position against each stop.
  /// If driver has passed a stop, save it permanently with current time.
  void _processPassedStops(TrackingData d) {
    if (driverLoc == null || pickup == null) return;

    final allStops = d.passedStops.isNotEmpty
        ? d.passedStops
        : _clientStops;

    if (allStops.isEmpty) return;

    bool changed = false;
    final now = DateTime.now();

    for (final stop in allStops) {
      final stopLat = (stop['lat'] as num?)?.toDouble();
      final stopLng = (stop['lng'] as num?)?.toDouble();
      final stopName = stop['name']?.toString() ?? '';

      if (stopLat == null || stopLng == null) continue;

      // Check if already saved as passed
      final alreadySaved = _savedPassedStops.any((s) => s['name'] == stopName);
      if (alreadySaved) continue;

      // Check if driver has passed this stop (further from pickup than the stop)
      if (PassedStopsService.hasPassedStop(driverLoc!, pickup!, stopLat, stopLng)) {
        // Use backend's passed_at if available, otherwise use now
        final backendPassedAt = stop['passed_at'] as String?;
        DateTime passedTime;
        if (backendPassedAt != null) {
          try {
            passedTime = DateTime.parse(backendPassedAt).toLocal();
          } catch (_) {
            passedTime = now;
          }
        } else {
          passedTime = now;
        }

        _savedPassedStops.add({
          'name': stopName,
          'lat': stopLat,
          'lng': stopLng,
          'passed_at': passedTime.toIso8601String(),
          'time': PassedStopsService.formatTime(passedTime),
          'date': PassedStopsService.formatDate(passedTime),
        });
        changed = true;
        debugPrint('🗺️ [PASSED] ✅ "$stopName" marked passed at ${PassedStopsService.formatTime(passedTime)}');
      }
    }

    if (changed) {
      PassedStopsService.save(widget.bookingId, _savedPassedStops);
      debugPrint('🗺️ [PASSED] Saved ${_savedPassedStops.length} passed stops');
    }
  }

  /// Calculate arriving time based on distance to destination and driver speed.
  void _calculateArrivingTime(TrackingData d) {
    if (driverLoc == null || drop == null) {
      _arrivingText = d.expectedDelivery;
      _arrivingMinutes = 0;
      return;
    }

    final speedKmh = d.driverLocation.speedKmh?.toDouble() ?? 0;
    final minutes = PassedStopsService.estimateMinutes(
      driverLoc!, drop!.latitude, drop!.longitude, speedKmh,
    );
    _arrivingMinutes = minutes;

    if (minutes < 1) {
      _arrivingText = 'Arrived';
    } else if (minutes < 60) {
      _arrivingText = '$minutes mins';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      _arrivingText = mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    debugPrint('🗺️ [ETA] $minutes mins ($speedKmh km/h) → "$_arrivingText"');
  }

  Future<BitmapDescriptor> loadMarker(String asset, int width) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    return BitmapDescriptor.fromBytes(
      (await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
  }

  /// Loads truck.png (top-down truck, front/cab at the top → already faces
  /// north/up at 0°). The Google Maps marker [rotation] then turns it to the
  /// vehicle's actual heading, so NO baked-in rotation is applied here.
  Future<BitmapDescriptor> _loadTruckMarker(int size) async {
    try {
      final data = await rootBundle.load('assets/images/tracking_truck.png');
      // Scale by width only so the truck keeps its aspect ratio (not squished).
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('🗺️ [TRACK] ❌ Truck marker error: $e');
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  double _distMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Future<void> loadPolyline() async {
    if (pickup == null || drop == null) return;

    final poly = PolylinePoints(apiKey: NetworkConfig.googleApiKey2);

    try {
      final result = await poly.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(pickup!.latitude, pickup!.longitude),
          destination: PointLatLng(drop!.latitude, drop!.longitude),
          mode: TravelMode.driving,
        ),
      );
      routePoints = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      debugPrint('🗺️ [POLYLINE] ✅ Route: ${routePoints.length} points');
    } catch (e) {
      debugPrint('🗺️ [POLYLINE] ❌ Route failed: $e');
    }

    // Split the route at the driver's current position
    _splitRouteAtDriver();
  }

  /// Splits [routePoints] (pickup→drop) at the nearest point to [driverLoc].
  /// [completedRoutePoints] = pickup → driver (green covered path, follows road).
  /// [remainingRoutePoints] = driver → drop (blue remaining path, follows road).
  void _splitRouteAtDriver() {
    if (routePoints.isEmpty) {
      completedRoutePoints = [];
      remainingRoutePoints = [];
      return;
    }
    if (driverLoc == null) {
      completedRoutePoints = [];
      remainingRoutePoints = List.from(routePoints);
      return;
    }

    // Find the nearest polyline point to the driver's current position
    int nearestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < routePoints.length; i++) {
      final d = _distMeters(
        driverLoc!.latitude, driverLoc!.longitude,
        routePoints[i].latitude, routePoints[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIdx = i;
      }
    }

    completedRoutePoints = [
      ...routePoints.sublist(0, nearestIdx + 1),
      driverLoc!,
    ];
    remainingRoutePoints = [
      driverLoc!,
      ...routePoints.sublist(nearestIdx),
    ];
    debugPrint('🗺️ [SPLIT] completed=${completedRoutePoints.length} remaining=${remainingRoutePoints.length} nearestIdx=$nearestIdx');
  }

  /// Build timeline: merge backend timeline + auto_timeline_points + saved passed stops.
  /// Passed stops use saved data (time fixed forever). Upcoming stops use estimated ETA.
  List<TimelineItem> _buildMergedTimeline(TrackingData d) {
    if (d.timeline.length < 2) return d.timeline;

    final pickupItem = d.timeline.first;
    final destinationItem = d.timeline.last;

    // ── Collect ALL intermediate stops from all sources ──
    final Map<String, Map<String, dynamic>> stopMap = {};

    // 1. Backend timeline entries (from vehicle_tracking DB) — skip first (pickup) and last (destination)
    for (int i = 1; i < d.timeline.length - 1; i++) {
      final t = d.timeline[i];
      if (t.title.isNotEmpty && t.lat != null && t.lng != null) {
        stopMap[t.title] = {
          'name': t.title,
          'lat': t.lat,
          'lng': t.lng,
          'backend_time': t.time,
          'backend_date': t.date,
          'backend_status': t.status,
        };
      }
    }

    // 2. passed_stops from DB — merge in, don't overwrite backend data
    for (final pt in d.passedStops) {
      final name = pt['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      if (!stopMap.containsKey(name)) {
        stopMap[name] = {
          'name': name,
          'lat': (pt['lat'] as num?)?.toDouble(),
          'lng': (pt['lng'] as num?)?.toDouble(),
          'passed_at': pt['passed_at'],
          'dist_fraction': (pt['dist_fraction'] as num?)?.toDouble(),
        };
      }
    }

    // 3. Client-side fallback stops
    if (stopMap.isEmpty) {
      for (final stop in _clientStops) {
        final name = stop['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final loc = stop['location'];
        stopMap[name] = {
          'name': name,
          'lat': loc is LatLng ? loc.latitude : null,
          'lng': loc is LatLng ? loc.longitude : null,
          'passed': stop['passed'] ?? false,
        };
      }
    }

    if (stopMap.isEmpty) return d.timeline;

    // ── Sort by distance from pickup (route progression) ──
    var sortedStops = stopMap.values.toList();
    if (pickup != null) {
      sortedStops.sort((a, b) {
        final distA = PassedStopsService.estimateMinutes(
          pickup!,
          (a['lat'] as num?)?.toDouble() ?? 0,
          (a['lng'] as num?)?.toDouble() ?? 0,
          100,
        );
        final distB = PassedStopsService.estimateMinutes(
          pickup!,
          (b['lat'] as num?)?.toDouble() ?? 0,
          (b['lng'] as num?)?.toDouble() ?? 0,
          100,
        );
        return distA.compareTo(distB);
      });
    }

    // ── Ensure every stop has a dist_fraction ──
    // auto_timeline_points already carry one from the server.
    // Backend timeline stops don't, so compute from straight-line distance.
    if (pickup != null && drop != null) {
      final totalDist = _distMeters(
          pickup!.latitude, pickup!.longitude, drop!.latitude, drop!.longitude);
      for (final s in sortedStops) {
        if (s['dist_fraction'] != null) continue;
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        if (lat == null || lng == null || totalDist == 0) {
          s['dist_fraction'] = 0.5;
        } else {
          final d = _distMeters(pickup!.latitude, pickup!.longitude, lat, lng);
          s['dist_fraction'] = (d / totalDist).clamp(0.0, 1.0);
        }
      }
    }

    // ── Filter stops too close to pickup (<5%) or destination (>90%) ──
    sortedStops = sortedStops.where((s) {
      final f = (s['dist_fraction'] as num?)?.toDouble() ?? 0.5;
      return f >= 0.05 && f <= 0.90;
    }).toList();

    // ── Filter consecutive stops that are less than 8% of the route apart ──
    if (sortedStops.length > 1) {
      final spaced = <Map<String, dynamic>>[sortedStops.first];
      for (int i = 1; i < sortedStops.length; i++) {
        final prevF = (spaced.last['dist_fraction'] as num?)?.toDouble() ?? 0.0;
        final currF = (sortedStops[i]['dist_fraction'] as num?)?.toDouble() ?? 1.0;
        if (currF - prevF >= 0.08) {
          spaced.add(sortedStops[i]);
        }
      }
      sortedStops = spaced;
    }

    // ── Build timeline items ──
    final intermediates = sortedStops.map((stop) {
      final stopName = stop['name'] as String;
      final stopLat = (stop['lat'] as num?)?.toDouble();
      final stopLng = (stop['lng'] as num?)?.toDouble();

      // Priority 1: Saved passed stop (permanent, never changes)
      final saved = _savedPassedStops.firstWhereOrNull((s) => s['name'] == stopName);
      if (saved != null) {
        return TimelineItem(
          title: stopName,
          subtitle: 'Passed',
          time: saved['time'] ?? '-',
          date: saved['date'] ?? '-',
          status: 'completed',
          lat: stopLat,
          lng: stopLng,
        );
      }

      // Priority 2: Backend timeline with completed status (already in DB)
      if (stop['backend_status'] == 'completed' || stop['backend_status'] == 'current') {
        return TimelineItem(
          title: stopName,
          subtitle: stop['backend_status'] == 'current' ? '' : 'Passed',
          time: stop['backend_time'] ?? '-',
          date: stop['backend_date'] ?? '-',
          status: 'completed',
          lat: stopLat,
          lng: stopLng,
        );
      }

      // Priority 3: auto_timeline_point with passed_at from server
      final passedAt = stop['passed_at'] as String?;
      if (passedAt != null) {
        try {
          final dt = DateTime.parse(passedAt).toLocal();
          return TimelineItem(
            title: stopName,
            subtitle: 'Passed',
            time: PassedStopsService.formatTime(dt),
            date: PassedStopsService.formatDate(dt),
            status: 'completed',
            lat: stopLat,
            lng: stopLng,
          );
        } catch (_) {}
      }

      // Priority 4: Upcoming — estimate arrival time
      String time = '-';
      String date = '-';
      if (driverLoc != null && stopLat != null && stopLng != null) {
        final speedKmh = _trackingData?.driverLocation.speedKmh?.toDouble() ?? 0;
        final etaMinutes = PassedStopsService.estimateMinutes(
          driverLoc!, stopLat, stopLng, speedKmh,
        );
        final eta = DateTime.now().add(Duration(minutes: etaMinutes));
        time = PassedStopsService.formatTime(eta);
        date = PassedStopsService.formatDate(eta);
      }

      return TimelineItem(
        title: stopName,
        subtitle: '',
        time: time,
        date: date,
        status: 'pending',
        lat: stopLat,
        lng: stopLng,
      );
    }).toList();

    // ── Destination with ETA ──
    final destItem = TimelineItem(
      title: destinationItem.title,
      subtitle: destinationItem.subtitle,
      time: _arrivingMinutes > 0 && driverLoc != null
          ? PassedStopsService.formatTime(DateTime.now().add(Duration(minutes: _arrivingMinutes)))
          : destinationItem.time,
      date: _arrivingMinutes > 0 && driverLoc != null
          ? PassedStopsService.formatDate(DateTime.now().add(Duration(minutes: _arrivingMinutes)))
          : destinationItem.date,
      status: destinationItem.status,
      lat: destinationItem.lat,
      lng: destinationItem.lng,
    );

    return [pickupItem, ...intermediates, destItem];
  }

  void fitMapBounds() {
    if (mapController == null || pickup == null || drop == null) return;

    final lats = <double>[pickup!.latitude, drop!.latitude];
    final lngs = <double>[pickup!.longitude, drop!.longitude];
    if (driverLoc != null) {
      lats.add(driverLoc!.latitude);
      lngs.add(driverLoc!.longitude);
    }

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

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Text(
          'Vehicle tracking',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Builder(builder: (context) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final d = _trackingData;
        if (d == null) {
          return const Center(child: Text("No tracking data found"));
        }

        final lastUpdateTime = d.timeline.isNotEmpty
            ? "${d.timeline.first.time}, ${d.timeline.first.date}"
            : "-";
        final lastUpdateAddress = d.driverLocation.name;

        return RefreshIndicator(
          onRefresh: () => _fetchAndProcess(isInitial: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Map ──
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenMapPage(
                          pickupLat: d.pickup.lat,
                          pickupLng: d.pickup.lng,
                          dropLat: d.drop.lat,
                          dropLng: d.drop.lng,
                          driverLat: d.driverLocation.lat,
                          driverLng: d.driverLocation.lng,
                          driverName: d.driverLocation.name,
                          routePoints: remainingRoutePoints.isNotEmpty ? remainingRoutePoints : routePoints,
                          completedRoutePoints: completedRoutePoints,
                          driverIcon: driverIcon,
                          pickupIcon: pickupIcon,
                          destinationIcon: destinationIcon,
                          driverBearing: _driverBearing,
                          lastUpdateTime: lastUpdateTime,
                          lastUpdateAddress: lastUpdateAddress,
                        ),
                      ),
                    );
                  },
                  child: MapSectionWidget(
                    pickupLat: d.pickup.lat,
                    pickupLng: d.pickup.lng,
                    dropLat: d.drop.lat,
                    dropLng: d.drop.lng,
                    driverLat: d.driverLocation.lat,
                    driverLng: d.driverLocation.lng,
                    driverName: d.driverLocation.name,
                    routePoints: remainingRoutePoints.isNotEmpty ? remainingRoutePoints : routePoints,
                    completedRoutePoints: completedRoutePoints,
                    driverIcon: driverIcon,
                    pickupIcon: pickupIcon,
                    destinationIcon: destinationIcon,
                    driverBearing: _driverBearing,
                    onMapCreated: (controller) {
                      mapController = controller;
                      Future.delayed(const Duration(milliseconds: 300), fitMapBounds);
                    },
                  ),
                ),

                // ── Active indicator + Arriving time ──
                _buildActiveIndicator(d),

                // ── Driver details ──
                DriverSectionWidget(
                  driverName: d.driverDetails.driverName,
                  phone: d.driverDetails.driverPhone,
                  vehicleNumber: d.driverDetails.vehicleNumber,
                  driverImage: d.driverDetails.driverImage,
                ),

                // ── Delivery updates ──
                DeliveryUpdateWidget(
                  travelCost: d.travelCost,
                  expectedDelivery: d.expectedDelivery,
                  expected: d.deliveryUpdates.deliveryExpected,
                  note: d.deliveryUpdates.note,
                ),

                // ── Timeline ──
                TimelineSectionWidget(
                  items: _buildMergedTimeline(d),
                  pickupLat: pickup?.latitude,
                  pickupLng: pickup?.longitude,
                  driverLat: driverLoc?.latitude,
                  driverLng: driverLoc?.longitude,
                  driverAddress: d.driverLocation.name.isNotEmpty
                      ? d.driverLocation.name
                      : null,
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20),
                    Text("Have a question? ", style: GoogleFonts.poppins(fontSize: 14)),
                    InkWell(
                      onTap: () async {
                        final vendorMobile = d.vendorMobile;
                        if (vendorMobile != null && vendorMobile.isNotEmpty) {
                          final uri = Uri(scheme: 'tel', path: vendorMobile);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                      },
                      child: Text(
                        "Contact us",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 30),
                  child: CustomBestSeedBackground(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Active indicator with arriving time and pulsing dot.
  Widget _buildActiveIndicator(TrackingData d) {
    final updatedAt = d.driverLocation.updatedAt;
    final hasLocation = d.driverLocation.lat != 0 && d.driverLocation.lng != 0;

    bool isActive = false;
    String statusText = 'Offline';
    if (hasLocation && updatedAt != null && updatedAt.isNotEmpty) {
      try {
        final lastUpdate = DateTime.parse(updatedAt);
        final diff = DateTime.now().difference(lastUpdate);
        if (diff.inMinutes < 5) {
          isActive = true;
          statusText = 'Active now';
        } else if (diff.inMinutes < 60) {
          statusText = 'Last seen ${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          statusText = 'Last seen ${diff.inHours}h ago';
        } else {
          statusText = 'Last seen ${diff.inDays}d ago';
        }
      } catch (_) {
        statusText = hasLocation ? 'Location available' : 'Offline';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot
          SizedBox(
            width: 20,
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
                      width: 20 * _pulseAnimation.value * 0.6,
                      height: 20 * _pulseAnimation.value * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withValues(
                          alpha: (1.0 - (_pulseAnimation.value - 1.0) / 1.5) * 0.35,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.local_shipping, size: 20,
            color: isActive ? Colors.green.shade700 : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
                if (d.driverLocation.name.isNotEmpty)
                  Text(
                    d.driverLocation.name,
                    style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Arriving time badge
          if (_arrivingText.isNotEmpty && hasLocation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _arrivingText == 'Arrived' ? 'Arrived' : 'ETA $_arrivingText',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
