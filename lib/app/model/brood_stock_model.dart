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
  final String categoryName;
  final String availableQuantity;
  final String availableOn;
  final String packingStart;
  final String vendorName;
  final String vendorAddress;
  final String latitude;
  final String longitude;
  final String image;
  final String importedDate;
  final List<String> images;

  BroodstockData({
    required this.id,
    required this.hatcheryName,
    required this.supplierName,
    required this.categoryName,
    required this.availableQuantity,
    required this.availableOn,
    required this.packingStart,
    required this.vendorName,
    required this.vendorAddress,
    required this.latitude,
    required this.longitude,
    required this.image,
    required this.importedDate,
    required this.images,
  });

  factory BroodstockData.fromJson(Map<String, dynamic> json) {
    return BroodstockData(
      id: json['id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      categoryName: json['category']?['category_name'] ?? '',
      availableQuantity: json['available_quantity'] ?? '',
      availableOn: json['available_on'] ?? '',
      packingStart: json['packing_start'] ?? '',
      vendorName: json['vendor']?['vendor_name'] ?? '',
      vendorAddress: json['vendor']?['vendor_address'] ?? '',
      latitude: json['vendor']?['latitude'] ?? '',
      longitude: json['vendor']?['longitude'] ?? '',
      image: json['image'] ?? '',
      importedDate: json['imported_date'] ?? '',
      images: List.generate(
        (json['images'] != null && json['images'].runtimeType == List)
            ? json['images'].length
            : 0,
        (index) => json['images'][index].toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hatchery_name': hatcheryName,
    'supplier_name': supplierName,
    'imported_date': importedDate,
    'category': {'category_name': categoryName},
    'available_quantity': availableQuantity,
    'available_on': availableOn,
    'packing_start': packingStart,
    'vendor': {
      'vendor_name': vendorName,
      'vendor_address': vendorAddress,
      'latitude': latitude,
      'longitude': longitude,
    },
    'images': image,
  };
}
