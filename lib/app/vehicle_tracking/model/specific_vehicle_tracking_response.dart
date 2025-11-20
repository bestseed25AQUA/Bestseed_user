class SpecificVehicleTrackingResponse {
  final bool status;
  final String message;
  final TrackingData? data;

  SpecificVehicleTrackingResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SpecificVehicleTrackingResponse.fromJson(Map<String, dynamic> json) {
    return SpecificVehicleTrackingResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? TrackingData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class TrackingData {
  final LocationPoint pickup;
  final LocationPoint drop;
  final LocationPoint driverLocation;   // ✅ NEW
  final DeliveryUpdates deliveryUpdates;
  final List<TimelineItem> timeline;

  TrackingData({
    required this.pickup,
    required this.drop,
    required this.driverLocation,       // ✅ NEW
    required this.deliveryUpdates,
    required this.timeline,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      pickup: LocationPoint.fromJson(json['pickup']),
      drop: LocationPoint.fromJson(json['drop']),
      driverLocation: LocationPoint.fromJson(json['driver_location']), // ✅ NEW
      deliveryUpdates: DeliveryUpdates.fromJson(json['delivery_updates']),
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => TimelineItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "pickup": pickup.toJson(),
        "drop": drop.toJson(),
        "driver_location": driverLocation.toJson(), // ✅ NEW
        "delivery_updates": deliveryUpdates.toJson(),
        "timeline": timeline.map((e) => e.toJson()).toList(),
      };
}


class LocationPoint {
  final String name;
  final double lat;
  final double lng;

  LocationPoint({
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      name: json['name'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "lat": lat,
        "lng": lng,
      };
}
class DeliveryUpdates {
  final String orderPlacedDate;
  final String orderPlacedTime;
  final String deliveryExpected;

  DeliveryUpdates({
    required this.orderPlacedDate,
    required this.orderPlacedTime,
    required this.deliveryExpected,
  });

  factory DeliveryUpdates.fromJson(Map<String, dynamic> json) {
    return DeliveryUpdates(
      orderPlacedDate: json['order_placed_date'] ?? '',
      orderPlacedTime: json['order_placed_time'] ?? '',
      deliveryExpected: json['delivery_expected'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "order_placed_date": orderPlacedDate,
        "order_placed_time": orderPlacedTime,
        "delivery_expected": deliveryExpected,
      };
}
class TimelineItem {
  final String title;
  final String subtitle;
  final String time;
  final String? date;

  TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.date,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      time: json['time'] ?? '',
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() => {
        "title": title,
        "subtitle": subtitle,
        "time": time,
        "date": date,
      };
}
