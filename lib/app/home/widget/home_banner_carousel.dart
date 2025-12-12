import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/broadstock/view/broad_stock_screen.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/utils/app_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final HomeBannerController controller = Get.put(HomeBannerController());

  // ✅ Correct Controller
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int _currentIndex = 0;
  bool _firstBannerDone = false;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _startFirstDelay();
  }

  void _startFirstDelay() {
    // First banner stay for 30 sec
    _sliderTimer = Timer(const Duration(seconds: 50), () {
      _firstBannerDone = true;
      _startNormalAutoSlide();
    });
  }

  void _startNormalAutoSlide() {
    // Slide every 3 seconds
    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _carouselController.nextPage();
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
        if (controller.isLoading.value || controller.banners.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
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
        }  else {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: controller.banners.length,

              itemBuilder: (context, index, realIndex) {
                final banner = controller.banners[index];

                if (banner.type == "image") {
                  return GestureDetector(
                    onTap: () {
                      // Determine this banner's index among image-type banners
                      final imageCountBefore = controller.banners
                          .sublist(0, index)
                          .where((b) => b.type == "image")
                          .length;
                      if (imageCountBefore == 0) {
                        Navigator.push(context, AppAnimations.fade(VehicleAvailabilityScreen()));
                      } else if (imageCountBefore == 1) {
                        Get.to(() => SeedRequestsFormScreen());
                      } else if (imageCountBefore == 2) {
                        Get.to(() => BroodStockScreen());
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          banner.url,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              // ignore: deprecated_member_use
                              Container(color: Colors.grey.withOpacity(.3)),
                        ),
                      ),
                    ),
                  );
                }
                // Video Banner
                return GestureDetector(
                  onTap: () {
                    Get.to(() => FullScreenVideoPlayer(videoUrl: banner.url));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: VideoPlayerBanner(url: banner.url),
                  ),
                );
              },

              options: CarouselOptions(
                height: 160,
                viewportFraction: 0.9,
                enlargeCenterPage: true,
                autoPlay: false, // ❌ TURN OFF AUTOPLAY

                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),

            Positioned(
              bottom: 10,
              child: Row(
                children: controller.banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.blue
                          : Colors.grey,
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

              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 70,
                  ),
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
