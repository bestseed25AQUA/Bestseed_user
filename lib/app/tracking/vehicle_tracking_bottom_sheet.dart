import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';

class VehicleTrackingBottomSheet extends StatefulWidget {
  const VehicleTrackingBottomSheet({super.key});

  @override
  State<VehicleTrackingBottomSheet> createState() =>
      _VehicleTrackingBottomSheetState();
}

class _VehicleTrackingBottomSheetState
    extends State<VehicleTrackingBottomSheet> {
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];

  static const pickup = LatLng(16.5062, 80.6480); // Vijayawada
  static const drop = LatLng(16.5790, 82.0067); // Amalapuram

  @override
  void initState() {
    super.initState();
    _setPolyline();
  }

  Future<void> _setPolyline() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: 'AIzaSyA111b89Exrm83RRWF-2hP1EPeUxvos87I',
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickup.latitude, pickup.longitude),
        destination: PointLatLng(drop.latitude, drop.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _routePoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      });

      // Auto zoom map to fit pickup & drop
      if (_mapController != null) {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            pickup.latitude < drop.latitude ? pickup.latitude : drop.latitude,
            pickup.longitude < drop.longitude
                ? pickup.longitude
                : drop.longitude,
          ),
          northeast: LatLng(
            pickup.latitude > drop.latitude ? pickup.latitude : drop.latitude,
            pickup.longitude > drop.longitude
                ? pickup.longitude
                : drop.longitude,
          ),
        );

        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildMapSection(),
                    _buildDeliveryUpdates(),
                    _buildTimeline(),
                    _buildOkayButton(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Vehicle tracking',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3263),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(target: pickup, zoom: 8),
          markers: {
            const Marker(markerId: MarkerId("pickup"), position: pickup),
            const Marker(markerId: MarkerId("drop"), position: drop),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: _routePoints,
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryUpdates() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Updates',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order placed at 23/06/2025, 10:30 AM',
            style: GoogleFonts.roboto(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery Expected on 27/06/2025',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _buildTimelineDot(
                  isFirst: true,
                  imageUrl: 'assets/images/map.png',
                ),
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
                _buildTimelineDot(
                  isFirst: true,
                  isLast: true,
                  imageUrl: 'assets/images/pickup_image.png',
                ),
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
                _buildTimelineDot(
                  isLast: true,
                  imageUrl: 'assets/images/success.png',
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineItem(
                    title: 'Started from',
                    subtitle: 'Puducherry',
                    time: '2:30 PM',
                  ),
                  _buildTimelineItem(
                    title: 'Pickup',
                    subtitle: 'Vijayawada',
                    time: '10:30 PM',
                    date: '24/06/2025',
                  ),
                  _buildTimelineItem(
                    title: 'Dropped at',
                    subtitle: 'Amalapuram',
                    time: '10:30 AM',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTimelineDot({
    bool isFirst = false,
    bool isLast = false,
    required String imageUrl,
  }) {
    return Container(
      width: 24,
      height: 24,
      margin: isFirst
          ? EdgeInsets.only(bottom: 4, top: 4)
          : EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isLast ? Colors.green : Colors.grey[400],
        shape: BoxShape.circle,
      ),
      child: Image.asset(imageUrl),
    );
  }

  static Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    String? date,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.roboto(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.roboto(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOkayButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: CustomButton(
        onPressed: () => Navigator.pop(context),

        text: 'Okay',
      ),
    );
  }
}
