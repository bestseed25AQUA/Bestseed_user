// These points are added by adithya

// Reduced Google Maps API cost by avoiding frequent Directions API calls
// Reused initial route instead of redrawing polyline on every GPS update
// Switched to marker-only updates for live movement (no full map redraw)
// previously route is guessing not shown actual travelled path
// Implemented breadcrumb-based tracking for travelled path (green line)
// Added intelligent rerouting only on route deviation (not continuously)
// Built hybrid snapping system (on-road smooth + off-road accurate)
// Prevented polyline cutting through buildings using snap + fallback logic
// Implemented segment-based route snapping (no full polyline scan)
// Added forward-only segment progression (no backward jumps)
// Designed dynamic speed-based system (city / suburban / highway modes)
// Adaptive thresholds for snapping, rerouting, breadcrumbs, and camera
// Implemented deviation detection with consecutive polling (noise-safe)
// Added immediate reroute for large deviations (>150m)
// Optimized breadcrumb density for long-distance travel (downsampling)
// Implemented smooth marker animation with easing
// Synced camera movement with marker animation (Uber-like follow mode)
// Added bearing-based vehicle rotation (realistic movement direction)
// Fixed rotation via asset normalization (no runtime hacks)
// Implemented camera follow mode with user override + recenter
// Dynamic zoom based on speed (city vs highway view)
// Prevented GPS jitter using spike + direction filtering
// Improved backend data consistency (timestamp ordering + deduplication)
// Switched from timeline dependency to real-time breadcrumb system
// Separated green (actual path) and blue (predicted route) logic
// Built lightweight reroute system (updates only remaining route)
// Handled long-distance trips efficiently (1000km+ scalability)

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/utils/custom_marker_helper.dart';
import 'package:seedsuser/app/utils/google_maps_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';

part 'parts/map_initialization.dart';
part 'parts/map_route.dart';
part 'parts/map_snap_pipeline.dart';
part 'parts/map_speed_mode.dart';
part 'parts/map_animation.dart';
part 'parts/map_timeline_logic.dart';
part 'parts/map_widgets.dart';
part 'parts/map_timeline_widgets.dart';

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
  static const Duration _liveTrackingPollInterval = Duration(seconds: 7);
  static const Duration _rerouteCooldown = Duration(seconds: 15);
  static const Duration _markerAnimationStepDuration = Duration(milliseconds: 40);
  static const int _markerAnimationSteps = 25; // 25 x 40ms = 1 second
  static const double _polylineRerouteThresholdMeters = 100;
  static const int _deviationsBeforeReroute = 2;
  static const Duration _followAutoResumeDelay = Duration(seconds: 8);

  late CameraPosition _initialPosition;
  late LatLng _currentVehiclePosition;

  // Markers for small map view
  Set<Marker> _smallMapMarkers = {};
  // Markers for expanded map view
  Set<Marker> _expandedMapMarkers = {};

  Set<Polyline> _polylines = {};

  bool _isMapExpanded = false;
  bool _isLoadingRoute = true;

  // Follow mode: camera tracks vehicle with bearing rotation
  bool _isFollowingVehicle = true;
  bool _isProgrammaticCameraMove = false;
  static const double _followZoom = 16.5;
  static const double _followTilt = 45.0;

  Timer? _followResumeTimer;

  // Custom markers for small map (smaller size)
  BitmapDescriptor? _smallTruckMarker;
  BitmapDescriptor? _smallPickupMarker;
  BitmapDescriptor? _smallDestinationMarker;

  // Custom markers for expanded map (bigger size)
  BitmapDescriptor? _expandedTruckMarker;
  BitmapDescriptor? _expandedPickupMarker;
  BitmapDescriptor? _expandedDestinationMarker;

  // LatLng positions
  LatLng? _pickupLatLng;
  LatLng? _homeMarkerLatLng;
  LatLng? _currentLatLng;
  LatLng? _destinationLatLng;
  LatLng? _lastVehicleMarkerLatLng;
  double _lastVehicleBearing = 0;

  // Segment-based snapping state
  int _currentSegmentIndex = 0;

  // Snap pipeline state
  LatLng? _lastAcceptedSnap;
  LatLng? _lastAcceptedRaw;
  LatLng? _lastRenderedSnap;

  // Snap idempotency cache
  LatLng? _snapCacheInput;
  LatLng? _snapCacheOutput;

  TrackingData? _trackingData;
  String _estimatedDuration = '';

  List<Map<String, dynamic>> _routeStops = [];
  DateTime? _routeStartTime;
  int _totalRouteDurationSeconds = 0;

  List<LatLng> _fullPolyline = [];
  List<double> _cumulativeDistances = [];

  // Approach polyline (admin pickup -> driver start)
  List<LatLng> _approachPolyline = [];

  // GPS breadcrumbs (actual driven path)
  List<LatLng> _driverBreadcrumbs = [];
  DateTime? _lastBreadcrumbTime;
  int _consecutiveDeviations = 0;

  // Point buffer for jitter filtering
  List<LatLng> _pointBuffer = [];
  static const int _minBufferCommitPoints = 3;
  bool _driverIsMoving = true;

  bool _isActiveDrop = true;

  // Speed-based dynamic behavior
  double _estimatedSpeedKmh = 0;
  LatLng? _lastSpeedCalcPos;
  DateTime? _lastSpeedCalcTime;
  int _currentMode = 0; // 0=city, 1=suburban, 2=highway
  int _pendingMode = 0;
  int _pendingModeCount = 0;
  static const int _modeChangeThreshold = 3;

  // Expandable sub-timelines
  int? _expandedSegmentIndex;
  Map<int, List<Map<String, dynamic>>> _subStopsCache = {};
  int? _loadingSegment;

  // Fixed timeline (Layer 1: Business milestones - NEVER changes)
  List<Map<String, dynamic>> _fixedStops = [];
  bool _isLoadingFixedStops = true;
  bool _fixedStopsGenerated = false;
  int _currentStopIndex = -1;
  Map<int, String> _passedStopTimes = {};

  // Full pickup->destination polyline for fixed stop generation
  List<LatLng> _fullRoutePolyline = [];
  List<double> _fullRouteCumulativeDistances = [];
  int _fullRouteDurationSeconds = 0;

  // Live remaining duration to drop
  int _remainingDurationSeconds = 0;

  // Preserved historical green path across reroutes
  final List<LatLng> _preservedGreenPath = [];

  // Highest fraction driver has ever reached on _fullRoutePolyline
  double _maxDriverFractionReached = 0.0;

  // Refresh state
  DateTime _lastRefreshedAt = DateTime.now();
  bool _isRefreshing = false;
  Timer? _timeAgoTimer;
  Timer? _autoRefreshTimer;
  Timer? _liveTrackingTimer;
  Timer? _markerAnimationTimer;
  DateTime? _lastRouteRefreshAt;

  // Pulse animation for vehicle icon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _timeAgoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    // Initialise first, then start live polling so there's no race condition
    _initializeMap().whenComplete(() {
      if (!mounted) return;
      _liveTrackingTimer = Timer.periodic(_liveTrackingPollInterval, (_) {
        if (mounted && !_isRefreshing) {
          _refreshData();
        }
      });
    });
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
            _buildHeader(context, width, height),
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

  @override
  void dispose() {
    _pulseController.dispose();
    _timeAgoTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _liveTrackingTimer?.cancel();
    _markerAnimationTimer?.cancel();
    _followResumeTimer?.cancel();
    _smallMapController?.dispose();
    _expandedMapController?.dispose();
    super.dispose();
  }
}
