class VehicleTrackingModel {
  String id;
  String bookingId;
  String time;
  String date;

  String hatcheryName;
  String categoryName;
  String status;

  String pickupLocation;
  String dropLocation;

  String quantity;

  VehicleTrackingModel({
    required this.id,
    required this.bookingId,
    required this.time,
    required this.date,
    required this.hatcheryName,
    required this.categoryName,
    required this.status,
    required this.pickupLocation,
    required this.dropLocation,
    required this.quantity,
  });

  factory VehicleTrackingModel.fromJson(Map<String, dynamic> json) {
    return VehicleTrackingModel(
      id: json['id']?.toString() ?? "",
      bookingId: json['booking_id']?.toString() ?? "",
      time: json['time'] ?? "",
      date: json['date'] ?? "",
      hatcheryName: json['hatchery_name'] ?? "",
      categoryName: json['category_name'] ?? "",
      status: json['status'] ?? "",
      pickupLocation: json['pickup_location'] ?? "",
      dropLocation: json['drop_location'] ?? "",
      quantity: json['quantity'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "booking_id": bookingId,
      "time": time,
      "date": date,
      "hatchery_name": hatcheryName,
      "category_name": categoryName,
      "status": status,
      "pickup_location": pickupLocation,
      "drop_location": dropLocation,
      "quantity": quantity,
    };
  }
}


class VehicleTrackingResponse {
  bool success;
  String message;
  List<VehicleTrackingModel> data;

  VehicleTrackingResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory VehicleTrackingResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTrackingResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] != null
          ? List<VehicleTrackingModel>.from(
              json["data"].map((x) => VehicleTrackingModel.fromJson(x)))
          : [],
    );
  }
}
