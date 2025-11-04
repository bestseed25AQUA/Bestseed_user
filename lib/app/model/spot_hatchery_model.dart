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
  final String categoryName;
  final String location;
  final String availableOn;
  final List<String> images;
  final String? callUrl;
  final String? whatsappUrl;

  SpotHatchery({
    required this.hatcheryId,
    required this.hatcheryName,
    required this.categoryName,
    required this.location,
    required this.availableOn,
    required this.images,
    this.callUrl,
    this.whatsappUrl,
  });

  factory SpotHatchery.fromJson(Map<String, dynamic> json) => SpotHatchery(
    hatcheryId: json["hatchery_id"] ?? 0,
    hatcheryName: json["hatchery_name"] ?? "",
    categoryName: json["category_name"] ?? "",
    location: json["location"] ?? "",
    availableOn: json["available_on"] ?? "",
    images: json["images"] == null
        ? []
        : List<String>.from(json["images"].map((x) => x)),
    callUrl: json["call_url"],
    whatsappUrl: json["whatsapp_url"],
  );

  Map<String, dynamic> toJson() => {
    "hatchery_id": hatcheryId,
    "hatchery_name": hatcheryName,
    "category_name": categoryName,
    "location": location,
    "available_on": availableOn,
    "images": List<dynamic>.from(images.map((x) => x)),
    "call_url": callUrl,
    "whatsapp_url": whatsappUrl,
  };
}
