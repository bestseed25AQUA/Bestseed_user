import 'package:seedsuser/app/utils/network_config.dart';

class HatcheryFilterResponse {
  final bool status;
  final String message;
  final MetaData meta;
  final List<HatcheryFilterItem> data;

  HatcheryFilterResponse({
    required this.status,
    required this.message,
    required this.meta,
    required this.data,
  });

  factory HatcheryFilterResponse.fromJson(Map<String, dynamic> json) {
    try {
      return HatcheryFilterResponse(
        status: json['status'] ?? false,
        message: json['message'] ?? "",
        meta: MetaData.fromJson(json['meta'] ?? {}),
        data: (json['data'] as List<dynamic>? ?? [])
            .map((e) => HatcheryFilterItem.fromJson(e ?? {}))
            .toList());
    } catch (e) {
      print("❌ HatcheryFilterResponse Error: $e");
      return HatcheryFilterResponse(
        status: false,
        message: "",
        meta: MetaData.fromJson({}),
        data: [],
      );
    }
  }
}

class MetaData {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  MetaData({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    try {
      return MetaData(
        total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? "0") ?? 0,
        perPage: json['per_page'] is int ? json['per_page'] : int.tryParse(json['per_page']?.toString() ?? "0") ?? 0,
        currentPage: json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? "0") ?? 0,
        lastPage: json['last_page'] is int ? json['last_page'] : int.tryParse(json['last_page']?.toString() ?? "0") ?? 0,
      );
    } catch (e) {
      print("❌ MetaData Error: $e");
      return MetaData(total: 0, perPage: 0, currentPage: 0, lastPage: 0);
    }
  }
}

class HatcheryFilterItem {
  final int id;
  final String hatcheryName;
  final int brandId;
  final String brand;
  final int categoryId;
  final String category;
  final int locationId;
  final String location;
  final String status;
  final String availableOn;
  final String image;
  final String lat;
  final String lng;
  final int isSpot;
  final String openingTime;
  final String closingTime;
  final double? distanceKm;

  HatcheryFilterItem({
    required this.id,
    required this.hatcheryName,
    required this.brandId,
    required this.brand,
    required this.categoryId,
    required this.category,
    required this.locationId,
    required this.location,
    required this.status,
    required this.availableOn,
    required this.image,
    required this.lat,
    required this.lng,
    required this.isSpot,
    required this.openingTime,
    required this.closingTime,
    required this.distanceKm,
  });

  factory HatcheryFilterItem.fromJson(Map<String, dynamic> json) {
    try {
      final rawImage = json['image']?.toString() ?? "";
      final resolvedImage = rawImage.isEmpty
          ? ""
          : (rawImage.startsWith('http')
                ? rawImage
                : '${NetworkConfig.imageURL}/$rawImage');

      return HatcheryFilterItem(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? "0") ?? 0,
        hatcheryName: json['hatchery_name']?.toString() ?? "",
        brandId: json['brand_id'] is int ? json['brand_id'] : int.tryParse(json['brand_id']?.toString() ?? "0") ?? 0,
        brand: json['brand']?.toString() ?? "",
        categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? "0") ?? 0,
        category: json['category']?.toString() ?? "",
        locationId: json['location_id'] is int ? json['location_id'] : int.tryParse(json['location_id']?.toString() ?? "0") ?? 0,
        location: json['location']?.toString() ?? "",
        status: json['status']?.toString() ?? "",
        availableOn: json['available_on']?.toString() ?? "",
        image: resolvedImage,
        lat: json['lat']?.toString() ?? "",
        lng: json['lng']?.toString() ?? "",
        isSpot: json['is_spot'] is int ? json['is_spot'] : int.tryParse(json['is_spot']?.toString() ?? "0") ?? 0,
        openingTime: json['opening_time']?.toString() ?? "",
        closingTime: json['closing_time']?.toString() ?? "",
        distanceKm: json['distance_km'] == null
            ? null
            : double.tryParse(json['distance_km'].toString()),
      );
    } catch (e) {
      print("❌ HatcheryFilterItem Error: $e");
      return HatcheryFilterItem(
        id: 0,
        hatcheryName: "",
        brandId: 0,
        brand: "",
        categoryId: 0,
        category: "",
        locationId: 0,
        location: "",
        status: "",
        availableOn: "",
        image: "",
        lat: "",
        lng: "",
        isSpot: 0,
        openingTime: "",
        closingTime: "",
        distanceKm: null,
      );
    }
  }
}
