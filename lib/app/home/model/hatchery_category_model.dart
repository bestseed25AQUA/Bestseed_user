import 'dart:convert';

HatcheryDetailsResponse hatcheryDetailsResponseFromJson(String str) {
  return HatcheryDetailsResponse.fromJson(json.decode(str));
}

class HatcheryDetailsResponse {
  final bool status;
  final String message;
  final List<HatcheryData> data;
  final List<SimilarHatchery> similarHatcheries;
  HatcheryDetailsResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.similarHatcheries,
  });

  factory HatcheryDetailsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json["data"];

    return HatcheryDetailsResponse(
      status: json["status"] == true,
      message: json["message"]?.toString() ?? "",
      data: rawData == null
          ? []
          : rawData is List
          ? rawData.map((e) => HatcheryData.fromJson(e)).toList()
          : [HatcheryData.fromJson(rawData)], // wrap single object
      similarHatcheries: json["similar_hatcheries"] is List
          ? (json["similar_hatcheries"] as List)
                .map((e) => SimilarHatchery.fromJson(e))
                .toList()
          : [],
    );
  }
}

class HatcheryData {
  final int id;
  final String hatcheryName;
  final List<String> images;
  final String status;
  final String? availableOn;
  final int isSpot;

  final HatcheryCategory? category;
  final HatcheryItem categories;

  final HatcheryLocation? location;
  final List<UnitModel> units;

  final int broodstock;
  final String price;
  final String callUrl;
  final String whatsappUrl;

  HatcheryData({
    required this.id,
    required this.hatcheryName,
    required this.images,
    required this.status,
    required this.availableOn,
    required this.isSpot,
    required this.category,
    required this.categories,
    required this.location,
    required this.units,
    required this.broodstock,
    required this.price,
    required this.callUrl,
    required this.whatsappUrl,
  });

  factory HatcheryData.fromJson(Map<String, dynamic> json) {
    return HatcheryData(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      hatcheryName: json["hatchery_name"]?.toString() ?? "",
      images: json["images"] is List
          ? List<String>.from(json["images"].map((e) => e?.toString() ?? ""))
          : [],

      status: json["status"]?.toString() ?? "unknown",
      availableOn: json["available_on"]?.toString(),

      isSpot: json["is_spot"] is int
          ? json["is_spot"]
          : int.tryParse("${json["is_spot"]}") ?? 0,

      category: json["category"] != null
          ? HatcheryCategory.fromJson(json["category"])
          : null,

      categories: HatcheryItem.fromJson(json['category']),

      location: json["location"] != null
          ? HatcheryLocation.fromJson(json["location"])
          : null,

      units: json["units"] is List
          ? (json["units"] as List).map((e) => UnitModel.fromJson(e)).toList()
          : [],

      broodstock: json["broodstock"] is int
          ? json["broodstock"]
          : int.tryParse("${json["broodstock"]}") ?? 0,

      price: json["price"]?.toString() ?? "0",

      callUrl: json["call_url"]?.toString() ?? "",
      whatsappUrl: json["whatsapp_url"]?.toString() ?? "",
    );
  }
}

class HatcheryCategory {
  final int id;
  final String name;
  final String description;
  final List<String> gallery;
  final String report;

  HatcheryCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.gallery,
    required this.report,
  });

  factory HatcheryCategory.fromJson(Map<String, dynamic> json) {
    return HatcheryCategory(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      name: json["name"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      gallery: json["gallery"] is List
          ? List<String>.from(json["gallery"].map((e) => e?.toString() ?? ""))
          : [],
      report: json["report"]?.toString() ?? "",
    );
  }
}

class HatcheryItem {
  final int id;
  final String name;

  HatcheryItem({required this.id, required this.name});

  factory HatcheryItem.fromJson(Map<String, dynamic> json) {
    return HatcheryItem(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class HatcheryLocation {
  final int id;
  final String name;

  HatcheryLocation({required this.id, required this.name});

  factory HatcheryLocation.fromJson(Map<String, dynamic> json) {
    return HatcheryLocation(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      name: json["name"]?.toString() ?? "",
    );
  }
}

class UnitModel {
  final int id;
  final String branchName;

  UnitModel({required this.id, required this.branchName});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      branchName: json["branch_name"]?.toString() ?? "",
    );
  }
}

class SimilarHatchery {
  final int id;
  final String hatcheryName;
  final int categoryId;
  final String? location;
  final String status;
  final String? availableOn;
  final String? image;
  final int isSpot;

  SimilarHatchery({
    required this.id,
    required this.hatcheryName,
    required this.categoryId,
    required this.location,
    required this.status,
    required this.availableOn,
    required this.image,
    required this.isSpot,
  });

  factory SimilarHatchery.fromJson(Map<String, dynamic> json) {
    return SimilarHatchery(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      hatcheryName: json["hatchery_name"]?.toString() ?? "",
      categoryId: json["category_id"] is int
          ? json["category_id"]
          : int.tryParse("${json["category_id"]}") ?? 0,
      location: json["location"]?.toString(),
      status: json["status"]?.toString() ?? "",
      availableOn: json["available_on"]?.toString(),
      image: json["image"]?.toString(),
      isSpot: json["is_spot"] is int
          ? json["is_spot"]
          : int.tryParse("${json["is_spot"]}") ?? 0,
    );
  }
}
