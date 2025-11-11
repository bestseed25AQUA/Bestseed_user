class BrandModel {
  final int id;
  final String brandName;

  BrandModel({
    required this.id,
    required this.brandName,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json["id"],
      brandName: json["brand_name"],
    );
  }
}
