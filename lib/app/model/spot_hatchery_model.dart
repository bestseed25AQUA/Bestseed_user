import 'dart:convert';

SpotHatcheryModel hatcheryResponseModelFromJson(String str) =>
    SpotHatcheryModel.fromJson(json.decode(str));

String hatcheryResponseModelToJson(SpotHatcheryModel data) =>
    json.encode(data.toJson());

class SpotHatcheryModel {
  final bool status;
  final List<SpotHatchery> spotHatcheries;

  SpotHatcheryModel({required this.status, required this.spotHatcheries});

  factory SpotHatcheryModel.fromJson(Map<String, dynamic> json) =>
      SpotHatcheryModel(
        status: json["status"] ?? false,
        spotHatcheries: json["spot_hatcheries"] == null
            ? []
            : List<SpotHatchery>.from(
                json["spot_hatcheries"].map((x) => SpotHatchery.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "spot_hatcheries": List<dynamic>.from(
      spotHatcheries.map((x) => x.toJson()),
    ),
  };
}

class SpotHatchery {
  final int hatcheryId;
  final String hatcheryName;
  final int categoryId;
  final int locationId;
  final String categoryName;
  final String? price;
  final String? locationName;
  final String? branchName;
  final int? broodstock;
  final bool isSpot;
  final String? availableOn;
  final String? description;
  final List<String> images;
  final String? callUrl;
  final String? whatsappUrl;
  final int? selectedHatcheryId;
  final SelectedHatchery? selectedHatchery;

  SpotHatchery({
    required this.hatcheryId,
    required this.hatcheryName,
    required this.categoryId,
    required this.locationId,
    required this.categoryName,
    this.price,
    required this.locationName,
    this.branchName,
    this.broodstock,
    required this.isSpot,
    this.availableOn,
    this.description,
    required this.images,
    this.callUrl,
    this.whatsappUrl,
    this.selectedHatcheryId,
    this.selectedHatchery,
  });

  factory SpotHatchery.fromJson(Map<String, dynamic> json) => SpotHatchery(
    hatcheryId: json["hatchery_id"] ?? 0,
    hatcheryName: json["hatchery_name"] ?? "",
    categoryId: json["category_id"] ?? 0,
    locationId: json["location_id"] ?? 0,
    categoryName: json["category_name"] ?? "",
    price: json['price']?.toString(),
    locationName: json["location_name"],
    branchName: json["branch_name"],
    isSpot: json["is_spot"] ?? false,
    availableOn: json["available_on"],
    description: json["description"],
    broodstock: json["broodstock"] is int
            ? json["broodstock"]
            : int.tryParse(json["broodstock"]?.toString() ?? ''),
    images: json["images"] == null
        ? []
        : List<String>.from(json["images"].map((x) => x)),
    callUrl: json["call_url"],
    whatsappUrl: json["whatsapp_url"],
    selectedHatcheryId: json["selected_hatchery_id"],
    selectedHatchery: json["selected_hatchery"] != null
        ? SelectedHatchery.fromJson(json["selected_hatchery"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "hatchery_id": hatcheryId,
    "hatchery_name": hatcheryName,
    "category_id": categoryId,
    "location_id": locationId,
    "category_name": categoryName,
    "price": price,
    "location_name": locationName,
    "branch_name": branchName,
    "is_spot": isSpot,
    "available_on": availableOn,
    "description": description,
    "images": List<dynamic>.from(images.map((x) => x)),
    "call_url": callUrl,
    "whatsapp_url": whatsappUrl,
    "selected_hatchery_id": selectedHatcheryId,
    "selected_hatchery": selectedHatchery?.toJson(),
  };
}

/// Model for selected/parent hatchery data
class SelectedHatchery {
  final int id;
  final String hatcheryName;
  final int? categoryId;
  final String? categoryName;
  final int? locationId;
  final String? locationName;
  final String? description;
  final String? price;
  final int? broodstockCount;
  final String? availableOn;
  final List<String> images;
  final String? callUrl;
  final String? whatsappUrl;

  SelectedHatchery({
    required this.id,
    required this.hatcheryName,
    this.categoryId,
    this.categoryName,
    this.locationId,
    this.locationName,
    this.description,
    this.price,
    this.broodstockCount,
    this.availableOn,
    required this.images,
    this.callUrl,
    this.whatsappUrl,
  });

  factory SelectedHatchery.fromJson(Map<String, dynamic> json) => SelectedHatchery(
    id: json["id"] ?? 0,
    hatcheryName: json["hatchery_name"] ?? "",
    categoryId: json["category_id"],
    categoryName: json["category_name"],
    locationId: json["location_id"],
    locationName: json["location_name"],
    description: json["description"],
    price: json["price"]?.toString(),
    broodstockCount: json["broodstock_count"],
    availableOn: json["available_on"],
    images: json["images"] == null
        ? []
        : List<String>.from(json["images"].map((x) => x)),
    callUrl: json["call_url"],
    whatsappUrl: json["whatsapp_url"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "hatchery_name": hatcheryName,
    "category_id": categoryId,
    "category_name": categoryName,
    "location_id": locationId,
    "location_name": locationName,
    "description": description,
    "price": price,
    "broodstock_count": broodstockCount,
    "available_on": availableOn,
    "images": List<dynamic>.from(images.map((x) => x)),
    "call_url": callUrl,
    "whatsapp_url": whatsappUrl,
  };
}
