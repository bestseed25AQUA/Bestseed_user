import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';

void main() {
  test('parses a tank whose totals arrive as numbers', () {
    // Verbatim from GET /api/farmer/farms/115/tanks — note total_feed_used is
    // a number here (a computed sum) while feed_quantity is a string (a raw
    // decimal column). Assigning the number to a String field used to throw.
    final tank = TankModel.fromJson({
      "id": 1283,
      "farm_id": 115,
      "tank_name": "Tank1",
      "status": 1,
      "store": 0,
      "total_feed_used": 0,
      "meals": 0,
      "feed_quantity": "0.00",
      "stocking_date": "2026-09-01",
      "batch_id": 1192,
      "batch_no": 1,
      "batch_active": true,
      "feed": null,
      "day": 1,
      "effective_stocking_date": "2026-09-01",
      "todays_meal_count": 2,
      "feed_used_before": 0,
      "fed_days": 0,
      "todays_feed": [],
    });

    expect(tank.tankName, 'Tank1', reason: 'not "Error"');
    expect(tank.status, 1, reason: 'the tank is active');
    expect(tank.totalFeedUsed, '0.00');
    expect(tank.day, 1);
    expect(tank.batchId, 1192);
    expect(tank.batchActive, isTrue);
  });

  test('parses a tank whose totals arrive as decimal strings', () {
    final tank = TankModel.fromJson({
      "id": 1286,
      "tank_name": "Tank4",
      "status": 1,
      "total_feed_used": "1000.00",
      "feed_quantity": "50.5",
      "day": 32,
    });

    expect(tank.tankName, 'Tank4');
    expect(tank.status, 1);
    expect(tank.totalFeedUsed, '1000.00');
    expect(tank.feedQuantity, '50.50');
  });

  test('a genuinely broken payload still degrades rather than crashing', () {
    final tank = TankModel.fromJson({"tank_name": null, "status": null});

    expect(tank.tankName, '');
    expect(tank.status, 0);
  });
}
