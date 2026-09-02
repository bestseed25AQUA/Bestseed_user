import 'dart:convert';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';

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

  /// Feed recorded against this farm so far. Used to decide whether the
  /// "feed already used" backfill field is still applicable.
  num? totalFeedUsed;

  /// The "feed already used" figure the farmer entered, if any. Distinct from
  /// [totalFeedUsed], which also includes feed recorded day by day since.
  num? feedUsedBefore;

  /// What is LEFT of [store] — the stock less the feed actually recorded.
  ///
  /// Null when the farmer has not entered a store figure, which is not the
  /// same as a remainder of zero. Computed server-side so the card, the farm
  /// header and the low-feed warning all quote one number.
  num? remainingStore;
  dynamic activeCount;
  dynamic inactiveCount;

  /// What the logged-in farmer may do with THIS farm.
  ///
  /// The list endpoint returns one of these per farm precisely so the app can
  /// hide what the caller cannot do; it was being dropped on the floor.
  FarmAccess access = const FarmAccess.ownerFallback();

  FarmData({
    this.id,
    this.farmName,
    this.farmerId,
    this.stockingDate,
    this.noOfTanks,
    this.store,
    this.lowFeedLimit,
    this.images,
    this.totalFeedUsed,
    this.feedUsedBefore,
  });

  FarmData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    farmName = json['farm_name'];
    farmerId = json['farmer_id'];
    stockingDate = json['stocking_date'];
    noOfTanks = json['no_of_tanks'];
    totalFeedUsed = num.tryParse('${json['total_feed_used'] ?? 0}') ?? 0;
    feedUsedBefore = json['feed_used_before'] == null
        ? null
        : num.tryParse('${json['feed_used_before']}');
    store = json['store'];
    remainingStore = json['remaining_store'] == null
        ? null
        : num.tryParse('${json['remaining_store']}');
    lowFeedLimit = json['low_feed_limit'];
    activeCount = json['active_tanks'];
    inactiveCount = json['inactive_tanks'];
    images = json['images'] != null
        ? FarmImages.fromJson(json['images'])
        : null;
    access = FarmAccess.fromJson(json['access'] as Map<String, dynamic>?);
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
