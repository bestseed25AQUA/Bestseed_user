class BookingDetailModel {
  final String bookingUId;

  final String status;
  final String statusDescription;

  final String bookingDateTime;
  final String unitLocation;
  final String pieces;
  final String estimatedPrice;
  final String droppingLocation;
  final String preferredDate;
  final int statusValue;
  final String note;

  final List<BookingStatusStep> bookingStatus; // timeline

  // 🔥 Newly added fields (because present in API)
  final int bookingId;
  final int hatcheryId;
  final String hatcheryName;

  final int categoryId;
  final String categoryName;

  final CancellationReasonModel? cancellationReason;

  BookingDetailModel({
    required this.bookingUId,
    required this.status,
    required this.statusDescription,
    required this.bookingDateTime,
    required this.unitLocation,
    required this.pieces,
    required this.estimatedPrice,
    required this.droppingLocation,
    required this.note,
    required this.preferredDate,
    required this.bookingStatus,

    required this.bookingId,
    required this.hatcheryId,
    required this.hatcheryName,
    required this.categoryId,
    required this.categoryName,
    this.cancellationReason,
    required this.statusValue,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    final booking = json["booking"] ?? {};

    final List<dynamic> statusList = booking["booking_status_timeline"] is List
        ? booking["booking_status_timeline"]
        : [];

    return BookingDetailModel(
      
      statusValue: booking["status"]?["value"] ?? 0,
      note: booking["note"] ?? '',

      bookingUId: booking["booking_uid"]?.toString() ?? "",
      status: booking["status"]?["label"] ?? "",
      statusDescription: booking["status"]?["message"] ?? "",

      bookingDateTime: booking["delivery_datetime"]?.toString() ?? "",
      unitLocation: booking["unit"]?.toString() ?? "",
      pieces: booking["no_of_pieces"]?.toString() ?? "",
      estimatedPrice: booking["estimated_price"]?.toString() ?? "",
      droppingLocation: booking["dropping_location"]?.toString() ?? "",
      preferredDate: booking["packing_date"]?.toString() ?? "",

      bookingStatus: statusList
          .map((e) => BookingStatusStep.fromJson(e))
          .toList(),

      // 🔥 Additional API fields
      bookingId: booking["booking_id"] ?? 0,
      hatcheryId: booking["hatchery_id"] ?? 0,
      hatcheryName: booking["hatchery_name"]?.toString() ?? "",

      categoryId: booking["category_id"] ?? 0,
      categoryName: booking["category_name"]?.toString() ?? "",

      cancellationReason: booking["cancellation_reason"] != null
          ? CancellationReasonModel.fromJson(booking["cancellation_reason"])
          : null,
    );
  }
}

class CancellationReasonModel {
  final int code;
  final String text;

  CancellationReasonModel({required this.code, required this.text});

  factory CancellationReasonModel.fromJson(Map<String, dynamic> json) {
    return CancellationReasonModel(
      code: json["code"] ?? 0,
      text: json["text"]?.toString() ?? "",
    );
  }
}

class BookingStatusStep {
  final String label;
  final String time;
  final bool status;

  BookingStatusStep({
    required this.label,
    required this.time,
    required this.status,
  });

  factory BookingStatusStep.fromJson(Map<String, dynamic> json) {
    return BookingStatusStep(
      label: json["label"] ?? "",
      time: json["time"] ?? "",
      status: (json["completed"] ?? false) is bool ? json["completed"] : false,
    );
  }
}
