import 'package:seedsuser/app/utils/network_config.dart';

class HatcheryHomeModel {
  final int id;
  final String imagePath;
  final String title;
  final String location;
  final String type;
  final int statusCode;
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
    required this.statusCode,
    required this.status,
    this.availableUntil,
    required this.categoryId,
    required this.locationId,
  });

  factory HatcheryHomeModel.fromJson(Map<String, dynamic> json) {
    final rawStatusCode = json["status_code"];
    final rawStatus = json["status"]?.toString().trim() ?? '';

    // ✅ Normalize status
    int resolvedStatusCode;
    String resolvedStatus;

    if (rawStatusCode == null && (rawStatus == '-' || rawStatus.isEmpty)) {
      // BUSINESS RULE
      resolvedStatusCode = 2; // Coming Soon
      resolvedStatus = 'Coming Soon';
    } else {
      resolvedStatusCode = rawStatusCode is int
          ? rawStatusCode
          : int.tryParse(rawStatusCode?.toString() ?? '') ?? 5;

      resolvedStatus = rawStatus.isNotEmpty && rawStatus != '-'
          ? rawStatus
          : 'Closed';
    }

    final rawImage = json["image"]?.toString() ?? "";
    final resolvedImage = rawImage.isEmpty
        ? ""
        : (rawImage.startsWith('http')
              ? rawImage
              : '${NetworkConfig.imageURL}/$rawImage');

    return HatcheryHomeModel(
      id: json["id"] ?? 0,
      imagePath: resolvedImage,
      title: json["hatchery_name"] ?? "",
      location: json["location"] ?? "Unknown",
      type: json["category"] ?? "",
      statusCode: resolvedStatusCode,
      status: resolvedStatus,
      availableUntil: json["available_on"], // nullable
      categoryId: json["category_id"] ?? 0,
      locationId: json["location_id"] ?? 0,
    );
  }
}
