import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholders for the Farm Management screens.
///
/// These stand in for content while it loads, so the screen keeps its shape
/// instead of collapsing to a spinner and then jumping back. Each skeleton
/// mirrors the real widget it replaces — same rough heights and spacing — so
/// nothing shifts when the data arrives.
///
/// Scoped to Farm Management on purpose; the rest of the app still uses its
/// own loading indicators.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

/// One grey block. Everything else here is built from these.
class ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder for the farm cards on the Farm Management list.
class FarmListShimmer extends StatelessWidget {
  final int itemCount;

  const FarmListShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBlock(height: 150, radius: 10),
              SizedBox(height: 14),
              Row(
                children: [
                  ShimmerBlock(width: 90, height: 26, radius: 6),
                  SizedBox(width: 10),
                  ShimmerBlock(width: 90, height: 26, radius: 6),
                ],
              ),
              SizedBox(height: 14),
              ShimmerBlock(width: 140, height: 18),
              SizedBox(height: 10),
              ShimmerBlock(width: 200, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for the tank grid on the farm detail screen.
class TankGridShimmer extends StatelessWidget {
  final int itemCount;

  const TankGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the per-day feed cards on the tank history screen.
class TankHistoryShimmer extends StatelessWidget {
  final int itemCount;

  const TankHistoryShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 26, 16, 26),
              child: ShimmerBlock(width: 120, height: 24),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ShimmerBlock(height: 74, radius: 12),
            ),
            ...List.generate(
              itemCount,
              (_) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBlock(width: 120, height: 18),
                        ShimmerBlock(width: 60, height: 18),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ShimmerBlock(height: 42)),
                        SizedBox(width: 8),
                        Expanded(child: ShimmerBlock(height: 42)),
                        SizedBox(width: 8),
                        ShimmerBlock(width: 84, height: 42, radius: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the people/code lists — managers, partners, QR codes,
/// scanned details and the access management screen.
class ListTileShimmer extends StatelessWidget {
  final int itemCount;
  final double height;

  const ListTileShimmer({super.key, this.itemCount = 5, this.height = 76});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
