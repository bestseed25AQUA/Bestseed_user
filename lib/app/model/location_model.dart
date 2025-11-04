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
  final String locationName;
  final String longitude;
  final String latitude;

  Location({
    required this.id,
    required this.locationName,
    required this.longitude,
    required this.latitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(

      id: json['id'] ?? 0,
      locationName: json['location_name'] ?? '',
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': locationName,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
