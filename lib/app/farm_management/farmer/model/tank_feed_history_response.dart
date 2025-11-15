import 'dart:convert';

TankFeedHistoryResponse tankFeedHistoryResponseFromJson(String str) {
  return TankFeedHistoryResponse.fromJson(json.decode(str));
}

class TankFeedHistoryResponse {
  final bool status;
  final String message;
  final List<TankFeedHistory> data;

  TankFeedHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TankFeedHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json["data"];

    return TankFeedHistoryResponse(
      status: json["status"] == true,
      message: json["message"]?.toString() ?? "",
      data: rawData is List
          ? rawData.map((e) => TankFeedHistory.fromJson(e)).toList()
          : [],
    );
  }
}

class TankFeedHistory {
  final int id;
  final int tankId;
  final int farmId;
  final int meals;
  final String feedQuantity;
  final String feedDate;
  final String createdAt;
  final String updatedAt;

  TankFeedHistory({
    required this.id,
    required this.tankId,
    required this.farmId,
    required this.meals,
    required this.feedQuantity,
    required this.feedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TankFeedHistory.fromJson(Map<String, dynamic> json) {
    return TankFeedHistory(
      id: _toInt(json["id"]),
      tankId: _toInt(json["tank_id"]),
      farmId: _toInt(json["farm_id"]),
      meals: _toInt(json["meals"]),
      feedQuantity: json["feed_quantity"]?.toString() ?? "0",
      feedDate: json["feed_date"]?.toString() ?? "",
      createdAt: json["created_at"]?.toString() ?? "",
      updatedAt: json["updated_at"]?.toString() ?? "",
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}
