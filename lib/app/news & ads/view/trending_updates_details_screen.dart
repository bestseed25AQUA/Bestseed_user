import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/full_media_screen.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news & ads/controller/single_new_detail_controller.dart';
import 'package:shimmer/shimmer.dart';

class TrendingUpdatesDetailsScreen extends StatefulWidget {
  final String id;
  final String title;

  const TrendingUpdatesDetailsScreen({
    super.key,
    required this.id,
    required this.title,
  });

  @override
  State<TrendingUpdatesDetailsScreen> createState() =>
      _TrendingUpdatesDetailsScreenState();
}

class _TrendingUpdatesDetailsScreenState
    extends State<TrendingUpdatesDetailsScreen> {
  final controller = Get.put(SingleNewDetailController());

  // Guards against repeatedly auto-pushing the fullscreen route every time
  // the Obx rebuilds (e.g. when the user closes fullscreen and lands back
  // on this screen — the isLoading→false transition would fire again).
  bool _didAutoOpenFullscreen = false;

  @override
  void initState() {
    super.initState();

    controller.fetch(type: "trending update", id: widget.id);
  }

  /// If the post's first media is a video, immediately push the full-screen
  /// player once. The user then sees the video in fullscreen right away; on
  /// back they land on THIS detail screen (small preview + text). This
  /// matches the requested UX of "tap video in view-all → fullscreen →
  /// back → small screen with text below".
  void _maybeAutoOpenFullscreen(List<String> mediaUrls, List<String> mediaTypes) {
    if (_didAutoOpenFullscreen) return;
    if (mediaUrls.isEmpty) return;
    final firstType = (mediaTypes.isNotEmpty ? mediaTypes.first : '').toLowerCase();
    final firstUrl = mediaUrls.first.toLowerCase();
    final isVideo = firstType.contains('video') ||
        firstUrl.endsWith('.mp4') ||
        firstUrl.endsWith('.mov') ||
        firstUrl.endsWith('.m3u8') ||
        firstUrl.endsWith('.webm') ||
        firstUrl.endsWith('.avi');
    if (!isVideo) return;
    _didAutoOpenFullscreen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullMediaScreen(
            mediaUrls: mediaUrls,
            mediaTypes: mediaTypes,
            initialIndex: 0,
            title: widget.title,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return trendingUpdatesShimmer();
      }
      final data = controller.singleDetailData.value?.data;

      if (data == null) {
        return const Scaffold(body: Center(child: Text("No Data Found")));
      }

      // PREPARE LISTS FOR CAROUSEL (use multi-media arrays with fallback)
      final mediaUrls = (data.mediaFiles != null && data.mediaFiles!.isNotEmpty)
          ? data.mediaFiles!
          : [data.mediaPath ?? ""];
      final mediaTypes = (data.mediaTypes != null && data.mediaTypes!.isNotEmpty)
          ? data.mediaTypes!
          : [data.mediaType ?? "image"];

      // Auto-open full-screen player once, if the first media is a video.
      // Scheduled via postFrameCallback inside the method so it fires after
      // the initial build settles.
      _maybeAutoOpenFullscreen(mediaUrls, mediaTypes);

      return Scaffold(
        appBar: CustomAppBar(
          backgroundColor: Colors.blue[800],
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            data.title ?? "",
            style: GoogleFonts.roboto(color: Colors.white),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MediaCarouselWidget(
                    mediaUrls: mediaUrls,
                    mediaTypes: mediaTypes,
                    borderRadius: 12, // optional, but keep consistent
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18, top: 8),
                child: Text(
                  data.title ?? "",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18),
                child: Text(
                  data.description ?? "",
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

Widget trendingUpdatesShimmer() {
  return Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          // IMAGE / CAROUSEL SHIMMER
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TITLE SHIMMER
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 22,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // MULTILINE DESCRIPTION SHIMMER
          Column(
            children: List.generate(8, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}
