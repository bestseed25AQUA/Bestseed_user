part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIXED TIMELINE LOGIC
//
// Generates the business milestone stops shown in the timeline (pickup →
// intermediate cities → destination) exactly once and never changes them,
// so the user always sees the same stop list regardless of reroutes.
//
// How stops are created:
//   • Fetches the full pickup-to-destination polyline from Google Directions
//   • Evenly spaces milestone points along the route by distance
//   • Merges in any named waypoints from the booking (e.g. specific cities)
//   • Sorts every stop by its position along the route (not alphabetically)
//   • Saves the result to SharedPreferences so it survives app restarts
//
// Progress tracking — runs on every GPS poll:
//   • Converts the driver's current position to a 0–1 fraction along the route
//   • Marks stops as passed when the driver goes beyond them (one-way, no rewind)
//   • Records the actual timestamp when each stop is first passed
//   • Saves the current stop index so progress is restored after an app restart
//
// ETA calculation:
//   • Uses the live remaining duration from the Directions API as the base
//   • Adjusts per stop by interpolating remaining seconds at that fraction
//   • Falls back to a distance-proportional estimate if API data is unavailable
// ─────────────────────────────────────────────────────────────────────────────

extension MapTimelineLogic on _VehicleTrackingMapScreenState {
  /// Haversine distance in meters (used by timeline logic).
  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 2 * earthRadius * asin(sqrt(h));
  }

  /// Fetch only the full route polyline (no stop generation).
  /// Used when stops are loaded from cache but polyline is needed for ETA/sub-stops.
  Future<void> _fetchFullRoutePolyline() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;
    if (_fullRoutePolyline.isNotEmpty) return;

    final sortedWaypoints = (_trackingData?.routeWaypoints ?? [])
        .where((wp) => wp.lat != 0 && wp.lng != 0)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final allWaypoints = sortedWaypoints.map((wp) => LatLng(wp.lat, wp.lng)).toList();

    final routeData = await GoogleMapsService.getRouteWithStops(
      origin: _pickupLatLng!,
      destination: _destinationLatLng!,
      routeWaypoints: allWaypoints,
    );

    if (routeData.isNotEmpty) {
      final polylinePoints = routeData['polyline_points'] as List<LatLng>? ?? [];
      final remaining = routeData['remaining_points'] as List<LatLng>? ?? [];
      final completed = routeData['completed_points'] as List<LatLng>? ?? [];
      _fullRoutePolyline = polylinePoints.isNotEmpty ? polylinePoints : [...completed, ...remaining];

      _fullRouteCumulativeDistances = [0.0];
      for (int i = 1; i < _fullRoutePolyline.length; i++) {
        _fullRouteCumulativeDistances.add(
          _fullRouteCumulativeDistances.last +
              _haversineDistance(_fullRoutePolyline[i - 1], _fullRoutePolyline[i]),
        );
      }
      _fullRouteDurationSeconds = routeData['total_duration_seconds'] as int? ?? _totalRouteDurationSeconds;
    }
  }

  /// Fetch full pickup->destination route and generate fixed stops.
  /// Called ONCE — stops are then persisted and never regenerated.
  Future<void> _fetchFullRouteAndGenerateFixedStops() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    setState(() => _isLoadingFixedStops = true);

    final sortedWps = (_trackingData?.routeWaypoints ?? [])
        .where((wp) => wp.lat != 0 && wp.lng != 0)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final allWaypoints = sortedWps.map((wp) => LatLng(wp.lat, wp.lng)).toList();

    final routeData = await GoogleMapsService.getRouteWithStops(
      origin: _pickupLatLng!,
      destination: _destinationLatLng!,
      routeWaypoints: allWaypoints,
    );

    if (routeData.isEmpty) {
      setState(() => _isLoadingFixedStops = false);
      return;
    }

    final polylinePoints = routeData['polyline_points'] as List<LatLng>? ?? [];
    final remaining = routeData['remaining_points'] as List<LatLng>? ?? [];
    final completed = routeData['completed_points'] as List<LatLng>? ?? [];
    final fullPolyline = polylinePoints.isNotEmpty ? polylinePoints : [...completed, ...remaining];
    final totalDuration = routeData['total_duration_seconds'] as int? ?? _totalRouteDurationSeconds;

    List<double> cumDist = [0.0];
    for (int i = 1; i < fullPolyline.length; i++) {
      cumDist.add(cumDist.last + _haversineDistance(fullPolyline[i - 1], fullPolyline[i]));
    }

    _fullRoutePolyline = fullPolyline;
    _fullRouteCumulativeDistances = cumDist;
    _fullRouteDurationSeconds = totalDuration;

    // Calculate stop count: 1 per hour, min 3, max 20
    final totalHours = totalDuration / 3600.0;
    int stopCount;
    if (totalHours <= 1) stopCount = 3;
    else if (totalHours <= 3) stopCount = 4;
    else stopCount = totalHours.round().clamp(5, 20);

    // Build waypoint (key stop) entries sorted by priority
    final waypoints = (_trackingData?.routeWaypoints ?? [])
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final List<Map<String, dynamic>> waypointStops = [];
    final Set<String> waypointNames = {};

    for (final wp in waypoints) {
      if (wp.lat == 0 && wp.lng == 0) continue;
      waypointStops.add({
        'name': wp.name.isNotEmpty ? wp.name : 'Waypoint',
        'lat': wp.lat,
        'lng': wp.lng,
        'is_key_stop': true,
      });
      if (wp.name.isNotEmpty) waypointNames.add(wp.name.toLowerCase());
    }

    // Generate auto stops along the full route
    final autoStops = await GoogleMapsService.generateSubStops(
      fullPolyline: fullPolyline,
      cumulativeDistances: cumDist,
      startFraction: 0.0,
      endFraction: 1.0,
      totalDurationSeconds: totalDuration,
      count: stopCount,
    );

    // Filter duplicates
    final filteredAutoStops = <Map<String, dynamic>>[];
    for (final stop in autoStops) {
      final name = (stop['name'] as String? ?? '').toLowerCase();
      if (waypointNames.contains(name) || name == 'unknown') continue;
      final loc = stop['location'] as LatLng?;
      if (loc == null) continue;
      bool tooClose = false;
      for (final wp in waypointStops) {
        if (_haversineDistance(loc, LatLng(wp['lat'] as double, wp['lng'] as double)) < 5000) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;
      filteredAutoStops.add({'name': stop['name'], 'lat': loc.latitude, 'lng': loc.longitude, 'is_key_stop': false});
    }

    final allStops = [...waypointStops, ...filteredAutoStops];
    _sortStopsByRoutePosition(allStops, fullPolyline, cumDist);

    if (mounted) {
      setState(() {
        _fixedStops = allStops;
        _isLoadingFixedStops = false;
      });
    }
  }

  /// Regenerate fixed timeline stops from an already-fetched polyline.
  /// Used after a reroute to avoid a redundant API call.
  Future<void> _regenerateFixedStopsFromPolyline(List<LatLng> polyline, int totalDurationSeconds) async {
    if (polyline.length < 2) return;

    _fixedStopsGenerated = false;
    _fixedStops = [];
    _currentStopIndex = -1;
    _passedStopTimes = {};
    _fullRoutePolyline = polyline;
    _fullRouteDurationSeconds = totalDurationSeconds;

    final List<double> cumDist = [0.0];
    for (int i = 1; i < polyline.length; i++) {
      cumDist.add(cumDist.last + _haversineDistance(polyline[i - 1], polyline[i]));
    }
    _fullRouteCumulativeDistances = cumDist;

    if (mounted) setState(() => _isLoadingFixedStops = true);

    final totalHours = totalDurationSeconds / 3600.0;
    int stopCount;
    if (totalHours <= 1) stopCount = 3;
    else if (totalHours <= 3) stopCount = 4;
    else stopCount = totalHours.round().clamp(5, 20);

    final remainingWps = (_trackingData?.routeWaypoints ?? [])
        .where((wp) => wp.lat != 0 && wp.lng != 0 && !wp.isCompleted)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final List<Map<String, dynamic>> waypointStops = [];
    final Set<String> waypointNames = {};
    for (final wp in remainingWps) {
      waypointStops.add({'name': wp.name.isNotEmpty ? wp.name : 'Waypoint', 'lat': wp.lat, 'lng': wp.lng, 'is_key_stop': true});
      if (wp.name.isNotEmpty) waypointNames.add(wp.name.toLowerCase());
    }

    final autoStops = await GoogleMapsService.generateSubStops(
      fullPolyline: polyline,
      cumulativeDistances: cumDist,
      startFraction: 0.0,
      endFraction: 1.0,
      totalDurationSeconds: totalDurationSeconds,
      count: stopCount,
    );

    final filteredAutoStops = <Map<String, dynamic>>[];
    for (final stop in autoStops) {
      final name = (stop['name'] as String? ?? '').toLowerCase();
      if (waypointNames.contains(name) || name == 'unknown') continue;
      final loc = stop['location'] as LatLng?;
      if (loc == null) continue;
      bool tooClose = false;
      for (final wp in waypointStops) {
        if (_haversineDistance(loc, LatLng(wp['lat'] as double, wp['lng'] as double)) < 5000) { tooClose = true; break; }
      }
      if (tooClose) continue;
      filteredAutoStops.add({'name': stop['name'], 'lat': loc.latitude, 'lng': loc.longitude, 'is_key_stop': false});
    }

    final allStops = [...waypointStops, ...filteredAutoStops];
    _sortStopsByRoutePosition(allStops, polyline, cumDist);

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('fixed_stops_${widget.bookingId}');
    prefs.remove('stop_index_${widget.bookingId}');
    prefs.remove('passed_stop_times_${widget.bookingId}');

    if (mounted) {
      setState(() {
        _fixedStops = allStops;
        _isLoadingFixedStops = false;
      });
    }
    _fixedStopsGenerated = true;
    await _saveFixedStops();
    debugPrint('Timeline regenerated after reroute: ${allStops.length} stops');
  }

  void _sortStopsByRoutePosition(List<Map<String, dynamic>> stops, List<LatLng> polyline, List<double> cumDist) {
    for (final stop in stops) {
      final sLat = stop['lat'] as double;
      final sLng = stop['lng'] as double;
      double minD = double.infinity;
      int bestIdx = 0;
      for (int i = 0; i < polyline.length; i++) {
        final d = _haversineDistance(LatLng(sLat, sLng), polyline[i]);
        if (d < minD) { minD = d; bestIdx = i; }
      }
      stop['_sortDist'] = cumDist[bestIdx];
    }
    stops.sort((a, b) => (a['_sortDist'] as double).compareTo(b['_sortDist'] as double));
    for (final stop in stops) { stop.remove('_sortDist'); }
  }

  /// Recompute current stop index from scratch based on driver fraction.
  void _updateProgress(LatLng currentLocation) {
    if (_fixedStops.isEmpty) return;

    final currentFraction = _currentDriverFraction();
    if (currentFraction <= 0 || _fullRoutePolyline.isEmpty) return;

    int recomputedIndex = -1;
    for (int i = 0; i < _fixedStops.length; i++) {
      final stopFraction = _getStopFraction(i);
      if (stopFraction > 0 && currentFraction >= stopFraction) {
        recomputedIndex = i;
      }
    }

    if (recomputedIndex == _currentStopIndex) return;

    final now = DateTime.now();
    if (recomputedIndex > _currentStopIndex) {
      for (int j = _currentStopIndex + 1; j <= recomputedIndex; j++) {
        if (!_passedStopTimes.containsKey(j)) {
          _passedStopTimes[j] = _formatDateTimeObj(now);
        }
      }
    } else {
      for (int j = recomputedIndex + 1; j <= _currentStopIndex; j++) {
        _passedStopTimes.remove(j);
      }
    }

    setState(() => _currentStopIndex = recomputedIndex);
    _saveCurrentStopIndex();
    _savePassedStopTimes();
  }

  Future<void> _saveCurrentStopIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stop_index_${widget.bookingId}', _currentStopIndex);
    } catch (e) {
      debugPrint('Error saving stop index: $e');
    }
  }

  Future<void> _loadCurrentStopIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt('stop_index_${widget.bookingId}') ?? -1;
      setState(() => _currentStopIndex = idx);
      _loadPassedStopTimes();
    } catch (e) {
      debugPrint('Error loading stop index: $e');
    }
  }

  Future<void> _savePassedStopTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _passedStopTimes.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString('passed_stop_times_${widget.bookingId}', jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving passed stop times: $e');
    }
  }

  Future<void> _loadPassedStopTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('passed_stop_times_${widget.bookingId}');
      if (json == null || json.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(json);
      setState(() {
        _passedStopTimes = decoded.map((k, v) => MapEntry(int.parse(k), v.toString()));
      });
    } catch (e) {
      debugPrint('Error loading passed stop times: $e');
    }
  }

  Future<void> _saveFixedStops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializable = _fixedStops.map((stop) => {
        'name': stop['name'],
        'lat': stop['lat'],
        'lng': stop['lng'],
        'is_key_stop': stop['is_key_stop'],
      }).toList();
      await prefs.setString('fixed_stops_${widget.bookingId}', jsonEncode(serializable));
    } catch (e) {
      debugPrint('Error saving fixed stops: $e');
    }
  }

  Future<bool> _loadFixedStops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('fixed_stops_${widget.bookingId}');
      if (json == null || json.isEmpty) return false;
      final List<dynamic> decoded = jsonDecode(json);
      final stops = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      debugPrint('Loaded ${stops.length} fixed stops from cache');
      if (stops.isNotEmpty) {
        setState(() {
          _fixedStops = stops;
          _isLoadingFixedStops = false;
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error loading fixed stops: $e');
    }
    return false;
  }

  /// Get the distance fraction (0..1) of a fixed stop on the full route polyline.
  double _getStopFraction(int stopIndex) {
    if (stopIndex < 0 || stopIndex >= _fixedStops.length) return 0.0;
    if (_fullRoutePolyline.isEmpty || _fullRouteCumulativeDistances.isEmpty) return 0.0;

    final stop = _fixedStops[stopIndex];
    final stopLatLng = LatLng(stop['lat'] as double, stop['lng'] as double);

    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < _fullRoutePolyline.length; i++) {
      final d = _haversineDistance(stopLatLng, _fullRoutePolyline[i]);
      if (d < minDist) { minDist = d; closestIdx = i; }
    }
    return _fullRouteCumulativeDistances[closestIdx] / _fullRouteCumulativeDistances.last;
  }

  /// Where the truck currently is along the full route as a fraction 0..1.
  /// Handles self-intersecting routes using forward-biased search.
  double _currentDriverFraction() {
    if (_currentLatLng == null) return _maxDriverFractionReached;
    if (_fullRoutePolyline.isEmpty || _fullRouteCumulativeDistances.isEmpty) {
      return _maxDriverFractionReached;
    }
    final total = _fullRouteCumulativeDistances.last;
    if (total <= 0) return 0.0;

    final minSearchDist = (_maxDriverFractionReached * total - 500).clamp(0.0, total);

    double absMin = double.infinity;
    for (int i = 0; i < _fullRoutePolyline.length; i++) {
      if (_fullRouteCumulativeDistances[i] < minSearchDist) continue;
      final d = _haversineDistance(_currentLatLng!, _fullRoutePolyline[i]);
      if (d < absMin) absMin = d;
    }
    if (absMin == double.infinity) return _maxDriverFractionReached;

    int bestIdx = 0;
    for (int i = 0; i < _fullRoutePolyline.length; i++) {
      if (_fullRouteCumulativeDistances[i] < minSearchDist) continue;
      final d = _haversineDistance(_currentLatLng!, _fullRoutePolyline[i]);
      if (d <= absMin + 200) { bestIdx = i; break; }
    }

    final fraction = (_fullRouteCumulativeDistances[bestIdx] / total).clamp(0.0, 1.0);
    if (fraction > _maxDriverFractionReached) {
      _maxDriverFractionReached = fraction;
    }
    return fraction;
  }

  String _getTimeForFraction(double fraction) {
    final duration = _fullRouteDurationSeconds > 0 ? _fullRouteDurationSeconds : _totalRouteDurationSeconds;
    if (duration == 0) return '-';

    final currentFraction = _currentDriverFraction();
    if (fraction <= currentFraction || _remainingDurationSeconds <= 0) {
      DateTime? baseTime;
      if (_trackingData?.inProgressAt != null && _trackingData!.inProgressAt!.isNotEmpty) {
        try { baseTime = DateTime.parse(_trackingData!.inProgressAt!); } catch (_) {}
      }
      baseTime ??= _routeStartTime;
      if (baseTime == null) return '-';
      final seconds = (fraction * duration).round();
      return _formatDateTimeObj(baseTime.add(Duration(seconds: seconds)));
    }

    final adaptiveRemaining = _adaptiveRemainingSeconds();
    final routeAhead = (1.0 - currentFraction).clamp(0.0001, 1.0);
    final stopAhead = (fraction - currentFraction).clamp(0.0, 1.0);
    final secondsFromNow = ((stopAhead / routeAhead) * adaptiveRemaining).round();
    final dt = DateTime.now().add(Duration(seconds: secondsFromNow));
    return _formatDateTimeObj(dt);
  }

  /// Locally-computed remaining duration adjusted for actual driver speed.
  int _adaptiveRemainingSeconds() {
    if (_remainingDurationSeconds <= 0) return _remainingDurationSeconds;
    if (_estimatedSpeedKmh < 5) return _remainingDurationSeconds;
    if (_fullRouteCumulativeDistances.isEmpty) return _remainingDurationSeconds;

    final totalRouteMeters = _fullRouteCumulativeDistances.last;
    final totalDurationSec = _fullRouteDurationSeconds > 0 ? _fullRouteDurationSeconds : _totalRouteDurationSeconds;
    if (totalRouteMeters <= 0 || totalDurationSec <= 0) return _remainingDurationSeconds;

    final expectedAvgKmh = (totalRouteMeters / totalDurationSec) * 3.6;
    if (expectedAvgKmh < 1) return _remainingDurationSeconds;

    final rawScale = expectedAvgKmh / _estimatedSpeedKmh;
    final scale = rawScale.clamp(0.5, 2.0);
    return (_remainingDurationSeconds * scale).round();
  }
}
