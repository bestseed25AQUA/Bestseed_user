import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/controller/best_deals_controller.dart';
import 'package:seedsuser/app/best_deals/view/best_deal_detail_screen.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';

class BestDealsScreen extends StatefulWidget {
  const BestDealsScreen({super.key});

  @override
  State<BestDealsScreen> createState() => _BestDealsScreenState();
}

class _BestDealsScreenState extends State<BestDealsScreen> {
  final controller = Get.put(BestDealsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Best Deals',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer();
        }

        final deals = controller.bestDealsData.value?.data;
        if (deals == null || deals.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * .3,
              ),
              child: const Text('No Best Deals Available'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchList(),
          child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            final mediaUrls = deal.mediaFiles ?? [deal.mediaPath ?? ''];
            final mediaTypes =
                deal.mediaTypes ?? [deal.mediaType ?? 'image'];

            return GestureDetector(
              onTap: () {
                Get.to(() => BestDealDetailScreen(
                      id: deal.id.toString(),
                      title: deal.title ?? '',
                      subtitle: deal.subtitle ?? '',
                      imageUrl: deal.mediaPath ?? '',
                    ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MiniMediaCarousel(
                        mediaUrls: mediaUrls,
                        mediaTypes: mediaTypes,
                        height: 180,
                        borderRadius: 12,
                        onTap: () {
                          Get.to(() => BestDealDetailScreen(
                                id: deal.id.toString(),
                                title: deal.title ?? '',
                                subtitle: deal.subtitle ?? '',
                                imageUrl: deal.mediaPath ?? '',
                              ));
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      deal.title ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (deal.subtitle != null &&
                        deal.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deal.subtitle!,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        );
      }),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
