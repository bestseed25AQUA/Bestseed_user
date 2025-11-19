class WantedBannerModel {
  final bool status;
  final List<WantedBannerItem> banners;

  WantedBannerModel({
    required this.status,
    required this.banners,
  });

  factory WantedBannerModel.fromJson(Map<String, dynamic> json) {
    return WantedBannerModel(
      status: json['status'] ?? false,
      banners: (json['wanted'] as List<dynamic>? ?? [])
          .map((e) => WantedBannerItem.fromJson(e))
          .toList(),
    );
  }
}

class WantedBannerItem {
  final int id;
  final String type; // image/video
  final String url;

  WantedBannerItem({
    required this.id,
    required this.type,
    required this.url,
  });

  factory WantedBannerItem.fromJson(Map<String, dynamic> json) {
    return WantedBannerItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? "",
      url: json['url'] ?? "",
    );
  }
}
