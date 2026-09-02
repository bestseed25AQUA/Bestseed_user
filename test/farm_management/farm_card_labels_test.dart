import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';

/// The two figures printed on a farm card.
///
/// Both are formatting decisions with a history: the store used to show what
/// was PUT IN rather than what is left, so a card read as though nothing had
/// been used; and the total used to be truncated by its Row, turning "300.00"
/// into "300…" — a figure that still looks like a number.
void main() {
  FarmSection card({
    String store = '10000',
    num? remainingStore,
    num totalFeedUsed = 0,
  }) =>
      FarmSection(
        name: 'Testing',
        id: '59',
        store: store,
        remainingStore: remainingStore,
        totalFeedUsed: totalFeedUsed,
        lowFeedLimit: '50',
        noOfTanks: 4,
        activeCount: '4',
        inactiveCount: '0',
        imageUrls: const [],
        stockingDate: '2026-08-01',
        access: const FarmAccess.ownerFallback(),
      );

  group('storeLabel', () {
    test('shows what is LEFT, not what was put in', () {
      // 10,000 bought, 20 recorded, 9,980 in the shed. The card must not read
      // 10,000 while the farm's own header says 9,980.
      expect(card(store: '10000', remainingStore: 9980).storeLabel, '9980 kgs');
    });

    test('drops a pointless decimal on a whole number', () {
      expect(card(remainingStore: 9980.0).storeLabel, '9980 kgs');
    });

    test('keeps the paise when there are any', () {
      expect(card(remainingStore: 942.5).storeLabel, '942.50 kgs');
      expect(card(remainingStore: 4443.71).storeLabel, '4443.71 kgs');
    });

    test('a farm with nothing left reads zero, not unknown', () {
      expect(card(remainingStore: 0).storeLabel, '0 kgs');
    });

    test('an em dash when no stock figure has ever been entered', () {
      // Unset is not the same as a store of nothing, and showing "0 kgs" for it
      // claims a farm is empty when nobody has said what it holds.
      expect(card(store: '', remainingStore: null).storeLabel, '—');
    });

    test('falls back to the raw figure only when the server sent no remainder',
        () {
      // An older API, or a farm the endpoint could not compute one for.
      expect(card(store: '600', remainingStore: null).storeLabel, '600 kgs');
    });
  });

  group('totalFeedUsedLabel', () {
    test('shows a whole number without a trailing .0', () {
      expect(card(totalFeedUsed: 1020).totalFeedUsedLabel, '1020');
      expect(card(totalFeedUsed: 1020.0).totalFeedUsedLabel, '1020');
    });

    test('keeps two decimals when the figure has them', () {
      expect(card(totalFeedUsed: 546.08).totalFeedUsedLabel, '546.08');
      expect(card(totalFeedUsed: 508.03).totalFeedUsedLabel, '508.03');
    });

    test('a farm that has fed nothing reads 0', () {
      expect(card(totalFeedUsed: 0).totalFeedUsedLabel, '0');
    });

    test('a five-figure total is printed in full, never abbreviated', () {
      // It used to be ellipsised to fit its Row: "25000…" reads as a number and
      // is wrong by a factor of ten.
      expect(card(totalFeedUsed: 25000).totalFeedUsedLabel, '25000');
      expect(card(totalFeedUsed: 25000).totalFeedUsedLabel, isNot(contains('…')));
    });
  });
}
