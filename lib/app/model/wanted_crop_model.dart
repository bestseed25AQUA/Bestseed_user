class WantedCropsModel {
  final bool status;
  final String message;
  final List<WantedCrop> wantedCrops;

  WantedCropsModel({
    required this.status,
    required this.message,
    required this.wantedCrops,
  });

  factory WantedCropsModel.fromJson(Map<String, dynamic> json) {
    return WantedCropsModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      wantedCrops:
          (json['wanted_crops'] as List<dynamic>?)
              ?.map((e) => WantedCrop.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'wanted_crops': wantedCrops.map((e) => e.toJson()).toList(),
  };
}

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
  final String description;

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
    required this.description,
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
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hatchery_name': hatcheryName,
    'category': category,
    'location': location,
    'packing_date': packingDate,
    'tons': tons,
    'payment': payment,
    'price': price,
    'contact': contact,
    'media_type': mediaType,
    'media_url': mediaUrl,
  };
}
