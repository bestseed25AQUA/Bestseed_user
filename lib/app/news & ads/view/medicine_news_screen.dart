import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class MedicineNewsScreen extends StatefulWidget {
  const MedicineNewsScreen({super.key});

  @override
  State<MedicineNewsScreen> createState() => _MedicineNewsScreenState();
}

class _MedicineNewsScreenState extends State<MedicineNewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final newsSpecificController = Get.put(NewsSpecificController());
  List<Map<String, String>> allNews = [];
  List<Map<String, String>> filteredNews = [];

  @override
  void initState() {
    super.initState();
    newsSpecificController.fetch('medicine news');
  }

  void _filterNews(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredNews = List.from(allNews);
      } else {
        filteredNews = allNews
            .where(
              (item) =>
                  item["title"]!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }
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
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'Medicine News',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterNews,
                  decoration: InputDecoration(
                    hintText: 'Search medicine news...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

          Obx(() {
            if (newsSpecificController.isLoading.value) {
              return medicineNewsShimmer();
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
                  child: Text('No Medicine News Availables'),
                ),
              );
            }
            return Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 0.95,
                ),
                itemCount:
                    newsSpecificController.newsSpecificData.value?.data?.length,
                itemBuilder: (context, index) {
                  final data = newsSpecificController
                      .newsSpecificData
                      .value
                      ?.data?[index];

                  final mediaUrls = data?.mediaFiles ?? [data?.mediaPath ?? ''];
                  final mediaTypes = data?.mediaTypes ?? [data?.mediaType ?? 'image'];

                  void navigateToDetail() {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(
                          milliseconds: 600,
                        ),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 600,
                        ),
                        pageBuilder: (_, __, ___) => MedicineDetailScreen(
                          id: data?.id.toString() ?? '',
                          title: data?.medicineName.toString() ?? '',
                          subtitle: data?.subtitle ?? data?.curesFor ?? "",
                          imageUrl: data?.mediaPath ?? "",
                          tag: 'medicineNewScreen$index',
                        ),
                      ),
                    );
                  }

                  return _buildNewsCard(
                    title: data?.medicineName ?? '',
                    subtitle: data?.subtitle ?? data?.curesFor ?? '',
                    mediaUrls: mediaUrls,
                    mediaTypes: mediaTypes,
                    onTap: navigateToDetail,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    String? subtitle,
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(.7),
              border: Border.all(width: .1, color: Colors.grey),
              boxShadow: [BoxShadow(color: Colors.grey)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MiniMediaCarousel(
                mediaUrls: mediaUrls,
                mediaTypes: mediaTypes,
                height: 120,
                borderRadius: 12,
                onTap: onTap,
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget medicineNewsShimmer() {
  return Expanded(
    child: GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
