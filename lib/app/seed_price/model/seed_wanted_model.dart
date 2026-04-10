class SeedWantedModel {
  final bool status;
  final String species;
  final List<SeedWantedItem> data;

  SeedWantedModel({
    required this.status,
    required this.species,
    required this.data,
  });

  factory SeedWantedModel.fromJson(Map<String, dynamic> json) {
    return SeedWantedModel(
      status: json['status'] ?? false,
      species: json['species'] ?? 'vannamei',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => SeedWantedItem.fromJson(e))
          .toList(),
    );
  }
}

class SeedWantedItem {
  final int id;
  final String title;
  final String species;
  final String countOrKg;
  final String? countOrKgValue;
  final String? payment;
  final String? minimum;
  final String? area;
  final String? price;
  final String? phone;

  SeedWantedItem({
    required this.id,
    required this.title,
    required this.species,
    required this.countOrKg,
    this.countOrKgValue,
    this.payment,
    this.minimum,
    this.area,
    this.price,
    this.phone,
  });

  factory SeedWantedItem.fromJson(Map<String, dynamic> json) {
    return SeedWantedItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      species: json['species'] ?? 'vannamei',
      countOrKg: json['count_or_kg'] ?? 'count',
      countOrKgValue: json['count_or_kg_value'],
      payment: json['payment'],
      minimum: json['minimum'],
      area: json['area'],
      price: json['price'],
      phone: json['phone'],
    );
  }
}
