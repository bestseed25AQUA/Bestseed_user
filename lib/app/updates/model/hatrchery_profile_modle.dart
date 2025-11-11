class HatcheryProfileModel {
  final bool status;
  final String message;
  final HatcheryData? data;

  HatcheryProfileModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory HatcheryProfileModel.fromJson(Map<String, dynamic> json) {
    return HatcheryProfileModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? HatcheryData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "data": data?.toJson(),
    };
  }
}

class HatcheryData {
  final int? hatcheryId;
  final String? hatcheryName;
  final String? profileImage;
  final String? location;
  final String? lat;
  final String? lng;
  final String? vendorName;
  final String? vendorMobile;
  final String? callUrl;
  final String? whatsappUrl;

  HatcheryData({
    this.hatcheryId,
    this.hatcheryName,
    this.profileImage,
    this.location,
    this.lat,
    this.lng,
    this.vendorName,
    this.vendorMobile,
    this.callUrl,
    this.whatsappUrl,
  });

  factory HatcheryData.fromJson(Map<String, dynamic> json) {
    return HatcheryData(
      hatcheryId: json['hatchery_id'],
      hatcheryName: json['hatchery_name'],
      profileImage: json['profile_image'],
      location: json['location'],
      lat: json['lat'],
      lng: json['lng'],
      vendorName: json['vendor_name'],
      vendorMobile: json['vendor_mobile'],
      callUrl: json['call_url'],
      whatsappUrl: json['whatsapp_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "hatchery_id": hatcheryId,
      "hatchery_name": hatcheryName,
      "profile_image": profileImage,
      "location": location,
      "lat": lat,
      "lng": lng,
      "vendor_name": vendorName,
      "vendor_mobile": vendorMobile,
      "call_url": callUrl,
      "whatsapp_url": whatsappUrl,
    };
  }
}
