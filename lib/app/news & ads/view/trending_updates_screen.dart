import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/trending_updates_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class TrendingUpdatesScreen extends StatefulWidget {
  const TrendingUpdatesScreen({super.key});

  @override
  State<TrendingUpdatesScreen> createState() => _TrendingUpdatesScreenState();
}

class _TrendingUpdatesScreenState extends State<TrendingUpdatesScreen> {
  final newsSpecificController = Get.put(NewsSpecificController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    newsSpecificController.fetch('trending update');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'Trending updates',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
            if (newsSpecificController.isLoading.value) {
              return trendingUpdatesShimmer();
            }

            if ((newsSpecificController.newsSpecificData.value?.data?.length ??
                    0) ==
                0) {
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * .3,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text('No Trending Updates Availables'),
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  newsSpecificController.newsSpecificData.value?.data?.length ??
                      0,
                  (index) {
                    final data = newsSpecificController
                        .newsSpecificData
                        .value
                        ?.data?[index];

                    final mediaUrls = data?.mediaFiles ?? [data?.mediaPath ?? ''];
                    final mediaTypes = data?.mediaTypes ?? [data?.mediaType ?? 'image'];

                    return Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 6),
                            child: MiniMediaCarousel(
                              mediaUrls: mediaUrls,
                              mediaTypes: mediaTypes,
                              height: 180,
                              borderRadius: 12,
                              onTap: () {
                                Get.to(
                                  () => TrendingUpdatesDetailsScreen(
                                    id: data?.id.toString() ?? '',
                                    title: data?.title ?? '',
                                  ),
                                );
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              data?.title ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          }),
          ),
        ),
      ),
    );
  }
}

Widget trendingUpdatesShimmer() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(6, (index) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE / VIDEO CONTAINER SHIMMER
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // TITLE SHIMMER
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}
