// vehicle_booking_detail_model.dart

class VehicleBookingDetailModel {
  final int bookingId;
  final String status;
  final String statusDescription;

  final PickupDrop pickupDetails;
  final PickupDrop dropDetails;
  final int driverId;

  final VehicleDetails vehicleDetails;

  final List<BookingStatusStep> bookingStatus;

  VehicleBookingDetailModel({
    required this.bookingId,
    required this.status,
    required this.statusDescription,
    required this.pickupDetails,
    required this.dropDetails,
    required this.vehicleDetails,
    required this.bookingStatus,
    required this.driverId,
  });

  factory VehicleBookingDetailModel.fromJson(Map<String, dynamic> json) {
    return VehicleBookingDetailModel(
      bookingId: json["booking_id"] ?? 0,
      status: json["status"] ?? "",
      driverId: json["driver_id"] ?? 0,
      statusDescription: json["status_description"] ?? "",
      pickupDetails: PickupDrop.fromJson(json["pickup_details"] ?? {}),
      dropDetails: PickupDrop.fromJson(json["drop_details"] ?? {}),
      vehicleDetails: VehicleDetails.fromJson(json["vehicle_booking_details"] ?? {}),
      bookingStatus: (json["vehicle_booking_status"] as List? ?? [])
          .map((item) => BookingStatusStep.fromJson(item))
          .toList(),
    );
  }
}

class PickupDrop {
  final String location;
  final String date;
  final String time;

  PickupDrop({required this.location, required this.date, required this.time});

  factory PickupDrop.fromJson(Map<String, dynamic> json) {
    return PickupDrop(
      location: json["location"] ?? "",
      date: json["date"] ?? "",
      time: json["time"] ?? "",
    );
  }
}

class VehicleDetails {
  final String hatchery;
  final String brand;
  final String qty;
  final String bookingDate;
  final String bookingTime;

  VehicleDetails({
    required this.hatchery,
    required this.brand,
    required this.qty,
    required this.bookingDate,
    required this.bookingTime,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      hatchery: json["hatchery_name"] ?? "",
      brand: json["brand_type"] ?? "",
      qty: json["seed_qty"] ?? "",
      bookingDate: json["booking_date"] ?? "",
      bookingTime: json["booking_time"] ?? "",
    );
  }
}

class BookingStatusStep {
  final String title;
  final String date;
  final String time;
  final bool completed;

  BookingStatusStep({
    required this.title,
    required this.date,
    required this.time,
    required this.completed
  });

  factory BookingStatusStep.fromJson(Map<String, dynamic> json) {
    return BookingStatusStep(
      title: json["title"] ?? "",
      date: json["date"] ?? "",
      time: json["time"] ?? "",
      completed: json["completed"]??false,
    );
  }
}
