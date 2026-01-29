class VehicleAvailabilityResponse {
  final bool status;
  final List<VehicleAvailability> vehicleAvailability;

  VehicleAvailabilityResponse({
    required this.status,
    required this.vehicleAvailability,
  });

  factory VehicleAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return VehicleAvailabilityResponse(
      status: json['status'] ?? false,
      vehicleAvailability: json['vehicle_availability'] == null
          ? []
          : List<VehicleAvailability>.from(
              json['vehicle_availability']
                  .map((e) => VehicleAvailability.fromJson(e)),
            ),
    );
  }
}


class VehicleAvailability {
  final int vehicleId;
  final String vehicleName;
  final int? categoryId;
  final String? categoryName;
  final String? price;
  final String? description;
  final int? locationId;
  final String? locationName;
  final List<VehicleLocation> locations;
  final bool isVehicle;
  final String? availableOn;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final int? availableSpace;
  final List<String> images;
  final String? callUrl;
  final String? whatsappUrl;
  final int? selectedHatcheryId;
  final SelectedVehicleHatchery? selectedHatchery;

  // Backwards compatibility getters
  int get hatcheryId => vehicleId;
  String get hatcheryName => vehicleName;

  VehicleAvailability({
    required this.vehicleId,
    required this.vehicleName,
    this.categoryId,
    this.categoryName,
    this.price,
    this.description,
    this.locationId,
    this.locationName,
    required this.locations,
    required this.isVehicle,
    this.availableOn,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.availableSpace,
    required this.images,
    this.callUrl,
    this.whatsappUrl,
    this.selectedHatcheryId,
    this.selectedHatchery,
  });

  factory VehicleAvailability.fromJson(Map<String, dynamic> json) {
    return VehicleAvailability(
      vehicleId: json['vehicle_id'] ?? json['hatchery_id'] ?? 0,
      vehicleName: json['vehicle_name'] ?? json['hatchery_name'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      price: json['price']?.toString(),
      description: json['description'],
      locationId: json['location_id'],
      locationName: json['location_name'],
      locations: json['locations'] == null
          ? []
          : List<VehicleLocation>.from(
              json['locations'].map((e) => VehicleLocation.fromJson(e)),
            ),
      isVehicle: json['is_vehicle'] ?? false,
      availableOn: json['available_on'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      availableSpace: json['available_space'],
      images: _parseImages(json['images']),
      callUrl: json['call_url'],
      whatsappUrl: json['whatsapp_url'],
      selectedHatcheryId: json['selected_hatchery_id'],
      selectedHatchery: json['selected_hatchery'] != null
          ? SelectedVehicleHatchery.fromJson(json['selected_hatchery'])
          : null,
    );
  }

  /// Strict image validation (prevents NetworkImage errors)
  static List<String> _parseImages(dynamic imagesJson) {
    if (imagesJson == null) return [];

    return List<String>.from(imagesJson)
        .map((e) => e.toString())
        .where((url) {
          final uri = Uri.tryParse(url);
          return uri != null &&
              uri.hasScheme &&
              uri.host.isNotEmpty;
        })
        .toList();
  }
}

/// Model for selected/parent hatchery data
class SelectedVehicleHatchery {
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

  SelectedVehicleHatchery({
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

  factory SelectedVehicleHatchery.fromJson(Map<String, dynamic> json) {
    return SelectedVehicleHatchery(
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
  }
}

class VehicleLocation {
  final int id;
  final String name;

  VehicleLocation({
    required this.id,
    required this.name,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> json) {
    return VehicleLocation(
      id: json['location_id'] ?? 0,
      name: json['location_name'] ?? '',
    );
  }
}
