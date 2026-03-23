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
      data: json['data'] != null ? TrackingData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

// ------------------------------------------------------------
// TRACKING DATA
// ------------------------------------------------------------
class TrackingData {
  final int vehicleId;
  final int bookingId;

  final LocationPoint pickup;
  final LocationPoint drop;
  final LocationPoint driverLocation;

  final DriverDetails driverDetails; // ✅ NEW
  final DeliveryUpdates deliveryUpdates;

  final List<TimelineItem> timeline;

  final String travelCost;
  final String expectedDelivery;
  final String? vendorMobile;
  final String? vehicleDescription;
  final String? inProgressAt;
  final List<RouteWaypoint> routeWaypoints;

  TrackingData({
    required this.vehicleId,
    required this.bookingId,
    required this.pickup,
    required this.drop,
    required this.driverLocation,
    required this.driverDetails,
    required this.deliveryUpdates,
    required this.timeline,
    required this.travelCost,
    required this.expectedDelivery,
    this.vendorMobile,
    this.vehicleDescription,
    this.inProgressAt,
    this.routeWaypoints = const [],
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      vehicleId: json['vehicle_id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      travelCost: json['travel_cost']?.toString() ?? 'N/A',
      expectedDelivery: json['expected_delivery']?.toString() ?? 'N/A',

      pickup: LocationPoint.fromJson(json['pickup']),
      drop: LocationPoint.fromJson(json['drop']),
      driverLocation: LocationPoint.fromJson(json['driver_location']),

      driverDetails: DriverDetails.fromJson(json['driver_details']), // ✅ NEW

      deliveryUpdates: DeliveryUpdates.fromJson(json['delivery_updates']),

      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => TimelineItem.fromJson(e))
          .toList(),
      vendorMobile: json['vendor_mobile']?.toString(),
      vehicleDescription: json['vehicle_description']?.toString(),
      inProgressAt: json['in_progress_at']?.toString(),
      routeWaypoints: (json['route_waypoints'] as List<dynamic>?)
              ?.map((e) => RouteWaypoint.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    "vehicle_id": vehicleId,
    "booking_id": bookingId,
    "pickup": pickup.toJson(),
    "drop": drop.toJson(),
    "driver_location": driverLocation.toJson(),
    "driver_details": driverDetails.toJson(), // ✅ NEW
    "delivery_updates": deliveryUpdates.toJson(),
    "timeline": timeline.map((e) => e.toJson()).toList(),
  };
}

// ------------------------------------------------------------
// LOCATION POINT
// ------------------------------------------------------------
class LocationPoint {
  final String name;
  final double lat;
  final double lng;
  final String? updatedAt;

  LocationPoint({required this.name, required this.lat, required this.lng, this.updatedAt,});

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      name: json['name'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {"name": name, "lat": lat, "lng": lng, "updated_at": updatedAt, };
}

// ------------------------------------------------------------
// DRIVER DETAILS (NEW MODEL)
// ------------------------------------------------------------
class DriverDetails {
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String driverImage;

  DriverDetails({
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    required this.driverImage,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      driverImage: json['driver_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "driver_name": driverName,
    "driver_phone": driverPhone,
    "vehicle_number": vehicleNumber,
    "driver_image": driverImage,
  };
}

// ------------------------------------------------------------
// DELIVERY UPDATES (MODIFIED)
// ------------------------------------------------------------
class DeliveryUpdates {
  final String deliveryExpected;
  final String note;

  DeliveryUpdates({required this.deliveryExpected, required this.note});

  factory DeliveryUpdates.fromJson(Map<String, dynamic> json) {
    return DeliveryUpdates(
      deliveryExpected: json['delivery_expected'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "delivery_expected": deliveryExpected,
    "note": note,
  };
}

// ------------------------------------------------------------
// TIMELINE ITEM (MIN CHANGE + status added)
// ------------------------------------------------------------
class TimelineItem {
  final String title;
  final String subtitle;
  final String time;
  final String date;
  final String status; // completed / pending

  TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.status,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "subtitle": subtitle,
    "time": time,
    "date": date,
    "status": status,
  };
}

// ------------------------------------------------------------
// ROUTE WAYPOINT (for multi-drop route calculation)
// ------------------------------------------------------------
class RouteWaypoint {
  final double lat;
  final double lng;
  final int status; // 4=in-progress, 5=delivered, 6=cancelled
  final int priority;
  final String name;

  RouteWaypoint({
    required this.lat,
    required this.lng,
    this.status = 4,
    this.priority = 0,
    this.name = '',
  });

  /// Whether this stop has already been delivered or cancelled
  bool get isCompleted => status == 5 || status == 6;

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      status: json['status'] ?? 4,
      priority: json['priority'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
    "status": status,
    "priority": priority,
    "name": name,
  };
}
