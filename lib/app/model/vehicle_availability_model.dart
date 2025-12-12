class VehicleAvailabilityModel {
  bool status;
  List<Vehicle> vehicles;

  VehicleAvailabilityModel({required this.status, required this.vehicles});

  factory VehicleAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return VehicleAvailabilityModel(
      status: json['status'] is bool ? json['status'] : false,
      vehicles: (json['vehicles'] is List)
          ? (json['vehicles'] as List)
                .map((x) => Vehicle.fromJson(x ?? {}))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'vehicles': vehicles.map((e) => e.toJson()).toList(),
    };
  }
}

class Vehicle {
  String vehicleNumber;
  String driverName;
  String driverMobile;
  List<String> vehicleImages;
  String hatcheryName;
  String? hatcheryLocation;
  List<String> vechileLocationTracking;
  DateTime startDate;
  DateTime? endDate;
  int availableSpace;
  String callNow;
  String whatsapp;

  Vehicle({
    required this.vehicleNumber,
    required this.driverName,
    required this.driverMobile,
    required this.vehicleImages,
    required this.hatcheryName,
    this.hatcheryLocation,
    required this.vechileLocationTracking,
    required this.startDate,
    this.endDate,
    required this.availableSpace,
    required this.callNow,
    required this.whatsapp,
  });

  /// ---------- STATIC SAFE HELPERS ----------
  static DateTime? safeDate(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static List<String> safeList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<String> safeVechileLocationTrackingList(dynamic value) {
    try {
      if (value is List) {
        return value
            .map((e) {
              if (e is Map && e.containsKey('location_name')) {
                return e['location_name']?.toString() ?? "";
              }
              return "";
            })
            .where((x) => x.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // ignore errors
    }

    return [];
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleNumber: json['vehicle_number']?.toString() ?? "",
      driverName: json['driver_name']?.toString() ?? "",
      driverMobile: json['driver_mobile']?.toString() ?? "",
      vehicleImages: safeList(json['vehicle_images']),
      hatcheryName: json['hatchery_name']?.toString() ?? "",
      hatcheryLocation: json['hatchery_location']?['location_name'] ?? '',
      vechileLocationTracking: safeVechileLocationTrackingList(
        json['vechile_location_tracking'],
      ),
      startDate: safeDate(json['start_date']) ?? DateTime.now(),
      endDate: safeDate(json['end_date']),
      availableSpace:
          int.tryParse(json['available_space']?.toString() ?? "0") ?? 0,
      callNow: json['call_now']?.toString() ?? "",
      whatsapp: json['whatsapp']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_mobile': driverMobile,
      'vehicle_images': vehicleImages,
      'hatchery_name': hatcheryName,
      'hatchery_location': hatcheryLocation,
      'vechile_location_tracking': vechileLocationTracking,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'available_space': availableSpace,
      'call_now': callNow,
      'whatsapp': whatsapp,
    };
  }
}
