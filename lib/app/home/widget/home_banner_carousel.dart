import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/broadstock/view/broad_stock_screen.dart';
import 'package:seedsuser/app/home/controller/home_banner_controller.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/utils/app_animations.dart';
import 'package:seedsuser/app/utils/app_size.dart';
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
    final double heightCarousel = AppSize.height*.15;
    return Obx(() {
        if (controller.isLoading.value || controller.banners.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,

              child: Container(
                height: heightCarousel,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        banner.url,
                        headers: const {'Accept': 'image/*,*/*'},
                        width: double.infinity,
                        height: heightCarousel,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, error) {
                          debugPrint('⚠️ Banner image FAILED: ${banner.url} → $error');
                          // ignore: deprecated_member_use
                          return Container(color: Colors.grey.withOpacity(.3));
                        },
                      ),
                    ),
                  );
                }
                // Video Banner
                return GestureDetector(
                  onTap: () {
                    Get.to(() => FullScreenVideoPlayer(videoUrl: banner.url));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayerBanner(
                      url: banner.url,
                      height: heightCarousel,
                    ),
                  ),
                );
              },

              options: CarouselOptions(
                height: heightCarousel,
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
  final double height;
  const VideoPlayerBanner({super.key, required this.url, required this.height});

  @override
  State<VideoPlayerBanner> createState() => _VideoPlayerBannerState();
}

class _VideoPlayerBannerState extends State<VideoPlayerBanner> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoUrl =  widget.url.trim();

    if (videoUrl.isEmpty) {
      print('VideoPlayerBanner: ERROR - Video URL is empty!');
      if (mounted) setState(() => _hasError = true);
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(videoUrl);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) {
        throw FormatException('Invalid URL scheme');
      }
    } catch (e) {
      print('VideoPlayerBanner: ERROR - Invalid URL: $videoUrl');
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      print('VideoPlayerBanner: Initializing video: $videoUrl');
      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
      );
      await _controller!.initialize();
      _controller!.setVolume(0);
      _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      print('VideoPlayerBanner: Video initialized successfully');
    } catch (e) {
      print('VideoPlayerBanner: Video initialization error!');
      print('VideoPlayerBanner: URL = $videoUrl');
      print('VideoPlayerBanner: Error = $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state on top of the loading shimmer so the banner area
    // never goes black — even when the video URL fails or the decoder dies
    // mid-init, the user sees a graceful shimmer + "Tap to play" recovery.
    if (_hasError) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.white),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill,
                        color: Colors.grey.shade600, size: 60),
                    const SizedBox(height: 8),
                    Text('Tap to play',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isInitialized && _controller != null
        ? Stack(
            children: [
              SizedBox(
                height: widget.height,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
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
              height: widget.height-10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
  }
}
