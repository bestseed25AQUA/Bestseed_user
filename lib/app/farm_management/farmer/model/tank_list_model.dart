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

  TankModel({
    this.todaysFeed = const [],
    this.todaysMeals = 0,
    this.todaysQuantity = 0,
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

  factory TankModel.fromJson(Map<String, dynamic> json) {
    try {
      return TankModel(
        id: json["id"] ?? 0,
        farmId: json["farm_id"] ?? 0,
        tankName: json["tank_name"] ?? "",
        status: json["status"] ?? 0,
        store: json["store"] ?? 0,
        totalFeedUsed: json["total_feed_used"] ?? "0.00",
        meals: json["meals"] ?? 0,
        feedQuantity: json["feed_quantity"] ?? "0.00",
        stockingDate: json["stocking_date"] ?? "",
        createdAt: json["created_at"] ?? "",
        updatedAt: json["updated_at"] ?? "",
        day: json["day"] ?? 0,
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
      );
    } catch (e) {
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
