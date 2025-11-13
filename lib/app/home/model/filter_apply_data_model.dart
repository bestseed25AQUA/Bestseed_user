class FilterResponseModel {
  bool status;
  String message;
  FilterData data;

  FilterResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory FilterResponseModel.fromJson(Map<String, dynamic> json) {
    return FilterResponseModel(
      status: json["status"] is bool ? json["status"] : false,
      message: json["message"]?.toString() ?? "",
      data: json["data"] is Map
          ? FilterData.fromJson(json["data"])
          : FilterData.empty(),
    );
  }
}

class FilterData {
  List<CategoryModel> categories;
  List<LocationModel> locations;
  List<BrandModel> brands;

  FilterData({
    required this.categories,
    required this.locations,
    required this.brands,
  });

  factory FilterData.fromJson(Map<String, dynamic> json) {
    return FilterData(
      categories: (json["categories"] is List)
          ? (json["categories"] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList()
          : [],
      locations: (json["locations"] is List)
          ? (json["locations"] as List)
              .map((e) => LocationModel.fromJson(e))
              .toList()
          : [],
      brands: (json["brands"] is List)
          ? (json["brands"] as List)
              .map((e) => BrandModel.fromJson(e))
              .toList()
          : [],
    );
  }

  /// Used when API doesn't return `data`
  factory FilterData.empty() {
    return FilterData(
      categories: [],
      locations: [],
      brands: [],
    );
  }
}


class CategoryModel {
  int id;
  String categoryName;

  CategoryModel({
    required this.id,
    required this.categoryName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      categoryName: json["category_name"]?.toString() ?? "",
    );
  }
}


class BrandModel {
  int id;
  String brandName;

  BrandModel({
    required this.id,
    required this.brandName,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      brandName: json["brand_name"]?.toString() ?? "",
    );
  }
}


class LocationModel {
  int id;
  String locationName;
  String latitude;
  String longitude;

  LocationModel({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json["id"] is int ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      locationName: json["location_name"]?.toString() ?? "",
      latitude: json["latitude"]?.toString() ?? "",
      longitude: json["longitude"]?.toString() ?? "",
    );
  }
}
