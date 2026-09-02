import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/util/date_format.dart';

/// The farmer reads `dd-MM-yyyy`; the API reads `yyyy-MM-dd`.
///
/// Both forms live in the same text fields — a field is seeded from the API in
/// ISO and rewritten in display form the moment a date is picked — so the risk
/// is not formatting but CONFUSION between the two. A display date posted raw
/// is either rejected or read as a different day, which is exactly the bug
/// these tests exist to keep out.
void main() {
  group('displayDate', () {
    test('pads day and month to two digits', () {
      expect(displayDate(DateTime(2026, 9, 2)), '02-09-2026');
      expect(displayDate(DateTime(2026, 12, 25)), '25-12-2026');
      expect(displayDate(DateTime(2026, 1, 1)), '01-01-2026');
    });
  });

  group('displayDateFrom', () {
    test('renders an ISO string from the API', () {
      expect(displayDateFrom('2026-08-16'), '16-08-2026');
    });

    test('leaves an already-display date alone', () {
      expect(displayDateFrom('16-08-2026'), '16-08-2026');
    });

    test('falls back rather than showing an empty gap', () {
      expect(displayDateFrom(null), '-');
      expect(displayDateFrom(''), '-');
      expect(displayDateFrom('not a date'), '-');
      expect(displayDateFrom(null, fallback: '—'), '—');
    });

    test('reads a full ISO timestamp, which is what the API sends', () {
      // created_at comes back as 2026-09-02T05:52:17.000000Z.
      expect(displayDateFrom('2026-09-02T05:52:17.000000Z'), '02-09-2026');
    });
  });

  group('isoDate', () {
    test('converts what a field holds into what the API takes', () {
      expect(isoDate('02-09-2026'), '2026-09-02');
    });

    test('leaves an API value untouched', () {
      expect(isoDate('2026-09-02'), '2026-09-02');
    });

    test('is empty when there is nothing to send', () {
      expect(isoDate(null), '');
      expect(isoDate(''), '');
      expect(isoDate('   '), '');
      expect(isoDate('rubbish'), '');
    });
  });

  group('parseDisplayDate', () {
    test('tells the two forms apart by the length of the first part', () {
      // 02-09-2026 is the 2nd of September; 2026-09-02 is the same day written
      // the other way round. Reading either as the other shifts the date.
      expect(parseDisplayDate('02-09-2026'), DateTime(2026, 9, 2));
      expect(parseDisplayDate('2026-09-02'), DateTime(2026, 9, 2));
    });

    test('returns null for anything unusable', () {
      expect(parseDisplayDate(null), isNull);
      expect(parseDisplayDate(''), isNull);
      expect(parseDisplayDate('  '), isNull);
      expect(parseDisplayDate('tomorrow'), isNull);
    });
  });

  group('round trip', () {
    test('a picked date survives display and submission unshifted', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 8, 16),
        DateTime(2026, 9, 2),
        DateTime(2026, 10, 31),
        DateTime(2026, 12, 31),
      ];

      for (final d in dates) {
        final shown = displayDate(d);
        expect(parseDisplayDate(shown), d, reason: 'lost the day for $shown');
        expect(
          isoDate(shown),
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}',
        );
      }
    });

    test('an ISO value survives a display pass and comes back unchanged', () {
      // What happens when a farmer opens the edit form and saves without
      // touching the date: API -> field -> API.
      for (final iso in ['2026-08-01', '2026-08-16', '2026-09-02']) {
        expect(isoDate(displayDateFrom(iso)), iso);
      }
    });
  });
}
