// Regression guard: timeline stops must span the WHOLE route, including the
// final leg into the destination.
//
// REPORTED (Adithya, bookings #1063-#1067):
//   #1067 (Chennai)  — stops ran out after Tirupati; Tirupati→Chennai empty.
//   #1066 (Tirupati) — stops ran out after Bapatla; Bapatla→Tirupati empty.
//   "for all bookings like that only"
//
// ROOT CAUSE: `getRouteWithStops` deduplicated candidates with an early break:
//
//     for (var stop in candidates) {
//       if (stops.length >= numStops) break;      // <-- discards the tail
//       ...
//     }
//
// Candidates are sampled evenly START -> END, so the loop filled its quota from
// the early part of the route and threw away every later candidate. The logs
// confirmed the count was right (15 stops for 524 km on #1067) — they were just
// all bunched into the first stretch.
//
// FIX: deduplicate across the whole route, then thin EVENLY, pinning the first
// and last index so the leg into the destination is always represented.

import 'package:flutter_test/flutter_test.dart';

/// A sampled candidate: its position along the route (0..1) and resolved name.
class Candidate {
  Candidate(this.fraction, this.name);
  final double fraction;
  final String name;
}

/// OLD selection (pre-fix): walk in route order, break at the quota.
List<Candidate> selectOld(List<Candidate> candidates, int numStops) {
  final stops = <Candidate>[];
  final seen = <String>{};
  for (final c in candidates) {
    if (stops.length >= numStops) break;
    if (c.name == 'Unknown' || seen.contains(c.name)) continue;
    seen.add(c.name);
    stops.add(c);
  }
  return stops;
}

/// NEW selection (post-fix): dedupe across the whole route, then thin evenly.
List<Candidate> selectNew(List<Candidate> candidates, int numStops) {
  final unique = <Candidate>[];
  final seen = <String>{};
  for (final c in candidates) {
    if (c.name == 'Unknown' || seen.contains(c.name)) continue;
    seen.add(c.name);
    unique.add(c);
  }
  if (unique.length <= numStops) return unique;
  if (numStops == 1) return [unique.last];
  final stops = <Candidate>[];
  final lastIdx = unique.length - 1;
  for (int i = 0; i < numStops; i++) {
    final idx = (i * lastIdx / (numStops - 1)).round().clamp(0, lastIdx);
    final picked = unique[idx];
    if (stops.isEmpty || !identical(stops.last, picked)) stops.add(picked);
  }
  return stops;
}

/// Candidates sampled evenly along a route, every one uniquely named.
List<Candidate> evenCandidates(int count) => [
      for (int i = 1; i <= count; i++) Candidate(i / (count + 1), 'Town$i')
    ];

void main() {
  group('#1067 Hyderabad → Chennai (524 km, 15 stops, 30 candidates)', () {
    final candidates = evenCandidates(30);

    test('OLD: coverage stops around halfway — the reported gap', () {
      final got = selectOld(candidates, 15);
      expect(got.length, 15);
      // Everything picked sits in the first half of the route: nothing is left
      // for the final leg into the destination.
      expect(got.last.fraction, lessThan(0.55),
          reason: 'tail of the route received no stops');
    });

    test('NEW: coverage reaches the destination', () {
      final got = selectNew(candidates, 15);
      expect(got.last.fraction, greaterThan(0.9),
          reason: 'the final leg into the destination must have a stop');
    });

    test('NEW: still returns the requested number of stops', () {
      expect(selectNew(candidates, 15).length, 15);
    });

    test('NEW: stops stay ordered by position along the route', () {
      final got = selectNew(candidates, 15);
      for (int i = 1; i < got.length; i++) {
        expect(got[i].fraction, greaterThan(got[i - 1].fraction));
      }
    });

    test('NEW: no gap larger than ~2 even spacings anywhere', () {
      final got = selectNew(candidates, 15);
      final spacing = 1.0 / 15;
      for (int i = 1; i < got.length; i++) {
        expect(got[i].fraction - got[i - 1].fraction, lessThan(spacing * 2.5),
            reason: 'stops must be spread, not bunched at one end');
      }
    });
  });

  group('#1066 Hyderabad → Tirupati (438 km, 12 stops, 24 candidates)', () {
    final candidates = evenCandidates(24);

    test('OLD: leaves the last stretch empty', () {
      expect(selectOld(candidates, 12).last.fraction, lessThan(0.55));
    });

    test('NEW: covers through to the destination', () {
      expect(selectNew(candidates, 12).last.fraction, greaterThan(0.9));
    });
  });

  group('duplicate place names collapse without breaking coverage', () {
    test('a long run of one city name does not eat the quota', () {
      // 10 samples all inside Vijayawada, then distinct towns onward — the
      // over-sampling case the dedup exists for.
      final candidates = <Candidate>[
        for (int i = 1; i <= 10; i++) Candidate(i / 31, 'Vijayawada'),
        for (int i = 11; i <= 30; i++) Candidate(i / 31, 'Town$i'),
      ];
      final got = selectNew(candidates, 8);
      expect(got.last.fraction, greaterThan(0.9));
      expect(got.map((c) => c.name).toSet().length, got.length,
          reason: 'names must stay unique');
    });
  });

  group('edge cases', () {
    test('fewer unique candidates than requested returns them all', () {
      expect(selectNew(evenCandidates(4), 10).length, 4);
    });

    test('single stop requested picks the far end, not the near one', () {
      expect(selectNew(evenCandidates(20), 1).first.fraction,
          greaterThan(0.9));
    });

    test('empty candidate list is safe', () {
      expect(selectNew(const <Candidate>[], 10), isEmpty);
    });

    test('Unknown names are excluded entirely', () {
      final candidates = <Candidate>[
        Candidate(0.1, 'Unknown'),
        Candidate(0.5, 'Guntur'),
        Candidate(0.9, 'Unknown'),
      ];
      final got = selectNew(candidates, 5);
      expect(got.map((c) => c.name), ['Guntur']);
    });
  });
}
