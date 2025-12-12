import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VehicleCardShimmer extends StatelessWidget {
  const VehicleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(  
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(12)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SHIMMER
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // ROUTE BAR SHIMMER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 30,
                width: double.infinity,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // TITLE SHIMMER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 18,
                width: 180,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // LOCATION ROW SHIMMER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 14,
                width: 140,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // DATE ROW SHIMMER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(height: 14, width: 80, color: Colors.white),
                  const SizedBox(width: 20),
                  Container(height: 14, width: 80, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SPACE AVAILABLE SHIMMER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(height: 18, width: 150, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // ACTION BUTTONS SHIMMER
            Row(
              children: [
                Expanded(child: Container(height: 45,decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12),bottomRight: Radius.circular(12))
                ) )),
                Expanded(child: Container(height: 45, color: Colors.white)),
                Expanded(child: Container(height: 45, decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12),bottomRight: Radius.circular(12))
                ),)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
