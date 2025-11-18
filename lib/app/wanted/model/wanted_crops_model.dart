class WantedCrop {
  final int id;
  final String hatcheryName;
  final String category;
  final String location;
  final String packingDate;
  final int tons;
  final String payment;
  final String price;
  final String contact;
  final String mediaType;
  final String mediaUrl;

  WantedCrop({
    required this.id,
    required this.hatcheryName,
    required this.category,
    required this.location,
    required this.packingDate,
    required this.tons,
    required this.payment,
    required this.price,
    required this.contact,
    required this.mediaType,
    required this.mediaUrl,
  });

  factory WantedCrop.fromJson(Map<String, dynamic> json) {
    return WantedCrop(
      id: json['id'] ?? 0,
      hatcheryName: json['hatchery_name'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      packingDate: json['packing_date'] ?? '',
      tons: json['tons'] ?? 0,
      payment: json['payment'] ?? '',
      price: json['price'] ?? '',
      contact: json['contact'] ?? '',
      mediaType: json['media_type'] ?? '',
      mediaUrl: json['media_url'] ?? '',
    );
  }
}
