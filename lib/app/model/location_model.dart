class LocationModel {
  final bool status;
  final List<Location> locations;
  

  LocationModel({required this.status, required this.locations});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      status: json['status'] ?? false,
      locations: json['locations'] != null
          ? List<Location>.from(
              json['locations'].map((x) => Location.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'locations': locations.map((x) => x.toJson()).toList(),
    };
  }
}
class Location {
  final int id;
  final String title;
  final String subtitle;
  final String longitude;
  final String latitude;
  final bool isDefault;

  Location({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.longitude,
    required this.latitude,
    required this.isDefault,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'longitude': longitude,
      'latitude': latitude,
      'is_default': isDefault,
    };
  }
}
