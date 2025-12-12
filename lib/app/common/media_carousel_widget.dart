import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/widget/hachery_category_banner_widget.dart';
import 'package:video_player/video_player.dart';

class MediaCarouselWidget extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String>? mediaTypes;
  final String? mediaType;
  final double? height;
  final double? borderRadius;

  const MediaCarouselWidget({
    super.key,
    required this.mediaUrls,
    this.mediaTypes,
    this.mediaType,
    this.height,
    this.borderRadius,
  });

  @override
  State<MediaCarouselWidget> createState() => _MediaCarouselWidgetState();
}

class _MediaCarouselWidgetState extends State<MediaCarouselWidget> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius??0),
          child: CarouselSlider.builder(
            itemCount: widget.mediaUrls.length,
            carouselController: _carouselController,
            itemBuilder: (context, index, realIndex) {
              final type = widget.mediaTypes?[index] ?? widget.mediaType;
              final url = widget.mediaUrls[index];
              print('object');
              print(url);
              return type == "image"
                  ? _buildImage(url, widget.borderRadius ?? 12)
                  : _buildVideo(url, widget.borderRadius ?? 12, widget.height);
            },
            options: CarouselOptions(
              height: widget.height,
              enlargeCenterPage: true,
              viewportFraction:
                  (MediaQuery.of(context).size.width) / (widget.height ?? 180),
              onPageChanged: (index, reason) {
                setState(() => currentIndex = index);
              },
            ),
          ),
        ),

        /// --- INDICATOR DOTS ---
        Positioned(
          bottom: 8,
          child: Row(
            children: List.generate(widget.mediaUrls.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentIndex == index ? Colors.blue : Colors.grey,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String url, double borderRadius) {
    return GestureDetector(
      onTap: () {
        Get.dialog(
          InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius??30),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300], 
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  /// ---------------- VIDEO VIEW ----------------
  Widget _buildVideo(String url, double borderRadius, double? aspectRatio) {
    return GestureDetector(
      onTap: () {
        Get.to(() => FullScreenVideoPlayer(videoUrl: url,));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayerPreview(
              url: url,
              aspectRatio: aspectRatio,
              height: widget.height,
            ),
            const Icon(Icons.play_circle_fill, size: 65, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerPreview extends StatefulWidget {
  final String url;
  final double? aspectRatio;
  final double? height;
  final double? width;

  const VideoPlayerPreview({
    super.key,
    required this.url,
    this.aspectRatio,
    this.height,
    this.width,
  });

  @override
  State<VideoPlayerPreview> createState() => _VideoPlayerPreviewState();
}

class _VideoPlayerPreviewState extends State<VideoPlayerPreview> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        controller.setLooping(true);
        controller.setVolume(0);
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final width = MediaQuery.of(context).size.width;
    final height = width / controller.value.aspectRatio;
    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: widget.height ?? 350,
      child: FittedBox(
        fit: BoxFit.cover, // or BoxFit.fill if you want full stretch
        child: SizedBox(
          height: 350, // original video width
          width: MediaQuery.of(context).size.width, // original video height
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

/// ---------------- FULL SCREEN VIDEO ----------------
