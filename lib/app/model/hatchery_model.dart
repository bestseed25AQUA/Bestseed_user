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

  HatcheryData({
    required this.hatcheryId,
    required this.hatcheryName,
    required this.profileImage,
    required this.viewProfileUrl,
  });

  factory HatcheryData.fromJson(Map<String, dynamic> json) {
    return HatcheryData(
      hatcheryId: json['hatchery_id'].toString(), // convert to string for safety
      hatcheryName: json['hatchery_name'] ?? '',
      profileImage: json['profile_image'] ?? '',
      viewProfileUrl: json['view_profile_url'] ?? '',
    );
  }
}
