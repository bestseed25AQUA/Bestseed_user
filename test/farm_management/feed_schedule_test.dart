import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/feed_schedule.dart';

/// Days 1-2 take 2 meals, days 3-4 take 3, day 5 onwards takes 4.
///
/// The server generates a tank's back-history from the same rule
/// (`FeedBackfillService::mealsForDay`). If these two drift, a farmer opening a
/// generated day sees a different number of meal boxes than the rows sitting
/// behind it — so the boundaries are pinned here deliberately.
void main() {
  group('mealsForDay', () {
    test('2 meals for the first two days', () {
      expect(mealsForDay(1), 2);
      expect(mealsForDay(2), 2);
    });

    test('3 meals for the next two', () {
      expect(mealsForDay(3), 3);
      expect(mealsForDay(4), 3);
    });

    test('4 meals from day 5 onwards, however old the crop', () {
      expect(mealsForDay(5), 4);
      expect(mealsForDay(6), 4);
      expect(mealsForDay(33), 4);
      expect(mealsForDay(400), 4);
    });
  });

  group('dayNumberFor', () {
    final stocked = DateTime(2026, 8, 20);

    test('the stocking date itself is day 1, not day 0', () {
      expect(dayNumberFor(stockingDate: stocked, date: DateTime(2026, 8, 20)), 1);
    });

    test('counts on by whole days', () {
      expect(dayNumberFor(stockingDate: stocked, date: DateTime(2026, 8, 21)), 2);
      expect(dayNumberFor(stockingDate: stocked, date: DateTime(2026, 8, 24)), 5);
      expect(dayNumberFor(stockingDate: stocked, date: DateTime(2026, 9, 2)), 14);
    });

    test('ignores the time of day', () {
      expect(
        dayNumberFor(
          stockingDate: DateTime(2026, 8, 20, 23, 59),
          date: DateTime(2026, 8, 21, 0, 1),
        ),
        2,
      );
    });

    test('a day before stocking is outside the crop', () {
      expect(dayNumberFor(stockingDate: stocked, date: DateTime(2026, 8, 19)), 0);
    });

    test('no stocking date means no day count', () {
      expect(dayNumberFor(stockingDate: null, date: DateTime(2026, 8, 20)), 0);
    });

    test('spans a month boundary correctly', () {
      expect(
        dayNumberFor(
          stockingDate: DateTime(2026, 8, 31),
          date: DateTime(2026, 9, 1),
        ),
        2,
      );
    });
  });

  group('mealsOnDate', () {
    // The worked example the farmer gave: stocked 20 Aug.
    final stocked = DateTime(2026, 8, 20);

    test('20th and 21st take 2 meals', () {
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 20)), 2);
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 21)), 2);
    });

    test('22nd and 23rd take 3', () {
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 22)), 3);
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 23)), 3);
    });

    test('24th onwards takes 4', () {
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 24)), 4);
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 9, 2)), 4);
    });

    test('nothing due outside the crop', () {
      expect(mealsOnDate(stockingDate: stocked, date: DateTime(2026, 8, 19)), 0);
      expect(mealsOnDate(stockingDate: null, date: DateTime(2026, 8, 20)), 0);
    });

    test('a whole crop sums to the slot count the backfill divides by', () {
      // 20 Aug to 2 Sep inclusive is 14 days: 2+2+3+3 then ten days of 4.
      var slots = 0;
      for (var d = DateTime(2026, 8, 20);
          !d.isAfter(DateTime(2026, 9, 2));
          d = d.add(const Duration(days: 1))) {
        slots += mealsOnDate(stockingDate: stocked, date: d);
      }

      expect(slots, 2 + 2 + 3 + 3 + (10 * 4));
    });
  });
}
