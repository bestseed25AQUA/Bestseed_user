import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';
import 'package:seedsuser/app/utils/video_player.dart';
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

  // Check if URL is a video
  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m3u8') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');
  }

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
          // 🔍 Search Field
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
                    // filled: true,
                    // fillColor: Colors.grey[200],
                    // contentPadding: const EdgeInsets.symmetric(
                    //   horizontal: 16,
                    //   vertical: 16,
                    // ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

          // 📰 Grid of News
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
                  childAspectRatio: 1,
                ),
                itemCount:
                    newsSpecificController.newsSpecificData.value?.data?.length,
                itemBuilder: (context, index) {
                  final data = newsSpecificController
                      .newsSpecificData
                      .value
                      ?.data?[index];

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
                          subtitle: data?.curesFor ?? "",
                          imageUrl: data?.mediaPath ?? "",
                          tag: 'medicineNewScreen$index',
                        ),
                      ),
                    );
                  }

                  return _buildNewsCard(
                    data?.medicineName ?? '',
                    data?.curesFor ?? '',
                    data?.mediaPath ?? '',
                    'medicineNewScreen$index',
                    navigateToDetail,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNewsCard(
    String title,
    String? subtitle,
    String imageUrl,
    String tag,
    VoidCallback onTap,
  ) {
    final isVideo = _isVideoUrl(imageUrl);

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
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? InlineVideoPlayer(
                        url: imageUrl,
                        title: title,
                        height: 120,
                      )
                    : Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(height: 120, width: 150);
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title and subtitle - tappable to navigate to detail
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
      itemCount: 6, // show 6 shimmer items
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
              // IMAGE SHIMMER
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),

              // TITLE SHIMMER
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(height: 6),

              // SUBTITLE SHIMMER
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


