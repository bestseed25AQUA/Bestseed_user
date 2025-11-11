import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/seed_price/widget/seed_price_banner_bottom_widget.dart'; 
import 'package:video_player/video_player.dart';

class WantedBannerWidget extends StatefulWidget {
  const WantedBannerWidget({super.key});

  @override
  State<WantedBannerWidget> createState() => _WantedBannerWidgetState();
}

class _WantedBannerWidgetState extends State<WantedBannerWidget> {
  final WantedBannerController controller = Get.put(WantedBannerController());
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      } else if (controller.banners.isEmpty) {
        return const Center(child: Text("No banners available"));
      } else {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              itemCount: controller.banners.length,
              itemBuilder: (context, index, realIndex) {
                final banner = controller.banners[index];

                if (banner.type == "image") {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      banner.url,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  );
                } else if (banner.type == "video") {
                  return GestureDetector(
                    onTap: () => Get.to(() => FullScreenVideoPlayer(videoUrl: banner.url)),
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
                    _currentIndex = index;
                  });
                },
              ),
            ),

            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controller.banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key ? Colors.blue : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            )
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
        if (mounted) setState(() {});
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
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 70,
                )
              ],
            ),
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
