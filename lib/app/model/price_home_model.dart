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
      status: json['status'] == true,
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      data: json['data'] is List
          ? (json['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((x) => PriceLocation.fromJson(x))
              .toList()
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
      location: json['location']?.toString() ?? '',
      msg: json['msg']?.toString() ?? '',
      prices: json['prices'] is List
          ? (json['prices'] as List)
              .whereType<Map<String, dynamic>>()
              .map((x) => Price.fromJson(x))
              .toList()
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
      size: json['size']?.toString() ?? '',
      // Backend may send int, double, or numeric string — parse defensively.
      todayPrice: _toInt(json['today_price']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ??
        double.tryParse(value?.toString() ?? '')?.round() ??
        0;
  }
}
