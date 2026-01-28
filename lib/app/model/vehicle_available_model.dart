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
  final int hatcheryId;
  final String hatcheryName;
  final int? categoryId;
  final String? categoryName;
  final String? price;
  final int locationId;
  final String? locationName;
  final List<VehicleLocation> locations;
  final bool isVehicle;
  final String? availableOn;
  final String? startTime;
  final String? endTime;
  final int? availableSpace;
  final int? broodstock;
  final List<String> images;
  final String? callUrl;
  final String? whatsappUrl;

  VehicleAvailability({
    required this.hatcheryId,
    required this.hatcheryName,
    this.categoryId,
    this.categoryName,
    this.price,
    required this.locationId,
    this.locationName,
    required this.locations,
    required this.isVehicle,
    this.availableOn,
    this.startTime,
    this.endTime,
    this.availableSpace,
    this.broodstock,
    required this.images,
    this.callUrl,
    this.whatsappUrl,
  });

  factory VehicleAvailability.fromJson(Map<String, dynamic> json) {
    return VehicleAvailability(
      hatcheryId: json['hatchery_id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      price: json['price']?.toString(),
      locationId: json['location_id'] ?? 0,
      locationName: json['location_name'],
      locations: json['locations'] == null
          ? []
          : List<VehicleLocation>.from(
              json['locations'].map((e) => VehicleLocation.fromJson(e)),
            ),
      isVehicle: json['is_vehicle'] ?? false,
      availableOn: json['available_on'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      availableSpace: json['available_space'],
      broodstock: json['broodstock'],
      images: _parseImages(json['images']),
      callUrl: json['call_url'],
      whatsappUrl: json['whatsapp_url'],
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
