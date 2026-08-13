// Proof for the vehicle-tracking polyline load on iOS.
//
// Ground truth pulled live from the production API for the reported bookings
// (GET /api/farmer/vehicle_tracking/{id}), then the exact Directions request
// the app issues:
//
//   1060 (prio 1)  0 waypoints  -> 1 leg   ->  4,009 pts / 183 km  — "correct"
//   1061 (prio 2)  1 waypoint   -> 2 legs  ->  7,308 pts / 324 km  — "polyline wrong"
//   1062 (prio 3)  2 waypoints  -> 3 legs  -> 11,631 pts / 506 km  — "crashes, some iPhones"
//
// Every one of those points was handed to the native map as a single Polyline.
// `_simplifyForRender` (Ramer-Douglas-Peucker, 8 m) is applied at render time
// only. These tests replicate it exactly and assert two things that must BOTH
// hold: the count collapses, and the drawn line does not visibly move.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ── verbatim copies of the implementation under test ────────────────────────

double perpDistMeters(LatLng p, LatLng a, LatLng b) {
  const mPerDegLat = 111320.0;
  final mPerDegLng = 111320.0 * cos(a.latitude * pi / 180.0);
  final px = (p.longitude - a.longitude) * mPerDegLng;
  final py = (p.latitude - a.latitude) * mPerDegLat;
  final bx = (b.longitude - a.longitude) * mPerDegLng;
  final by = (b.latitude - a.latitude) * mPerDegLat;
  final len2 = bx * bx + by * by;
  if (len2 == 0) return sqrt(px * px + py * py);
  final t = ((px * bx + py * by) / len2).clamp(0.0, 1.0);
  final dx = px - t * bx;
  final dy = py - t * by;
  return sqrt(dx * dx + dy * dy);
}

List<LatLng> simplifyForRender(List<LatLng> pts,
    {double toleranceMeters = 8.0}) {
  if (pts.length <= 2) return pts;
  final keep = List<bool>.filled(pts.length, false);
  keep[0] = true;
  keep[pts.length - 1] = true;
  final stack = <List<int>>[
    [0, pts.length - 1]
  ];
  while (stack.isNotEmpty) {
    final seg = stack.removeLast();
    final first = seg[0];
    final last = seg[1];
    double maxD = 0.0;
    int idx = -1;
    for (int i = first + 1; i < last; i++) {
      final d = perpDistMeters(pts[i], pts[first], pts[last]);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx != -1 && maxD > toleranceMeters) {
      keep[idx] = true;
      stack.add([first, idx]);
      stack.add([idx, last]);
    }
  }
  final out = <LatLng>[];
  for (int i = 0; i < pts.length; i++) {
    if (keep[i]) out.add(pts[i]);
  }
  return out;
}

// ── real production route data ──────────────────────────────────────────────

/// Decode a Google encoded-polyline string (same algorithm as the app's
/// `_decodePolyline`).
List<LatLng> decodePolyline(String s) {
  final pts = <LatLng>[];
  int i = 0, lat = 0, lng = 0;
  while (i < s.length) {
    for (int k = 0; k < 2; k++) {
      int shift = 0, result = 0, b;
      do {
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final v = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      if (k == 0) {
        lat += v;
      } else {
        lng += v;
      }
    }
    pts.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return pts;
}

/// Merge encoded steps exactly as `getDirectionsHighRes` does, skipping the
/// duplicate point at each step boundary.
List<LatLng> mergeSteps(List<dynamic> steps) {
  final merged = <LatLng>[];
  for (final enc in steps) {
    final p = decodePolyline(enc as String);
    if (p.isEmpty) continue;
    final start = (merged.isNotEmpty &&
            p.first.latitude == merged.last.latitude &&
            p.first.longitude == merged.last.longitude)
        ? 1
        : 0;
    for (int i = start; i < p.length; i++) {
      merged.add(p[i]);
    }
  }
  return merged;
}

/// Greatest distance from any original point to the simplified line — the
/// honest measure of whether the drawn route moved.
double maxDeviationMeters(List<LatLng> original, List<LatLng> simplified) {
  double worst = 0.0;
  for (final p in original) {
    double best = double.infinity;
    for (int i = 0; i < simplified.length - 1; i++) {
      final d = perpDistMeters(p, simplified[i], simplified[i + 1]);
      if (d < best) best = d;
    }
    if (best > worst) worst = best;
  }
  return worst;
}

void main() {
  final fixture = json.decode(
      File('test/fixtures/real_routes.json').readAsStringSync()) as Map<String, dynamic>;

  List<LatLng> route(String id) =>
      mergeSteps((fixture[id] as Map<String, dynamic>)['steps'] as List<dynamic>);

  final route1060 = route('1060');
  final route1061 = route('1061');
  final route1062 = route('1062');

  group('point counts match the measured production routes', () {
    test('1060 / 1061 / 1062 are 4009 / 7308 / 11631', () {
      expect(route1060.length, 4009);
      expect(route1061.length, 7308);
      expect(route1062.length, 11631);
    });
  });

  group('simplification collapses the native-map load', () {
    for (final c in [
      ('1060 (prio 1)', route1060),
      ('1061 (prio 2)', route1061),
      ('1062 (prio 3)', route1062),
    ]) {
      test('${c.$1}: at least 85% of points removed', () {
        final simplified = simplifyForRender(c.$2);
        // ignore: avoid_print
        print('  ${c.$1}: ${c.$2.length} -> ${simplified.length} points '
            '(${(100 * (1 - simplified.length / c.$2.length)).toStringAsFixed(1)}% removed)');
        expect(simplified.length / c.$2.length, lessThan(0.15),
            reason: 'measured ~10-11% retained on real Directions geometry');
        expect(simplified.length, greaterThan(2));
      });
    }

    test('worst case 1062 retains under 12% of its points', () {
      final simplified = simplifyForRender(route1062);
      expect(simplified.length / route1062.length, lessThan(0.12));
    });
  });

  group('the drawn route does not visibly move', () {
    for (final c in [
      ('1060', route1060),
      ('1061', route1061),
      ('1062', route1062),
    ]) {
      test('${c.$1}: max deviation stays within the 8 m tolerance', () {
        final simplified = simplifyForRender(c.$2);
        final dev = maxDeviationMeters(c.$2, simplified);
        // ignore: avoid_print
        print('  ${c.$1}: max deviation ${dev.toStringAsFixed(2)} m');
        expect(dev, lessThanOrEqualTo(8.0),
            reason: 'RDP guarantees every dropped point lies within tolerance');
      });
    }
  });

  group('endpoints and ordering are preserved', () {
    test('first and last points are never dropped', () {
      final simplified = simplifyForRender(route1062);
      expect(simplified.first, equals(route1062.first));
      expect(simplified.last, equals(route1062.last));
    });

    test('simplified points remain a subsequence of the original', () {
      final simplified = simplifyForRender(route1061);
      int j = 0;
      for (final p in route1061) {
        if (j < simplified.length && identical(p, simplified[j])) j++;
      }
      expect(j, simplified.length,
          reason: 'no interpolated points are invented');
    });
  });

  group('degenerate inputs are safe', () {
    test('empty, single and two-point lists pass through untouched', () {
      final a = route1060.first;
      final b = route1060.last;
      expect(simplifyForRender(const <LatLng>[]), isEmpty);
      expect(simplifyForRender([a]).length, 1);
      expect(simplifyForRender([a, b]).length, 2);
    });

    test('all-identical points collapse to the two endpoints', () {
      final same = List<LatLng>.filled(500, route1060.first);
      expect(simplifyForRender(same).length, 2);
    });

    test('11k points complete quickly (no pathological blow-up)', () {
      final sw = Stopwatch()..start();
      simplifyForRender(route1062);
      sw.stop();
      // ignore: avoid_print
      print('  1062 simplified in ${sw.elapsedMilliseconds} ms');
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
