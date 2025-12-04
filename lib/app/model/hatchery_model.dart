class HatcheryModel {
  final bool status;
  final String message;
  final List<HatcheryData> data;

  HatcheryModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory HatcheryModel.fromJson(Map<String, dynamic> json) {
    return HatcheryModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((item) => HatcheryData.fromJson(item))
          .toList(),
    );
  }
}

class HatcheryData {
  final String hatcheryId;
  final String hatcheryName;
  final String profileImage;
  final String viewProfileUrl;
  final String vendorId;
  final String categoryId;
  final String locationId;
  final String hatcheryLogo;

  HatcheryData({
    required this.hatcheryId,
    required this.hatcheryName,
    required this.profileImage,
    required this.viewProfileUrl,
    required this.vendorId, required this.categoryId, required this.locationId, required this.hatcheryLogo, 
  });

  factory HatcheryData.fromJson(Map<String, dynamic> json) {
    return HatcheryData(
      hatcheryId: json['hatchery_id'].toString(), // convert to string for safety
      hatcheryName: json['hatchery_name']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      viewProfileUrl: json['view_profile_url'] ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      locationId: json['location_id']?.toString() ?? '',
      hatcheryLogo: json['hatchery_logo']?.toString() ?? '',
    );
  }
}
