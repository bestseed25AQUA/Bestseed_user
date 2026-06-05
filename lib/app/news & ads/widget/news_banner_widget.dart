import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_banner_controller.dart';
import 'package:seedsuser/app/common/safe_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class NewsBannerWidget extends StatefulWidget {
  const NewsBannerWidget({super.key});

  @override
  State<NewsBannerWidget> createState() => _NewsBannerWidgetState();
}

class _NewsBannerWidgetState extends State<NewsBannerWidget> {
  final NewsBannerController controller = Get.put(NewsBannerController());
  int _currentIndex = 0; // Track current banner index

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        // return const Center(child: CircularProgressIndicator());
        return SizedBox();
      } else if (controller.banners.isEmpty) {
        // return const Center(child: Text("No banners available"));
        return SizedBox();
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeNetworkImage(
                        imageUrl: banner.url,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.fill,
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

class _VideoPlayerBannerState extends State<VideoPlayerBanner>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _isInitialized = false;

  // Debounced buffering — only show spinner after 800ms of continuous buffering
  bool _showBuffering = false;
  Timer? _bufferingDebounce;
  bool _lastRawBuffering = false;

  bool _wasPlayingBeforePause = false;

  String get _tag => 'VideoPlayerBanner[${widget.url.split('/').last.split('?').first}]';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('$_tag: initState');
    _initVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasPlayingBeforePause = c.value.isPlaying;
      debugPrint('$_tag: lifecycle → background (wasPlaying=$_wasPlayingBeforePause)');
      if (_wasPlayingBeforePause) c.pause();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('$_tag: lifecycle → resumed');
      if (_wasPlayingBeforePause) c.play();
    }
  }

  Future<void> _initVideo() async {
    try {
      debugPrint('$_tag: initializing...');
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller!.addListener(_onUpdate);
      await _controller!.initialize();
      if (mounted) {
        debugPrint('$_tag: initialized — duration=${_controller!.value.duration.inSeconds}s, starting playback');
        _controller!.setVolume(0);
        _controller!.setLooping(true);
        _controller!.play();
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('$_tag: init FAILED: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onUpdate() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;

    // --- Debounced buffering ---
    final rawBuffering = v.isBuffering;
    if (rawBuffering != _lastRawBuffering) {
      _lastRawBuffering = rawBuffering;
      _bufferingDebounce?.cancel();
      if (rawBuffering) {
        _bufferingDebounce = Timer(const Duration(milliseconds: 800), () {
          if (mounted && _lastRawBuffering) {
            debugPrint('$_tag: buffering confirmed (>800ms) pos=${v.position.inMilliseconds}ms');
            setState(() => _showBuffering = true);
          }
        });
      } else {
        if (_showBuffering) {
          debugPrint('$_tag: buffering ended pos=${v.position.inMilliseconds}ms');
          setState(() => _showBuffering = false);
        }
      }
    }

    if (v.hasError && !_hasError) {
      debugPrint('$_tag: ERROR from controller: ${v.errorDescription}');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    debugPrint('$_tag: dispose');
    WidgetsBinding.instance.removeObserver(this);
    _bufferingDebounce?.cancel();
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 70),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Shimmer.fromColors(
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

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (_showBuffering)
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          if (!_showBuffering)
            Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 70,
              ),
            ),
        ],
      ),
    );
  }
}
