import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';

/// Multi-drop tracking: one driver, two bookings.
///
///   priority 1 → Kakinada     (delivered, but "Delivered" never pressed)
///   priority 2 → Kona Forest
///
/// The Kona Forest customer's live route was being drawn BACK through
/// Kakinada, because the only "skip this stop" signal was the booking status —
/// and that booking is still status 4.
///
/// The API now sends `is_passed` when the truck's own GPS trail shows it
/// reached the drop, stood still, and drove on. These tests pin the client
/// contract that depends on it.
void main() {
  /// Mirrors the filter the map screen applies when working out the route the
  /// truck has STILL to drive (6 call sites, all `!wp.isRouteSkippable`).
  List<RouteWaypoint> remaining(List<RouteWaypoint> all) => all
      .where((wp) => wp.lat != 0 && wp.lng != 0 && !wp.isRouteSkippable)
      .toList();

  /// Mirrors the FULL/planned route builder, which deliberately keeps every
  /// waypoint — the green covered line is sliced out of it and the arrival
  /// time is a fraction of it.
  List<RouteWaypoint> fullRoute(List<RouteWaypoint> all) =>
      all.where((wp) => wp.lat != 0 && wp.lng != 0).toList();

  RouteWaypoint kakinada({int status = 4, bool isPassed = false}) =>
      RouteWaypoint(
        lat: 16.9891,
        lng: 82.2475,
        status: status,
        priority: 1,
        name: 'Kakinada',
        isPassed: isPassed,
      );

  group('RouteWaypoint.fromJson', () {
    test('reads is_passed from the API', () {
      final wp = RouteWaypoint.fromJson({
        'lat': 16.9891,
        'lng': 82.2475,
        'status': 4,
        'priority': 1,
        'name': 'Kakinada',
        'is_passed': true,
      });

      expect(wp.isPassed, isTrue);
      expect(wp.name, 'Kakinada');
    });

    test('defaults is_passed to false when the API omits it', () {
      // An older backend that does not send the key must keep today's
      // behaviour rather than silently skipping stops.
      final wp = RouteWaypoint.fromJson({
        'lat': 16.9891,
        'lng': 82.2475,
        'status': 4,
        'name': 'Kakinada',
      });

      expect(wp.isPassed, isFalse);
      expect(wp.isRouteSkippable, isFalse);
    });

    test('survives a null is_passed', () {
      final wp = RouteWaypoint.fromJson({
        'lat': 1.0,
        'lng': 1.0,
        'is_passed': null,
      });

      expect(wp.isPassed, isFalse);
    });
  });

  group('isRouteSkippable', () {
    test('false for a stop the truck has not reached', () {
      expect(kakinada().isRouteSkippable, isFalse);
    });

    test('true once the truck has physically visited it', () {
      // The bug: status is still 4 because nobody pressed Delivered.
      final wp = kakinada(status: 4, isPassed: true);

      expect(wp.isCompleted, isFalse, reason: 'booking is still in journey');
      expect(wp.isRouteSkippable, isTrue, reason: 'but the truck has been there');
    });

    test('still true for a delivered stop, as before', () {
      expect(kakinada(status: 5).isRouteSkippable, isTrue);
    });

    test('still true for a cancelled stop, as before', () {
      expect(kakinada(status: 6).isRouteSkippable, isTrue);
    });

    test('does not change the meaning of isCompleted', () {
      // isCompleted is used elsewhere and must keep meaning delivered/cancelled
      // ONLY — a physically-visited stop is not a completed booking.
      expect(kakinada(status: 4, isPassed: true).isCompleted, isFalse);
      expect(kakinada(status: 5).isCompleted, isTrue);
      expect(kakinada(status: 6).isCompleted, isTrue);
    });
  });

  group('the Kona Forest customer route', () {
    test('routes through Kakinada until the truck has been there', () {
      final waypoints = [kakinada()];

      expect(
        remaining(waypoints).map((w) => w.name),
        contains('Kakinada'),
        reason: 'the truck really is stopping there first',
      );
    });

    test('drops Kakinada from the remaining route once visited', () {
      final waypoints = [kakinada(status: 4, isPassed: true)];

      expect(
        remaining(waypoints),
        isEmpty,
        reason: 'no back-track to a drop the truck already served',
      );
    });

    test('the OLD rule would have kept the back-track — this is the bug', () {
      // Demonstrates the defect directly rather than by implication. The
      // previous filter tested `!isCompleted`, and a booking nobody marked
      // Delivered is still status 4 — so the visited drop stayed on the route.
      final waypoints = [kakinada(status: 4, isPassed: true)];

      final underOldRule = waypoints
          .where((wp) => wp.lat != 0 && wp.lng != 0 && !wp.isCompleted)
          .toList();

      expect(
        underOldRule.map((w) => w.name),
        contains('Kakinada'),
        reason: 'the old filter could not tell that the truck had been there',
      );
      // Same input, new rule: gone.
      expect(remaining(waypoints), isEmpty);
    });

    test('keeps Kakinada in the FULL route even after it is visited', () {
      // This is the one that protects the green covered line and the ETA:
      // the full route must still contain every stop.
      final waypoints = [kakinada(status: 4, isPassed: true)];

      expect(
        fullRoute(waypoints).map((w) => w.name),
        contains('Kakinada'),
        reason: 'the green line is sliced from the full route',
      );
    });

    test('a zero-coordinate waypoint is excluded from both', () {
      final broken = RouteWaypoint(lat: 0, lng: 0, name: 'Nowhere');

      expect(remaining([broken]), isEmpty);
      expect(fullRoute([broken]), isEmpty);
    });
  });

  group('the Kakinada customer', () {
    test('has no earlier stops, so nothing can be skipped', () {
      // The API returns priority < 1 for a priority-1 booking, which matches
      // nothing — so this customer's waypoint list is empty and the new flag
      // cannot affect what they see.
      expect(remaining(const []), isEmpty);
      expect(fullRoute(const []), isEmpty);
    });
  });
}
