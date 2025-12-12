import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class HatcheryCategoryBannerWidget extends StatefulWidget {
  const HatcheryCategoryBannerWidget({super.key, required this.id});
  final String id;

  @override
  State<HatcheryCategoryBannerWidget> createState() =>
      _SpotHatcheryBannerWidgetState();
}

class _SpotHatcheryBannerWidgetState
    extends State<HatcheryCategoryBannerWidget> {
  final HatcheryCategoryController controller =
      Get.find<HatcheryCategoryController>();
  int _currentIndex = 0; // Track current banner index
  @override
  void initState() {
    controller.fetchBanners(widget.id);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
     if (controller.isLoading.value||controller.banners.isEmpty) {
        // return const Center(child: Text("No banners available"));
        return Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Shimmer.fromColors(
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
        );
      } else {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              itemCount: controller.banners.length,
              itemBuilder: (context, index, realIndex) {
                final banner = controller.banners[index];
                if (banner.type == "image") {
                  return GestureDetector(
                    onTap: () {
                      print('=========');
                      print(banner.url);
                      // Get.to(() => VehicleAvailabilityScreen());
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        banner.url,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else if (banner.type == "video") {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => FullScreenVideoPlayer(videoUrl: banner.url));
                    },
                    child: VideoPlayerBanner(url: banner.url),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
              options: CarouselOptions(
                height: 160,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index; // update current index
                  });
                },
              ),
            ),

            // Indicator Dots
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controller.banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors
                                .blue // Active dot
                          : Colors.grey, // Inactive dot
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }
    });
  }
}

class VideoPlayerBanner extends StatefulWidget {
  final String url;
  const VideoPlayerBanner({super.key, required this.url});

  @override
  State<VideoPlayerBanner> createState() => _VideoPlayerBannerState();
}

class _VideoPlayerBannerState extends State<VideoPlayerBanner> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        // _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),

              Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ],
          )
        : Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
  }
}
