import 'package:seedsuser/app/utils/network_config.dart';

class HatcheryCategory {
  final int id;
  final String name;

  HatcheryCategory({required this.id, required this.name});

  factory HatcheryCategory.fromJson(Map<String, dynamic> json) {
    return HatcheryCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class HatcheryHomeModel {
  final int id;
  final String imagePath;
  final String title;
  final String location;
  final String type; // Single category name (for backward compatibility)
  final List<HatcheryCategory> categories; // All categories
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
    required this.categories,
    required this.statusCode,
    required this.status,
    this.availableUntil,
    required this.categoryId,
    required this.locationId,
  });

  // Get all category names as comma-separated string
  String get categoryNames {
    if (categories.isEmpty) return type;
    return categories.map((c) => c.name).join(', ');
  }

  // Get category count
  int get categoryCount => categories.isEmpty ? (type.isNotEmpty ? 1 : 0) : categories.length;

  factory HatcheryHomeModel.fromJson(Map<String, dynamic> json) {
    final rawStatusCode = json["status_code"];
    final rawStatus = json["status"]?.toString().trim() ?? '';

    // Normalize status
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

    // Parse categories array
    List<HatcheryCategory> categoriesList = [];
    if (json["categories"] != null && json["categories"] is List) {
      categoriesList = (json["categories"] as List)
          .map((c) => HatcheryCategory.fromJson(c))
          .toList();
    }

    return HatcheryHomeModel(
      id: json["id"] ?? 0,
      imagePath: resolvedImage,
      title: json["hatchery_name"] ?? "",
      location: json["location"] ?? "Unknown",
      type: json["category"] ?? "",
      categories: categoriesList,
      statusCode: resolvedStatusCode,
      status: resolvedStatus,
      availableUntil: json["available_on"], // nullable
      categoryId: json["category_id"] ?? 0,
      locationId: json["location_id"] ?? 0,
    );
  }
}
