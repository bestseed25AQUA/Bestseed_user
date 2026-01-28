import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerHelper {
  /// Load truck marker from asset with fallback to canvas-drawn marker
  static Future<BitmapDescriptor> getTruckMarkerFromAsset({int size = 60}) async {
    try {
      final ByteData data = await rootBundle.load('assets/images/vehicle_truck.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading truck marker from asset: $e');
    }

    // Fallback: Create a canvas-drawn truck marker
    return _createCanvasTruckMarker(size);
  }

  /// Load start/pickup location marker from asset with fallback
  static Future<BitmapDescriptor> getStartLocationMarkerFromAsset({int size = 30}) async {
    try {
      final ByteData data = await rootBundle.load('assets/images/pickup_vehicle_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading start location marker from asset: $e');
    }

    // Fallback: Green pin marker
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  /// Load drop/destination location marker from asset with fallback
  static Future<BitmapDescriptor> getDropLocationMarkerFromAsset({int size = 30}) async {
    try {
      final ByteData data = await rootBundle.load('assets/images/drop_vehicle_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading drop location marker from asset: $e');
    }

    // Fallback: Red pin marker
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  /// Create a canvas-drawn truck marker as fallback
  static Future<BitmapDescriptor> _createCanvasTruckMarker(int size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double s = size.toDouble();

    // Draw blue circle background
    final Paint bgPaint = Paint()..color = const Color(0xFF0077C8);
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2, bgPaint);

    // Draw white truck icon
    final Paint iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Simplified truck shape
    final Path truckPath = Path();
    final double padding = s * 0.25;
    final double truckWidth = s - (padding * 2);
    final double truckHeight = truckWidth * 0.6;
    final double startX = padding;
    final double startY = (s - truckHeight) / 2;

    // Truck body
    truckPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, startY, truckWidth * 0.7, truckHeight),
      Radius.circular(s * 0.05),
    ));

    // Truck cabin
    truckPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startX + truckWidth * 0.7,
        startY + truckHeight * 0.3,
        truckWidth * 0.3,
        truckHeight * 0.7,
      ),
      Radius.circular(s * 0.05),
    ));

    canvas.drawPath(truckPath, iconPaint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }
}
