import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';

void main() {
  test('shows dd-MM-yyyy', () {
    expect(displayDate(DateTime(2026, 9, 2)), '02-09-2026');
    expect(displayDate(DateTime(2026, 12, 25)), '25-12-2026');
  });

  test('sends yyyy-MM-dd whatever the field holds', () {
    expect(isoDate('02-09-2026'), '2026-09-02');
    // Values straight from the API are already ISO and must survive untouched.
    expect(isoDate('2026-09-02'), '2026-09-02');
    expect(isoDate(''), '');
    expect(isoDate(null), '');
  });

  test('a display date round-trips without shifting the day', () {
    for (final d in [
      DateTime(2026, 1, 1),
      DateTime(2026, 8, 16),
      DateTime(2026, 9, 2),
      DateTime(2026, 12, 31),
    ]) {
      expect(isoDate(displayDate(d)),
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  });

  test('parses both forms back to the same day', () {
    expect(parseDisplayDate('02-09-2026'), DateTime(2026, 9, 2));
    expect(parseDisplayDate('2026-09-02'), DateTime(2026, 9, 2));
    expect(parseDisplayDate('  '), isNull);
  });

  test('ISO ordering is what the earliest-date sort relies on', () {
    // The bug this guards: sorted as display text, 02-09 beats 16-08.
    final display = ['02-09-2026', '16-08-2026']..sort();
    expect(display.first, '02-09-2026', reason: 'wrong, and why we convert');

    final iso = ['02-09-2026', '16-08-2026'].map(isoDate).toList()..sort();
    expect(iso.first, '2026-08-16', reason: 'August really is earlier');
  });
}
