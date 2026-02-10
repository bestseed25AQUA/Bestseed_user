class PriceModel {
  bool status;
  String category;
  String location;
  String description;
  String disclaimer;
  String msg;
  List<Price> prices;

  PriceModel({
    required this.status,
    required this.category,
    required this.location,
    required this.description,
    required this.disclaimer,
    required this.msg,
    required this.prices,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      status: json['status'] ?? false,
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      disclaimer: json['disclaimer'] ?? '',
      msg: json['msg'] ?? '',
      prices: json['prices'] != null
          ? List<Price>.from(json['prices'].map((x) => Price.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'category': category,
    'location': location,
    'description': description,
    'disclaimer': disclaimer,
    'msg': msg,
    'prices': List<dynamic>.from(prices.map((x) => x.toJson())),
  };
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

  Map<String, dynamic> toJson() => {'size': size, 'today_price': todayPrice};
}
