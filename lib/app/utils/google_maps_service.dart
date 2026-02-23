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

  /// Reverse geocode coordinates to get neighborhood/area name.
  /// Prefers sublocality (e.g. "Kothaguda", "Madhapur") over city ("Hyderabad").
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&result_type=sublocality_level_1|sublocality|neighborhood|locality|administrative_area_level_3'
          '&language=en'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      // Priority: sublocality > neighborhood > locality (city)
      const priority = [
        'sublocality_level_1',
        'sublocality',
        'neighborhood',
        'locality',
        'administrative_area_level_3',
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
    int maxStops = 5,
  }) async {
    try {
      // Use driver position as waypoint so route goes through it
      String waypointStr = '';
      if (driverPosition != null) {
        waypointStr =
            '&waypoints=${driverPosition.latitude},${driverPosition.longitude}';
      }

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointStr'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return {};

      final data = response.data;
      if (data['status'] != 'OK') return {};

      final route = data['routes'][0];
      final legs = route['legs'] as List;

      // Decode per-leg polylines
      List<LatLng> completedPoints = [];
      List<LatLng> remainingPoints = [];
      int totalDurationSeconds = 0;
      int totalDistanceMeters = 0;
      int remainingSeconds = 0;
      int completedSeconds = 0;

      if (driverPosition != null && legs.length >= 2) {
        // Leg 0: origin → driver (completed portion)
        // Leg 1: driver → destination (remaining portion)
        completedPoints = _decodeStepsPolyline(legs[0]['steps'] as List);
        remainingPoints = _decodeStepsPolyline(legs[1]['steps'] as List);

        completedSeconds = legs[0]['duration']['value'] as int;
        remainingSeconds = legs[1]['duration']['value'] as int;
        totalDurationSeconds = completedSeconds + remainingSeconds;
        totalDistanceMeters = (legs[0]['distance']['value'] as int) +
            (legs[1]['distance']['value'] as int);
      } else {
        // No driver position — single leg, full route as remaining
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
      };
    } catch (e) {
      debugPrint('Error getting route with stops: $e');
      return {};
    }
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
