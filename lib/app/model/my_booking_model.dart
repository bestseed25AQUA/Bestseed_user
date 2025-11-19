class MyBookingModel {
  final bool status;
  final String message;
  final List<BookingData> bookings;

  MyBookingModel({
    required this.status,
    required this.message,
    required this.bookings,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    return MyBookingModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      bookings: json['bookings'] != null
          ? (json['bookings'] as List)
              .map((e) => BookingData.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'bookings': bookings.map((e) => e.toJson()).toList(),
      };
}

// ----------------------------------------------------------------------

class BookingData {
  final int bookingId;
  final String hatcheryName;
  final List<CategoryModel> categories;
  final String customerName;
  final String customerMobile;
  final int noOfPieces;
  final String droppingLocation;
  final String packingDate;
  final String? deliveryLocation;
  final String mediaType;
  final List<String> images;

  BookingData({
    required this.bookingId,
    required this.hatcheryName,
    required this.categories,
    required this.customerName,
    required this.customerMobile,
    required this.noOfPieces,
    required this.droppingLocation,
    required this.packingDate,
    this.deliveryLocation,
    required this.mediaType,
    required this.images,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      bookingId: json['booking_id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList()
          : [],
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      noOfPieces: json['no_of_pieces'] ?? 0,
      droppingLocation: json['dropping_location'] ?? '',
      packingDate: json['packing_date'] ?? '',
      deliveryLocation: json['delivery_location'],
      mediaType: json['media_type'] ?? '',
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'hatchery_name': hatcheryName,
        'categories': categories.map((e) => e.toJson()).toList(),
        'customer_name': customerName,
        'customer_mobile': customerMobile,
        'no_of_pieces': noOfPieces,
        'dropping_location': droppingLocation,
        'packing_date': packingDate,
        'delivery_location': deliveryLocation,
        'media_type': mediaType,
        'images': images,
      };
}

// ----------------------------------------------------------------------

class CategoryModel {
  final int id;
  final String categoryName;
  final int priority;

  CategoryModel({
    required this.id,
    required this.categoryName,
    required this.priority,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_name': categoryName,
        'priority': priority,
      };
}
