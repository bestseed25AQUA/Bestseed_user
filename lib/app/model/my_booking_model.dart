class MyBookingModel {
  final bool status;
  final String message;
  final BookingData? data;

  MyBookingModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BookingData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data?.toJson(),
      };
}

class BookingData {
  final int bookingId;
  final String hatcheryName;
  final String customerName;
  final String customerMobile;
  final String unit;
  final int noOfPieces;
  final String droppingLocation;
  final String packingDate;
  final String hatcheryLocation;
  final String createdAt;

  BookingData({
    required this.bookingId,
    required this.hatcheryName,
    required this.customerName,
    required this.customerMobile,
    required this.unit,
    required this.noOfPieces,
    required this.droppingLocation,
    required this.packingDate,
    required this.hatcheryLocation,
    required this.createdAt,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      bookingId: json['booking_id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      unit: json['unit'] ?? '',
      noOfPieces: json['no_of_pieces'] ?? 0,
      droppingLocation: json['dropping_location'] ?? '',
      packingDate: json['packing_date'] ?? '',
      hatcheryLocation: json['hatchery_location'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'hatchery_name': hatcheryName,
        'customer_name': customerName,
        'customer_mobile': customerMobile,
        'unit': unit,
        'no_of_pieces': noOfPieces,
        'dropping_location': droppingLocation,
        'packing_date': packingDate,
        'hatchery_location': hatcheryLocation,
        'created_at': createdAt,
      };
}
