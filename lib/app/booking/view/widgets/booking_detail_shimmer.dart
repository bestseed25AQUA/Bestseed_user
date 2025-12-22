import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BookingDetailShimmer extends StatelessWidget {
  const BookingDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ---------- STATUS BOX ----------
            _box(height: 90, radius: 14),

            const SizedBox(height: 24),

            // ---------- TITLE ----------
            _box(width: 160, height: 18),

            const SizedBox(height: 16),

            // ---------- DETAILS ----------
            ...List.generate(4, (index) => _detailRow()),

            const SizedBox(height: 24),

            // ---------- TIMELINE ----------
            _box(width: 140, height: 16),
            const SizedBox(height: 10),
            _box(width: double.infinity, height: 14),
            const SizedBox(height: 20),

            ...List.generate(3, (index) => _timelineRow()),

            const SizedBox(height: 24),

            // ---------- BUTTON ----------
            _box(width: double.infinity, height: 48, radius: 30),

            const SizedBox(height: 30),

            // ---------- HELP ----------
            Align(
              alignment: Alignment.center,
              child: _box(width: 200, height: 14),
            ),

            const SizedBox(height: 40),
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
        Column(children: [_circle(26), _line(40)]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 120, height: 16),
              const SizedBox(height: 6),
              _box(width: 90, height: 14),
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
        _box(width: 120, height: 14),
        const SizedBox(height: 6),
        _box(width: 140, height: 14),
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
  return Container(width: 2, height: height, color: Colors.white);
}
