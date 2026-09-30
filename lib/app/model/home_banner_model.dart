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
  String? thumbnail; // thumbnail image URL (for video banners)
  String? redirectUrl; // opened when the banner is tapped, when set

  BannerItem({
    required this.title,
    required this.type,
    required this.url,
    this.id,
    this.thumbnail,
    this.redirectUrl,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      redirectUrl: json['redirect_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'url': url,
        'thumbnail': thumbnail,
        'redirect_url': redirectUrl,
      };
}
