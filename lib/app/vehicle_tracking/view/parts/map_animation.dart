part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MARKER ANIMATION & CAMERA CONTROL
//
// Smoothly moves the vehicle marker from its previous GPS position to the
// new one over 25 steps (1 second total) using a cubic ease-in-out curve,
// so the truck glides on screen instead of jumping.  Bearing is interpolated
// at the same time so the truck rotates naturally as it turns.
//
// Camera follow mode keeps the map locked on the vehicle with tilt + bearing
// rotation (Uber-style).  Zoom level adjusts automatically per driving mode:
//   • City 16.5 → Suburban 15.5 → Highway 14.5
//
// If the user manually pans the map, follow mode pauses.  After 8 seconds
// of no interaction it automatically re-enables and snaps back to the truck.
//
// Safety net: if the truck drifts outside the visible viewport while follow
// is paused, the camera pans once to bring it back into view.
//
// Recenter button instantly re-enables follow and animates back to the truck.
// Fit-to-markers zooms out to show pickup, vehicle, and destination at once.
// ─────────────────────────────────────────────────────────────────────────────

extension MapAnimation on _VehicleTrackingMapScreenState {
  void _animateVehicleMarker(LatLng from, LatLng to) {
    _markerAnimationTimer?.cancel();
    _lastVehicleMarkerLatLng = from;

    if (_haversineMeters(from, to) < 2) {
      _buildMarkers();
      if (mounted) setState(() {});
      return;
    }

    final startBearing = _lastVehicleBearing;
    final endBearing = _getBearing(from, to);
    int step = 0;

    _markerAnimationTimer = Timer.periodic(
      _VehicleTrackingMapScreenState._markerAnimationStepDuration,
      (timer) {
        step++;
        final linearT = step / _VehicleTrackingMapScreenState._markerAnimationSteps;
        final easedT = _easeInOutCubic(linearT);

        final interpolated = LatLng(
          from.latitude + (to.latitude - from.latitude) * easedT,
          from.longitude + (to.longitude - from.longitude) * easedT,
        );
        _currentLatLng = _snapToRoute(interpolated);

        double bearingDiff = endBearing - startBearing;
        if (bearingDiff > 180) bearingDiff -= 360;
        if (bearingDiff < -180) bearingDiff += 360;
        _lastVehicleBearing = (startBearing + bearingDiff * easedT) % 360;

        _buildMarkers();
        _lastVehicleMarkerLatLng = _currentLatLng;
        if (mounted) setState(() {});

        if (step >= _VehicleTrackingMapScreenState._markerAnimationSteps) {
          timer.cancel();
          _currentLatLng = _snapToRoute(to);
          _lastVehicleBearing = endBearing;
          _buildMarkers();
          _lastVehicleMarkerLatLng = _currentLatLng;
          _refreshCompletedPolylineFromTimeline();

          if (_isFollowingVehicle) {
            _animateCameraToVehicle();
          } else {
            _ensureVehicleVisible();
          }
        }
      },
    );
  }

  /// Re-arm the auto-resume timer every time the user touches the map.
  void _scheduleFollowAutoResume() {
    _followResumeTimer?.cancel();
    _followResumeTimer = Timer(
      _VehicleTrackingMapScreenState._followAutoResumeDelay,
      () {
        if (!mounted) return;
        if (_isFollowingVehicle) return;
        setState(() => _isFollowingVehicle = true);
        _animateCameraToVehicle();
      },
    );
  }

  /// Edge-detection safety net: if the truck leaves the viewport while
  /// follow mode is off, pan the camera once to keep it visible.
  Future<void> _ensureVehicleVisible() async {
    if (_currentLatLng == null) return;
    if (_isFollowingVehicle) return;

    final mapCtrl = _isMapExpanded ? _expandedMapController : _smallMapController;
    if (mapCtrl == null) return;

    try {
      final region = await mapCtrl.getVisibleRegion();
      final lat = _currentLatLng!.latitude;
      final lng = _currentLatLng!.longitude;
      final inside = lat >= region.southwest.latitude &&
          lat <= region.northeast.latitude &&
          lng >= region.southwest.longitude &&
          lng <= region.northeast.longitude;
      if (inside) return;

      _isProgrammaticCameraMove = true;
      await mapCtrl.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
      _isProgrammaticCameraMove = false;
    } catch (e) {
      _isProgrammaticCameraMove = false;
      debugPrint('ensureVehicleVisible failed: $e');
    }
  }

  /// Animate camera to follow vehicle with bearing rotation and tilt.
  void _animateCameraToVehicle() {
    if (_currentLatLng == null) return;

    final mapCtrl = _isMapExpanded ? _expandedMapController : _smallMapController;
    if (mapCtrl == null) return;

    final double zoom;
    switch (_currentMode) {
      case 2: zoom = 14.5; break;  // highway
      case 1: zoom = 15.5; break;  // suburban
      default: zoom = _VehicleTrackingMapScreenState._followZoom; // city
    }

    try {
      _isProgrammaticCameraMove = true;
      mapCtrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLatLng!,
            zoom: zoom,
            bearing: _lastVehicleBearing,
            tilt: _VehicleTrackingMapScreenState._followTilt,
          ),
        ),
      ).then((_) {
        _isProgrammaticCameraMove = false;
      });
    } catch (e) {
      _isProgrammaticCameraMove = false;
      debugPrint('Error animating camera to vehicle: $e');
    }
  }

  void _centerOnVehicle() {
    final mapCtrl = _isMapExpanded ? _expandedMapController : _smallMapController;
    if (mapCtrl == null) return;

    setState(() => _isFollowingVehicle = true);

    if (_currentLatLng == null) {
      if (_isMapExpanded) {
        _fitExpandedMapToAllMarkers();
      } else {
        _fitSmallMapToAllMarkers();
      }
      return;
    }

    try {
      _isProgrammaticCameraMove = true;
      mapCtrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLatLng!,
            zoom: _VehicleTrackingMapScreenState._followZoom,
            bearing: _lastVehicleBearing,
            tilt: _VehicleTrackingMapScreenState._followTilt,
          ),
        ),
      ).then((_) => _isProgrammaticCameraMove = false);
    } catch (e) {
      _isProgrammaticCameraMove = false;
      debugPrint('Error centering on vehicle: $e');
    }
  }

  void _fitExpandedMapToAllMarkers() {
    if (_expandedMapController == null) return;
    _fitMapToPoints(_expandedMapController!, padding: 60);
  }

  void _fitSmallMapToAllMarkers() {
    if (_smallMapController == null) return;
    _fitMapToPoints(_smallMapController!, padding: 40);
  }

  void _fitMapToPoints(GoogleMapController mapCtrl, {required double padding}) {
    final allPoints = <LatLng>[
      if (_pickupLatLng != null) _pickupLatLng!,
      if (_currentLatLng != null) _currentLatLng!,
      if (_destinationLatLng != null) _destinationLatLng!,
    ];
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

      final latPadding = max((maxLat - minLat) * 0.2, 0.01);
      final lngPadding = max((maxLng - minLng) * 0.2, 0.01);

      mapCtrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          padding,
        ),
      );
    } catch (e) {
      debugPrint('Error fitting map to markers: $e');
    }
  }
}
