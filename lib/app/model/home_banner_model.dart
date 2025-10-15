class HomeBannerModel {
  bool status;
  List<BannerItem> banners;

  HomeBannerModel({required this.status, required this.banners});

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) {
    return HomeBannerModel(
      status: json['status'] ?? false,
      banners:
          (json['banners'] as List<dynamic>?)
              ?.map((e) => BannerItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BannerItem {
  dynamic id;
  String title;
  String type; // "image" or "video"
  String url;

  BannerItem({
    required this.title,
    required this.type,
    required this.url,
    this.id,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
    );
  }
}
