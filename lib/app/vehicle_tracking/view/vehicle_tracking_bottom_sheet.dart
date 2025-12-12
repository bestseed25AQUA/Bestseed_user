// // ignore_for_file: unnecessary_nullable_for_final_variable_declarations

// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:ui' hide Codec;
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:seedsuser/app/common/app_color.dart';
// import 'package:seedsuser/app/common/custom_button.dart';
// import 'package:seedsuser/app/utils/network_config.dart';
// import 'package:seedsuser/app/vehicle_tracking/controller/vehicle_tracking_controller.dart';

// class VehicleTrackingBottomSheet extends StatefulWidget {
//   final String vehicleId;

//   const VehicleTrackingBottomSheet({super.key, required this.vehicleId});

//   @override
//   State<VehicleTrackingBottomSheet> createState() =>
//       _VehicleTrackingBottomSheetState();
// }

// class _VehicleTrackingBottomSheetState
//     extends State<VehicleTrackingBottomSheet> {
//   final VehicleTrackingController controller = Get.put(
//     VehicleTrackingController(),
//   );

//   GoogleMapController? _mapController;
//   List<LatLng> _routePoints = [];

//   LatLng? pickup;
//   LatLng? drop;

//   BitmapDescriptor? carIcon;
//   LatLng? driverLocation;

//   @override
//   void initState() {
//     super.initState();
//     initFunction();
//   }

//   initFunction() async {
//     await controller.fetchSpecificVehicleTracking(widget.vehicleId);

//     loadTruckIcon();

//     pickup = LatLng(
//       controller.specificVehicle.value!.data!.pickup.lat,
//       controller.specificVehicle.value!.data!.pickup.lng,
//     );

//     drop = LatLng(
//       controller.specificVehicle.value!.data!.drop.lat,
//       controller.specificVehicle.value!.data!.drop.lng,
//     );

//     driverLocation = LatLng(
//       controller.specificVehicle.value!.data!.driverLocation.lat,
//       controller.specificVehicle.value!.data!.driverLocation.lng,
//     );

//     // NOW call polyline
//     await _setPolyline();

//     setState(() {});
//   }

//   void loadTruckIcon() async {
//     carIcon = await getResizedMarker(
//       "assets/images/truck.png",
//       60,
//     ); // 60px size
//     setState(() {});
//   }

//   Future<BitmapDescriptor> getResizedMarker(String assetPath, int width) async {
//     ByteData data = await rootBundle.load(assetPath);

//     ui.Codec codec = await ui.instantiateImageCodec(
//       data.buffer.asUint8List(),
//       targetWidth: width, // Resize here
//     );

//     ui.FrameInfo fi = await codec.getNextFrame();

//     final Uint8List markerBytes = (await fi.image.toByteData(
//       format: ui.ImageByteFormat.png,
//     ))!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(markerBytes);
//   }

//   Future<void> _setPolyline() async {
//     if (pickup == null || drop == null) return;

//     PolylinePoints polylinePoints = PolylinePoints(
//       apiKey: NetworkConfig.googleApiKey2,
//     );

//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       // ignore: deprecated_member_use
//       request: PolylineRequest(
//         origin: PointLatLng(pickup!.latitude, pickup!.longitude),
//         destination: PointLatLng(drop!.latitude, drop!.longitude),
//         mode: TravelMode.driving,
//       ),
//     );

//     if (result.points.isNotEmpty) {
//       _routePoints = result.points
//           .map((p) => LatLng(p.latitude, p.longitude))
//           .toList();
//       setState(() {});
//       LatLngBounds bounds = LatLngBounds(
//         southwest: LatLng(
//           pickup!.latitude < drop!.latitude ? pickup!.latitude : drop!.latitude,
//           pickup!.longitude < drop!.longitude
//               ? pickup!.longitude
//               : drop!.longitude,
//         ),
//         northeast: LatLng(
//           pickup!.latitude > drop!.latitude ? pickup!.latitude : drop!.latitude,
//           pickup!.longitude > drop!.longitude
//               ? pickup!.longitude
//               : drop!.longitude,
//         ),
//       );

//       if (_mapController != null) {
//         _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final loading = controller.specificLoading.value;
//       final response = controller.specificVehicle.value;

//       return DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.95,
//         maxChildSize: 0.95,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: Column(
//               children: [
//                 // ---------- HEADER ----------
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Vehicle tracking',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1E3263),
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.close, color: Colors.grey),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                 ),

//                 Expanded(
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     child: loading
//                         ? SizedBox(
//                             height: 300,
//                             child: Center(child: CircularProgressIndicator()),
//                           )
//                         : response == null
//                         ? SizedBox(
//                             height: 200,
//                             child: Center(
//                               child: Text("No tracking data found"),
//                             ),
//                           )
//                         : Column(
//                             children: [
//                               Container(
//                                 margin: EdgeInsets.symmetric(horizontal: 16),
//                                 height: 250,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.grey.shade300,
//                                   ),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: GoogleMap(
//                                     initialCameraPosition: CameraPosition(
//                                       target: pickup ?? LatLng(0, 0),
//                                       zoom: 12,
//                                     ),
//                                     onMapCreated: (controller) {
//                                       _mapController = controller;
//                                       if (_routePoints.isNotEmpty) {
//                                         _setPolyline();
//                                       }
//                                     },
//                                     markers: {
//                                       // Pickup Marker
//                                       if (pickup != null)
//                                         Marker(
//                                           markerId: MarkerId("pickup"),
//                                           position: pickup!,
//                                           infoWindow: InfoWindow(
//                                             title: "Pickup",
//                                           ),
//                                         ),

//                                       // Drop Marker
//                                       if (drop != null)
//                                         Marker(
//                                           markerId: MarkerId("drop"),
//                                           position: drop!,
//                                           infoWindow: InfoWindow(title: "Drop"),
//                                         ),

//                                       // DRIVER LIVE MARKER
//                                       if (driverLocation != null &&
//                                           carIcon != null)
//                                         Marker(
//                                           markerId: MarkerId("driver"),
//                                           position: driverLocation!,
//                                           icon: carIcon!,
//                                           infoWindow: InfoWindow(
//                                             title: response
//                                                 .data!
//                                                 .driverLocation
//                                                 .name,
//                                           ),
//                                         ),
//                                     },
//                                     polylines: {
//                                       if (_routePoints.isNotEmpty)
//                                         Polyline(
//                                           polylineId: PolylineId(
//                                             "route_polyline",
//                                           ),
//                                           points: _routePoints,
//                                           color: Colors.blue,
//                                           width: 5
//                                         ),
//                                     },
//                                   ),
//                                 ),
//                               ),

//                               SizedBox(height: 20),

//                               // ---------- DELIVERY UPDATES ----------
//                               Padding(
//                                 padding: EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Delivery Updates',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 16,
//                                         color: Colors.black87,
//                                       ),
//                                     ),
//                                     SizedBox(height: 8),
//                                     Text(
//                                       'Order placed at ${response.data!.deliveryUpdates.orderPlacedDate}, ${response.data!.deliveryUpdates.orderPlacedTime}',
//                                       style: TextStyle(color: Colors.black54),
//                                     ),
//                                     SizedBox(height: 8),
//                                     Text(
//                                       'Delivery Expected on ${response.data!.deliveryUpdates.deliveryExpected}',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               // ---------- TIMELINE ----------
//                               Padding(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 24,
//                                   vertical: 8,
//                                 ),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // LEFT DOTS
//                                     Column(
//                                       children: List.generate(
//                                         response.data!.timeline.length,
//                                         (index) {
//                                           final isLast =
//                                               index ==
//                                               response.data!.timeline.length -
//                                                   1;

//                                           final icon = index == 0
//                                               ? 'assets/images/map.png'
//                                               : index == 1
//                                               ? 'assets/images/pickup_image.png'
//                                               : 'assets/images/success.png';

//                                           return Column(
//                                             children: [
//                                               Container(
//                                                 width: 24,
//                                                 height: 24,
//                                                 margin: EdgeInsets.only(
//                                                   top: 4,
//                                                   bottom: 4,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   color: isLast
//                                                       ? Colors.green
//                                                       : Colors.grey[400],
//                                                   shape: BoxShape.circle,
//                                                 ),
//                                                 child: Image.asset(icon),
//                                               ),
//                                               if (!isLast)
//                                                 Container(
//                                                   width: 2,
//                                                   height: 50,
//                                                   color: Colors.grey[300],
//                                                 ),
//                                             ],
//                                           );
//                                         },
//                                       ),
//                                     ),

//                                     SizedBox(width: 16),

//                                     // RIGHT CONTENT
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: response.data!.timeline.map((
//                                           item,
//                                         ) {
//                                           return Padding(
//                                             padding: EdgeInsets.only(
//                                               bottom:
//                                                   item ==
//                                                       response
//                                                           .data!
//                                                           .timeline
//                                                           .last
//                                                   ? 0
//                                                   : 20,
//                                             ),
//                                             child: Row(
//                                               children: [
//                                                 Expanded(
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Text(
//                                                         item.title,
//                                                         style: TextStyle(
//                                                           color: Colors.blue,
//                                                           fontSize: 14,
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         item.subtitle,
//                                                         style: TextStyle(
//                                                           fontWeight:
//                                                               FontWeight.w500,
//                                                           fontSize: 15,
//                                                         ),
//                                                       ),
//                                                       if (item.date != null)
//                                                         Text(
//                                                           item.date!,
//                                                           style: TextStyle(
//                                                             color:
//                                                                 Colors.black54,
//                                                             fontSize: 13,
//                                                           ),
//                                                         ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   item.time,
//                                                   style: TextStyle(
//                                                     color: Colors.black87,
//                                                     fontWeight: FontWeight.w500,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         }).toList(),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               // ---------- OKAY BUTTON ----------
//                               Padding(
//                                 padding: EdgeInsetsGeometry.all(12),
//                                 child: CustomButton(
//                                   text: 'Okay',
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                   },
//                                 ),
//                               ),
//                               SizedBox(height: 12),
//                             ],
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     });
//   }
// }
