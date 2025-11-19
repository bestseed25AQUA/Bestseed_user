class VehicleTrackingModel {
  String hatcheryName;
  String categoryName;
  List<String> images;

  Customer customer;
  BookingDetails bookingDetails;
  DriverDetails driverDetails;

  String smsTo;

  VehicleTrackingModel({
    required this.hatcheryName,
    required this.categoryName,
    required this.images,
    required this.customer,
    required this.bookingDetails,
    required this.driverDetails,
    required this.smsTo,
  });

  factory VehicleTrackingModel.fromJson(Map<String, dynamic> json) {
    return VehicleTrackingModel(
      hatcheryName: json['hatchery_name'] ?? "",
      categoryName: json['category_name'] ?? "",
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],

      customer: Customer.fromJson(json['customer'] ?? {}),
      bookingDetails: BookingDetails.fromJson(json['booking_details'] ?? {}),
      driverDetails: DriverDetails.fromJson(json['driver_details'] ?? {}),

      smsTo: json['sms_to'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "hatchery_name": hatcheryName,
      "category_name": categoryName,
      "images": images,
      "customer": customer.toJson(),
      "booking_details": bookingDetails.toJson(),
      "driver_details": driverDetails.toJson(),
      "sms_to": smsTo,
    };
  }
}


class Customer {
  String name;
  String mobile;

  Customer({required this.name, required this.mobile});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? "",
      mobile: json['mobile'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "mobile": mobile,
    };
  }
}

class BookingDetails {
  int id;
  String pieces;
  String unitName;
  String availableDate;

  BookingDetails({
    required this.id,
    required this.pieces,
    required this.unitName,
    required this.availableDate,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      id: json['id'] ?? 0,
      pieces: json['pieces'] ?? "",
      unitName: json['unit_name'] ?? "",
      availableDate: json['available_date'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "pieces": pieces,
      "unit_name": unitName,
      "available_date": availableDate,
    };
  }
}
class DriverDetails {
  String driverName;
  String driverMobile;
  String vehicleNumber;

  DriverDetails({
    required this.driverName,
    required this.driverMobile,
    required this.vehicleNumber,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      driverName: json['driver_name'] ?? "",
      driverMobile: json['driver_mobile'] ?? "",
      vehicleNumber: json['vehicle_number'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "driver_name": driverName,
      "driver_mobile": driverMobile,
      "vehicle_number": vehicleNumber,
    };
  }
}
