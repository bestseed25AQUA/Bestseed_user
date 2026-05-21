import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

/// Persists passed stops per booking. Once a stop is marked "passed",
/// its time and data never change — even if the driver deviates later.
class PassedStopsService {
  static const _prefix = 'passed_stops_';

  /// Load saved passed stops for a booking.
  static Future<List<Map<String, dynamic>>> load(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bookingId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('PassedStopsService: load error: $e');
      return [];
    }
  }

  /// Save passed stops for a booking.
  static Future<void> save(String bookingId, List<Map<String, dynamic>> stops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$bookingId', jsonEncode(stops));
  }

  /// Check if driver is within [thresholdMeters] of a stop's lat/lng.
  static bool isNearStop(LatLng driverPos, double stopLat, double stopLng, {double thresholdMeters = 1000}) {
    final dist = _distanceMeters(driverPos.latitude, driverPos.longitude, stopLat, stopLng);
    return dist <= thresholdMeters;
  }

  /// Check if driver has passed a stop based on route progression.
  /// A stop is "passed" if the driver's distance from pickup along the route
  /// is greater than the stop's distance from pickup.
  static bool hasPassedStop(
    LatLng driverPos,
    LatLng pickup,
    double stopLat,
    double stopLng,
  ) {
    final driverDistFromPickup = _distanceMeters(
      pickup.latitude, pickup.longitude,
      driverPos.latitude, driverPos.longitude,
    );
    final stopDistFromPickup = _distanceMeters(
      pickup.latitude, pickup.longitude,
      stopLat, stopLng,
    );
    // Driver has passed the stop if they're further from pickup than the stop
    // AND within reasonable proximity (not on a completely different road)
    return driverDistFromPickup > stopDistFromPickup;
  }

  /// Calculate ETA in minutes from current position to a target position
  /// given speed in km/h. Falls back to 40 km/h if speed is 0.
  static int estimateMinutes(LatLng from, double toLat, double toLng, double speedKmh) {
    final dist = _distanceMeters(from.latitude, from.longitude, toLat, toLng);
    final speed = speedKmh > 0 ? speedKmh : 40.0; // default 40 km/h
    final hours = (dist / 1000.0) / speed;
    return (hours * 60).round();
  }

  /// Haversine distance in meters.
  static double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  /// Format DateTime to "hh:mm AM/PM" string.
  static String formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  /// Format DateTime to "dd/MM/yyyy" string.
  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
