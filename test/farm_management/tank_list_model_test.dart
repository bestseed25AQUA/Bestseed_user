import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';

/// Parsing `GET /api/farmer/farms/{id}/tanks`.
///
/// The payload mixes types by accident of where each figure comes from:
/// computed sums arrive as numbers, raw decimal columns as strings. Assigning
/// one to a field typed for the other used to throw and surface as a tank
/// literally named "Error", so the coercions are pinned here.
void main() {
  Map<String, dynamic> tankJson() =>
      jsonDecode(jsonEncode({
        "id": 1209,
        "farm_id": 59,
        "tank_name": "Tank1",
        "status": 1,
        "store": 0,
        "total_feed_used": 546.08,
        "meals": 0,
        "feed_quantity": "15.84",
        "stocking_date": "2026-08-01",
        "created_at": "2026-09-02T10:26:50.000000Z",
        "updated_at": "2026-09-02T12:05:07.000000Z",
        "day": 33,
        "batch_id": 1216,
        "batch_no": 1,
        "batch_active": true,
        "effective_stocking_date": "2026-08-01",
        "todays_meal_count": 4,
        "feed_used_before": "500.00",
        "todays_meals": 3,
        "todays_quantity": 61.92,
        "todays_feed": [
          {"id": 501, "meals": 1, "feed_quantity": "20.64"},
          {"id": 502, "meals": 2, "feed_quantity": "20.64"},
          {"id": 503, "meals": 3, "feed_quantity": "20.64"},
        ],
        "feed": null,
      })) as Map<String, dynamic>;

  group('TankModel.fromJson', () {
    test('reads a tank card', () {
      final tank = TankModel.fromJson(tankJson());

      expect(tank.id, 1209);
      expect(tank.tankName, 'Tank1');
      expect(tank.status, 1);
      expect(tank.day, 33);
      expect(tank.stockingDate, '2026-08-01');
    });

    test('takes a number for a computed sum and a string for a column', () {
      final tank = TankModel.fromJson(tankJson());

      expect(tank.totalFeedUsed, '546.08');
      expect(tank.feedQuantity, '15.84');
    });

    test('reads every meal recorded today, not just the last one', () {
      // A day is a LIST. Reading one entry meant a second meal recorded today
      // replaced the first on screen instead of joining it.
      final tank = TankModel.fromJson(tankJson());

      expect(tank.todaysFeed, hasLength(3));
      expect(tank.todaysFeed.map((e) => e.meals), ['1', '2', '3']);
      expect(tank.todaysFeed.first.id, 501);
      expect(tank.todaysFeed.first.feedQuantity, '20.64');
    });

    test('a tank fed nothing today has an empty list, never null', () {
      final json = tankJson()..remove('todays_feed');

      expect(TankModel.fromJson(json).todaysFeed, isEmpty);
    });

    test('carries the crop cycle it belongs to', () {
      final tank = TankModel.fromJson(tankJson());

      expect(tank.batchId, 1216);
      expect(tank.batchNo, 1);
      expect(tank.batchActive, isTrue);
    });

    test('a harvested tank reads as inactive so its history locks', () {
      final json = tankJson()
        ..['batch_active'] = false
        ..['status'] = 0;

      final tank = TankModel.fromJson(json);

      expect(tank.batchActive, isFalse);
      expect(tank.status, 0);
    });

    test('a server without batches leaves the tank editable', () {
      // Defaulting to false would silently lock every tank on an older API.
      final json = tankJson()..remove('batch_active');

      expect(TankModel.fromJson(json).batchActive, isTrue);
    });

    test('falls back to the tank date when there is no effective one', () {
      final json = tankJson()..remove('effective_stocking_date');

      expect(TankModel.fromJson(json).effectiveStockingDate, '2026-08-01');
    });

    test('reads the prior-usage figure the edit form shows back', () {
      expect(TankModel.fromJson(tankJson()).feedUsedBefore, 500);
    });

    test('a broken payload yields a marked tank rather than throwing', () {
      // The list must still render; one bad row should not take the screen out.
      final tank = TankModel.fromJson(<String, dynamic>{'todays_feed': 5});

      expect(tank.tankName, isNotNull);
    });
  });

  group('TodayFeedEntry.fromJson', () {
    test('keeps the history row id the edit and delete act on', () {
      final e = TodayFeedEntry.fromJson(const {
        'id': 77,
        'meals': 2,
        'feed_quantity': '12.50',
      });

      expect(e.id, 77);
      expect(e.meals, '2');
      expect(e.feedQuantity, '12.50');
    });

    test('normalises numbers and strings to the same shape', () {
      final asNumber = TodayFeedEntry.fromJson(const {
        'id': 1,
        'meals': 3,
        'feed_quantity': 4.5,
      });
      final asString = TodayFeedEntry.fromJson(const {
        'id': 1,
        'meals': '3',
        'feed_quantity': '4.5',
      });

      expect(asNumber.meals, asString.meals);
      expect(asNumber.feedQuantity, asString.feedQuantity);
    });

    test('an entry with no id is a line not yet saved', () {
      final e = TodayFeedEntry.fromJson(const {'meals': 1, 'feed_quantity': '1'});

      expect(e.id, isNull);
    });
  });
}
