import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
          // "via:" influences the route to pass through these roads
          // without creating mandatory stops (no loops/backtracking)
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

      // Decode the polyline from the response
      final encodedPolyline =
          data['routes'][0]['overview_polyline']['points'] as String;

      return _decodePolyline(encodedPolyline);
    } catch (e) {
      debugPrint('Error getting directions: $e');
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

      return LatLng(location['lat'], location['lng']);
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to get a recognizable town/city name.
  /// Prefers locality/town names over tiny neighborhoods or hamlets.
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&result_type=locality|administrative_area_level_3|administrative_area_level_2|sublocality_level_1|sublocality|neighborhood'
          '&language=en'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      // Priority: recognizable town/city > mandal/sub-district > small locality
      const priority = [
        'locality',
        'administrative_area_level_3',
        'administrative_area_level_2',
        'sublocality_level_1',
        'sublocality',
        'neighborhood',
      ];

      for (final type in priority) {
        for (final result in results) {
          final components = result['address_components'] as List;
          for (final component in components) {
            final types = component['types'] as List;
            if (types.contains(type)) {
              return component['long_name'];
            }
          }
        }
      }

      return results[0]['formatted_address']?.toString().split(',').first;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
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
      // 2. Too close to destination (< 5km) — redundant
      // 3. Too close to each other (< 5km) — duplicates
      List<String> allWaypoints = [];
      if (routeWaypoints.isNotEmpty) {
        List<LatLng> filteredWaypoints = [];
        for (final wp in routeWaypoints) {
          // Skip waypoints too close to origin (prevents route looping back to start)
          if (_haversineDistance(origin, wp) < 5000) {
            debugPrint('🗺️ Skipping waypoint too close to origin: ${wp.latitude},${wp.longitude} '
                '(${_haversineDistance(origin, wp).toStringAsFixed(0)}m)');
            continue;
          }
          // Skip waypoints too close to destination
          if (_haversineDistance(destination, wp) < 5000) {
            debugPrint('🗺️ Skipping waypoint too close to destination: ${wp.latitude},${wp.longitude}');
            continue;
          }
          // Skip waypoints too close to a previously added waypoint
          bool isDuplicate = false;
          for (final existing in filteredWaypoints) {
            if (_haversineDistance(existing, wp) < 5000) {
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

        int driverIdx;
        if (pickupToDriverDist < 1000) {
          // Driver is within 1km of pickup (just started) — no completed portion
          driverIdx = 0;
        } else {
          // Only search within a bounded range along the polyline
          // (1.5x straight-line pickup→driver distance + 10km buffer for road curves)
          double searchLimit = pickupToDriverDist * 1.5 + 10000;
          double accDist = 0;
          driverIdx = 0;
          double minDist = double.infinity;
          for (int i = 0; i < allPoints.length; i++) {
            if (i > 0) {
              accDist += _haversineDistance(allPoints[i - 1], allPoints[i]);
            }
            if (accDist > searchLimit) break; // Stop searching beyond reasonable range
            double dist = _haversineDistance(allPoints[i], driverPosition);
            if (dist < minDist) {
              minDist = dist;
              driverIdx = i;
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
        // No driver position, no waypoints — single leg, full route as remaining
        final encodedPolyline =
            route['overview_polyline']['points'] as String;
        remainingPoints = _decodePolyline(encodedPolyline);
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

      // Determine number of stops based on route distance (minimum 3 always)
      int numStops;
      if (totalDistanceMeters < 200000) {
        numStops = min(3, maxStops);
      } else if (totalDistanceMeters < 500000) {
        numStops = min(5, maxStops);
      } else {
        numStops = maxStops;
      }

      // Sample evenly-spaced intermediate stops
      List<Map<String, dynamic>> stops = [];
      if (numStops > 0 && totalPolylineDist > 0) {
        double interval = totalPolylineDist / (numStops + 1);
        for (int i = 1; i <= numStops; i++) {
          double targetDist = interval * i;
          LatLng point = _interpolatePointOnPolyline(
              targetDist, fullPolyline, cumulativeDistances);
          double fraction = targetDist / totalPolylineDist;
          bool passed = targetDist <= driverDistanceOnRoute;
          stops.add({
            'location': point,
            'distance_fraction': fraction,
            'estimated_seconds': (totalDurationSeconds * fraction).round(),
            'passed': passed,
          });
        }

        // Reverse geocode all stops in parallel
        List<String?> names = await Future.wait(
          stops.map((s) => reverseGeocode(s['location'] as LatLng)),
        );
        for (int i = 0; i < stops.length; i++) {
          stops[i]['name'] = names[i] ?? 'Unknown';
        }

        // Remove all duplicate names (keep first occurrence)
        List<Map<String, dynamic>> uniqueStops = [];
        Set<String> seenNames = {};
        for (var stop in stops) {
          final name = stop['name'] as String;
          if (name != 'Unknown' && !seenNames.contains(name)) {
            uniqueStops.add(stop);
            seenNames.add(name);
          }
        }
        stops = uniqueStops;
      }

      return {
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
    final names = await Future.wait(
      candidates.map((s) => reverseGeocode(s['location'] as LatLng)),
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
