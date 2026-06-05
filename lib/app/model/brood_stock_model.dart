import 'package:flutter/foundation.dart' show debugPrint;

enum BroodstockStatus {
  available,
  comingSoon,
  upcoming,
  shortlyAvailable,
  closed,
  unknown,
}

class BroodstockModel {
  final bool status;
  final String message;
  final List<BroodstockData> data;

  BroodstockModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BroodstockModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<BroodstockData> parsed = [];

    if (rawData is List) {
      for (int i = 0; i < rawData.length; i++) {
        try {
          if (rawData[i] is Map<String, dynamic>) {
            parsed.add(BroodstockData.fromJson(rawData[i]));
          } else {
            debugPrint('🦐 [BROOD MODEL] item[$i] is not a Map: ${rawData[i].runtimeType}');
          }
        } catch (e) {
          debugPrint('🦐 [BROOD MODEL] ❌ Failed to parse item[$i]: $e');
          debugPrint('🦐 [BROOD MODEL] Raw item[$i]: ${rawData[i]}');
        }
      }
    } else {
      debugPrint('🦐 [BROOD MODEL] data is not a List: ${rawData.runtimeType}');
    }

    return BroodstockModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: parsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

class BroodstockData {
  final int id;
  final int hatcheryId;
  final String hatcheryName;
  final String supplierName;
  final String categoryName;
  final String description;
  final String availableQuantity;
  final String availableOn;
  final String packingStart;
  final String vendorName;
  final String vendorAddress;
  final String latitude;
  final String longitude;
  final String locationName;
  final String image;
  final String importedDate;
  final List<String> images;
  final BroodstockStatus status;

  BroodstockData({
    required this.id,
    required this.hatcheryId,
    required this.hatcheryName,
    required this.supplierName,
    required this.categoryName,
    required this.description,
    required this.availableQuantity,
    required this.availableOn,
    required this.packingStart,
    required this.vendorName,
    required this.vendorAddress,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.image,
    required this.importedDate,
    required this.images,
    required this.status,
  });

  factory BroodstockData.fromJson(Map<String, dynamic> json) {
    // Safely extract nested objects — API may send String, Map, null, or int
    final rawLocation = json['location'];
    final rawVendor = json['vendor'];
    final rawCategory = json['category'];

    final location = rawLocation is Map<String, dynamic> ? rawLocation : <String, dynamic>{};
    final vendor = rawVendor is Map<String, dynamic> ? rawVendor : <String, dynamic>{};

    // category can be a Map like {"category_name":"Tiger"} or a String like "Tiger"
    String categoryName = '';
    if (rawCategory is Map) {
      categoryName = rawCategory['category_name']?.toString() ?? '';
    } else if (rawCategory is String) {
      categoryName = rawCategory;
    }
    // Fallback to top-level category_name if nested is empty
    if (categoryName.isEmpty) {
      categoryName = json['category_name']?.toString() ?? '';
    }

    // Parse images — could be List<String>, List<dynamic>, null, or even a single String
    final rawImages = json['images'];
    List<String> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      imagesList = [rawImages];
    }

    // id/hatcheryId — could be int, String, or null
    int safeInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return BroodstockData(
      id: safeInt(json['id']),
      hatcheryId: safeInt(json['hatchery_id']),
      hatcheryName: json['hatchery_name']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? '',
      categoryName: categoryName,
      description: json['description']?.toString() ?? '',
      availableQuantity: json['available_quantity']?.toString() ?? '',
      availableOn: json['available_on']?.toString() ?? '',
      packingStart: json['packing_start']?.toString() ?? '',
      vendorName: vendor['vendor_name']?.toString() ?? json['vendor_name']?.toString() ?? '',
      vendorAddress: vendor['vendor_address']?.toString() ?? json['vendor_address']?.toString() ?? '',
      latitude: (location['latitude'] ?? vendor['latitude'] ?? '').toString(),
      longitude: (location['longitude'] ?? vendor['longitude'] ?? '').toString(),
      locationName: location['location_name']?.toString() ?? json['location_name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      importedDate: json['imported_date']?.toString() ?? '',
      images: imagesList,
      status: broodstockStatusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hatchery_id': hatcheryId,
    'hatchery_name': hatcheryName,
    'supplier_name': supplierName,
    'description': description,
    'imported_date': importedDate,
    'category': {'category_name': categoryName},
    'available_quantity': availableQuantity,
    'available_on': availableOn,
    'packing_start': packingStart,
    'vendor': {
      'vendor_name': vendorName,
      'vendor_address': vendorAddress,
    },
    'location': {
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    },
    'image': image,
    'images': images,
  };
}

BroodstockStatus broodstockStatusFromString(dynamic value) {
  final str = value?.toString().toLowerCase().trim() ?? '';
  switch (str) {
    case '1':
    case 'available':
      return BroodstockStatus.available;
    case '2':
    case 'coming_soon':
    case 'coming soon':
      return BroodstockStatus.comingSoon;
    case '3':
    case 'upcoming':
      return BroodstockStatus.upcoming;
    case '4':
    case 'shortly_available':
    case 'shortly available':
      return BroodstockStatus.shortlyAvailable;
    case '5':
    case 'closed':
      return BroodstockStatus.closed;
    default:
      if (str.isNotEmpty) {
        debugPrint('🦐 [BROOD MODEL] Unknown status value: "$str"');
      }
      return BroodstockStatus.unknown;
  }
}
