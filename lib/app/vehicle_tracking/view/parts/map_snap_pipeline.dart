part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SNAP PIPELINE, GEO UTILITIES, BEARING, MARKERS & CAMERA CALCULATION
//
// Takes a raw GPS coordinate and snaps it onto the nearest road segment
// using a 7-gate filter pipeline so the vehicle marker stays on the road:
//   Gate 0 — if the driver is stopped, hold the last known position
//   Gate 1 — reject the snap if it is too far from the route (noise)
//   Gate 2 — reject if the snap direction disagrees with the GPS direction
//   Gate 3 — reject if the snap jumped to a parallel road
//   Pass    — accept the snap, advance the segment index forward
//
// Also contains all geo math helpers:
//   • Haversine distance between two LatLng points (in metres)
//   • Project a point onto a line segment (for snapping)
//   • Minimum distance from a point to a polyline
//   • Compass bearing between two points
//   • Downsample breadcrumbs on long trips to save memory
//
// Builds the truck / pickup / destination markers for both map sizes,
// warms up the snap pipeline state from timeline history on first load,
// and calculates the initial camera zoom to fit the whole route in view.
// ─────────────────────────────────────────────────────────────────────────────

extension MapSnapPipeline on _VehicleTrackingMapScreenState {
  // ── Haversine distance in meters ──
  double _haversineMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * R * asin(sqrt(h));
  }

  /// Minimum perpendicular distance from [point] to the polyline (segment-based).
  double _minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return _haversineMeters(point, polyline.first);

    double minDist = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final projected = _projectOntoSegment(point, polyline[i], polyline[i + 1]);
      final d = _haversineMeters(point, projected);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Downsample breadcrumbs to prevent memory/render issues on long trips.
  void _downsampleBreadcrumbs() {
    final total = _driverBreadcrumbs.length;
    final halfIdx = total ~/ 2;

    final older = <LatLng>[];
    for (int i = 0; i < halfIdx; i++) {
      if (i % 3 == 0) {
        older.add(_driverBreadcrumbs[i]);
      } else if (i >= 1 && i < halfIdx - 1) {
        final prev = _driverBreadcrumbs[i - 1];
        final curr = _driverBreadcrumbs[i];
        final next = _driverBreadcrumbs[i + 1];
        final b1 = _getBearing(prev, curr);
        final b2 = _getBearing(curr, next);
        var diff = (b2 - b1).abs();
        if (diff > 180) diff = 360 - diff;
        if (diff > 25) older.add(curr); // turning point — keep it
      }
    }

    final recent = _driverBreadcrumbs.sublist(halfIdx);
    _driverBreadcrumbs = [...older, ...recent];
  }

  /// Project point P onto line segment A->B, returning the closest point on AB.
  LatLng _projectOntoSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.latitude - a.latitude;
    final dy = b.longitude - a.longitude;
    if (dx == 0 && dy == 0) return a;
    var t = ((p.latitude - a.latitude) * dx + (p.longitude - a.longitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    return LatLng(a.latitude + t * dx, a.longitude + t * dy);
  }

  /// Segment-based route snapping with 7-gate pipeline.
  /// Only searches nearby segments (forward) to prevent backward jumps.
  LatLng _snapToRoute(LatLng raw) {
    if (_fullPolyline.length < 2) return raw;

    // Idempotency cache — same input returns same output without re-running gates
    if (_snapCacheInput != null && _snapCacheOutput != null) {
      if ((_snapCacheInput!.latitude - raw.latitude).abs() < 1e-7 &&
          (_snapCacheInput!.longitude - raw.longitude).abs() < 1e-7) {
        return _snapCacheOutput!;
      }
    }

    final threshold = _snapThreshold;
    final windowSize = _segmentSearchWindow;
    final searchStart = _currentSegmentIndex;
    final searchEnd = (_currentSegmentIndex + windowSize).clamp(0, _fullPolyline.length - 1).toInt();

    double minDist = double.infinity;
    LatLng snapped = raw;
    int bestIndex = _currentSegmentIndex;

    for (int i = searchStart; i < searchEnd; i++) {
      final projected = _projectOntoSegment(raw, _fullPolyline[i], _fullPolyline[i + 1]);
      final dist = _haversineMeters(raw, projected);
      if (dist < minDist) {
        minDist = dist;
        snapped = projected;
        bestIndex = i;
      }
    }

    // Widen forward window if no good match (but never scan entire route)
    if (minDist > threshold) {
      final wideEnd = (_currentSegmentIndex + windowSize * 3).clamp(0, _fullPolyline.length - 1).toInt();
      for (int i = searchEnd; i < wideEnd; i++) {
        final projected = _projectOntoSegment(raw, _fullPolyline[i], _fullPolyline[i + 1]);
        final dist = _haversineMeters(raw, projected);
        if (dist < minDist) {
          minDist = dist;
          snapped = projected;
          bestIndex = i;
        }
      }
    }

    // ── GATE 0: Stop filter ──
    if (!_driverIsMoving) {
      final hold = _lastAcceptedSnap
          ?? (_driverBreadcrumbs.isNotEmpty ? _driverBreadcrumbs.last : raw);
      _snapCacheInput = raw;
      _snapCacheOutput = hold;
      return hold;
    }

    // ── GATE 1: Snap quality (hard threshold, no raw fallback) ──
    if (minDist > threshold) {
      final hold = _lastAcceptedSnap
          ?? (_driverBreadcrumbs.isNotEmpty ? _driverBreadcrumbs.last : raw);
      _snapCacheInput = raw;
      _snapCacheOutput = hold;
      return hold;
    }

    // ── GATE 2: Bearing/direction agreement ──
    if (_lastAcceptedSnap != null) {
      final rawHop = _haversineMeters(_lastAcceptedSnap!, raw);
      if (rawHop > 15) {
        final rawBearing = _getBearing(_lastAcceptedSnap!, raw);
        final snapBearing = _getBearing(_lastAcceptedSnap!, snapped);
        var diff = (rawBearing - snapBearing).abs();
        if (diff > 180) diff = 360 - diff;
        final double maxBearingDiff = _currentMode == 0 ? 75 : (_currentMode == 1 ? 90 : 110);
        if (diff > maxBearingDiff) {
          _snapCacheInput = raw;
          _snapCacheOutput = _lastAcceptedSnap!;
          return _lastAcceptedSnap!;
        }
      }
    }

    // ── GATE 3: Parallel-road filter ──
    if (_lastAcceptedSnap != null && _lastAcceptedRaw != null) {
      final rawHop = _haversineMeters(_lastAcceptedRaw!, raw);
      final snapHop = _haversineMeters(_lastAcceptedSnap!, snapped);
      if (rawHop < 30 && snapHop > 80) {
        _snapCacheInput = raw;
        _snapCacheOutput = _lastAcceptedSnap!;
        return _lastAcceptedSnap!;
      }
    }

    // ── ALL GATES PASSED — commit ──
    _currentSegmentIndex = bestIndex;
    _lastAcceptedSnap = snapped;
    _lastAcceptedRaw = raw;
    _snapCacheInput = raw;
    _snapCacheOutput = snapped;
    return snapped;
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
    if (_fullPolyline.isEmpty) return 0;

    final searchEnd = (_currentSegmentIndex + 30).clamp(0, _fullPolyline.length);
    double minDist = double.infinity;
    int index = _currentSegmentIndex;

    for (int i = _currentSegmentIndex; i < searchEnd; i++) {
      final d = _haversineMeters(_fullPolyline[i], current);
      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }
    return index;
  }

  /// Warm up snap pipeline state after fresh load so first live poll has
  /// correct _currentSegmentIndex and populated snap state.
  void _replayTimelineThroughPipeline() {
    if (_trackingData == null) return;
    if (_fullPolyline.length < 2) return;
    if (_currentLatLng == null) return;

    // 1. Seed segment index from the CURRENT driver position
    _initializeSegmentIndex(_currentLatLng!);

    // 2. Snap the current position to its segment
    LatLng snappedCurrent = _currentLatLng!;
    if (_currentSegmentIndex < _fullPolyline.length - 1) {
      snappedCurrent = _projectOntoSegment(
        _currentLatLng!,
        _fullPolyline[_currentSegmentIndex],
        _fullPolyline[_currentSegmentIndex + 1],
      );
    }

    // 3. Extract timeline points for bearing/parallel context
    final timelinePoints = <LatLng>[];
    for (final t in _trackingData!.timeline) {
      final lat = t.lat;
      final lng = t.lng;
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        timelinePoints.add(LatLng(lat, lng));
      }
    }

    // 4. Seed snap state
    _lastAcceptedSnap = snappedCurrent;
    _lastAcceptedRaw = timelinePoints.isNotEmpty ? timelinePoints.last : _currentLatLng;

    // 5. Clear snap idempotency cache
    _snapCacheInput = null;
    _snapCacheOutput = null;

    debugPrint('Pipeline warmed from current position: '
        'segment $_currentSegmentIndex / ${_fullPolyline.length - 1} '
        '(timeline had ${timelinePoints.length} points)');
  }

  /// Global search of entire polyline to find the correct starting segment.
  /// Called ONCE on route load.
  void _initializeSegmentIndex(LatLng driverPos) {
    if (_fullPolyline.length < 2) return;
    double minDist = double.infinity;
    int bestIdx = 0;
    for (int i = 0; i < _fullPolyline.length - 1; i++) {
      final projected = _projectOntoSegment(driverPos, _fullPolyline[i], _fullPolyline[i + 1]);
      final d = _haversineMeters(driverPos, projected);
      if (d < minDist) {
        minDist = d;
        bestIdx = i;
      }
    }
    _currentSegmentIndex = bestIdx;
    debugPrint('Segment index initialized to $bestIdx (dist=${minDist.toStringAsFixed(0)}m)');
  }

  double _getRouteBearing(LatLng current) {
    if (_fullPolyline.length < 2) return 0;
    int index = _getClosestPolylineIndex(current);
    if (index >= _fullPolyline.length - 1) {
      index = _fullPolyline.length - 2;
    }
    return _getBearing(_fullPolyline[index], _fullPolyline[index + 1]);
  }

  void _updateVehicleBearing(LatLng? previous, LatLng? current) {
    if (previous == null || current == null) return;
    if (_haversineMeters(previous, current) < 2) return;
    _lastVehicleBearing = _getBearing(previous, current);
  }

  double _getVehicleBearing() {
    if (_lastVehicleMarkerLatLng != null && _currentLatLng != null) {
      _updateVehicleBearing(_lastVehicleMarkerLatLng, _currentLatLng);
    }
    if (_lastVehicleBearing != 0) return _lastVehicleBearing;
    if (_currentLatLng != null && _fullPolyline.isNotEmpty) {
      return _getRouteBearing(_currentLatLng!);
    }
    return 0;
  }

  /// Build markers for both small and expanded map views.
  void _buildMarkers() {
    if (_trackingData == null) return;

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    Set<Marker> smallMarkers = {};
    Set<Marker> expandedMarkers = {};

    // Pickup (home marker)
    final homeMarker = _homeMarkerLatLng ?? _pickupLatLng;
    final adminPickupName = _trackingData?.adminPickup?.name ?? '';
    final homeMarkerName = adminPickupName.isNotEmpty ? adminPickupName : pickup.name;
    if (homeMarker != null) {
      smallMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: homeMarker,
        icon: _smallPickupMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: homeMarkerName),
      ));
      expandedMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: homeMarker,
        icon: _expandedPickupMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: homeMarkerName),
      ));
    }

    // Vehicle marker
    if (_currentLatLng != null && _isActiveDrop) {
      final snappedPos = _snapToRoute(_currentLatLng!);
      final rotationAngle = _getVehicleBearing();
      final smallIcon = _smallTruckMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      final expandedIcon = _expandedTruckMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      smallMarkers.add(Marker(
        markerId: const MarkerId('vehicle'),
        position: snappedPos,
        icon: smallIcon,
        anchor: const Offset(0.5, 0.5),
        rotation: rotationAngle,
        flat: true,
        infoWindow: InfoWindow(title: 'Vehicle', snippet: driverLoc.name),
      ));
      expandedMarkers.add(Marker(
        markerId: const MarkerId('vehicle'),
        position: snappedPos,
        icon: expandedIcon,
        anchor: const Offset(0.5, 0.5),
        rotation: rotationAngle,
        flat: true,
        infoWindow: InfoWindow(title: 'Vehicle', snippet: driverLoc.name),
      ));
    }

    // Destination marker
    if (_destinationLatLng != null) {
      smallMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLatLng!,
        icon: _smallDestinationMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: destination.name),
      ));
      expandedMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLatLng!,
        icon: _expandedDestinationMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: destination.name),
      ));
    }

    _smallMapMarkers = smallMarkers;
    _expandedMapMarkers = expandedMarkers;
    _lastVehicleMarkerLatLng = _currentLatLng;
  }

  /// Calculate initial camera position to show the full route.
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
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = max(latDiff, lngDiff);

    double zoom;
    if (maxDiff > 5) zoom = 6;
    else if (maxDiff > 2) zoom = 7;
    else if (maxDiff > 1) zoom = 8;
    else if (maxDiff > 0.5) zoom = 9;
    else if (maxDiff > 0.2) zoom = 10;
    else if (maxDiff > 0.1) zoom = 11;
    else if (maxDiff > 0.05) zoom = 12;
    else zoom = 13;

    _initialPosition = CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoom);
  }
}
