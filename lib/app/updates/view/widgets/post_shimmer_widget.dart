import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:shimmer/shimmer.dart';

Widget postShimmerCard() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      // color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 Header Row (avatar + name + date)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 80, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // 🔵 Caption Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(height: 12, width: 200, color: Colors.white),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔵 Hashtags Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(height: 14, width: 150, color: Colors.white),
          ),

          const SizedBox(height: 12),

          // 🔵 Media Carousel Placeholder
          Container(height: 250, width: double.infinity, color: Colors.white),

          const SizedBox(height: 12),

          // 🔵 Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🔵 Action Bar (call, whatsapp, facebook, share)
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Row(
          //         children: [
          //           Container(
          //             decoration: BoxDecoration(
          //               borderRadius: BorderRadius.circular(15),
          //               color: Colors.white,
          //             ),
          //             height: 30,
          //             width: 30,
          //           ),
          //           const SizedBox(width: 12),
          //           Container(
          //             decoration: BoxDecoration(
          //               borderRadius: BorderRadius.circular(15),
          //               color: Colors.white,
          //             ),
          //             height: 30,
          //             width: 30,
          //           ),
          //           const SizedBox(width: 12),
          //           Container(
          //             decoration: BoxDecoration(
          //               borderRadius: BorderRadius.circular(15),
          //               color: Colors.white,
          //             ),
          //             height: 30,
          //             width: 30,
          //           ),
          //         ],
          //       ),

          //       Container(height: 20, width: 60, color: Colors.white),
          //     ],
          //   ),
          // ),
        ],
      ),
    ),
  );
}
