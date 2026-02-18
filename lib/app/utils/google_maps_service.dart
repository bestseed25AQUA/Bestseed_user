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

  /// Reverse geocode coordinates to get city/town name
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${location.latitude},${location.longitude}'
          '&result_type=locality|administrative_area_level_3'
          '&language=en'
          '&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List;
      if (results.isEmpty) return null;

      for (var component in results[0]['address_components']) {
        final types = component['types'] as List;
        if (types.contains('locality')) {
          return component['long_name'];
        }
      }
      return results[0]['formatted_address']?.toString().split(',').first;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Get full route from origin to destination with intermediate stops
  static Future<Map<String, dynamic>> getRouteWithStops({
    required LatLng origin,
    required LatLng destination,
    LatLng? driverPosition,
    int maxStops = 5,
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
      final polylinePoints = _decodePolyline(encodedPolyline);

      final totalDurationSeconds = leg['duration']['value'] as int;
      final totalDistanceMeters = leg['distance']['value'] as int;
      final durationText = leg['duration']['text'] as String;
      final distanceText = leg['distance']['text'] as String;

      // Calculate cumulative distances along polyline
      List<double> cumulativeDistances = [0.0];
      for (int i = 1; i < polylinePoints.length; i++) {
        double segDist =
            _haversineDistance(polylinePoints[i - 1], polylinePoints[i]);
        cumulativeDistances.add(cumulativeDistances.last + segDist);
      }
      double totalPolylineDist = cumulativeDistances.last;

      // Determine number of stops based on route distance
      int numStops;
      if (totalDistanceMeters < 50000) {
        numStops = 0;
      } else if (totalDistanceMeters < 200000) {
        numStops = min(3, maxStops);
      } else if (totalDistanceMeters < 500000) {
        numStops = min(5, maxStops);
      } else {
        numStops = maxStops;
      }

      // Find driver's progress on route
      double driverDistanceOnRoute = 0;
      int driverSplitIndex = 0;
      if (driverPosition != null) {
        double minDist = double.infinity;
        for (int i = 0; i < polylinePoints.length; i++) {
          double d = _haversineDistance(driverPosition, polylinePoints[i]);
          if (d < minDist) {
            minDist = d;
            driverSplitIndex = i;
          }
        }
        driverDistanceOnRoute = cumulativeDistances[driverSplitIndex];
      }

      double driverFraction = totalPolylineDist > 0
          ? driverDistanceOnRoute / totalPolylineDist
          : 0;

      // Sample evenly-spaced intermediate stops
      List<Map<String, dynamic>> stops = [];
      if (numStops > 0 && totalPolylineDist > 0) {
        double interval = totalPolylineDist / (numStops + 1);
        for (int i = 1; i <= numStops; i++) {
          double targetDist = interval * i;
          LatLng point = _interpolatePointOnPolyline(
              targetDist, polylinePoints, cumulativeDistances);
          double fraction = targetDist / totalPolylineDist;
          bool passed =
              driverPosition != null && targetDist <= driverDistanceOnRoute;
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

        // Remove consecutive duplicate city names
        List<Map<String, dynamic>> uniqueStops = [];
        String? prevName;
        for (var stop in stops) {
          if (stop['name'] != prevName && stop['name'] != 'Unknown') {
            uniqueStops.add(stop);
            prevName = stop['name'] as String;
          }
        }
        stops = uniqueStops;
      }

      int remainingSeconds =
          ((1 - driverFraction) * totalDurationSeconds).round();

      return {
        'polyline_points': polylinePoints,
        'stops': stops,
        'total_duration_seconds': totalDurationSeconds,
        'total_distance_meters': totalDistanceMeters,
        'duration_text': durationText,
        'distance_text': distanceText,
        'driver_split_index': driverSplitIndex,
        'driver_progress_fraction': driverFraction,
        'remaining_duration_seconds': remainingSeconds,
      };
    } catch (e) {
      debugPrint('Error getting route with stops: $e');
      return {};
    }
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
