import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/seed_price/controller/seed_banner_controller.dart';
import 'package:seedsuser/app/common/safe_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class SeedPriceBannerWidget extends StatefulWidget {
  const SeedPriceBannerWidget({super.key});

  @override
  State<SeedPriceBannerWidget> createState() => _SeedPriceBannerWidgetState();
}

class _SeedPriceBannerWidgetState extends State<SeedPriceBannerWidget> {
  final SeedBannerController controller = Get.put(SeedBannerController());

  int _currentIndex = 0; // Track current banner index

  @override
  void initState() {
    super.initState();
    if (controller.banners.isEmpty) {
      controller.fetchBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value || controller.banners.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,

            child: Container(
              height: 150,
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
                      // Get.to(() => VehicleAvailabilityScreen());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(1)),
                          color: Colors.grey.withOpacity(.2),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 2,
                              // offset: Offset(2, 3)
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SafeNetworkImage(
                            imageUrl: banner.url,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.fill,
                          ),
                        ),
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
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0);
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
        : Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
  }
}
