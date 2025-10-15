class MyBookingModel {
  final bool status;
  final String message;
  final List<Booking> bookings;

  MyBookingModel({
    required this.status,
    required this.message,
    required this.bookings,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      bookings:
          (json['bookings'] as List<dynamic>?)
              ?.map((e) => Booking.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'bookings': bookings.map((e) => e.toJson()).toList(),
  };
}

class Booking {
  final int bookingId;
  final String hatcheryName;
  final String? categories;
  final String customerName;
  final String customerMobile;
  final int noOfPieces;
  final String? droppingLocation;
  final String packingDate;
  final String deliveryLocation;
  final String mediaType;
  final String? mediaUrl;

  Booking({
    required this.bookingId,
    required this.hatcheryName,
    this.categories,
    required this.customerName,
    required this.customerMobile,
    required this.noOfPieces,
    this.droppingLocation,
    required this.packingDate,
    required this.deliveryLocation,
    required this.mediaType,
    this.mediaUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      categories: json['categories'],
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      noOfPieces: json['no_of_pieces'] ?? 0,
      droppingLocation: json['dropping_location'],
      packingDate: json['packing_date'] ?? '',
      deliveryLocation: json['delivery_location'] ?? '',
      mediaType: json['media_type'] ?? '',
      mediaUrl: json['media_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'hatchery_name': hatcheryName,
    'categories': categories,
    'customer_name': customerName,
    'customer_mobile': customerMobile,
    'no_of_pieces': noOfPieces,
    'dropping_location': droppingLocation,
    'packing_date': packingDate,
    'delivery_location': deliveryLocation,
    'media_type': mediaType,
    'media_url': mediaUrl,
  };
}
