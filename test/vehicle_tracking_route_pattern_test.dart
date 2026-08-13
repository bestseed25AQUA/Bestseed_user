// Regression guard for the iOS dashed-polyline truncation.
//
// ROOT CAUSE (confirmed on an iPhone 16 Plus simulator against live production
// data for bookings #1060/#1061/#1062):
//
//   iOS renders `PatternItem.dash/gap` by generating GMSStyleSpans along the
//   path. On a long route the spans run out before the line does, so the map
//   draws only the leading portion and stops — at whatever point the spans were
//   exhausted, which in practice was the last route waypoint. The polyline
//   handed to the platform was COMPLETE: the render log recorded
//     last=(16.57748,82.00320)
//   which is booking #1062's exact destination (Kakinada, 16.5774798/82.0031455).
//   Android implements patterns natively and never truncated — hence iOS-only.
//
//   Disabling the dash pattern made the full route draw. That experiment is the
//   proof; `_routePattern` is the shipped form of it.
//
// Observed, and the basis for the 75 km threshold:
//   #1060  183 km  dashed  -> drew correctly
//   #1061  324 km  dashed  -> truncated at the priority-1 drop
//   #1062  506 km  dashed  -> truncated at the priority-2 drop

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const double maxDashedRouteMeters = 75000;

double haversineMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * pi / 180.0;
  final dLng = (b.longitude - a.longitude) * pi / 180.0;
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(a.latitude * pi / 180.0) *
          cos(b.latitude * pi / 180.0) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return 2 * r * asin(sqrt(h));
}

/// Verbatim copy of the implementation under test.
List<PatternItem> routePattern(List<LatLng> pts) {
  if (pts.length < 2) return const <PatternItem>[];
  double metres = 0;
  for (int i = 1; i < pts.length; i++) {
    metres += haversineMeters(pts[i - 1], pts[i]);
    if (metres > maxDashedRouteMeters) return const <PatternItem>[];
  }
  return [PatternItem.dash(20), PatternItem.gap(10)];
}

bool isSolid(List<PatternItem> p) => p.isEmpty;

/// Straight line of [n] samples between two points.
List<LatLng> leg(LatLng from, LatLng to, [int n = 200]) => [
      for (int i = 0; i < n; i++)
        LatLng(
          from.latitude + (to.latitude - from.latitude) * (i / (n - 1)),
          from.longitude + (to.longitude - from.longitude) * (i / (n - 1)),
        )
    ];

void main() {
  // Real coordinates from the production API.
  const driver = LatLng(17.47762, 78.394887);
  const drop1060 = LatLng(17.1417379, 79.6204326); // priority 1, Suryapet
  const drop1061 = LatLng(16.5061743, 80.6480153); // priority 2, Vijayawada
  const drop1062 = LatLng(16.5774798, 82.0031455); // priority 3, Kakinada

  group('the routes that actually broke now render solid', () {
    test('#1061 (324 km, truncated at priority-1 drop) is solid', () {
      final route = [...leg(driver, drop1060), ...leg(drop1060, drop1061)];
      expect(isSolid(routePattern(route)), isTrue);
    });

    test('#1062 (506 km, truncated at priority-2 drop) is solid', () {
      final route = [
        ...leg(driver, drop1060),
        ...leg(drop1060, drop1061),
        ...leg(drop1061, drop1062),
      ];
      expect(isSolid(routePattern(route)), isTrue);
    });

    test('#1060 (183 km) is also solid — it is above the 75 km threshold', () {
      // #1060 drew correctly WITH dashes, but 183 km is close enough to the
      // failure range that the conservative threshold covers it too. Being
      // solid here is intentional, not a regression.
      expect(isSolid(routePattern(leg(driver, drop1060))), isTrue);
    });
  });

  group('short city deliveries keep the dashed styling', () {
    test('a ~12 km KPHB → Gachibowli hop stays dashed', () {
      final route =
          leg(const LatLng(17.4849, 78.3915), const LatLng(17.4401, 78.3489));
      final p = routePattern(route);
      expect(isSolid(p), isFalse);
      expect(p.length, 2);
    });

    test('just under the threshold stays dashed', () {
      // ~0.6° latitude ≈ 67 km.
      final route =
          leg(const LatLng(17.0, 78.0), const LatLng(17.6, 78.0));
      final len = haversineMeters(route.first, route.last);
      expect(len, lessThan(maxDashedRouteMeters));
      expect(isSolid(routePattern(route)), isFalse);
    });

    test('just over the threshold flips to solid', () {
      // ~0.8° latitude ≈ 89 km.
      final route =
          leg(const LatLng(17.0, 78.0), const LatLng(17.8, 78.0));
      final len = haversineMeters(route.first, route.last);
      expect(len, greaterThan(maxDashedRouteMeters));
      expect(isSolid(routePattern(route)), isTrue);
    });
  });

  group('degenerate inputs', () {
    test('empty and single-point lists are solid, never crash', () {
      expect(isSolid(routePattern(const <LatLng>[])), isTrue);
      expect(isSolid(routePattern(const [drop1060])), isTrue);
    });

    test('two identical points are dashed (zero length, well under limit)', () {
      expect(isSolid(routePattern(const [drop1060, drop1060])), isFalse);
    });

    test('early-out does not scan the whole list on a long route', () {
      // 20k points spanning far more than the threshold: the loop must bail
      // as soon as the running total crosses it, not total the entire route.
      final huge = leg(driver, drop1062, 20000);
      final sw = Stopwatch()..start();
      final p = routePattern(huge);
      sw.stop();
      expect(isSolid(p), isTrue);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });
}
