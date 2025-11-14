import 'dart:convert';

class FarmListModel {
  bool? status;
  String? message;
  List<FarmData>? data;

  FarmListModel({this.status, this.message, this.data});

  FarmListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <FarmData>[];
      json['data'].forEach((v) {
        data!.add(FarmData.fromJson(v));
      });
    }
  }
}

class FarmData {
  int? id;
  String? farmName;
  int? farmerId;
  String? stockingDate;
  int? noOfTanks;
  String? store;
  String? lowFeedLimit;
  FarmImages? images;
  dynamic activeCount;
  dynamic inactiveCount;

  FarmData({
    this.id,
    this.farmName,
    this.farmerId,
    this.stockingDate,
    this.noOfTanks,
    this.store,
    this.lowFeedLimit,
    this.images,
  });

  FarmData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    farmName = json['farm_name'];
    farmerId = json['farmer_id'];
    stockingDate = json['stocking_date'];
    noOfTanks = json['no_of_tanks'];
    store = json['store'];
    lowFeedLimit = json['low_feed_limit'];
    activeCount = json['active_count'];
    inactiveCount = json['inactive_count'];
    images = json['images'] != null
        ? FarmImages.fromJson(json['images'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "farm_name": farmName,
      "farmer_id": farmerId,
      "stocking_date": stockingDate,
      "no_of_tanks": noOfTanks,
      "store": store,
      "active_count": activeCount,
      "inactive_count": inactiveCount,
      "low_feed_limit": lowFeedLimit,
      "images": images?.toJson(),
    };
  }
}

class FarmImages {
  int? id;
  int? farmId;
  List<String>? imagesList;
  String? createdAt;
  String? updatedAt;

  FarmImages({
    this.id,
    this.farmId,
    this.imagesList,
    this.createdAt,
    this.updatedAt,
  });

  FarmImages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    farmId = json['farm_id'];

    // ✅ FIXED: handle String, List or null safely
    if (json['images'] is String) {
      try {
        imagesList = List<String>.from(jsonDecode(json['images']));
      } catch (e) {
        imagesList = [];
      }
    } else if (json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    } else {
      imagesList = [];
    }

    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "farm_id": farmId,
      "images": jsonEncode(imagesList ?? []),
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }
}
