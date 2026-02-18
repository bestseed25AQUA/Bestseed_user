import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/utils/custom_marker_helper.dart';
import 'package:seedsuser/app/utils/google_maps_service.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';

class VehicleTrackingMapScreen extends StatefulWidget {
  final String bookingId;

  const VehicleTrackingMapScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<VehicleTrackingMapScreen> createState() =>
      _VehicleTrackingMapScreenState();
}

class _VehicleTrackingMapScreenState extends State<VehicleTrackingMapScreen> {
  final VehicleTrackingController controller = Get.put(VehicleTrackingController());

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

  // Refresh state
  DateTime _lastRefreshedAt = DateTime.now();
  bool _isRefreshing = false;
  Timer? _timeAgoTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    // Update "Updated X mins ago" text every 30 seconds
    _timeAgoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
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
    _smallTruckMarker =
        await CustomMarkerHelper.getTruckMarkerFromAsset(size: 30);
    _smallPickupMarker =
        await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 26);
    _smallDestinationMarker =
        await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 26);

    // Expanded map markers (bigger size for full screen view)
    _expandedTruckMarker =
        await CustomMarkerHelper.getTruckMarkerFromAsset(size: 60);
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
      _destinationLatLng =
          await GoogleMapsService.geocodeAddress(destination.name);
    }

    // Build markers for both small and expanded views
    _buildMarkers();

    /// -------- Route + Intermediate Stops using single Directions API call --------
    if (_pickupLatLng != null && _destinationLatLng != null) {
      final routeData = await GoogleMapsService.getRouteWithStops(
        origin: _pickupLatLng!,
        destination: _destinationLatLng!,
        driverPosition: _currentLatLng,
      );

      if (routeData.isNotEmpty) {
        final polylinePoints =
            routeData['polyline_points'] as List<LatLng>? ?? [];
        _routeStops =
            routeData['stops'] as List<Map<String, dynamic>>? ?? [];
        _totalRouteDurationSeconds =
            routeData['total_duration_seconds'] as int? ?? 0;

        final driverSplitIndex =
            routeData['driver_split_index'] as int? ?? 0;
        final driverFraction =
            routeData['driver_progress_fraction'] as double? ?? 0.0;
        final remainingSeconds =
            routeData['remaining_duration_seconds'] as int? ?? 0;

        _estimatedDuration = _formatDuration(remainingSeconds);

        // Calculate estimated route start time from driver's last update
        final driverLoc = _trackingData!.driverLocation;
        if (_currentLatLng != null &&
            driverLoc.updatedAt != null &&
            driverLoc.updatedAt!.isNotEmpty) {
          try {
            final updatedAt = DateTime.parse(driverLoc.updatedAt!);
            final elapsedSeconds =
                (driverFraction * _totalRouteDurationSeconds).round();
            _routeStartTime =
                updatedAt.subtract(Duration(seconds: elapsedSeconds));
          } catch (_) {}
        }

        if (polylinePoints.isNotEmpty) {
          if (_currentLatLng != null &&
              driverSplitIndex > 0 &&
              driverSplitIndex < polylinePoints.length) {
            // Green solid line: pickup to driver position (completed)
            polylines.add(
              Polyline(
                polylineId: const PolylineId('completed'),
                points: polylinePoints.sublist(0, driverSplitIndex + 1),
                color: Colors.green,
                width: 5,
              ),
            );
            // Blue dashed line: driver position to destination (remaining)
            polylines.add(
              Polyline(
                polylineId: const PolylineId('remaining'),
                points: polylinePoints.sublist(driverSplitIndex),
                color: const Color(0xFF0077C8),
                width: 5,
                patterns: [
                  PatternItem.dash(20),
                  PatternItem.gap(10),
                ],
              ),
            );
          } else {
            // No current location — full route as dashed blue
            polylines.add(
              Polyline(
                polylineId: const PolylineId('full_route'),
                points: polylinePoints,
                color: const Color(0xFF0077C8),
                width: 5,
                patterns: [
                  PatternItem.dash(20),
                  PatternItem.gap(10),
                ],
              ),
            );
          }
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
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
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

  /// Build markers for both small and expanded map views
  void _buildMarkers() {
    if (_trackingData == null) return;

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    Set<Marker> smallMarkers = {};
    Set<Marker> expandedMarkers = {};

    /// -------- Pickup Markers --------
    if (_pickupLatLng != null) {
      smallMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: _smallPickupMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: pickup.name,
          ),
        ),
      );
      expandedMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: _expandedPickupMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: pickup.name,
          ),
        ),
      );
    }

    /// -------- Current/Truck Markers --------
    if (_currentLatLng != null) {
      smallMarkers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _currentLatLng!,
          icon: _smallTruckMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Vehicle Location',
            snippet: driverLoc.name.isNotEmpty ? driverLoc.name : 'Current Position',
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
      expandedMarkers.add(
        Marker(
          markerId: const MarkerId('vehicle'),
          position: _currentLatLng!,
          icon: _expandedTruckMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Vehicle Location',
            snippet: driverLoc.name.isNotEmpty ? driverLoc.name : 'Current Position',
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    /// -------- Destination Markers --------
    if (_destinationLatLng != null) {
      smallMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon: _smallDestinationMarker ??
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
          icon: _expandedDestinationMarker ??
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
      _initialPosition = CameraPosition(
        target: points.first,
        zoom: 14.0,
      );
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

  /// Default view with small map + details + timeline
  Widget _buildDefaultView(double width, double height) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Map Section (clickable to expand)
                _buildSmallMapSection(width, height),

                /// Content Section
                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDriverDetails(width, height),
                      SizedBox(height: height * 0.025),
                      _buildVehicleStatus(width, height),
                      SizedBox(height: height * 0.01),
                      _buildDeliveryInfo(width, height),
                      SizedBox(height: height * 0.025),
                      _buildLocationTimeline(width, height),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Bottom refresh bar
        _buildRefreshBar(width, height),
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
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
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
            child: CircularProgressIndicator(
              color: Color(0xFF0077C8),
            ),
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
            southwest:
                LatLng(minLat - actualLatPadding, minLng - actualLngPadding),
            northeast:
                LatLng(maxLat + actualLatPadding, maxLng + actualLngPadding),
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
            southwest:
                LatLng(minLat - actualLatPadding, minLng - actualLngPadding),
            northeast:
                LatLng(maxLat + actualLatPadding, maxLng + actualLngPadding),
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
        horizontal: width * 0.05,
        vertical: height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isMapExpanded) {
                setState(() {
                  _isMapExpanded = false;
                });
              } else {
                Navigator.pop(context);
              }
            },
            child: Icon(
              Icons.arrow_back,
              size: width * 0.06,
              color: Colors.black,
            ),
          ),
          SizedBox(width: width * 0.04),
          Text(
            'Vehicle tracking',
            style: TextStyle(
              fontSize: width * 0.048,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMapSection(double width, double height) {
    return Container(
      height: height * 0.22,
      margin: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPosition,
              markers: _smallMapMarkers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _smallMapController = controller;
                Future.delayed(const Duration(milliseconds: 300), () {
                  _fitSmallMapToAllMarkers();
                });
              },
            ),
            // Loading overlay
            if (_isLoadingRoute)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0077C8),
                  ),
                ),
              ),
            // Expand icon
            Positioned(
              top: width * 0.03,
              right: width * 0.03,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMapExpanded = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(width * 0.02),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    size: width * 0.045,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDetails(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final driver = _trackingData!.driverDetails;
    final driverName = driver.driverName.isNotEmpty ? driver.driverName : 'Not assigned';
    final driverMobile =
        driver.driverPhone.isNotEmpty ? '+91${driver.driverPhone}' : 'N/A';
    final vehicleNumber =
        driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : 'N/A';

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
        Icon(
          icon,
          size: width * 0.05,
          color: Colors.grey.shade700,
        ),
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

    String statusMessage = _trackingData!.vehicleDescription ??
        (_trackingData!.deliveryUpdates.note.isNotEmpty
            ? _trackingData!.deliveryUpdates.note
            : 'We\'ve received your booking. Within a few days, we will assign your vehicle');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Status',
          style: TextStyle(
            fontSize: width * 0.042,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          statusMessage,
          style: TextStyle(
            fontSize: width * 0.036,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
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
      style: TextStyle(
        fontSize: width * 0.036,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildLocationTimeline(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;

    // Split intermediate stops into passed and upcoming
    final passedStops =
        _routeStops.where((s) => s['passed'] == true).toList();
    final upcomingStops =
        _routeStops.where((s) => s['passed'] != true).toList();

    List<Widget> timelineItems = [];

    // 1. Pickup location
    String pickupTime = '-';
    if (_routeStartTime != null) {
      pickupTime = _formatDateTimeObj(_routeStartTime!);
    } else {
      pickupTime = _formatDateTime(driverLoc.updatedAt);
    }
    timelineItems.add(
      _buildTimelineItem(
        width,
        height,
        Icons.location_on,
        hasCurrentLocation ? Colors.green : Colors.grey,
        'Pickup started from',
        pickup.name.isNotEmpty ? pickup.name : 'N/A',
        pickupTime,
        isFirst: true,
      ),
    );

    // 2. Passed intermediate stops
    for (final stop in passedStops) {
      String stopTime = '-';
      if (_routeStartTime != null) {
        final estimatedSeconds = stop['estimated_seconds'] as int? ?? 0;
        final stopDateTime =
            _routeStartTime!.add(Duration(seconds: estimatedSeconds));
        stopTime = _formatDateTimeObj(stopDateTime);
      }
      timelineItems.add(
        _buildTimelineItem(
          width,
          height,
          Icons.circle,
          Colors.green,
          stop['name'] as String? ?? 'Unknown',
          null,
          stopTime,
        ),
      );
    }

    // 3. Current location (if vehicle is in transit)
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
        ),
      );
    }

    // 4. Upcoming intermediate stops
    for (final stop in upcomingStops) {
      String stopTime = '-';
      if (_routeStartTime != null) {
        final estimatedSeconds = stop['estimated_seconds'] as int? ?? 0;
        final stopDateTime =
            _routeStartTime!.add(Duration(seconds: estimatedSeconds));
        stopTime = _formatDateTimeObj(stopDateTime);
      }
      timelineItems.add(
        _buildTimelineItem(
          width,
          height,
          Icons.circle,
          Colors.grey,
          stop['name'] as String? ?? 'Unknown',
          null,
          stopTime,
        ),
      );
    }

    // 5. Destination
    String destinationTime = '-';
    if (_routeStartTime != null && _totalRouteDurationSeconds > 0) {
      final arrivalTime = _routeStartTime!.add(Duration(seconds: _totalRouteDurationSeconds));
      destinationTime = _formatDateTimeObj(arrivalTime);
    }
    timelineItems.add(
      _buildTimelineItem(
        width,
        height,
        Icons.flag,
        Colors.grey,
        'Destination',
        destination.name.isNotEmpty ? destination.name : 'N/A',
        destinationTime,
        isLast: true,
      ),
    );

    // 6. ETA row below destination
    if (_estimatedDuration.isNotEmpty) {
      timelineItems.add(
        Padding(
          padding: EdgeInsets.only(left: width * 0.08 + width * 0.04, top: height * 0.01),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: width * 0.015,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0077C8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deliver in',
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: const Color(0xFF0077C8),
                  ),
                ),
                SizedBox(width: width * 0.015),
                Icon(
                  Icons.access_time,
                  size: width * 0.035,
                  color: const Color(0xFF0077C8),
                ),
                SizedBox(width: width * 0.01),
                Text(
                  _estimatedDuration,
                  style: TextStyle(
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0077C8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: timelineItems);
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: width * 0.08,
              height: width * 0.08,
              decoration: BoxDecoration(
                color: iconColor == Colors.green
                    ? Colors.green
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: width * 0.045,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: height * 0.05,
                color: Colors.grey.shade300,
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
                            color: const Color(0xFF0077C8).withValues(alpha: 0.1),
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
              if (!isLast) SizedBox(height: height * 0.01),
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
    // Get location name
    String locationName = driverLoc.name.isNotEmpty
        ? driverLoc.name
        : 'Location not available';

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Last Update Title
          Text(
            'Last Update',
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: height * 0.015),

          // Status indicator and time
          Row(
            children: [
              // Green dot indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasCurrentLocation ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: width * 0.03),
              // Time and date
              Text(
                '$lastUpdateTime, $lastUpdateDate',
                style: TextStyle(
                  fontSize: width * 0.038,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),

          // Location name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: width * 0.055),
              Expanded(
                child: Text(
                  locationName,
                  style: TextStyle(
                    fontSize: width * 0.035,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
          CameraPosition(
            target: _currentLatLng!,
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error centering on vehicle: $e');
    }
  }

  @override
  void dispose() {
    _timeAgoTimer?.cancel();
    _smallMapController?.dispose();
    _expandedMapController?.dispose();
    super.dispose();
  }
}
