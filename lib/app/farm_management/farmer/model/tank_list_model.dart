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

  TankModel({
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
