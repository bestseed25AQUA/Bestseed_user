class HatcheryHomeModel {
  final int id;
  final String imagePath;
  final String title;
  final String location;
  final String type;
  final String status;
  final String? availableUntil;
  final int categoryId;
  final int locationId;

  HatcheryHomeModel({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.type,
    required this.status,
    this.availableUntil,
    required this.categoryId,
    required this.locationId,
  });

  factory HatcheryHomeModel.fromJson(Map<String, dynamic> json) {
    return HatcheryHomeModel(
      id: json["id"] ?? 0,
      imagePath: json["image"] ?? "",
      title: json["hatchery_name"] ?? "",
      location: json["location"] ?? "Unknown",
      type: json["category"] ?? "",
      status: json["status"] ?? "",
      availableUntil: json["available_on"], // nullable
      categoryId: json["category_id"] ?? 0,
      locationId: json["location_id"] ?? 0,
    );
  }
}
