class PriceHomeModel {
  bool status;
  String category;
  String description;
  List<PriceLocation> data;

  PriceHomeModel({
    required this.status,
    required this.category,
    required this.description,
    required this.data,
  });

  factory PriceHomeModel.fromJson(Map<String, dynamic> json) {
    return PriceHomeModel(
      status: json['status'] ?? false,
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      data: json['data'] != null
          ? List<PriceLocation>.from(
              json['data'].map((x) => PriceLocation.fromJson(x)))
          : [],
    );
  }
}

class PriceLocation {
  String location;
  String msg;
  List<Price> prices;

  PriceLocation({
    required this.location,
    required this.msg,
    required this.prices,
  });

  factory PriceLocation.fromJson(Map<String, dynamic> json) {
    return PriceLocation(
      location: json['location'] ?? '',
      msg: json['msg'] ?? '',
      prices: json['prices'] != null
          ? List<Price>.from(json['prices'].map((x) => Price.fromJson(x)))
          : [],
    );
  }
}

class Price {
  String size;
  int todayPrice;

  Price({required this.size, required this.todayPrice});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      size: json['size'] ?? '',
      todayPrice: json['today_price'] ?? 0,
    );
  }
}
