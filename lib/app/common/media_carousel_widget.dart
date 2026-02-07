import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/common/full_media_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaCarouselWidget extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String>? mediaTypes;
  final String? title;
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
    this.title,
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
        CarouselSlider.builder(
          itemCount: widget.mediaUrls.length,
          carouselController: _carouselController,
          itemBuilder: (context, index, realIndex) {
            final type = widget.mediaTypes?[index] ?? widget.mediaType;
            final url = widget.mediaUrls[index];
            return type == "image"
                ? _buildImage(
                    url,
                    widget.borderRadius ?? 12,
                    title: widget.title,
                    index: index,
                  )
                : _buildVideo(
                    url,
                    widget.borderRadius ?? 12,
                    widget.height,
                    widget.title,
                    index: index,
                  );
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

  void _openFullScreen(int index) {
    // Build media types list for full screen
    final types = widget.mediaTypes ??
        List.generate(widget.mediaUrls.length, (_) => widget.mediaType ?? 'image');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullMediaScreen(
          mediaUrls: widget.mediaUrls,
          mediaTypes: types,
          initialIndex: index,
          title: widget.title,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl, double borderRadius, {String? title, int index = 0}) {
    return GestureDetector(
      onTap: () => _openFullScreen(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
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
  Widget _buildVideo(
    String url,
    double borderRadius,
    double? aspectRatio,
    String? title, {
    int index = 0,
  }) {
    return GestureDetector(
      onTap: () => _openFullScreen(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayerPreview(
              url: url,
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
  final double? height;
  final double? width;

  const VideoPlayerPreview({
    super.key,
    required this.url,
    this.height,
    this.width,
  });

  @override
  State<VideoPlayerPreview> createState() => _VideoPlayerPreviewState();
}

class _VideoPlayerPreviewState extends State<VideoPlayerPreview> {
  Uint8List? thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await VideoThumbnail.thumbnailData(
      video: widget.url,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 350, // banner height
      quality: 75,
    );

    if (mounted) {
      setState(() => thumbnail = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: widget.height ?? 350,
      child: thumbnail == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(thumbnail!, fit: BoxFit.cover),

                // ▶ Play icon overlay (optional)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
