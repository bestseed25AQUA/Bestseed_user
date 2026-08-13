import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class GoogleMapsService {
  static const String _apiKey = NetworkConfig.googleApiKey2;
  static final Dio _dio = Dio();

  /// Get directions between two points and return polyline points
  static Future<List<LatLng>> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    bool useViaWaypoints = false,
  }) async {
    try {
      String waypointsStr = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        if (useViaWaypoints) {
          waypointsStr =
              '&waypoints=${waypoints.map((wp) => 'via:${wp.latitude},${wp.longitude}').join('|')}';
        } else {
          waypointsStr =
              '&waypoints=${waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}';
        }
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointsStr'
          '&key=$_apiKey';

      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        debugPrint('Directions API error: ${response.statusCode}');
        return [];
      }

      final data = response.data;

      if (data['status'] != 'OK') {
        debugPrint('Directions API status: ${data['status']}');
        return [];
      }

      final encodedPolyline =
          data['routes'][0]['overview_polyline']['points'] as String;
      return _decodePolyline(encodedPolyline);
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return [];
    }
  }

  /// HIGH-RESOLUTION directions. Same endpoint + same cost as [getDirections]
  /// but decodes `steps[].polyline.points` instead of `overview_polyline`.
  /// `overview_polyline` is a Douglas–Peucker-simplified geometry optimised
  /// for drawing an overview at low zoom — villages, side-streets and tight
  /// curves get collapsed to straight chords, which is why the green trail
  /// appears to cut through buildings in dense grids.
  /// Each step's polyline is the full-resolution geometry for that maneuver,
  /// so concatenating them produces a polyline that faithfully follows every
  /// bend of every road along the route.
  static Future<List<LatLng>> getDirectionsHighRes({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      String waypointsStr = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsStr =
            '&waypoints=${waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}';
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointsStr'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return [];
      final data = response.data;
      if (data['status'] != 'OK') return [];

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];
      final legs = routes[0]['legs'] as List?;
      if (legs == null || legs.isEmpty) return [];

      final List<LatLng> merged = [];
      for (final leg in legs) {
        final steps = leg['steps'] as List?;
        if (steps == null) continue;
        for (final step in steps) {
          final encoded = step['polyline']?['points'] as String?;
          if (encoded == null || encoded.isEmpty) continue;
          final stepPts = _decodePolyline(encoded);
          // Skip step-boundary duplicates: first point of a step equals the
          // last point of the previous step.
          final start = (merged.isNotEmpty && stepPts.isNotEmpty &&
                  stepPts.first.latitude == merged.last.latitude &&
                  stepPts.first.longitude == merged.last.longitude)
              ? 1
              : 0;
          for (int i = start; i < stepPts.length; i++) {
            merged.add(stepPts[i]);
          }
        }
      }

      if (merged.isEmpty) return [];
      return merged;
    } catch (e) {
      debugPrint('Error getting high-res directions: $e');
      return [];
    }
  }

  /// Get directions with duration info (returns polyline points + duration text)
  static Future<Map<String, dynamic>> getDirectionsWithDuration({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';

      final response = await _dio.get(url);

      if (response.statusCode != 200) return {};

      final data = response.data;
      if (data['status'] != 'OK') return {};

      final route = data['routes'][0];
      final leg = route['legs'][0];

      final encodedPolyline = route['overview_polyline']['points'] as String;
      final points = _decodePolyline(encodedPolyline);

      final durationText = leg['duration']['text'] ?? '';
      final durationSeconds = leg['duration']['value'] ?? 0;
      final distanceText = leg['distance']['text'] ?? '';

      return {
        'points': points,
        'duration_text': durationText,
        'duration_seconds': durationSeconds,
        'distance_text': distanceText,
      };
    } catch (e) {
      debugPrint('Error getting directions with duration: $e');
      return {};
    }
  }

  /// Geocode an address to get LatLng coordinates
  static Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') return null;

      final location = data['results'][0]['geometry']['location'];
      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to a human-readable stop name.
  ///
  /// The naming strategy adapts to total route distance so stops at every
  /// scale are recognisable:
  ///   < 30 km  → neighborhood / colony (Ameerpet, Kondapur…)
  ///   30–200 km → sublocality first, falls back to city (Guntur, Ongole…)
  ///   > 200 km  → city / district (Nellore, Vijayawada, Rajahmundry…)
  ///
  /// Pass [routeDistanceKm] when you know the total route length.
  // Cache resolved names by ~50 m grid so we don't re-hit the API (and re-risk
  // a rate-limit failure) for points we've already named this session.
  static final Map<String, String> _geocodeCache = {};

  /// Reverse-geocode a batch of points, SEQUENTIALLY.
  ///
  /// The platform geocoder is `CLGeocoder` on iOS, and Apple is explicit that
  /// it must be driven one request at a time — concurrent or rapid-fire calls
  /// are throttled and fail with a network error. The previous code issued the
  /// whole batch at once via `Future.wait`, so on a long route (10 sampled
  /// stops) most calls came back empty and every one of those stops fell back
  /// to the placeholder "Stop N" name. Android's `Geocoder` is far more
  /// permissive, which is why this only ever showed up on iPhones, and why it
  /// only started at priority 3 — shorter routes sample fewer stops and stayed
  /// under the limit.
  ///
  /// Cached points resolve instantly and cost no request, so a re-render of an
  /// already-named route does not re-hit the geocoder at all.
  static Future<List<String?>> reverseGeocodeBatch(
    List<LatLng> points, {
    double routeDistanceKm = 0,
    Duration spacing = const Duration(milliseconds: 120),
  }) async {
    final out = <String?>[];
    for (var i = 0; i < points.length; i++) {
      final name = await reverseGeocode(points[i],
          routeDistanceKm: routeDistanceKm);
      out.add(name);
      // Space out only real requests — a cache hit needs no cool-down, and the
      // last point never needs a trailing delay.
      final wasCached = _geocodeCache.containsKey(
          '${points[i].latitude.toStringAsFixed(3)},${points[i].longitude.toStringAsFixed(3)}');
      if (i < points.length - 1 && !wasCached) {
        await Future<void>.delayed(spacing);
      }
    }
    return out;
  }

  static Future<String?> reverseGeocode(LatLng location,
      {double routeDistanceKm = 0}) async {
    final cacheKey =
        '${location.latitude.toStringAsFixed(3)},${location.longitude.toStringAsFixed(3)}';
    final cached = _geocodeCache[cacheKey];
    if (cached != null) return cached;

    try {
      // FREE native device geocoder (Android/iOS) — no Google Geocoding API
      // key/cost.
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;

      // Preferred granularity for this route length, then coarse fallbacks so a
      // highway / rural point is never nameless (the "Stop 1 / Stop 2" symptom).
      final List<String?> candidates;
      if (routeDistanceKm > 200) {
        candidates = [p.locality, p.subAdministrativeArea, p.administrativeArea];
      } else if (routeDistanceKm > 30) {
        candidates = [p.subLocality, p.locality, p.subAdministrativeArea];
      } else {
        candidates = [p.subLocality, p.locality, p.name];
      }
      candidates.addAll([
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
        p.name,
        p.street,
      ]);

      for (final c in candidates) {
        final name = c?.trim() ?? '';
        if (name.isNotEmpty) {
          _geocodeCache[cacheKey] = name;
          return name;
        }
      }
      // Native geocoder answered but had no usable place name for this point.
      return _reverseGeocodeViaApi(location, cacheKey, routeDistanceKm);
    } catch (e) {
      // The on-device geocoder failed outright. On iOS this is usually
      // CLGeocoder throttling; on any platform it can be a transient network
      // error. Either way, fall back to the Google Geocoding API so the stop
      // still gets a REAL place name instead of a "Stop N" placeholder.
      debugPrint('🌍 [GEO] native geocoder failed ($e) — falling back to API');
      return _reverseGeocodeViaApi(location, cacheKey, routeDistanceKm);
    }
  }

  /// Google Geocoding API fallback. Costs a request, but only ever runs when
  /// the free on-device geocoder could not name the point — and the result is
  /// cached, so a route is named at most once per session.
  static Future<String?> _reverseGeocodeViaApi(
      LatLng location, String cacheKey, double routeDistanceKm) async {
    try {
      // `result_type` narrows the response to the granularity that matches the
      // route length, mirroring the native strategy above: city/district names
      // for long hauls, neighbourhoods for short city runs.
      final types = routeDistanceKm > 200
          ? 'locality|administrative_area_level_2'
          : (routeDistanceKm > 30
              ? 'sublocality|locality|administrative_area_level_2'
              : 'neighborhood|sublocality|locality');

      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&result_type=$types'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return null;
      final data = response.data;

      // ZERO_RESULTS at this granularity is normal on a highway — retry once
      // without the type filter rather than giving up on the name.
      List<dynamic> results = (data['results'] as List?) ?? const [];
      if (data['status'] != 'OK' || results.isEmpty) {
        final loose = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&key=$_apiKey',
        );
        if (loose.statusCode != 200) return null;
        final ld = loose.data;
        if (ld['status'] != 'OK') {
          debugPrint('🌍 [GEO] API reverse geocode status=${ld['status']}');
          return null;
        }
        results = (ld['results'] as List?) ?? const [];
      }
      if (results.isEmpty) return null;

      // Prefer the shortest named administrative component — "Suryapet" reads
      // better on a timeline than "Suryapet, Telangana 508213, India".
      for (final type in const [
        'locality',
        'sublocality',
        'neighborhood',
        'administrative_area_level_2',
        'administrative_area_level_1',
      ]) {
        for (final r in results) {
          for (final comp in (r['address_components'] as List? ?? const [])) {
            final compTypes = (comp['types'] as List? ?? const []).cast<String>();
            if (compTypes.contains(type)) {
              final name = (comp['long_name'] as String?)?.trim() ?? '';
              if (name.isNotEmpty) {
                _geocodeCache[cacheKey] = name;
                return name;
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('🌍 [GEO] API reverse geocode failed: $e');
      return null;
    }
  }

  /// Get full route from origin to destination with intermediate stops.
  /// When driverPosition is provided, it is used as a waypoint so the route
  /// passes through the vehicle's actual location on the road.
  static Future<Map<String, dynamic>> getRouteWithStops({
    required LatLng origin,
    required LatLng destination,
    LatLng? driverPosition,
    List<LatLng> routeWaypoints = const [],
    int maxStops = 5,
  }) async {
    try {
      // Build waypoints for Directions API
      // When route waypoints exist (multi-drop), only use drop waypoints — NOT driver position.
      // The driver position will be used to split the polyline into completed/remaining.
      // When no route waypoints, use driver position as waypoint (original behavior).
      //
      // Filter out waypoints that are:
      // 1. Too close to origin (< 5km) — would cause unnecessary loop back
      // 2. Identical to destination (< 200m) — exact duplicate, already the endpoint
      //    NOTE: do NOT filter by large radius here; a legitimate intermediate stop
      //    (e.g. priority-1 drop 3 km before the priority-2 destination) must be kept.
      // 3. Too close to each other (< 200m) — exact duplicates only
      List<String> allWaypoints = [];
      if (routeWaypoints.isNotEmpty) {
        List<LatLng> filteredWaypoints = [];
        for (final wp in routeWaypoints) {
          // Only filter out waypoints that ARE the origin (exact duplicate
          // ≤ 200 m). The old 5-km radius silently stripped priority-1 drops
          // that happened to be close to the pickup — e.g. on a Madhapur →
          // Ayyappa Society (1.5 km) → Kukatpally trip, Ayyappa Society
          // was dropped and the blue line skipped it entirely. The fix is
          // to trust the caller: any waypoint they supply is a real stop
          // the driver actually has to visit. We only dedup exact-overlap
          // points (origin / destination / each other) so Google doesn't
          // crash on a "0 m segment".
          if (_haversineDistance(origin, wp) < 200) {
            debugPrint('🗺️ Skipping waypoint that matches origin: ${wp.latitude},${wp.longitude}');
            continue;
          }
          // Skip waypoints that ARE the destination (exact duplicate ≤ 200 m).
          if (_haversineDistance(destination, wp) < 200) {
            debugPrint('🗺️ Skipping waypoint that matches destination: ${wp.latitude},${wp.longitude}');
            continue;
          }
          // Skip waypoints too close to a previously added waypoint (dedup)
          bool isDuplicate = false;
          for (final existing in filteredWaypoints) {
            if (_haversineDistance(existing, wp) < 200) {
              isDuplicate = true;
              debugPrint('🗺️ Skipping duplicate waypoint: ${wp.latitude},${wp.longitude}');
              break;
            }
          }
          if (!isDuplicate) {
            filteredWaypoints.add(wp);
            allWaypoints.add('${wp.latitude},${wp.longitude}');
          }
        }
        debugPrint('🗺️ Waypoints: ${routeWaypoints.length} raw → ${filteredWaypoints.length} after filtering');
      } else if (driverPosition != null) {
        allWaypoints.add('${driverPosition.latitude},${driverPosition.longitude}');
      }
      String waypointStr = '';
      if (allWaypoints.isNotEmpty) {
        waypointStr = '&waypoints=${allWaypoints.join('|')}';
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointStr'
          '&key=$_apiKey';

      debugPrint('🗺️ Directions API: origin=${origin.latitude},${origin.longitude} '
          'dest=${destination.latitude},${destination.longitude} '
          'waypoints=${routeWaypoints.length} driver=${driverPosition != null}');

      final response = await _dio.get(url);
      if (response.statusCode != 200) return {};

      final data = response.data;
      if (data['status'] != 'OK') return {};

      final route = data['routes'][0];
      final legs = route['legs'] as List;

      // Debug: log each leg's duration and distance
      for (int i = 0; i < legs.length; i++) {
        final leg = legs[i];
        debugPrint('🗺️ Leg $i: ${leg['start_address']} → ${leg['end_address']} '
            'duration=${leg['duration']['text']} distance=${leg['distance']['text']}');
      }

      // Decode per-leg polylines
      List<LatLng> completedPoints = [];
      List<LatLng> remainingPoints = [];
      int totalDurationSeconds = 0;
      int totalDistanceMeters = 0;
      int remainingSeconds = 0;
      int completedSeconds = 0;

      if (routeWaypoints.isNotEmpty && driverPosition != null) {
        // Multi-drop route with driver position:
        // Route goes: origin → drop1 → drop2 → ... → destination (driver NOT a waypoint)
        // Split the polyline at the driver's actual position for green/blue coloring
        List<LatLng> allPoints = [];
        List<int> legDurations = [];
        List<int> legDistances = [];
        // Track which polyline index each leg starts at
        List<int> legStartIndices = [0];

        for (int legIdx = 0; legIdx < legs.length; legIdx++) {
          final legPoints = _decodeStepsPolyline(legs[legIdx]['steps'] as List);
          // Remove duplicate junction point between legs to avoid double-counting
          if (legIdx > 0 && allPoints.isNotEmpty && legPoints.isNotEmpty) {
            legStartIndices.add(allPoints.length);
            allPoints.addAll(legPoints.sublist(1));
          } else {
            allPoints.addAll(legPoints);
          }
          final legDur = legs[legIdx]['duration']['value'] as int;
          final legDist = legs[legIdx]['distance']['value'] as int;
          legDurations.add(legDur);
          legDistances.add(legDist);
          totalDurationSeconds += legDur;
          totalDistanceMeters += legDist;
        }

        // Find the closest point on the polyline to the driver's position
        // Use BOUNDED search to prevent matching a far-away point on the route
        // when driver is still near the start (fixes green line extending to 1st drop)
        double pickupToDriverDist = allPoints.isNotEmpty
            ? _haversineDistance(allPoints.first, driverPosition)
            : 0;

        // The waypoints supplied here are the REMAINING (uncompleted) drops, so
        // the driver is still heading to the FIRST of them — i.e. somewhere on
        // LEG 0 (origin → first pending drop). Constrain the driver-snap search
        // to leg 0 so a LATER leg that loops back near the driver can't hijack
        // the match and make the "remaining" split skip the priority-1 drop
        // (the Order #862 bug, where blue shot straight to the priority-2 drop).
        final int leg0End =
            legStartIndices.length > 1 ? legStartIndices[1] : allPoints.length;

        int driverIdx;
        if (pickupToDriverDist < 1000) {
          // Driver is within 1km of pickup (just started) — no completed portion
          driverIdx = 0;
        } else {
          driverIdx = 0;
          double minDist = double.infinity;
          for (int i = 0; i < leg0End; i++) {
            double dist = _haversineDistance(allPoints[i], driverPosition);
            if (dist < minDist) {
              minDist = dist;
              driverIdx = i;
            }
          }
          // Safety net: if the driver isn't actually near leg 0 (e.g. a drop was
          // physically reached but not yet marked complete, so they're already
          // on a later leg), fall back to a bounded full-route nearest-point
          // match so the split doesn't snap backwards to an old drop.
          if (minDist > 500) {
            double searchLimit = pickupToDriverDist * 1.5 + 10000;
            double accDist = 0;
            minDist = double.infinity;
            driverIdx = 0;
            for (int i = 0; i < allPoints.length; i++) {
              if (i > 0) {
                accDist += _haversineDistance(allPoints[i - 1], allPoints[i]);
              }
              if (accDist > searchLimit) break;
              double dist = _haversineDistance(allPoints[i], driverPosition);
              if (dist < minDist) {
                minDist = dist;
                driverIdx = i;
              }
            }
          }
        }

        debugPrint('🚛 Multi-drop route split: pickupToDriver=${pickupToDriverDist.toStringAsFixed(0)}m, '
            'driverIdx=$driverIdx/${allPoints.length}, totalDuration=${totalDurationSeconds}s (${(totalDurationSeconds / 3600).toStringAsFixed(1)}h)');

        // Split at driver's actual position
        completedPoints = allPoints.sublist(0, driverIdx + 1);
        remainingPoints = allPoints.sublist(driverIdx);

        // Calculate remaining duration using per-leg durations (more accurate than distance fraction)
        // Find which leg the driver is currently in
        int driverLegIdx = 0;
        for (int i = legStartIndices.length - 1; i >= 0; i--) {
          if (driverIdx >= legStartIndices[i]) {
            driverLegIdx = i;
            break;
          }
        }

        // Sum full durations of legs AFTER the driver's current leg
        remainingSeconds = 0;
        for (int i = driverLegIdx + 1; i < legDurations.length; i++) {
          remainingSeconds += legDurations[i];
        }
        // Add partial remaining duration of the current leg (by distance fraction within the leg)
        int currentLegStart = legStartIndices[driverLegIdx];
        int currentLegEnd = (driverLegIdx + 1 < legStartIndices.length)
            ? legStartIndices[driverLegIdx + 1]
            : allPoints.length;
        double currentLegTotalDist = 0;
        for (int i = currentLegStart + 1; i < currentLegEnd; i++) {
          currentLegTotalDist += _haversineDistance(allPoints[i - 1], allPoints[i]);
        }
        double currentLegCompletedDist = 0;
        for (int i = currentLegStart + 1; i <= driverIdx; i++) {
          currentLegCompletedDist += _haversineDistance(allPoints[i - 1], allPoints[i]);
        }
        double currentLegRemainingFraction = currentLegTotalDist > 0
            ? 1.0 - (currentLegCompletedDist / currentLegTotalDist)
            : 1.0;
        remainingSeconds += (legDurations[driverLegIdx] * currentLegRemainingFraction).round();

        completedSeconds = totalDurationSeconds - remainingSeconds;

        debugPrint('🚛 Duration: driverInLeg=$driverLegIdx/${legs.length}, '
            'remaining=${(remainingSeconds / 3600).toStringAsFixed(1)}h, '
            'completed=${(completedSeconds / 3600).toStringAsFixed(1)}h');
      } else if (driverPosition != null && legs.length >= 2) {
        // Single-drop route with driver as waypoint (original behavior)
        // Leg 0: origin → driver (completed), Leg 1: driver → destination (remaining)
        completedPoints = _decodeStepsPolyline(legs[0]['steps'] as List);
        remainingPoints = _decodeStepsPolyline(legs[1]['steps'] as List);
        completedSeconds = legs[0]['duration']['value'] as int;
        remainingSeconds = legs[1]['duration']['value'] as int;
        totalDurationSeconds = completedSeconds + remainingSeconds;
        totalDistanceMeters = (legs[0]['distance']['value'] as int) +
            (legs[1]['distance']['value'] as int);
      } else if (routeWaypoints.isNotEmpty && legs.length >= 2) {
        // Waypoints but no driver position — all legs combined as remaining
        for (final leg in legs) {
          remainingPoints.addAll(_decodeStepsPolyline(leg['steps'] as List));
          totalDurationSeconds += leg['duration']['value'] as int;
          totalDistanceMeters += leg['distance']['value'] as int;
        }
        remainingSeconds = totalDurationSeconds;
      } else {
        // No driver position, no waypoints — single leg, full route as remaining.
        // Decode the per-STEP polylines (full road geometry) instead of the
        // overview_polyline. overview_polyline is Douglas–Peucker-simplified and
        // collapses curves into straight chords — that's the "part of the route
        // shows a straight line" bug. Fall back to overview only if steps are
        // somehow empty.
        remainingPoints = _decodeStepsPolyline(legs[0]['steps'] as List);
        if (remainingPoints.isEmpty) {
          final encodedPolyline =
              route['overview_polyline']['points'] as String;
          remainingPoints = _decodePolyline(encodedPolyline);
        }
        totalDurationSeconds = legs[0]['duration']['value'] as int;
        totalDistanceMeters = legs[0]['distance']['value'] as int;
        remainingSeconds = totalDurationSeconds;
      }

      // Combine for full route polyline
      List<LatLng> fullPolyline = [...completedPoints, ...remainingPoints];
      int driverSplitIndex =
          completedPoints.isNotEmpty ? completedPoints.length - 1 : 0;
      double driverFraction = totalDurationSeconds > 0
          ? completedSeconds / totalDurationSeconds
          : 0;

      // Calculate cumulative distances along full polyline
      List<double> cumulativeDistances = [0.0];
      for (int i = 1; i < fullPolyline.length; i++) {
        double segDist =
            _haversineDistance(fullPolyline[i - 1], fullPolyline[i]);
        cumulativeDistances.add(cumulativeDistances.last + segDist);
      }
      double totalPolylineDist = cumulativeDistances.last;
      double driverDistanceOnRoute = driverSplitIndex < cumulativeDistances.length
          ? cumulativeDistances[driverSplitIndex]
          : 0;

      // Use maxStops directly — caller already computed the correct count
      // via TrackingStopsService.recommendedStopCount(distanceKm).
      // The old internal cap (min(5, maxStops) for <500km) was overriding
      // the caller's value and capping a 411km route at 5 stops instead of 10.
      final int numStops = maxStops;

      // Sample 2× candidate stops then deduplicate to get numStops unique names.
      // Over-sampling ensures we still hit the target even after geocoding dedup
      // (e.g. two sample points in the same city collapse to one name).
      List<Map<String, dynamic>> stops = [];
      if (numStops > 0 && totalPolylineDist > 0) {
        // Over-sample so name-dedup still leaves enough unique stops, but cap
        // the total: every candidate costs one reverse-geocode, and iOS
        // CLGeocoder throttles around 50 requests/minute. Uncapped 2×
        // over-sampling on a 40-stop route would be 80 lookups and walk
        // straight back into the rate limit this batch was serialised to avoid.
        final candidateCount = min(numStops * 2, 36);
        final List<Map<String, dynamic>> candidates = [];
        double interval = totalPolylineDist / (candidateCount + 1);
        for (int i = 1; i <= candidateCount; i++) {
          double targetDist = interval * i;
          LatLng point = _interpolatePointOnPolyline(
              targetDist, fullPolyline, cumulativeDistances);
          double fraction = targetDist / totalPolylineDist;
          bool passed = targetDist <= driverDistanceOnRoute;
          candidates.add({
            'location': point,
            'distance_fraction': fraction,
            'estimated_seconds': (totalDurationSeconds * fraction).round(),
            'passed': passed,
          });
        }

        // Reverse geocode candidates SEQUENTIALLY — iOS CLGeocoder throttles
        // concurrent requests, which used to leave most stops unnamed.
        final routeDistKm = totalDistanceMeters / 1000.0;
        List<String?> names = await reverseGeocodeBatch(
          candidates.map((s) => s['location'] as LatLng).toList(),
          routeDistanceKm: routeDistKm,
        );
        for (int i = 0; i < candidates.length; i++) {
          candidates[i]['name'] = names[i] ?? 'Unknown';
        }

        // Deduplicate across the WHOLE route first, keeping the first
        // occurrence of each name.
        final List<Map<String, dynamic>> unique = [];
        final Set<String> seenNames = {};
        for (final stop in candidates) {
          final name = stop['name'] as String;
          if (name == 'Unknown' || seenNames.contains(name)) continue;
          seenNames.add(name);
          unique.add(stop);
        }

        // Then thin EVENLY across the route to reach numStops.
        //
        // The previous code walked candidates in route order and `break`-ed the
        // moment it had numStops names. Candidates are sampled start→end, so
        // the quota filled up from the early part of the route and every later
        // candidate was thrown away — leaving the final stretch with no stops
        // at all (Tirupati→Chennai on #1067, Bapatla→Tirupati on #1066).
        //
        // Spacing the picks over the full deduplicated list keeps coverage from
        // the driver all the way to the destination, and pinning the first and
        // last index guarantees the leg into the destination is represented.
        if (unique.length <= numStops) {
          stops = unique;
        } else if (numStops == 1) {
          stops = [unique.last];
        } else {
          final lastIdx = unique.length - 1;
          for (int i = 0; i < numStops; i++) {
            final idx = (i * lastIdx / (numStops - 1)).round().clamp(0, lastIdx);
            final picked = unique[idx];
            if (stops.isEmpty || !identical(stops.last, picked)) {
              stops.add(picked);
            }
          }
        }
      }

      final result = {
        'polyline_points': fullPolyline,
        'completed_points': completedPoints,
        'remaining_points': remainingPoints,
        'stops': stops,
        'total_duration_seconds': totalDurationSeconds,
        'total_distance_meters': totalDistanceMeters,
        'driver_split_index': driverSplitIndex,
        'driver_progress_fraction': driverFraction,
        'remaining_duration_seconds': remainingSeconds,
        'cumulative_distances': cumulativeDistances,
      };
      return result;
    } catch (e) {
      debugPrint('Error getting route with stops: $e');
      return {};
    }
  }

  /// Generate sub-stops between two fractions along the route polyline.
  /// Returns a list of maps with 'name' and 'estimated_seconds' for each sub-stop.
  static Future<List<Map<String, dynamic>>> generateSubStops({
    required List<LatLng> fullPolyline,
    required List<double> cumulativeDistances,
    required double startFraction,
    required double endFraction,
    required int totalDurationSeconds,
    int count = 3,
    double routeDistanceKm = 0,
  }) async {
    if (fullPolyline.isEmpty || cumulativeDistances.isEmpty) return [];

    final totalDist = cumulativeDistances.last;
    final startDist = totalDist * startFraction;
    final endDist = totalDist * endFraction;
    final segmentDist = endDist - startDist;
    if (segmentDist <= 0) return [];

    final segmentKm = segmentDist / 1000;
    final desiredCount = segmentKm >= 220
        ? 7
        : segmentKm >= 160
        ? 6
        : segmentKm >= 120
        ? 5
        : segmentKm >= 80
        ? 4
        : count;
    final targetCount = max(count, desiredCount);
    final candidateCount = min(max(targetCount * 4, 8), 24);
    final interval = segmentDist / (candidateCount + 1);
    List<Map<String, dynamic>> candidates = [];

    for (int i = 1; i <= candidateCount; i++) {
      final targetDist = startDist + interval * i;
      final point = _interpolatePointOnPolyline(
        targetDist,
        fullPolyline,
        cumulativeDistances,
      );
      final fraction = targetDist / totalDist;
      candidates.add({
        'location': point,
        'estimated_seconds': (totalDurationSeconds * fraction).round(),
        'distance_fraction': fraction,
      });
    }

    // Reverse geocode many candidate points, then keep the best ordered localities.
    final routeKm = routeDistanceKm > 0 ? routeDistanceKm : totalDist / 1000;
    // Sequential — see reverseGeocodeBatch: iOS throttles concurrent geocoding.
    final names = await reverseGeocodeBatch(
      candidates.map((s) => s['location'] as LatLng).toList(),
      routeDistanceKm: routeKm,
    );
    for (int i = 0; i < candidates.length; i++) {
      candidates[i]['name'] = names[i] ?? 'Unknown';
    }

    // Remove duplicates/unknowns while preserving route order.
    List<Map<String, dynamic>> unique = [];
    Set<String> seen = {};
    for (var stop in candidates) {
      final name = stop['name'] as String;
      if (name != 'Unknown' && !seen.contains(name)) {
        unique.add(stop);
        seen.add(name);
      }
    }

    if (unique.length <= targetCount) {
      return unique;
    }

    // Keep a broader but still readable set of towns/cities in route order.
    final trimmed = <Map<String, dynamic>>[];
    final step = (unique.length - 1) / (targetCount - 1);
    for (int i = 0; i < targetCount; i++) {
      trimmed.add(unique[(i * step).round()]);
    }

    // Final de-duplication after thinning.
    final finalStops = <Map<String, dynamic>>[];
    final finalNames = <String>{};
    for (final stop in trimmed) {
      final name = stop['name'] as String;
      if (!finalNames.contains(name)) {
        finalStops.add(stop);
        finalNames.add(name);
      }
    }

    return finalStops;
  }

  /// Decode polylines from all steps in a Directions API leg
  static List<LatLng> _decodeStepsPolyline(List steps) {
    List<LatLng> points = [];
    for (var step in steps) {
      final stepPoints =
          _decodePolyline(step['polyline']['points'] as String);
      if (points.isNotEmpty && stepPoints.isNotEmpty) {
        // Skip first point of subsequent steps to avoid duplicates
        points.addAll(stepPoints.sublist(1));
      } else {
        points.addAll(stepPoints);
      }
    }
    return points;
  }

  /// Interpolate a point along the polyline at a given cumulative distance
  static LatLng _interpolatePointOnPolyline(
    double targetDist,
    List<LatLng> polylinePoints,
    List<double> cumulativeDistances,
  ) {
    for (int j = 1; j < cumulativeDistances.length; j++) {
      if (cumulativeDistances[j] >= targetDist) {
        double segStart = cumulativeDistances[j - 1];
        double segEnd = cumulativeDistances[j];
        double fraction =
            (segEnd - segStart) > 0 ? (targetDist - segStart) / (segEnd - segStart) : 0;
        return LatLng(
          polylinePoints[j - 1].latitude +
              (polylinePoints[j].latitude - polylinePoints[j - 1].latitude) *
                  fraction,
          polylinePoints[j - 1].longitude +
              (polylinePoints[j].longitude - polylinePoints[j - 1].longitude) *
                  fraction,
        );
      }
    }
    return polylinePoints.last;
  }

  /// Calculate haversine distance between two points in meters
  static double _haversineDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    double dLat = _toRadians(b.latitude - a.latitude);
    double dLng = _toRadians(b.longitude - a.longitude);
    double h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(a.latitude)) *
            cos(_toRadians(b.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 2 * earthRadius * asin(sqrt(h));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;


  /// Decode Google's encoded polyline algorithm
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
