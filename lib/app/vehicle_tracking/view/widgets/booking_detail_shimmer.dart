import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookingDetailsShimmer extends StatelessWidget {
  const BookingDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.02),

            // ---------- STATUS BOX ----------
            _box(height: 90, radius: 12),

            SizedBox(height: h * 0.03),

            // ---------- LOCATION CARD ----------
            _box(height: 140, radius: 14),

            const SizedBox(height: 25),

            // ---------- TITLE ----------
            _box(width: 200, height: 18),

            const SizedBox(height: 16),

            // ---------- DETAILS ----------
            ...List.generate(4, (_) => _detailRow()),

            const SizedBox(height: 24),

            // ---------- TIMELINE TITLE ----------
            _box(width: 220, height: 16),
            const SizedBox(height: 6),
            _box(width: double.infinity, height: 14),

            const SizedBox(height: 20),

            // ---------- TIMELINE STEPS ----------
            ...List.generate(3, (_) => _timelineRow()),

            const SizedBox(height: 30),

            // ---------- BUTTON ----------
            _box(width: double.infinity, height: 48, radius: 30),

            const SizedBox(height: 30),

            // ---------- HELP ----------
            Align(
              alignment: Alignment.center,
              child: _box(width: 220, height: 14),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
Widget _timelineRow() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _circle(26),
            _line(40),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 180, height: 16),
              const SizedBox(height: 6),
              _box(width: 120, height: 14),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _detailRow() {
  return Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(width: 140, height: 14),
        const SizedBox(height: 6),
        _box(width: double.infinity, height: 14),
      ],
    ),
  );
}
Widget _box({
  double width = double.infinity,
  double height = 14,
  double radius = 8,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(width: 1),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget _circle(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

Widget _line(double height) {
  return Container(
    width: 2,
    height: height,
    color: Colors.white,
  );
}
