class BookingDetailModel {
  final String bookingUId;

  final String status;
  final String statusDescription;

  final String bookingDateTime;
  final String unitLocation;
  final String pickupLocation;
  final int salinity;
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

  // Driver details (available when status >= 3)
  final DriverDetailModel? driver;
  final String? vendorMobile;
  final String? bookingDescription;
  final String? vehicleDescription;

  BookingDetailModel({
    required this.bookingUId,
    required this.status,
    required this.statusDescription,
    required this.bookingDateTime,
    required this.unitLocation,
    required this.pickupLocation,
    required this.salinity,
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
    this.driver,
    this.vendorMobile,
    this.bookingDescription,
    this.vehicleDescription,
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
      pickupLocation: booking["pickup_location"]?.toString() ?? "",
      salinity: booking["salinity"] ?? 0,
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

      driver: booking["driver"] != null
          ? DriverDetailModel.fromJson(booking["driver"])
          : null,
      vendorMobile: booking["vendor_mobile"]?.toString(),
      bookingDescription: booking["booking_description"]?.toString(),
      vehicleDescription: booking["vehicle_description"]?.toString(),
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

class DriverDetailModel {
  final String? name;
  final String? mobile;
  final String? image;
  final String? vehicleNumber;
  final String? vehicleStartedDate;
  final String? vehicleStartAddress;

  DriverDetailModel({
    this.name,
    this.mobile,
    this.image,
    this.vehicleNumber,
    this.vehicleStartedDate,
    this.vehicleStartAddress,
  });

  factory DriverDetailModel.fromJson(Map<String, dynamic> json) {
    return DriverDetailModel(
      name: json["name"]?.toString(),
      mobile: json["mobile"]?.toString(),
      image: json["image"]?.toString(),
      vehicleNumber: json["vehicle_number"]?.toString(),
      vehicleStartedDate: json["vehicle_started_date"]?.toString(),
      vehicleStartAddress: json["vehicle_start_address"]?.toString(),
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
