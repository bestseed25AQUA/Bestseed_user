import 'package:flutter/foundation.dart';

class TankListModel {
  bool? status;
  String? message;
  List<TankModel>? data;

  TankListModel({this.status, this.message, this.data});

  factory TankListModel.fromJson(Map<String, dynamic> json) {
    try {
      return TankListModel(
        status: json["status"] ?? false,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? List<TankModel>.from(
                json["data"].map((x) => TankModel.fromJson(x)),
              )
            : [],
      );
    } catch (e) {
      return TankListModel(
        status: false,
        message: "Parsing Error: $e",
        data: [],
      );
    }
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.map((x) => x.toJson()).toList() ?? [],
  };
}

class TankModel {
  int? id;
  int? farmId;
  String? tankName;
  int? status;
  int? store;
  String? totalFeedUsed;
  int? meals;
  String? feedQuantity;
  String? stockingDate;
  String? createdAt;
  String? updatedAt;
  FeedModel? feed;
  int? day;

  /// Every entry recorded against this tank TODAY, oldest first.
  ///
  /// Feed is given several times a day. [feed] is a single row — and the tank's
  /// most recent of any date at that — so it can neither show what was fed
  /// today nor hold more than one meal.
  List<TodayFeedEntry> todaysFeed;

  /// Today's totals, summed server-side so every screen agrees.
  num todaysMeals;
  num todaysQuantity;

  /// The date this tank's stock went in — its own, or the farm's for tanks
  /// created before dates were kept per tank. Already resolved server-side.
  String? effectiveStockingDate;

  /// How many meals today calls for, by the schedule in [mealsForDay].
  /// Sent by the server so the boxes drawn match the rows behind them.
  int todaysMealCount;

  /// The "already used" figure this tank was set up with, read back from the
  /// history it generated. The edit form shows it so it can be corrected.
  num feedUsedBefore;

  // ── The crop cycle this tank is on ────────────────────────────────────
  //
  // A tank is stocked, fed for weeks, harvested, and stocked again. Everything
  // above — the total, the day count, today's meals — belongs to the CURRENT
  // batch, so a second crop starts from nothing instead of piling onto the
  // first.

  int? batchId;

  /// 1, 2, 3 … per tank. What the farmer calls the cycle.
  int? batchNo;

  /// False once the tank has been made inactive: the crop is finished, the
  /// screen goes read-only, and the report is still there to download.
  bool batchActive;

  TankModel({
    this.todaysFeed = const [],
    this.todaysMeals = 0,
    this.todaysQuantity = 0,
    this.effectiveStockingDate,
    this.todaysMealCount = 0,
    this.feedUsedBefore = 0,
    this.batchId,
    this.batchNo,
    this.batchActive = true,
    this.id,
    this.farmId,
    this.tankName,
    this.status,
    this.store,
    this.totalFeedUsed,
    this.meals,
    this.feedQuantity,
    this.stockingDate,
    this.createdAt,
    this.updatedAt,
    this.feed,
    this.day,
  });

  /// A decimal that may arrive as a string or a number.
  ///
  /// The server sends a raw decimal column as `"0.00"` but a computed sum as
  /// `0` — and assigning that number to a String field threw, which the catch
  /// below turned into a tank called "Error" with no status. Both forms are
  /// legitimate; the model has to take either.
  static String _decimal(dynamic value, [String fallback = "0.00"]) {
    if (value == null) return fallback;
    if (value is num) return value.toStringAsFixed(2);

    final parsed = num.tryParse('$value');
    return parsed != null ? parsed.toStringAsFixed(2) : '$value';
  }

  /// A whole number that may arrive as a string, a number, or a decimal.
  static int _whole(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();

    return num.tryParse('$value')?.round() ?? fallback;
  }

  factory TankModel.fromJson(Map<String, dynamic> json) {
    try {
      return TankModel(
        id: _whole(json["id"]),
        farmId: _whole(json["farm_id"]),
        tankName: json["tank_name"]?.toString() ?? "",
        status: _whole(json["status"]),
        store: _whole(json["store"]),
        totalFeedUsed: _decimal(json["total_feed_used"]),
        meals: _whole(json["meals"]),
        feedQuantity: _decimal(json["feed_quantity"]),
        stockingDate: json["stocking_date"]?.toString() ?? "",
        createdAt: json["created_at"]?.toString() ?? "",
        updatedAt: json["updated_at"]?.toString() ?? "",
        day: _whole(json["day"]),
        feed: json["feed"] != null ? FeedModel.fromJson(json["feed"]) : null,
        todaysFeed: json["todays_feed"] is List
            ? List<TodayFeedEntry>.from(
                (json["todays_feed"] as List).map(
                  (e) => TodayFeedEntry.fromJson(e as Map<String, dynamic>),
                ),
              )
            : const [],
        todaysMeals: num.tryParse('${json["todays_meals"] ?? 0}') ?? 0,
        todaysQuantity: num.tryParse('${json["todays_quantity"] ?? 0}') ?? 0,
        effectiveStockingDate:
            json["effective_stocking_date"]?.toString() ??
            json["stocking_date"]?.toString(),
        todaysMealCount: int.tryParse('${json["todays_meal_count"] ?? 0}') ?? 0,
        feedUsedBefore: num.tryParse('${json["feed_used_before"] ?? 0}') ?? 0,
        batchId: int.tryParse('${json["batch_id"]}'),
        batchNo: int.tryParse('${json["batch_no"]}'),
        // Defaults to true so a response from a server without batches leaves
        // the screen editable rather than silently locking every tank.
        batchActive: json["batch_active"] == null
            ? true
            : json["batch_active"] == true,
      );
    } catch (e, stack) {
      // Never silently: a shape change in the payload showed up as a tank
      // named "Error" with no status, and nothing said why.
      debugPrint('TankModel.fromJson failed for $json');
      debugPrint('$e\n$stack');
      return TankModel(id: 0, tankName: "Error");
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "farm_id": farmId,
    "tank_name": tankName,
    "status": status,
    "store": store,
    "total_feed_used": totalFeedUsed,
    "meals": meals,
    "feed_quantity": feedQuantity,
    "stocking_date": stockingDate,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "feed": feed?.toJson(),
    "day": day,
  };
}

class FeedModel {
  int? id;
  String? meals;
  int? tankId;
  int? farmId;
  String? feedQuantity;
  String? feedDate;
  String? createdAt;
  String? updatedAt;

  FeedModel({
    this.id,
    this.meals,
    this.tankId,
    this.farmId,
    this.feedQuantity,
    this.feedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    try {
      return FeedModel(
        id: json["id"] ?? 0,
        meals: json["meals"] ?? "0",
        tankId: json["tank_id"] ?? 0,
        farmId: json["farm_id"] ?? 0,
        feedQuantity: json["feed_quantity"] ?? "0.00",
        feedDate: json["feed_date"] ?? "",
        createdAt: json["created_at"] ?? "",
        updatedAt: json["updated_at"] ?? "",
      );
    } catch (e) {
      return FeedModel();
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "meals": meals,
    "tank_id": tankId,
    "farm_id": farmId,
    "feed_quantity": feedQuantity,
    "feed_date": feedDate,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}

/// One feed entry recorded today.
///
/// [id] is the `tank_feed_histories` row id — the same handle the tank history
/// screen edits and deletes by, so the two screens act on the same records
/// rather than each keeping its own idea of the day.
class TodayFeedEntry {
  final int? id;
  final String meals;
  final String feedQuantity;

  const TodayFeedEntry({
    this.id,
    required this.meals,
    required this.feedQuantity,
  });

  factory TodayFeedEntry.fromJson(Map<String, dynamic> json) {
    return TodayFeedEntry(
      id: int.tryParse('${json["id"]}'),
      meals: '${json["meals"] ?? 0}',
      feedQuantity: '${json["feed_quantity"] ?? 0}',
    );
  }
}
