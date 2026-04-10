part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEED ESTIMATION & DYNAMIC DRIVING MODE
//
// Estimates the vehicle's current speed from consecutive GPS positions and
// switches the app into one of three driving modes:
//   • City     (< 25 km/h) — tight snapping, short search window, dense breadcrumbs
//   • Suburban (25–60 km/h) — relaxed thresholds for wider roads
//   • Highway  (> 60 km/h) — loose snapping, large window, sparse breadcrumbs
//
// Speed is smoothed with exponential averaging (70/30 split) to prevent a
// single bad GPS reading from flipping the mode. Mode changes only stick
// after 3 consecutive polls agree on the new mode (no flickering).
//
// Each mode getter returns the right threshold value for that context:
//   • _snapThreshold        — how far off-road before a snap is rejected
//   • _rerouteThreshold     — how far off-route before rerouting triggers
//   • _breadcrumbMinDistance — minimum metres between saved GPS breadcrumbs
//   • _segmentSearchWindow  — how many polyline segments to scan for snapping
//
// Also provides the cubic ease-in-out curve used by the marker animator.
// ─────────────────────────────────────────────────────────────────────────────

extension MapSpeedMode on _VehicleTrackingMapScreenState {
  /// Update speed estimate from GPS positions. Called every poll.
  /// Uses exponential smoothing + stable mode switching (no flickering).
  void _updateSpeedEstimate(LatLng newPos) {
    final now = DateTime.now();
    if (_lastSpeedCalcPos != null && _lastSpeedCalcTime != null) {
      final elapsed = now.difference(_lastSpeedCalcTime!).inSeconds;
      if (elapsed > 0) {
        final dist = _haversineMeters(_lastSpeedCalcPos!, newPos);
        final instantSpeed = (dist / elapsed) * 3.6; // km/h
        // Exponential smoothing (a=0.3): prevents GPS spike from flipping mode
        _estimatedSpeedKmh = _estimatedSpeedKmh * 0.7 + instantSpeed * 0.3;
      }
    }
    _lastSpeedCalcPos = newPos;
    _lastSpeedCalcTime = now;

    // Stable mode switching: only change after 3 consecutive polls agree
    final int targetMode;
    if (_estimatedSpeedKmh >= 60) {
      targetMode = 2; // highway
    } else if (_estimatedSpeedKmh >= 25) {
      targetMode = 1; // suburban
    } else {
      targetMode = 0; // city
    }

    if (targetMode != _currentMode) {
      if (targetMode == _pendingMode) {
        _pendingModeCount++;
        if (_pendingModeCount >= _VehicleTrackingMapScreenState._modeChangeThreshold) {
          _currentMode = targetMode;
          _pendingModeCount = 0;
          debugPrint('Mode switched to ${['city', 'suburban', 'highway'][_currentMode]} '
              '(speed=${_estimatedSpeedKmh.toStringAsFixed(0)}km/h)');
        }
      } else {
        _pendingMode = targetMode;
        _pendingModeCount = 1;
      }
    } else {
      _pendingModeCount = 0;
    }
  }

  /// Dynamic snap threshold: city 25m / suburban 40m / highway 60m
  double get _snapThreshold {
    switch (_currentMode) {
      case 2: return 60;  // highway
      case 1: return 40;  // suburban
      default: return 25; // city
    }
  }

  /// Dynamic reroute threshold: city 100m / suburban 120m / highway 150m
  double get _rerouteThreshold {
    switch (_currentMode) {
      case 2: return 150;  // highway
      case 1: return 120;  // suburban
      default: return _VehicleTrackingMapScreenState._polylineRerouteThresholdMeters; // city = 100m
    }
  }

  /// Dynamic breadcrumb min distance: city 20m / suburban 30m / highway 50m
  double get _breadcrumbMinDistance {
    switch (_currentMode) {
      case 2: return 50;  // highway
      case 1: return 30;  // suburban
      default: return 20; // city
    }
  }

  /// Dynamic segment search window: city 10 / suburban 20 / highway 50
  int get _segmentSearchWindow {
    switch (_currentMode) {
      case 2: return 50;  // highway
      case 1: return 20;  // suburban
      default: return 10; // city
    }
  }

  // Cubic ease-in-out for smooth marker acceleration/deceleration
  double _easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
  }
}
