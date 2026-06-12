/// Details of a delivered booking that still needs a rating, returned by
/// GET /api/farmer/pending-rating and shown in the rating popup.
class PendingRating {
  final String id;
  final String? bookingUid;
  final String? hatcheryName;
  final String? categoryName;
  final String? noOfPieces;
  final String? unit;
  final String? driverName;
  final String? driverMobile;
  final String? deliveredAt;

  PendingRating({
    required this.id,
    this.bookingUid,
    this.hatcheryName,
    this.categoryName,
    this.noOfPieces,
    this.unit,
    this.driverName,
    this.driverMobile,
    this.deliveredAt,
  });

  factory PendingRating.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v?.toString();
    return PendingRating(
      id: json['id']?.toString() ?? '',
      bookingUid: str(json['booking_uid']),
      hatcheryName: str(json['hatchery_name']),
      categoryName: str(json['category_name']),
      noOfPieces: str(json['no_of_pieces']),
      unit: str(json['unit']),
      driverName: str(json['driver_name']),
      driverMobile: str(json['driver_mobile']),
      deliveredAt: str(json['delivered_at']),
    );
  }
}
