import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/meal_row_state.dart';

/// One editable meal line on a feed card.
///
/// Both halves are typed — the meal NUMBER as well as the quantity — so a meal
/// recorded out of order can still be called what it was. Whether a line came
/// from the server decides everything else about it: a saved line is corrected
/// through the API and removed with the bin, an unsaved one is simply taken off
/// the card.
void main() {
  group('MealRowState', () {
    test('a new line starts empty and unsaved', () {
      final row = MealRowState();

      expect(row.historyId, isNull);
      expect(row.isSaved, isFalse);
      expect(row.number.text, '');
      expect(row.quantity.text, '');

      row.dispose();
    });

    test('a line seeded from a record knows it exists on the server', () {
      final row = MealRowState(historyId: 501, number: '2', quantity: '20.64');

      expect(row.isSaved, isTrue);
      expect(row.number.text, '2');
      expect(row.quantity.text, '20.64');

      row.dispose();
    });

    test('an added line carries a number but no record behind it', () {
      // What "Add meal" produces: numbered on from the highest on the card,
      // editable, and not yet anything the server knows about.
      final row = MealRowState(number: '5');

      expect(row.isSaved, isFalse);
      expect(row.number.text, '5');
      expect(row.quantity.text, '');

      row.dispose();
    });

    test('the number is editable — it is typed, not derived from position', () {
      final row = MealRowState(number: '1');

      row.number.text = '3';

      expect(row.number.text, '3');

      row.dispose();
    });

    test('each line owns its own controllers', () {
      // Rows used to be keyed by list index, which handed one line the text
      // another was typing as soon as the order changed.
      final a = MealRowState(number: '1', quantity: '10');
      final b = MealRowState(number: '2', quantity: '20');

      a.number.text = '9';

      expect(b.number.text, '2', reason: 'b must not follow a');
      expect(a.quantity.text, '10');

      a.dispose();
      b.dispose();
    });

    test('dispose releases both controllers', () {
      final row = MealRowState(number: '1', quantity: '5');

      row.dispose();

      // A disposed controller throws when written to, because notifying its
      // listeners is what it can no longer do. That is the proof it was
      // actually released rather than left to leak on every rebuild.
      expect(() => row.number.text = '2', throwsFlutterError);
      expect(() => row.quantity.text = '9', throwsFlutterError);
    });
  });
}
