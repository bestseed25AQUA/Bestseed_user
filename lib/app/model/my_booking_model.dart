import 'dart:convert';

MyBookingModel myBookingModelFromJson(String str) =>
    MyBookingModel.fromJson(json.decode(str));

String myBookingModelToJson(MyBookingModel data) =>
    json.encode(data.toJson());

// ============================================================================
// MAIN MODEL
// ============================================================================

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
      status: json["status"] ?? false,
      message: json["message"] ?? "",
      bookings: json["bookings"] == null
          ? []
          : List<BookingData>.from(
              (json["bookings"] as List)
                  .map((e) => BookingData.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "bookings": bookings.map((x) => x.toJson()).toList(),
      };
}

// ============================================================================
// BOOKING DATA
// ============================================================================

class BookingData {
  final String bookingUid;
  final int bookingId;
  final int hatcheryId;
  final String hatcheryName;

  final int categoryId;
  final String categoryName;

  final int noOfPieces;
  final String packingDate;
  final String droppingLocation;
  final String deliveryDatetime;
  final String status;

  final SpotInfo? isSpot;

  BookingData({
    required this.bookingUid,
    required this.bookingId,
    required this.hatcheryId,
    required this.hatcheryName,
    required this.categoryId,
    required this.categoryName,
    required this.noOfPieces,
    required this.packingDate,
    required this.droppingLocation,
    required this.deliveryDatetime,
    required this.status,
    this.isSpot,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      bookingUid: json["booking_uid"]?.toString() ?? "",
      bookingId: json["booking_id"] ?? 0,
      hatcheryId: json["hatchery_id"] ?? 0,
      hatcheryName: json["hatchery_name"] ?? "",
      categoryId: json["category_id"] ?? 0,
      categoryName: json["category_name"] ?? "",

      noOfPieces: json["no_of_pieces"] ?? 0,
      packingDate: json["packing_date"] ?? "",
      droppingLocation: json["dropping_location"] ?? "",

      deliveryDatetime: json["delivery_datetime"] ?? "",
      status: json["status"] ?? "",

      isSpot: json["is_spot"] != null
          ? SpotInfo.fromJson(json["is_spot"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "booking_uid": bookingUid,
        "booking_id": bookingId,
        "hatchery_id": hatcheryId,
        "hatchery_name": hatcheryName,
        "category_id": categoryId,
        "category_name": categoryName,
        "no_of_pieces": noOfPieces,
        "packing_date": packingDate,
        "dropping_location": droppingLocation,
        "delivery_datetime": deliveryDatetime,
        "status": status,
        "is_spot": isSpot?.toJson(),
      };
}

// ============================================================================
// SPOT INFO MODEL
// ============================================================================

class SpotInfo {
  final int value;
  final String label;

  SpotInfo({
    required this.value,
    required this.label,
  });

  factory SpotInfo.fromJson(Map<String, dynamic> json) {
    return SpotInfo(
      value: json["value"] ?? 0,
      label: json["label"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "value": value,
        "label": label,
      };
}
