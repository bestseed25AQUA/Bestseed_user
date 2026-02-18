import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_best_seed_background.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/full_map_screen.dart';

import 'widgets/map_section_widget.dart';
import 'widgets/driver_section_widget.dart';
import 'widgets/delivery_update_widget.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking/widgets/time_line_section_widget.dart';

class VehicleTrackingScreen extends StatefulWidget {
  final String bookingId;
  const VehicleTrackingScreen({super.key, required this.bookingId});

  @override
  State<VehicleTrackingScreen> createState() => _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState extends State<VehicleTrackingScreen> {
  late final VehicleTrackingController controller;

  GoogleMapController? mapController;

  LatLng? pickup;
  LatLng? drop;
  LatLng? driverLoc;

  List<LatLng> routePoints = [];

  BitmapDescriptor? driverIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? destinationIcon;

  bool _isLoading = true;
  TrackingData? _trackingData;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VehicleTrackingController());
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await controller.fetchSpecificVehicleTracking(widget.bookingId);

      final d = controller.specificVehicle.value?.data;
      if (d == null) {
        print("VehicleTrackingScreen: No tracking data found for ${widget.bookingId}");
        return;
      }

      _trackingData = d;
      pickup = LatLng(d.pickup.lat, d.pickup.lng);
      drop = LatLng(d.drop.lat, d.drop.lng);
      driverLoc = LatLng(d.driverLocation.lat, d.driverLocation.lng);

      try {
        driverIcon = await loadMarker("assets/images/vehicle_truck.png", 70);
        pickupIcon = await loadMarker("assets/images/pickup_vehicle_icon.png", 70);
        destinationIcon = await loadMarker(
          "assets/images/drop_vehicle_icon.png",
          70,
        );
      } catch (e) {
        print("VehicleTrackingScreen: Error loading markers: $e");
      }

      try {
        await loadPolyline();
      } catch (e) {
        print("VehicleTrackingScreen: Error loading polyline: $e");
      }
    } catch (e) {
      print("VehicleTrackingScreen: Error in loadData: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<BitmapDescriptor> loadMarker(String asset, int width) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    return BitmapDescriptor.fromBytes(
      (await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
  }

  Future<void> loadPolyline() async {
    if (pickup == null || drop == null) return;

    final poly = PolylinePoints(apiKey: NetworkConfig.googleApiKey2);

    final result = await poly.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickup!.latitude, pickup!.longitude),
        destination: PointLatLng(drop!.latitude, drop!.longitude),
        mode: TravelMode.driving,
      ),
    );

    routePoints = result.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
  }

  void fitMapBounds() {
    if (mapController == null || pickup == null || drop == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        pickup!.latitude < drop!.latitude ? pickup!.latitude : drop!.latitude,
        pickup!.longitude < drop!.longitude
            ? pickup!.longitude
            : drop!.longitude,
      ),
      northeast: LatLng(
        pickup!.latitude > drop!.latitude ? pickup!.latitude : drop!.latitude,
        pickup!.longitude > drop!.longitude
            ? pickup!.longitude
            : drop!.longitude,
      ),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Text(
          'Vehicle tracking',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Builder(builder: (context) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final d = _trackingData;
        if (d == null) {
          return const Center(child: Text("No tracking data found"));
        }

        // Build last update details
        final lastUpdateTime = d.timeline.isNotEmpty
            ? "${d.timeline.first.time}, ${d.timeline.first.date}"
            : "-";
        final lastUpdateAddress = d.driverLocation.name;
        return SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenMapPage(
                        pickupLat: d.pickup.lat,
                        pickupLng: d.pickup.lng,
                        dropLat: d.drop.lat,
                        dropLng: d.drop.lng,
                        driverLat: d.driverLocation.lat,
                        driverLng: d.driverLocation.lng,
                        driverName: d.driverLocation.name,
                        routePoints: routePoints,
                        driverIcon: driverIcon,
                        pickupIcon: pickupIcon,
                        destinationIcon: destinationIcon,

                        lastUpdateTime: lastUpdateTime,
                        lastUpdateAddress: lastUpdateAddress,
                      ),
                    ),
                  );
                },
                child: MapSectionWidget(
                  pickupLat: d.pickup.lat,
                  pickupLng: d.pickup.lng,
                  dropLat: d.drop.lat,
                  dropLng: d.drop.lng,
                  driverLat: d.driverLocation.lat,
                  driverLng: d.driverLocation.lng,
                  driverName: d.driverLocation.name,
                  routePoints: routePoints,
                  driverIcon: driverIcon,
                  pickupIcon: pickupIcon,
                  destinationIcon: destinationIcon,
                  onMapCreated: (controller) {
                    mapController = controller;
                    Future.delayed(const Duration(milliseconds: 300), () {
                      fitMapBounds();
                    });
                  },
                ),
              ),

              DriverSectionWidget(
                driverName: d.driverDetails.driverName,
                phone: d.driverDetails.driverPhone,
                vehicleNumber: d.driverDetails.vehicleNumber,
                driverImage: d.driverDetails.driverImage,
              ),

              DeliveryUpdateWidget(
                travelCost: d.travelCost,
                expectedDelivery: d.expectedDelivery,
                expected: d.deliveryUpdates.deliveryExpected,
                note: d.deliveryUpdates.note,
              ),

              TimelineSectionWidget(items: d.timeline),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 20),
                  Text(
                    "Have a question? ",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  InkWell(
                    onTap: () async {
                      final vendorMobile = d.vendorMobile;
                      if (vendorMobile != null && vendorMobile.isNotEmpty) {
                        final uri = Uri(scheme: 'tel', path: vendorMobile);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                    child: Text(
                      "Contact us",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 30),
                child: CustomBestSeedBackground()),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }
}
