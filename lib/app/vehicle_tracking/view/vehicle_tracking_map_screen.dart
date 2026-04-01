import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/utils/custom_marker_helper.dart';
import 'package:seedsuser/app/utils/google_maps_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';

class VehicleTrackingMapScreen extends StatefulWidget {
  final String bookingId;

  const VehicleTrackingMapScreen({super.key, required this.bookingId});

  @override
  State<VehicleTrackingMapScreen> createState() =>
      _VehicleTrackingMapScreenState();
}

class _VehicleTrackingMapScreenState extends State<VehicleTrackingMapScreen>
    with TickerProviderStateMixin {
  final VehicleTrackingController controller = Get.put(
    VehicleTrackingController(),
  );

  // Separate controllers for small and expanded maps
  GoogleMapController? _smallMapController;
  GoogleMapController? _expandedMapController;

  // Default location (Hyderabad, India)
  static const LatLng _defaultLocation = LatLng(17.3850, 78.4867);

  late CameraPosition _initialPosition;
  late LatLng _currentVehiclePosition;

  // Markers for small map view
  Set<Marker> _smallMapMarkers = {};
  // Markers for expanded map view
  Set<Marker> _expandedMapMarkers = {};

  Set<Polyline> _polylines = {};

  // Track if map is expanded
  bool _isMapExpanded = false;

  // Loading state for directions
  bool _isLoadingRoute = true;

  // Custom markers for small map (smaller size)
  BitmapDescriptor? _smallTruckMarker;
  BitmapDescriptor? _smallPickupMarker;
  BitmapDescriptor? _smallDestinationMarker;

  // Custom markers for expanded map (bigger size)
  BitmapDescriptor? _expandedTruckMarker;
  BitmapDescriptor? _expandedPickupMarker;
  BitmapDescriptor? _expandedDestinationMarker;

  // Store LatLng positions for reuse
  LatLng? _pickupLatLng;
  LatLng? _currentLatLng;
  LatLng? _destinationLatLng;

  // Tracking data
  TrackingData? _trackingData;

  // Estimated delivery time from vehicle to destination
  String _estimatedDuration = '';

  // Intermediate route stops
  List<Map<String, dynamic>> _routeStops = [];
  DateTime? _routeStartTime;
  int _totalRouteDurationSeconds = 0;

  // Full polyline data for sub-stop generation
  List<LatLng> _fullPolyline = [];
  List<double> _cumulativeDistances = [];

  // Expandable sub-timelines
  int? _expandedSegmentIndex;
  Map<int, List<Map<String, dynamic>>> _subStopsCache = {};
  int? _loadingSegment;

  bool _isTimelineExpanded = false;

  // Refresh state
  DateTime _lastRefreshedAt = DateTime.now();
  bool _isRefreshing = false;
  Timer? _timeAgoTimer;
  Timer? _autoRefreshTimer;

  // Pulse animation for vehicle icon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for vehicle icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _initializeMap();
    // Update "Updated X mins ago" text every 30 seconds
    _timeAgoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // Auto-refresh tracking data and ETA every 2 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && !_isRefreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _initializeMap() async {
    // Fetch tracking data
    await controller.fetchSpecificVehicleTracking(widget.bookingId);

    _trackingData = controller.specificVehicle.value?.data;
    if (_trackingData == null) {
      setState(() {
        _isLoadingRoute = false;
      });
      return;
    }

    final driverLoc = _trackingData!.driverLocation;

    // Get current vehicle position from API
    if (driverLoc.lat != 0 && driverLoc.lng != 0) {
      _currentVehiclePosition = LatLng(driverLoc.lat, driverLoc.lng);
    } else {
      _currentVehiclePosition = _defaultLocation;
    }

    // Set initial camera position - will be updated to fit all markers
    _initialPosition = CameraPosition(
      target: _currentVehiclePosition,
      zoom: 10.0,
    );

    // Load custom markers first (both sizes)
    await _loadCustomMarkers();

    // Then setup markers and routes
    await _setupMarkersAndPolylines();

    setState(() {
      _lastRefreshedAt = DateTime.now();
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await controller.fetchSpecificVehicleTracking(widget.bookingId);
      _trackingData = controller.specificVehicle.value?.data;

      if (_trackingData != null) {
        final driverLoc = _trackingData!.driverLocation;
        if (driverLoc.lat != 0 && driverLoc.lng != 0) {
          _currentVehiclePosition = LatLng(driverLoc.lat, driverLoc.lng);
        }

        // Reset route data
        _routeStops = [];
        _routeStartTime = null;
        _totalRouteDurationSeconds = 0;
        _estimatedDuration = '';
        _fullPolyline = [];
        _cumulativeDistances = [];
        _expandedSegmentIndex = null;
        _subStopsCache = {};
        _loadingSegment = null;

        await _setupMarkersAndPolylines();

        // Re-fit maps
        _fitSmallMapToAllMarkers();
        _fitExpandedMapToAllMarkers();
      }

      setState(() {
        _lastRefreshedAt = DateTime.now();
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadCustomMarkers() async {
    // Small map markers (smaller size for compact view)
    _smallTruckMarker = await CustomMarkerHelper.getTruckMarkerFromAsset(
      size: 30,
    );
    _smallPickupMarker =
        await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 26);
    _smallDestinationMarker =
        await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 26);

    // Expanded map markers (bigger size for full screen view)
    _expandedTruckMarker = await CustomMarkerHelper.getTruckMarkerFromAsset(
      size: 60,
    );
    _expandedPickupMarker =
        await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 30);
    _expandedDestinationMarker =
        await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 30);
  }

  Future<void> _setupMarkersAndPolylines() async {
    if (_trackingData == null) return;

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    Set<Polyline> polylines = {};

    /// -------- Get Pickup Coordinates --------
    if (pickup.lat != 0 && pickup.lng != 0) {
      _pickupLatLng = LatLng(pickup.lat, pickup.lng);
    } else if (pickup.name.isNotEmpty) {
      _pickupLatLng = await GoogleMapsService.geocodeAddress(pickup.name);
    }

    /// -------- Get Current Location Coordinates --------
    if (driverLoc.lat != 0 && driverLoc.lng != 0) {
      _currentLatLng = LatLng(driverLoc.lat, driverLoc.lng);
    }

    /// -------- Get Destination Coordinates --------
    if (destination.lat != 0 && destination.lng != 0) {
      _destinationLatLng = LatLng(destination.lat, destination.lng);
    } else if (destination.name.isNotEmpty) {
      _destinationLatLng = await GoogleMapsService.geocodeAddress(
        destination.name,
      );
    }

    // Build markers for both small and expanded views
    _buildMarkers();

    /// -------- Route + Intermediate Stops using single Directions API call --------
    if (_pickupLatLng != null && _destinationLatLng != null) {
      // Separate waypoints into delivered (completed) and remaining (pending/in-progress)
      final allWaypoints = _trackingData!.routeWaypoints
          .where((wp) => wp.lat != 0 && wp.lng != 0)
          .toList();
      final remainingWaypoints = allWaypoints
          .where((wp) => !wp.isCompleted)
          .map((wp) => LatLng(wp.lat, wp.lng))
          .toList();

      // When driver position is available, calculate route from DRIVER → remaining stops → destination.
      // This gives accurate ETA because it uses the actual road from where the driver IS,
      // not the shortest path from pickup which may be a completely different road.
      // Example: Chennai → Vijayawada(delivered) → Amalapuram
      //   Old: origin=Chennai, waypoints=[], dest=Amalapuram → shortest direct route (WRONG)
      //   New: origin=DriverPos(near Vijayawada), waypoints=[], dest=Amalapuram → actual road (CORRECT)
      final routeOrigin = _currentLatLng ?? _pickupLatLng!;
      final useDriverAsOrigin = _currentLatLng != null;

      debugPrint(
        '🗺️ Route params: origin=$routeOrigin (driver=$useDriverAsOrigin), '
        'dest=$_destinationLatLng, remainingWaypoints=${remainingWaypoints.length}, '
        'totalWaypoints=${allWaypoints.length}',
      );

      final routeData = await GoogleMapsService.getRouteWithStops(
        origin: routeOrigin,
        destination: _destinationLatLng!,
        driverPosition: useDriverAsOrigin ? null : _currentLatLng,
        routeWaypoints: remainingWaypoints,
      );

      if (routeData.isNotEmpty) {
        final remainingPointsRoute =
            routeData['remaining_points'] as List<LatLng>? ?? [];
        final completedFromApi =
            routeData['completed_points'] as List<LatLng>? ?? [];
        _routeStops = routeData['stops'] as List<Map<String, dynamic>>? ?? [];
        _totalRouteDurationSeconds =
            routeData['total_duration_seconds'] as int? ?? 0;
        _fullPolyline = routeData['polyline_points'] as List<LatLng>? ?? [];
        _cumulativeDistances =
            (routeData['cumulative_distances'] as List?)?.cast<double>() ?? [];

        final remainingSeconds =
            routeData['remaining_duration_seconds'] as int? ?? 0;

        if (useDriverAsOrigin) {
          // Route was calculated from driver → destination, so the ENTIRE
          // route duration IS the remaining ETA (no fraction math needed)
          _estimatedDuration = _formatDuration(_totalRouteDurationSeconds);

          // Route start time = driver's last update (journey is "starting" from driver)
          final driverLoc = _trackingData!.driverLocation;
          if (driverLoc.updatedAt != null && driverLoc.updatedAt!.isNotEmpty) {
            try {
              _routeStartTime = DateTime.parse(driverLoc.updatedAt!);
            } catch (_) {}
          }

          // Green solid line: pickup → driver (road-following via timeline GPS points)
          List<LatLng> completedRoute = [];

          // Collect timeline GPS points for the traveled path
          final timelineCoords = <LatLng>[];
          for (final item in _trackingData!.timeline) {
            if (item.lat != null && item.lng != null) {
              timelineCoords.add(LatLng(item.lat!, item.lng!));
            }
          }

          if (timelineCoords.isNotEmpty) {
            // Sample max 10 evenly spaced points as via waypoints
            const maxPoints = 10;
            List<LatLng> viaPoints;
            if (timelineCoords.length <= maxPoints) {
              viaPoints = timelineCoords;
            } else {
              viaPoints = [];
              final step = timelineCoords.length / maxPoints;
              for (int i = 0; i < maxPoints; i++) {
                viaPoints.add(timelineCoords[(i * step).floor()]);
              }
              viaPoints[viaPoints.length - 1] = timelineCoords.last;
            }

            // Get road-snapped route using via waypoints
            completedRoute = await GoogleMapsService.getDirections(
              origin: _pickupLatLng!,
              destination: _currentLatLng!,
              waypoints: viaPoints,
              useViaWaypoints: true,
            );
          }

          // Fallback: direct road route without timeline
          if (completedRoute.isEmpty) {
            completedRoute = await GoogleMapsService.getDirections(
              origin: _pickupLatLng!,
              destination: _currentLatLng!,
            );
          }

          // Final fallback: straight line
          if (completedRoute.isEmpty) {
            completedRoute = [_pickupLatLng!, _currentLatLng!];
          }

          polylines.add(
            Polyline(
              polylineId: const PolylineId('completed'),
              points: completedRoute,
              color: Colors.green,
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
          // Remaining route: split into forward (blue) + return (yellow)
          // Forward = driver → last waypoint, Return = last waypoint → destination
          final allRoutePoints = [...completedFromApi, ...remainingPointsRoute];
          if (allRoutePoints.isNotEmpty) {
            _addSplitPolylines(polylines, allRoutePoints, remainingWaypoints);
          }
        } else if (_currentLatLng != null && completedFromApi.isNotEmpty) {
          // Fallback: route from pickup with driver as waypoint (original logic)
          final driverFraction =
              routeData['driver_progress_fraction'] as double? ?? 0.0;
          _estimatedDuration = _formatDuration(remainingSeconds);

          final driverLoc = _trackingData!.driverLocation;
          if (driverLoc.updatedAt != null && driverLoc.updatedAt!.isNotEmpty) {
            try {
              final updatedAt = DateTime.parse(driverLoc.updatedAt!);
              final elapsedSeconds =
                  (driverFraction * _totalRouteDurationSeconds).round();
              _routeStartTime = updatedAt.subtract(
                Duration(seconds: elapsedSeconds),
              );
            } catch (_) {}
          }

          // Green solid line: pickup to driver position (completed)
          polylines.add(
            Polyline(
              polylineId: const PolylineId('completed'),
              points: completedFromApi,
              color: Colors.green,
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
          // Remaining: split into forward (blue) + return (yellow)
          if (remainingPointsRoute.isNotEmpty) {
            _addSplitPolylines(
              polylines,
              remainingPointsRoute,
              remainingWaypoints,
            );
          }
        } else if (remainingPointsRoute.isNotEmpty) {
          _estimatedDuration = _formatDuration(remainingSeconds);
          // No current location — full route as dashed blue
          polylines.add(
            Polyline(
              polylineId: const PolylineId('full_route'),
              points: remainingPointsRoute,
              color: const Color(0xFF0077C8),
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        }
      } else {
        // Fallback: straight lines if Directions API fails
        if (_currentLatLng != null) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('completed'),
              points: [_pickupLatLng!, _currentLatLng!],
              color: Colors.green,
              width: 4,
            ),
          );
          polylines.add(
            Polyline(
              polylineId: const PolylineId('remaining'),
              points: [_currentLatLng!, _destinationLatLng!],
              color: const Color(0xFF0077C8),
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        } else {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('full_route'),
              points: [_pickupLatLng!, _destinationLatLng!],
              color: const Color(0xFF0077C8),
              width: 4,
            ),
          );
        }
      }
    }

    // Calculate initial camera position to show full route
    _calculateInitialCameraPosition();

    setState(() {
      _polylines = polylines;
      _isLoadingRoute = false;
    });
  }

  double _getBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lon1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lon2 = end.longitude * pi / 180;

    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  int _getClosestPolylineIndex(LatLng current) {
    double minDist = double.infinity;
    int index = 0;

    for (int i = 0; i < _fullPolyline.length; i++) {
      final d =
          (_fullPolyline[i].latitude - current.latitude).abs() +
          (_fullPolyline[i].longitude - current.longitude).abs();

      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }

    return index;
  }

  double _getRouteBearing(LatLng current) {
    if (_fullPolyline.length < 2) return 0;

    int index = _getClosestPolylineIndex(current);

    // prevent overflow
    if (index >= _fullPolyline.length - 1) {
      index = _fullPolyline.length - 2;
    }

    final start = _fullPolyline[index];
    final end = _fullPolyline[index + 1];

    return _getBearing(start, end);
  }

  /// Build markers for both small and expanded map views
  void _buildMarkers() {
    if (_trackingData == null) return;

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    Set<Marker> smallMarkers = {};
    Set<Marker> expandedMarkers = {};

    /// -------- Pickup --------
    if (_pickupLatLng != null) {
      smallMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon:
              _smallPickupMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup', snippet: pickup.name),
        ),
      );

      expandedMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon:
              _expandedPickupMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup', snippet: pickup.name),
        ),
      );
    }

    /// -------- Vehicle (ONLY ONCE) --------
    if (_currentLatLng != null) {
      final rotationAngle = _fullPolyline.isNotEmpty
          ? _getRouteBearing(_currentLatLng!)
          : 0.0;

      smallMarkers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _currentLatLng!,
          icon: _smallTruckMarker!,
          anchor: const Offset(0.5, 0.5),
          rotation: rotationAngle,
          flat: true,
          infoWindow: InfoWindow(title: 'Vehicle', snippet: driverLoc.name),
        ),
      );

      expandedMarkers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _currentLatLng!,
          icon: _expandedTruckMarker!,
          anchor: const Offset(0.5, 0.5),
          rotation: rotationAngle,
          flat: true,
          infoWindow: InfoWindow(title: 'Vehicle', snippet: driverLoc.name),
        ),
      );
    }

    /// -------- Destination --------
    if (_destinationLatLng != null) {
      smallMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon:
              _smallDestinationMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: destination.name,
          ),
        ),
      );

      expandedMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon:
              _expandedDestinationMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: destination.name,
          ),
        ),
      );
    }

    _smallMapMarkers = smallMarkers;
    _expandedMapMarkers = expandedMarkers;
  }

  /// Calculate initial camera position to show the full route
  void _calculateInitialCameraPosition() {
    List<LatLng> points = [];

    if (_pickupLatLng != null) points.add(_pickupLatLng!);
    if (_currentLatLng != null) points.add(_currentLatLng!);
    if (_destinationLatLng != null) points.add(_destinationLatLng!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      _initialPosition = CameraPosition(target: points.first, zoom: 14.0);
      return;
    }

    // Calculate center point
    double minLat = points.first.latitude;
    double maxLat = minLat;
    double minLng = points.first.longitude;
    double maxLng = minLng;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculate zoom level based on distance
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = max(latDiff, lngDiff);

    double zoom;
    if (maxDiff > 5) {
      zoom = 6;
    } else if (maxDiff > 2) {
      zoom = 7;
    } else if (maxDiff > 1) {
      zoom = 8;
    } else if (maxDiff > 0.5) {
      zoom = 9;
    } else if (maxDiff > 0.2) {
      zoom = 10;
    } else if (maxDiff > 0.1) {
      zoom = 11;
    } else if (maxDiff > 0.05) {
      zoom = 12;
    } else {
      zoom = 13;
    }

    _initialPosition = CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= Header =================
            _buildHeader(context, width, height),

            /// ================= Content =================
            Expanded(
              child: Obx(() {
                if (controller.specificLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_trackingData == null) {
                  return const Center(child: Text("No tracking data found"));
                }

                return _isMapExpanded
                    ? _buildExpandedMapView(width, height)
                    : _buildDefaultView(width, height);
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Default view: Map fills top, draggable bottom sheet with details
  Widget _buildDefaultView(double width, double height) {
    return Stack(
      children: [
        /// ── Map fills entire background ──
        Column(
          children: [Expanded(child: _buildSmallMapSection(width, height))],
        ),

        /// ── Floating ETA pill on map ──
        if (_estimatedDuration.isNotEmpty)
          Positioned(
            top: height * 0.015,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                  vertical: width * 0.025,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Arriving in ',
                      style: TextStyle(
                        fontSize: width * 0.033,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      _estimatedDuration,
                      style: TextStyle(
                        fontSize: width * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        /// ── Expand map button ──
        Positioned(
          top: height * 0.015,
          right: width * 0.04,
          child: GestureDetector(
            onTap: () => setState(() => _isMapExpanded = true),
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.fullscreen,
                size: width * 0.05,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        /// ── Draggable Bottom Sheet ──
        DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  /// Drag handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: height * 0.012,
                        bottom: height * 0.01,
                      ),
                      width: width * 0.1,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  /// Live status bar
                  _buildLiveStatusBar(width, height),

                  /// Driver card
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.008,
                    ),
                    child: _buildDriverCard(width, height),
                  ),

                  /// Vehicle status + delivery info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVehicleStatus(width, height),
                        SizedBox(height: height * 0.008),
                        _buildDeliveryInfo(width, height),
                        SizedBox(height: height * 0.012),
                        _buildTravelCostRow(width),
                      ],
                    ),
                  ),

                  /// Divider
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.012),
                    child: Divider(
                      color: Colors.grey.shade200,
                      thickness: 6,
                      height: 0,
                    ),
                  ),

                  /// Timeline
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: _buildLocationTimeline(width, height),
                  ),

                  SizedBox(height: height * 0.03),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _timeAgoText() {
    final diff = DateTime.now().difference(_lastRefreshedAt);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Updated ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  }

  Widget _buildRefreshBar(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driverLoc = _trackingData!.driverLocation;
    final locationName = driverLoc.name.isNotEmpty
        ? driverLoc.name
        : 'Location not available';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.05,
        vertical: height * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Arrived $locationName",
                  style: TextStyle(
                    fontSize: width * 0.037,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  _timeAgoText(),
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: width * 0.03),
          GestureDetector(
            onTap: _isRefreshing ? null : _refreshData,
            child: Container(
              width: width * 0.12,
              height: width * 0.12,
              decoration: BoxDecoration(
                color: const Color(0xFF0077C8),
                shape: BoxShape.circle,
              ),
              child: _isRefreshing
                  ? Padding(
                      padding: EdgeInsets.all(width * 0.03),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: width * 0.06,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded map view with Last Update card
  Widget _buildExpandedMapView(double width, double height) {
    return Stack(
      children: [
        // Full screen Google Map
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialPosition,
          markers: _expandedMapMarkers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(
            bottom: height * 0.16,
            right: width * 0.02,
            top: height * 0.02,
          ),
          onMapCreated: (GoogleMapController controller) {
            _expandedMapController = controller;
            Future.delayed(const Duration(milliseconds: 300), () {
              _fitExpandedMapToAllMarkers();
            });
          },
        ),

        // Loading indicator for route
        if (_isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF0077C8)),
          ),

        // Center on vehicle button
        Positioned(
          bottom: height * 0.3,
          right: width * 0.04,
          child: GestureDetector(
            onTap: _centerOnVehicle,
            child: Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location,
                size: width * 0.06,
                color: const Color(0xFF0077C8),
              ),
            ),
          ),
        ),

        // Last Update Card at bottom
        Positioned(
          bottom: height * 0.02,
          left: width * 0.04,
          right: width * 0.04,
          child: _buildLastUpdateCard(width, height),
        ),
      ],
    );
  }

  /// Fit expanded map to show all markers
  void _fitExpandedMapToAllMarkers() {
    if (_expandedMapController == null) return;

    List<LatLng> allPoints = [];
    if (_pickupLatLng != null) allPoints.add(_pickupLatLng!);
    if (_currentLatLng != null) allPoints.add(_currentLatLng!);
    if (_destinationLatLng != null) allPoints.add(_destinationLatLng!);

    if (allPoints.isEmpty) return;

    try {
      double minLat = allPoints.first.latitude;
      double maxLat = minLat;
      double minLng = allPoints.first.longitude;
      double maxLng = minLng;

      for (final point in allPoints) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      // Add padding to bounds
      final latPadding = (maxLat - minLat) * 0.2;
      final lngPadding = (maxLng - minLng) * 0.2;

      // Ensure minimum padding
      const minPadding = 0.01;
      final actualLatPadding = max(latPadding, minPadding);
      final actualLngPadding = max(lngPadding, minPadding);

      _expandedMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              minLat - actualLatPadding,
              minLng - actualLngPadding,
            ),
            northeast: LatLng(
              maxLat + actualLatPadding,
              maxLng + actualLngPadding,
            ),
          ),
          60,
        ),
      );
    } catch (e) {
      debugPrint('Error fitting expanded map to markers: $e');
    }
  }

  /// Fit small map to show all markers
  void _fitSmallMapToAllMarkers() {
    if (_smallMapController == null) return;

    List<LatLng> allPoints = [];
    if (_pickupLatLng != null) allPoints.add(_pickupLatLng!);
    if (_currentLatLng != null) allPoints.add(_currentLatLng!);
    if (_destinationLatLng != null) allPoints.add(_destinationLatLng!);

    if (allPoints.isEmpty) return;

    try {
      double minLat = allPoints.first.latitude;
      double maxLat = minLat;
      double minLng = allPoints.first.longitude;
      double maxLng = minLng;

      for (final point in allPoints) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      // Add padding to bounds
      final latPadding = (maxLat - minLat) * 0.2;
      final lngPadding = (maxLng - minLng) * 0.2;

      // Ensure minimum padding
      const minPadding = 0.01;
      final actualLatPadding = max(latPadding, minPadding);
      final actualLngPadding = max(lngPadding, minPadding);

      _smallMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              minLat - actualLatPadding,
              minLng - actualLngPadding,
            ),
            northeast: LatLng(
              maxLat + actualLatPadding,
              maxLng + actualLngPadding,
            ),
          ),
          40,
        ),
      );
    } catch (e) {
      debugPrint('Error fitting small map to markers: $e');
    }
  }

  Widget _buildHeader(BuildContext context, double width, double height) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.012,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isMapExpanded) {
                setState(() => _isMapExpanded = false);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: width * 0.04,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle tracking',
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Order #${widget.bookingId}',
                style: TextStyle(
                  fontSize: width * 0.03,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          RefreshButton(onTap: _refreshData),
        ],
      ),
    );
  }

  Widget _buildSmallMapSection(double width, double height) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialPosition,
          markers: _smallMapMarkers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(bottom: height * 0.15),
          onMapCreated: (GoogleMapController controller) {
            _smallMapController = controller;
            Future.delayed(const Duration(milliseconds: 300), () {
              _fitSmallMapToAllMarkers();
            });
          },
        ),
        if (_isLoadingRoute)
          Container(
            color: Colors.white.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0077C8)),
            ),
          ),
      ],
    );
  }

  /// Live status bar with pulsing dot and location
  Widget _buildLiveStatusBar(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driverLoc = _trackingData!.driverLocation;
    final locationName = driverLoc.name.isNotEmpty
        ? driverLoc.name
        : 'Tracking...';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.005,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          // Pulsing live dot
          SizedBox(
            width: 12,
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12 * _pulseAnimation.value * 0.6,
                      height: 12 * _pulseAnimation.value * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withValues(
                          alpha:
                              (1.0 - (_pulseAnimation.value - 1.0) / 1.5) * 0.3,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: width * 0.03),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: width * 0.028,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(
              locationName,
              style: TextStyle(
                fontSize: width * 0.033,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _timeAgoText(),
            style: TextStyle(
              fontSize: width * 0.028,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern driver card with avatar, info, and call button
  Widget _buildDriverCard(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driver = _trackingData!.driverDetails;
    final driverName = driver.driverName.isNotEmpty
        ? driver.driverName
        : 'Not assigned';
    final vehicleNumber = driver.vehicleNumber.isNotEmpty
        ? driver.vehicleNumber
        : 'N/A';
    final driverPhone = driver.driverPhone;

    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver avatar
          Container(
            width: width * 0.13,
            height: width * 0.13,
            decoration: BoxDecoration(
              color: const Color(0xFF0077C8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: driver.driverImage.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      driver.driverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: width * 0.07,
                        color: const Color(0xFF0077C8),
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: width * 0.07,
                    color: const Color(0xFF0077C8),
                  ),
          ),
          SizedBox(width: width * 0.035),
          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: TextStyle(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: width * 0.035,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: width * 0.015),
                    Text(
                      vehicleNumber,
                      style: TextStyle(
                        fontSize: width * 0.033,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call button
          if (driverPhone.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: driverPhone);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Icon(
                  Icons.phone,
                  size: width * 0.05,
                  color: Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverDetails(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driver = _trackingData!.driverDetails;
    final driverName = driver.driverName.isNotEmpty
        ? driver.driverName
        : 'Not assigned';
    final driverMobile = driver.driverPhone.isNotEmpty
        ? '+91${driver.driverPhone}'
        : 'N/A';
    final vehicleNumber = driver.vehicleNumber.isNotEmpty
        ? driver.vehicleNumber
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver Details',
          style: TextStyle(
            fontSize: width * 0.042,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: height * 0.015),
        Wrap(
          spacing: width * 0.08,
          runSpacing: height * 0.016,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _infoItem(
              icon: Icons.person_outline,
              text: driverName,
              width: width,
            ),
            _infoItem(
              icon: Icons.phone_outlined,
              text: driverMobile,
              width: width,
            ),
            _infoItem(
              icon: Icons.local_shipping_outlined,
              text: vehicleNumber,
              width: width,
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String text,
    required double width,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: width * 0.05, color: Colors.grey.shade700),
        SizedBox(width: width * 0.02),
        Text(
          text,
          style: TextStyle(
            fontSize: width * 0.038,
            color: Colors.grey.shade800,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildVehicleStatus(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    String statusMessage =
        _trackingData!.vehicleDescription ??
        (_trackingData!.deliveryUpdates.note.isNotEmpty
            ? _trackingData!.deliveryUpdates.note
            : 'We\'ve received your booking. Within a few days, we will assign your vehicle');

    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: width * 0.04,
                color: const Color(0xFF0077C8),
              ),
              SizedBox(width: width * 0.02),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.008),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: width * 0.033,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final deliveryExpected = _trackingData!.deliveryUpdates.deliveryExpected;
    final expectedDelivery = _trackingData!.expectedDelivery;

    String deliveryText = '';

    if (deliveryExpected.isNotEmpty) {
      deliveryText = 'Delivery Expected on $deliveryExpected';
    } else if (expectedDelivery.isNotEmpty && expectedDelivery != 'N/A') {
      deliveryText = 'Delivery Expected on $expectedDelivery';
    }

    if (deliveryText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      deliveryText,
      style: TextStyle(fontSize: width * 0.036, color: Colors.grey.shade700),
    );
  }

  Widget _buildTravelCostRow(double width) {
    if (_trackingData == null) return const SizedBox.shrink();
    final travelCost = _trackingData!.travelCost;
    final expectedDelivery = _trackingData!.expectedDelivery;
    if (travelCost == 'N/A' &&
        (expectedDelivery == 'N/A' || expectedDelivery.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (travelCost != 'N/A')
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF6F6F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel cost',
                    style: TextStyle(
                      color: const Color(0xff374151),
                      fontSize: width * 0.035,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₹$travelCost',
                    style: TextStyle(
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (travelCost != 'N/A' &&
            expectedDelivery != 'N/A' &&
            expectedDelivery.isNotEmpty)
          const SizedBox(width: 8),
        if (expectedDelivery != 'N/A' && expectedDelivery.isNotEmpty)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF6F6F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Expected on',
                    style: TextStyle(
                      color: const Color(0xff374151),
                      fontSize: width * 0.035,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    expectedDelivery,
                    style: TextStyle(
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _addSplitPolylines(
    Set<Polyline> polylines,
    List<LatLng> routePoints,
    List<LatLng> waypoints,
  ) {
    if (routePoints.length < 2) return;

    polylines.add(
      Polyline(
        polylineId: const PolylineId('remaining'),
        points: routePoints,
        color: const Color(0xFF0077C8), // blue
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  /// Build the ordered list of all main timeline entries with their segment index.
  /// Each entry: { 'type': pickup|stop|driver|destination, 'data': ..., 'segmentIndex': int }
  List<Map<String, dynamic>> _buildOrderedTimelineEntries() {
    final driverLoc = _trackingData!.driverLocation;
    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;

    final passedStops = _routeStops.where((s) => s['passed'] == true).toList();
    final upcomingStops = _routeStops
        .where((s) => s['passed'] != true)
        .toList();

    List<Map<String, dynamic>> entries = [];
    int segIdx = 0;

    // Pickup (segment 0)
    entries.add({'type': 'pickup', 'segmentIndex': segIdx});

    // Passed stops
    for (final stop in passedStops) {
      segIdx++;
      entries.add({
        'type': 'stop',
        'data': stop,
        'segmentIndex': segIdx,
        'color': 'green',
      });
    }

    // Current driver location
    if (hasCurrentLocation) {
      segIdx++;
      entries.add({'type': 'driver', 'segmentIndex': segIdx});
    }

    // Upcoming stops
    for (final stop in upcomingStops) {
      segIdx++;
      entries.add({
        'type': 'stop',
        'data': stop,
        'segmentIndex': segIdx,
        'color': 'grey',
      });
    }

    // Destination
    segIdx++;
    entries.add({'type': 'destination', 'segmentIndex': segIdx});

    return entries;
  }

  /// Get the distance fraction for a given timeline entry
  double _getFractionForEntry(Map<String, dynamic> entry) {
    switch (entry['type']) {
      case 'pickup':
        return 0.0;
      case 'destination':
        return 1.0;
      case 'driver':
        if (_cumulativeDistances.isNotEmpty &&
            _fullPolyline.isNotEmpty &&
            _currentLatLng != null) {
          double minDist = double.infinity;
          int closestIdx = 0;
          for (int i = 0; i < _fullPolyline.length; i++) {
            final d =
                (_fullPolyline[i].latitude - _currentLatLng!.latitude).abs() +
                (_fullPolyline[i].longitude - _currentLatLng!.longitude).abs();
            if (d < minDist) {
              minDist = d;
              closestIdx = i;
            }
          }
          return _cumulativeDistances[closestIdx] / _cumulativeDistances.last;
        }
        return 0.5;
      case 'stop':
        return (entry['data']?['distance_fraction'] as double?) ?? 0.0;
      default:
        return 0.0;
    }
  }

  /// Handle timeline item tap — expand/collapse sub-stops
  void _onTimelineTap(
    int segmentIndex,
    double prevFraction,
    double currentFraction,
  ) async {
    // Toggle if already expanded
    if (_expandedSegmentIndex == segmentIndex) {
      setState(() => _expandedSegmentIndex = null);
      return;
    }

    // If already cached, just expand
    if (_subStopsCache.containsKey(segmentIndex)) {
      setState(() => _expandedSegmentIndex = segmentIndex);
      return;
    }

    // Need to generate sub-stops
    if (_fullPolyline.isEmpty || _cumulativeDistances.isEmpty) return;

    setState(() {
      _loadingSegment = segmentIndex;
      _expandedSegmentIndex = segmentIndex;
    });

    final subStops = await GoogleMapsService.generateSubStops(
      fullPolyline: _fullPolyline,
      cumulativeDistances: _cumulativeDistances,
      startFraction: prevFraction,
      endFraction: currentFraction,
      totalDurationSeconds: _totalRouteDurationSeconds,
      count: 3,
    );

    if (mounted) {
      setState(() {
        _subStopsCache[segmentIndex] = subStops;
        _loadingSegment = null;
      });
    }
  }

  Widget _buildLocationTimeline(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;

    List<Widget> timelineItems = [];

    /// -------- Pickup --------
    timelineItems.add(
      GestureDetector(
        onTap: () {
          _onTimelineTap(
            0,
            0.0,
            1 / (_trackingData!.routeWaypoints.length + 1),
          );
        },
        child: _buildTimelineItem(
          width,
          height,
          Icons.location_on,
          Colors.green,
          'Pickup started from',
          pickup.name.isNotEmpty ? pickup.name : 'N/A',
          _formatDateTime(driverLoc.updatedAt),
          isFirst: true,
        ),
      ),
    );

    /// -------- Vehicle --------
    if (hasCurrentLocation) {
      timelineItems.add(
        _buildTimelineItem(
          width,
          height,
          Icons.local_shipping,
          Colors.green,
          driverLoc.name.isNotEmpty ? driverLoc.name : 'Current Location',
          _formatDate(driverLoc.updatedAt),
          _formatDateTime(driverLoc.updatedAt),
          isPulsing: true,
        ),
      );
    }

    /// -------- EXPANDED: REAL STOPS ONLY --------
    if (_isTimelineExpanded) {
      final waypoints = _trackingData!.routeWaypoints;

      for (int i = 0; i < waypoints.length; i++) {
        final wp = waypoints[i];
        final fraction = (i + 1) / (_trackingData!.routeWaypoints.length + 1);
        final time = _getTimeForFraction(fraction);

        final currentFraction =
            (i + 1) / (_trackingData!.routeWaypoints.length + 1);
        final prevFraction = i / (_trackingData!.routeWaypoints.length + 1);

        timelineItems.add(
          GestureDetector(
            onTap: () {
              final segmentIndex = i + 1;

              _onTimelineTap(segmentIndex, prevFraction, currentFraction);
            },
            child: _buildTimelineItem(
              width,
              height,
              Icons.circle,
              Colors.black,
              wp.name.isNotEmpty ? wp.name : 'Stop ${i + 1}',
              'Stop ${i + 1}',
              time,
            ),
          ),
        );

        // -------- SUB-STOPS BETWEEN THIS AND NEXT --------
      
          final segmentIndex = i + 1;

          final isExpanded = _expandedSegmentIndex == segmentIndex;
          final isLoading = _loadingSegment == segmentIndex;

          if (isExpanded) {
            timelineItems.add(
              _buildSubTimeline(
                width,
                height,
                segmentIndex,
                isLoading,
                Colors.grey,
              ),
            );
          }
        }
      }

    /// -------- Destination --------
    String destinationTime = '-';
    if (_routeStartTime != null && _totalRouteDurationSeconds > 0) {
      final arrivalTime = _routeStartTime!.add(
        Duration(seconds: _totalRouteDurationSeconds),
      );
      destinationTime = _formatDateTimeObj(arrivalTime);
    }

    final lastSegment = _trackingData!.routeWaypoints.length + 1;

    timelineItems.add(
      GestureDetector(
        onTap: () {
          final prevFraction =
              (_trackingData!.routeWaypoints.length) /
              (_trackingData!.routeWaypoints.length + 1);

          _onTimelineTap(lastSegment, prevFraction, 1.0);
        },
        child: _buildTimelineItem(
          width,
          height,
          Icons.flag,
          Colors.grey,
          'Destination',
          destination.name.isNotEmpty ? destination.name : 'N/A',
          destinationTime,
          isLast: true,
        ),
      ),
    );

    /// -------- Expand / Collapse Button --------
    timelineItems.add(
      GestureDetector(
        onTap: () {
          setState(() {
            _isTimelineExpanded = !_isTimelineExpanded;
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: height * 0.015),
          child: Center(
            child: Text(
              _isTimelineExpanded ? "Show Less" : "Show Full Route",
              style: TextStyle(
                color: const Color(0xFF0077C8),
                fontSize: width * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    return Column(children: timelineItems);
  }

  Future<void> _generateSubStopsForSegment(int index) async {
    if (_fullPolyline.isEmpty || _cumulativeDistances.isEmpty) return;

    if (_subStopsCache.containsKey(index)) return;

    final totalDistance = _cumulativeDistances.last;

    // divide route properly by distance
    final segmentCount = _trackingData!.routeWaypoints.length + 1;

    final startFraction = (index / segmentCount).clamp(0.0, 1.0);
    final endFraction = ((index + 1) / segmentCount).clamp(0.0, 1.0);

    final subStops = await GoogleMapsService.generateSubStops(
      fullPolyline: _fullPolyline,
      cumulativeDistances: _cumulativeDistances,
      startFraction: startFraction,
      endFraction: endFraction,
      totalDurationSeconds: _totalRouteDurationSeconds,
      count: 3,
    );

    if (mounted) {
      setState(() {
        _subStopsCache[index] = subStops;
      });
    }
  }

  String _getTimeForFraction(double fraction) {
    if (_routeStartTime == null || _totalRouteDurationSeconds == 0) return '-';

    final seconds = (fraction * _totalRouteDurationSeconds).round();

    final dt = _routeStartTime!.add(Duration(seconds: seconds));

    return _formatDateTimeObj(dt);
  }

  /// Build the sub-timeline items between two main stops
  Widget _buildSubTimeline(
    double width,
    double height,
    int segmentIndex,
    bool isLoading,
    Color lineColor,
  ) {
    if (isLoading && !_subStopsCache.containsKey(segmentIndex)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — same width as main timeline icon column
          SizedBox(
            width: width * 0.09,
            child: Center(
              child: Container(
                width: 2,
                height: height * 0.04,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          SizedBox(width: width * 0.04),
          Padding(
            padding: EdgeInsets.only(top: height * 0.012),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width * 0.04,
                  height: width * 0.04,
                  child: const CircularProgressIndicator(strokeWidth: 1.5),
                ),
                SizedBox(width: width * 0.02),
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: width * 0.03, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final subStops = _subStopsCache[segmentIndex];
    if (subStops == null || subStops.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: subStops.map((sub) {
          String subTime = '-';
          if (_routeStartTime != null) {
            final seconds = sub['estimated_seconds'] as int? ?? 0;
            final dt = _routeStartTime!.add(Duration(seconds: seconds));
            subTime = _formatDateTimeObj(dt);
          }
          return _buildSubTimelineItem(
            width,
            height,
            sub['name'],
            subTime,
            lineColor,
          );
        }).toList(),
      ),
    );
  }

  /// Single sub-timeline item (smaller dot, lighter style)
  Widget _buildSubTimelineItem(
    double width,
    double height,
    String name,
    String time,
    Color lineColor,
  ) {
    final dotSize = width * 0.025;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column — same width as main timeline, centered line + dot
        SizedBox(
          width: width * 0.09,
          child: Column(
            children: [
              Container(
                width: 2,
                height: height * 0.015,
                color: Colors.grey.shade300,
              ),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: lineColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  color: Colors.white,
                ),
              ),
              Container(
                width: 2,
                height: height * 0.015,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
        SizedBox(width: width * 0.04),
        // Content — vertically centered with the dot
        Expanded(
          child: Container(
            height: height * 0.03 + dotSize,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: width * 0.033,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      return '-';
    }
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  /// Convert "HH:mm" (24h) string to "hh:mm AM/PM" (12h) format
  String _format24to12(String time24) {
    try {
      final parts = time24.split(':');
      final hour24 = int.parse(parts[0]);
      final minute = parts[1];
      final hour = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
      final amPm = hour24 >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
    } catch (_) {
      return time24;
    }
  }

  String _formatDateTimeObj(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) return '$hours hours $minutes mins';
    if (hours > 0) return '$hours hours';
    return '$minutes mins';
  }

  Widget _buildTimelineItem(
    double width,
    double height,
    IconData icon,
    Color iconColor,
    String title,
    String? subtitle,
    String time, {
    bool isFirst = false,
    bool isLast = false,
    bool etaLabel = false,
    bool isPulsing = false,
  }) {
    final isActive = iconColor == Colors.green;
    final iconCircle = Container(
      width: width * 0.09,
      height: width * 0.09,
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: width * 0.04,
        color: isActive ? Colors.green : Colors.grey.shade500,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            isPulsing
                ? SizedBox(
                    width: width * 0.09,
                    height: width * 0.09,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final size = width * 0.09 * _pulseAnimation.value;
                            final offset = (size - width * 0.09) / 2;
                            return Positioned(
                              left: -offset,
                              top: -offset,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withValues(
                                    alpha:
                                        (1.0 -
                                            (_pulseAnimation.value - 1.0) /
                                                1.5) *
                                        0.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Solid icon circle
                        iconCircle,
                      ],
                    ),
                  )
                : iconCircle,
            if (!isLast)
              Builder(
                builder: (context) {
                  double lineHeight;
                  if (subtitle != null && subtitle.isNotEmpty) {
                    // Measure subtitle lines to adjust connecting line height
                    final textSpan = TextSpan(
                      text: subtitle,
                      style: TextStyle(fontSize: width * 0.034),
                    );
                    final tp = TextPainter(
                      text: textSpan,
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                    );
                    tp.layout(maxWidth: width * 0.55);
                    final lines = tp.computeLineMetrics().length;
                    if (lines >= 2) {
                      lineHeight = height * 0.04;
                    } else {
                      lineHeight = height * 0.061;
                    }
                  } else {
                    lineHeight = height * 0.035;
                  }
                  return Container(
                    width: 2,
                    height: lineHeight,
                    color: Colors.grey.shade300,
                  );
                },
              ),
          ],
        ),
        SizedBox(width: width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * 0.038,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: width * 0.034,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  etaLabel
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: width * 0.012,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0077C8,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Deliver in',
                                style: TextStyle(
                                  fontSize: width * 0.028,
                                  color: const Color(0xFF0077C8),
                                ),
                              ),
                              SizedBox(height: width * 0.005),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: width * 0.035,
                                    color: const Color(0xFF0077C8),
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: width * 0.032,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0077C8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Text(
                          time,
                          style: TextStyle(
                            fontSize: width * 0.036,
                            color: Colors.grey.shade600,
                          ),
                        ),
                ],
              ),
              if (!isLast) SizedBox(height: height * 0.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdateCard(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driverLoc = _trackingData!.driverLocation;
    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;

    // Get last update from driverLocation.updatedAt
    String lastUpdateTime = _formatDateTime(driverLoc.updatedAt);
    String lastUpdateDate = _formatDate(driverLoc.updatedAt);
    print("checking for last update $lastUpdateDate");
    print("checking for last update $lastUpdateTime");
    // Get location name from API response
    String locationName = driverLoc.name.isNotEmpty
        ? driverLoc.name
        : 'Location not available';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.035,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live indicator
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: hasCurrentLocation
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping,
              size: width * 0.045,
              color: hasCurrentLocation ? Colors.green : Colors.grey,
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locationName,
                  style: TextStyle(
                    fontSize: width * 0.036,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '$lastUpdateTime, $lastUpdateDate',
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Center on vehicle
          GestureDetector(
            onTap: _centerOnVehicle,
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFF0077C8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location,
                size: width * 0.045,
                color: const Color(0xFF0077C8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnVehicle() {
    if (_expandedMapController == null) {
      debugPrint('Expanded map controller is null');
      return;
    }

    // If no current location, fit to all markers instead
    if (_currentLatLng == null) {
      _fitExpandedMapToAllMarkers();
      return;
    }

    try {
      _expandedMapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLatLng!, zoom: 15.0),
        ),
      );
    } catch (e) {
      debugPrint('Error centering on vehicle: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timeAgoTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _smallMapController?.dispose();
    _expandedMapController?.dispose();
    super.dispose();
  }
}
