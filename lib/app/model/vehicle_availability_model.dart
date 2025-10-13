class VehicleAvailabilityModel {
  bool status;
  List<Vehicle> vehicles;

  VehicleAvailabilityModel({required this.status, required this.vehicles});

  factory VehicleAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return VehicleAvailabilityModel(
      status: json['status'] ?? false,
      vehicles: json['vehicles'] != null
          ? List<Vehicle>.from(json['vehicles'].map((x) => Vehicle.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'vehicles': vehicles.map((x) => x.toJson()).toList(),
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

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    DateTime? safeParseDate(String? date) {
      if (date == null || date.isEmpty) return null;
      try {
        return DateTime.parse(date);
      } catch (_) {
        return null;
      }
    }

    return Vehicle(
      vehicleNumber: json['vehicle_number'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverMobile: json['driver_mobile'] ?? '',
      vehicleImages: json['vehicle_images'] != null
          ? List<String>.from(json['vehicle_images'])
          : [],
      hatcheryName: json['hatchery_name'] ?? '',
      hatcheryLocation: json['hatchery_location'],
      vechileLocationTracking: json['vechile_location_tracking'] != null
          ? List<String>.from(json['vechile_location_tracking'])
          : [],
      startDate: safeParseDate(json['start_date']) ?? DateTime.now(),
      endDate: safeParseDate(json['end_date']),
      availableSpace: json['available_space'] ?? 0,
      callNow: json['call_now'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
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
