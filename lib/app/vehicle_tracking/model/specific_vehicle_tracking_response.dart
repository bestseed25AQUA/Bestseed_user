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
    TrackingData? trackingData;

    // Legacy format: { "data": { ... tracking fields ... } }
    if (json['data'] != null && json['data'] is Map) {
      trackingData = TrackingData.fromJson(json['data']);
    }
    // New format: { "booking": {...}, "timeline": [...], "route_waypoints": [...] }
    else if (json['booking'] != null && json['booking'] is Map) {
      trackingData = TrackingData.fromBookingResponse(json);
    }

    return SpecificVehicleTrackingResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: trackingData,
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
  // Admin-set pickup location (`vehicle_start_lat`/`lng`). May differ from
  // `pickup` (which is the driver's actual journey-start position). Null
  // when admin didn't set a separate pickup. Used by the customer app to
  // draw the green "approach" line from admin-pickup → driver position.
  final LocationPoint? adminPickup;
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
  final double totalDistanceKm;
  final double remainingDistanceKm;
  // Passed stops saved in DB — actual times, permanent history
  final List<Map<String, dynamic>> passedStops;
  // Last ~60 GPS breadcrumbs for client-side path drawing and stop detection
  final List<dynamic> driverBreadcrumbs;
  // Road-snapped ACTUAL driven path ([[lat,lng], ...]). Built by the backend by
  // snapping the driver's real breadcrumbs to the road network (Google Roads
  // API), so it covers the actual points but follows road geometry. This is the
  // authoritative source for the GREEN (travelled) line — never the planned route.
  final List<dynamic> trackingPath;
  // True when driver has marked the booking as delivered (status == 5).
  // Authoritative signal for showing "Reached" on destination in the timeline.
  final bool isDelivered;
  final String? deliveredAt;

  TrackingData({
    required this.vehicleId,
    required this.bookingId,
    required this.pickup,
    this.adminPickup,
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
    this.totalDistanceKm = 0,
    this.remainingDistanceKm = 0,
    this.passedStops = const [],
    this.driverBreadcrumbs = const [],
    this.trackingPath = const [],
    this.isDelivered = false,
    this.deliveredAt,
  });

  /// Parse from new API format: { "booking": {...}, "timeline": [...], "route_waypoints": [...] }
  factory TrackingData.fromBookingResponse(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>;
    final pickup = booking['pickup'] as Map<String, dynamic>? ?? {};
    final destination = booking['destination'] as Map<String, dynamic>? ?? {};
    final currentLocation = booking['current_location'] as Map<String, dynamic>? ?? {};
    final driver = booking['driver'] as Map<String, dynamic>? ?? {};

    return TrackingData(
      vehicleId: driver['driver_id'] ?? 0,
      bookingId: booking['booking_id'] ?? 0,
      travelCost: booking['price']?.toString() ?? 'N/A',
      expectedDelivery: booking['delivery_datetime']?.toString() ?? 'N/A',
      pickup: LocationPoint(
        name: pickup['location_name'] ?? '',
        lat: double.tryParse(pickup['lat']?.toString() ?? '') ?? 0,
        lng: double.tryParse(pickup['lng']?.toString() ?? '') ?? 0,
        updatedAt: pickup['vehicle_started_date'],
      ),
      drop: LocationPoint(
        name: destination['location_name'] ?? '',
        lat: double.tryParse(destination['lat']?.toString() ?? '') ?? 0,
        lng: double.tryParse(destination['lng']?.toString() ?? '') ?? 0,
      ),
      driverLocation: LocationPoint(
        name: currentLocation['location_name'] ?? '',
        lat: double.tryParse(currentLocation['lat']?.toString() ?? '') ?? 0,
        lng: double.tryParse(currentLocation['lng']?.toString() ?? '') ?? 0,
        updatedAt: currentLocation['updated_at'],
      ),
      driverDetails: DriverDetails(
        driverName: driver['driver_name'] ?? '',
        driverPhone: driver['driver_mobile'] ?? '',
        vehicleNumber: driver['vehicle_number'] ?? '',
        driverImage: '',
      ),
      deliveryUpdates: DeliveryUpdates(
        deliveryExpected: booking['delivery_datetime'] ?? '',
        note: booking['vendor_booking_description'] ?? '',
      ),
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineItem.fromJson(e))
              .toList() ??
          [],
      vendorMobile: null,
      vehicleDescription: booking['vendor_vehicle_description']?.toString(),
      inProgressAt: pickup['in_progress_at']?.toString(),
      routeWaypoints: (json['route_waypoints'] as List<dynamic>?)
              ?.map((e) => RouteWaypoint.fromJson(e))
              .toList() ??
          [],
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      remainingDistanceKm: (json['remaining_distance_km'] as num?)?.toDouble() ?? 0,
      passedStops: (json['passed_stops'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      driverBreadcrumbs: (json['driver_breadcrumbs'] as List<dynamic>?) ?? [],
      trackingPath: (json['tracking_path'] as List<dynamic>?) ?? [],
      isDelivered: json['is_delivered'] ?? false,
      deliveredAt: json['delivered_at']?.toString(),
    );
  }

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      vehicleId: json['vehicle_id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      travelCost: json['travel_cost']?.toString() ?? 'N/A',
      expectedDelivery: json['expected_delivery']?.toString() ?? 'N/A',

      pickup: LocationPoint.fromJson(json['pickup']),
      // admin_pickup is optional — only present when admin set vehicle_start_lat
      // and it differs from the driver's actual journey start. Lat/lng can
      // both be null in the API payload, in which case we expose null on
      // the model so callers can short-circuit cleanly.
      adminPickup: () {
        final ap = json['admin_pickup'];
        if (ap is! Map<String, dynamic>) return null;
        if (ap['lat'] == null || ap['lng'] == null) return null;
        return LocationPoint.fromJson(ap);
      }(),
      drop: LocationPoint.fromJson(json['drop']),
      driverLocation: LocationPoint.fromJson(json['driver_location']),

      driverDetails: DriverDetails.fromJson(json['driver_details']), // ✅ NEW

      deliveryUpdates: DeliveryUpdates.fromJson(json['delivery_updates']),

      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineItem.fromJson(e))
              .toList() ??
          [],
      vendorMobile: json['vendor_mobile']?.toString(),
      vehicleDescription: json['vehicle_description']?.toString(),
      inProgressAt: json['in_progress_at']?.toString(),
      routeWaypoints: (json['route_waypoints'] as List<dynamic>?)
              ?.map((e) => RouteWaypoint.fromJson(e))
              .toList() ??
          [],
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      remainingDistanceKm: (json['remaining_distance_km'] as num?)?.toDouble() ?? 0,
      passedStops: (json['passed_stops'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      driverBreadcrumbs: (json['driver_breadcrumbs'] as List<dynamic>?) ?? [],
      trackingPath: (json['tracking_path'] as List<dynamic>?) ?? [],
      isDelivered: json['is_delivered'] ?? false,
      deliveredAt: json['delivered_at']?.toString(),
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
/// Five-state driver status emitted by the backend.
/// moving      – fresh GPS, net displacement > 30 m / 60 s
/// idle        – fresh GPS, speed ≈ 0 (genuine short stop at toll/traffic)
/// signal_lost – 2–5 min GPS gap (Doze, poor signal, WorkManager hiccup)
/// offline     – 5–30 min gap (no signal / OEM kill)
/// stopped     – > 30 min gap (long break / loading)
enum DriverStatus { moving, idle, signalLost, offline, stopped }

class LocationPoint {
  final String name;
  final double lat;
  final double lng;
  final String? updatedAt;
  /// Granular status — prefer over the legacy `isMoving` bool.
  final DriverStatus driverStatus;
  /// Backward-compat bool (true for moving/signal_lost/offline).
  final bool isMoving;
  /// True when GPS data is 2–30 min old (background gap, not a real halt).
  final bool locationStale;
  final double speedKmh;

  LocationPoint({
    required this.name,
    required this.lat,
    required this.lng,
    this.updatedAt,
    this.driverStatus = DriverStatus.moving,
    this.isMoving = true,
    this.locationStale = false,
    this.speedKmh = 0,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    final statusStr = json['driver_status'] as String? ?? '';
    final DriverStatus status;
    switch (statusStr) {
      case 'idle':        status = DriverStatus.idle;        break;
      case 'signal_lost': status = DriverStatus.signalLost; break;
      case 'offline':     status = DriverStatus.offline;     break;
      case 'stopped':     status = DriverStatus.stopped;     break;
      default:            status = DriverStatus.moving;
    }
    return LocationPoint(
      name:          json['name'] ?? '',
      lat:           (json['lat'] ?? 0).toDouble(),
      lng:           (json['lng'] ?? 0).toDouble(),
      updatedAt:     json['updated_at'],
      driverStatus:  status,
      isMoving:      json['is_moving'] ?? true,
      locationStale: json['location_stale'] ?? false,
      speedKmh:      (json['speed_kmh'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name, "lat": lat, "lng": lng, "updated_at": updatedAt,
    "driver_status": driverStatus.name, "is_moving": isMoving,
    "location_stale": locationStale, "speed_kmh": speedKmh,
  };
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
  final double? lat;
  final double? lng;

  TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.status,
    this.lat,
    this.lng,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "subtitle": subtitle,
    "time": time,
    "date": date,
    "status": status,
    "lat": lat,
    "lng": lng,
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
  final bool isBefore; // true = driver has already passed this waypoint

  RouteWaypoint({
    required this.lat,
    required this.lng,
    this.status = 4,
    this.priority = 0,
    this.name = '',
    this.isBefore = false,
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
      isBefore: json['is_before'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
    "status": status,
    "priority": priority,
    "name": name,
    "is_before": isBefore,
  };
}
