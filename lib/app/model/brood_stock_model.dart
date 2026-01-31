enum BroodstockStatus {
  available,
  upcoming,
  closed,
  shortlyAvailable,
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
    return BroodstockModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => BroodstockData.fromJson(item))
              .toList() ??
          [],
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
    // Safely extract location and vendor as Map
    final location = json['location'] is Map ? json['location'] as Map : null;
    final vendor = json['vendor'] is Map ? json['vendor'] as Map : null;
    final category = json['category'] is Map ? json['category'] as Map : null;

    return BroodstockData(
      id: json['id'] ?? 0,
      hatcheryId: json['hatchery_id'] ?? 0,
      hatcheryName: json['hatchery_name']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? '',
      categoryName: category?['category_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      availableQuantity: json['available_quantity']?.toString() ?? '',
      availableOn: json['available_on']?.toString() ?? '',
      packingStart: json['packing_start']?.toString() ?? '',
      vendorName: vendor?['vendor_name']?.toString() ?? '',
      vendorAddress: vendor?['vendor_address']?.toString() ?? '',
      latitude: (location?['latitude'] ?? vendor?['latitude'] ?? '').toString(),
      longitude: (location?['longitude'] ?? vendor?['longitude'] ?? '').toString(),
      locationName: location?['location_name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      importedDate: json['imported_date']?.toString() ?? '',
      images: List.generate(
        (json['images'] != null && json['images'] is List)
            ? (json['images'] as List).length
            : 0,
        (index) => json['images'][index].toString(),
      ),
      status: broodstockStatusFromString(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hatchery_id': hatcheryId,
    'hatchery_name': hatcheryName,
    'supplier_name': supplierName,
    'description' : description,
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
    'images': image,
  };
}

BroodstockStatus broodstockStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'available':
      return BroodstockStatus.available;
    case 'upcoming':
      return BroodstockStatus.upcoming;
    case 'closed':
      return BroodstockStatus.closed;
    case 'shortly_available':
      return BroodstockStatus.shortlyAvailable;
    default:
      return BroodstockStatus.unknown;
  }
}

