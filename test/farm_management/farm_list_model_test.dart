import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';

/// Parsing `GET /api/farmer/farm-lists`.
///
/// Every figure on a farm card comes from here, and the columns are a mix of
/// numbers and decimal strings depending on whether the server computed them or
/// read them from a column — so the parsing has to take both.
void main() {
  /// Verbatim shape of one farm from the endpoint.
  Map<String, dynamic> farmJson() =>
      jsonDecode(jsonEncode({
        "id": 59,
        "farm_name": "Testing",
        "farmer_id": 44,
        "status": 1,
        "stocking_date": "2026-08-01",
        "no_of_tanks": 4,
        "store": "10000",
        "total_feed_used": "1020.00",
        "remaining_store": 9980,
        "low_feed_limit": "50",
        "feed_used_before": "1000.00",
        "created_at": "2026-09-02T05:52:17.000000Z",
        "active_tanks": 4,
        "inactive_tanks": 0,
        "access": {
          "role": "owner",
          "is_owner": true,
          "permissions": {
            "view": true,
            "edit": true,
            "tank_status": true,
            "total_feed": true,
            "create": true,
            "delete": true,
          },
        },
      })) as Map<String, dynamic>;

  group('FarmData.fromJson', () {
    test('reads the farm a card is built from', () {
      final farm = FarmData.fromJson(farmJson());

      expect(farm.id, 59);
      expect(farm.farmName, 'Testing');
      expect(farm.noOfTanks, 4);
      expect(farm.store, '10000');
      expect(farm.stockingDate, '2026-08-01');
      expect(farm.activeCount, 4);
      expect(farm.inactiveCount, 0);
    });

    test('takes a decimal string for the running total', () {
      final farm = FarmData.fromJson(farmJson());

      expect(farm.totalFeedUsed, 1020);
      expect(farm.feedUsedBefore, 1000);
    });

    test('reads what is LEFT of the store, separately from the store', () {
      // The two differ by the feed recorded: 10000 put in, 20 recorded, 9980
      // left. The card shows the remainder; the raw column never moves.
      final farm = FarmData.fromJson(farmJson());

      expect(farm.store, '10000');
      expect(farm.remainingStore, 9980);
    });

    test('a missing remainder is null, not zero', () {
      // Null means "no stock figure entered", which is not a store of nothing —
      // treating it as 0 would report the farm as overdrawn.
      final json = farmJson()..remove('remaining_store');

      expect(FarmData.fromJson(json).remainingStore, isNull);
    });

    test('carries the access block through instead of dropping it', () {
      final farm = FarmData.fromJson(farmJson());

      expect(farm.access.isOwner, isTrue);
      expect(farm.access.canDelete, isTrue);
    });

    test('a farm with no feed recorded reads as zero, not null', () {
      final json = farmJson()..['total_feed_used'] = null;

      expect(FarmData.fromJson(json).totalFeedUsed, 0);
    });

    test('survives a farm whose optional columns are all null', () {
      // Store and the low-feed limit are both nullable, and a farm can be
      // created without either.
      final json = farmJson()
        ..['store'] = null
        ..['low_feed_limit'] = null
        ..['remaining_store'] = null
        ..['feed_used_before'] = null;

      final farm = FarmData.fromJson(json);

      expect(farm.store, isNull);
      expect(farm.lowFeedLimit, isNull);
      expect(farm.remainingStore, isNull);
      expect(farm.feedUsedBefore, isNull);
    });
  });

  group('FarmListModel', () {
    test('reads the whole envelope', () {
      final body = jsonDecode(jsonEncode({
        "status": true,
        "message": "Farm list fetched successfully",
        "data": [farmJson()],
      })) as Map<String, dynamic>;

      final model = FarmListModel.fromJson(body);

      expect(model.status, isTrue);
      expect(model.data, hasLength(1));
      expect(model.data!.first.farmName, 'Testing');
    });

    test('an empty list is empty, not null', () {
      final body = jsonDecode(jsonEncode({
        "status": true,
        "message": "Farm list fetched successfully",
        "data": [],
      })) as Map<String, dynamic>;

      expect(FarmListModel.fromJson(body).data, isEmpty);
    });
  });
}
