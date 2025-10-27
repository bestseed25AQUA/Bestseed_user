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
  final String hatcheryName;
  final String supplierName;
  final List<String> category;
  final String availableQuantity;
  final String availableOn;
  final String packingStart;
  final String location;
  final String latitude;
  final String longitude;
  final List<String> images;

  BroodstockData({
    required this.id,
    required this.hatcheryName,
    required this.supplierName,
    required this.category,
    required this.availableQuantity,
    required this.availableOn,
    required this.packingStart,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.images,
  });

  factory BroodstockData.fromJson(Map<String, dynamic> json) {
    return BroodstockData(
      id: json['id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      category:
          (json['category'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availableQuantity: json['available_quantity'] ?? '',
      availableOn: json['available_on'] ?? '',
      packingStart: json['packing_start'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hatchery_name': hatcheryName,
    'supplier_name': supplierName,
    'category': category,
    'available_quantity': availableQuantity,
    'available_on': availableOn,
    'packing_start': packingStart,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'images': images,
  };
}
