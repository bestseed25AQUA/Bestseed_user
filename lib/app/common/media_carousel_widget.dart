import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:seedsuser/app/common/full_media_screen.dart';
import 'package:seedsuser/app/utils/video_thumbnail_cache.dart';

class MediaCarouselWidget extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String>? mediaTypes;
  // Backend-provided posters, index-aligned with [mediaUrls]. A non-empty entry
  // for a video makes the carousel show it instead of generating one on-device.
  final List<String>? thumbnailUrls;
  final String? title;
  final String? mediaType;
  final double? height;
  final double? borderRadius;

  const MediaCarouselWidget({
    super.key,
    required this.mediaUrls,
    this.mediaTypes,
    this.thumbnailUrls,
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
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.mediaUrls.length > 1,
            scrollPhysics: widget.mediaUrls.length <= 1
                ? const NeverScrollableScrollPhysics()
                : null,
            onPageChanged: (index, reason) {
              setState(() => currentIndex = index);
            },
          ),
        ),

        /// --- INDICATOR DOTS (only when multiple items) ---
        if (widget.mediaUrls.length > 1)
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
          fit: BoxFit.cover,
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
    // Inline lazy playback: the poster is shown until the user taps play. Only
    // then is the video fetched and, once it starts, the poster is removed.
    // The fullscreen button still opens the immersive player.
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: VideoPlayerPreview(
        url: url,
        height: widget.height,
        inlinePlay: true,
        onFullscreen: () => _openFullScreen(index),
        thumbnailUrl: (widget.thumbnailUrls != null &&
                index < widget.thumbnailUrls!.length)
            ? widget.thumbnailUrls![index]
            : null,
      ),
    );
  }
}

/// Lightweight carousel for list/grid cards - uses PageView with dots.
/// Tapping any media calls [onTap]. Shows dots only when multiple media.
class MiniMediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final double height;
  final double? width;
  final VoidCallback? onTap;
  final double borderRadius;

  const MiniMediaCarousel({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
    required this.height,
    this.width,
    this.onTap,
    this.borderRadius = 12,
  });

  @override
  State<MiniMediaCarousel> createState() => _MiniMediaCarouselState();
}

class _MiniMediaCarouselState extends State<MiniMediaCarousel> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Prefetch posters for any videos so they appear instantly on scroll.
    final videoUrls = <String>[];
    for (var i = 0; i < widget.mediaUrls.length; i++) {
      final url = widget.mediaUrls[i];
      final type = i < widget.mediaTypes.length ? widget.mediaTypes[i] : 'image';
      if (type == 'video' || _isVideoUrl(url)) videoUrls.add(url);
    }
    if (videoUrls.isNotEmpty) VideoThumbnailCache.instance.warm(videoUrls);
  }

  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m3u8') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return SizedBox(height: widget.height, width: widget.width);
    }

    if (widget.mediaUrls.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: _buildMediaItem(widget.mediaUrls[0],
              widget.mediaTypes.isNotEmpty ? widget.mediaTypes[0] : 'image'),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: widget.height,
            width: widget.width,
            child: PageView.builder(
              itemCount: widget.mediaUrls.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final url = widget.mediaUrls[index];
                final type = index < widget.mediaTypes.length
                    ? widget.mediaTypes[index]
                    : 'image';
                return GestureDetector(
                  onTap: widget.onTap,
                  child: _buildMediaItem(url, type),
                );
              },
            ),
          ),
          Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.mediaUrls.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == i ? Colors.blue : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String url, String type) {
    if (type == 'video' || _isVideoUrl(url)) {
      return VideoPlayerPreview(
        url: url,
        height: widget.height,
        width: widget.width,
      );
    }
    return Image.network(
      url,
      height: widget.height,
      width: widget.width ?? double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: widget.height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}

class VideoPlayerPreview extends StatefulWidget {
  final String url;
  final double? height;
  final double? width;
  // Backend-provided poster for this video. When present we render it directly
  // and skip the expensive on-device thumbnail generation entirely.
  final String? thumbnailUrl;
  // When true the poster is a tap-to-play affordance: the video is only fetched
  // once the user taps, and the poster is removed the moment playback starts.
  // When false (default) this is a static poster and the parent handles taps.
  final bool inlinePlay;
  // Opens the immersive fullscreen player (inlinePlay only).
  final VoidCallback? onFullscreen;

  const VideoPlayerPreview({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.thumbnailUrl,
    this.inlinePlay = false,
    this.onFullscreen,
  });

  @override
  State<VideoPlayerPreview> createState() => _VideoPlayerPreviewState();
}

class _VideoPlayerPreviewState extends State<VideoPlayerPreview> {
  File? _thumbnail;
  bool _loading = true;

  // Inline playback state — only used when widget.inlinePlay is true.
  VideoPlayerController? _controller;
  bool _starting = false; // fetching/initialising after the user tapped play
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _thumbnail = null;
      _loading = true;
      _disposeController();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    _playing = false;
    _starting = false;
  }

  // Tap handler: fetch + start the video inline. This is the first moment any
  // video data is requested, so nothing downloads until the user asks to play.
  Future<void> _startInlinePlayback() async {
    if (_controller != null || _starting) return;
    final videoUrl = widget.url.trim();
    if (videoUrl.isEmpty) return;

    Uri uri;
    try {
      uri = Uri.parse(videoUrl);
    } catch (_) {
      return;
    }

    setState(() => _starting = true);
    try {
      final c = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      await c.setLooping(true);
      c.addListener(_onTick);
      await c.play();
      setState(() {
        _controller = c;
        _starting = false;
        _playing = true;
      });
    } catch (_) {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted) return;
    final playing = c.value.isPlaying;
    if (playing != _playing) setState(() => _playing = playing);
  }

  void _toggleInline() {
    final c = _controller;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  Future<void> _loadThumbnail() async {
    // Backend already has a poster for this video — use it, skip generation.
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Generated once and cached to disk — instant on every subsequent view.
    // onUpdated fires later if the backend's video changed, swapping in the
    // latest frame without the user re-opening the screen.
    final file = await VideoThumbnailCache.instance.get(
      widget.url,
      onUpdated: (fresh) {
        if (mounted) setState(() => _thumbnail = fresh);
      },
    );
    if (mounted) {
      setState(() {
        _thumbnail = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? MediaQuery.of(context).size.width;
    final h = widget.height ?? 350;

    // Playback has started — show the video itself; the poster is gone.
    final c = _controller;
    if (widget.inlinePlay && c != null && c.value.isInitialized) {
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
            // Tap toggles play/pause; the badge fades out while playing.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleInline,
              child: AnimatedOpacity(
                opacity: _playing ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Center(child: _playBadge()),
              ),
            ),
            if (widget.onFullscreen != null)
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: widget.onFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final backendThumb = widget.thumbnailUrl;
    final hasBackendThumb = backendThumb != null && backendThumb.isNotEmpty;

    Widget child;
    if (hasBackendThumb) {
      // Backend poster — render directly, no on-device frame extraction.
      child = _posterStack(Image.network(
        backendThumb,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(loading: false),
      ));
    } else if (_thumbnail != null) {
      child = _posterStack(
          Image.file(_thumbnail!, fit: BoxFit.cover, gaplessPlayback: true));
    } else {
      // Spinner only while generating the first time; otherwise a play
      // affordance so the (failed-thumbnail) video stays tappable.
      child = _placeholder(loading: _loading);
    }

    final poster = SizedBox(width: w, height: h, child: child);

    // In inline mode the poster is a tap-to-load-and-play affordance.
    if (widget.inlinePlay) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _starting ? null : _startInlinePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            poster,
            if (_starting)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      );
    }

    return poster;
  }

  // Grey box with a spinner (still generating) or a play affordance.
  Widget _placeholder({required bool loading}) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: loading ? const CircularProgressIndicator() : _playBadge(),
      ),
    );
  }

  // Poster image with a centered ▶ play badge on top.
  Widget _posterStack(Widget image) {
    return Stack(
      fit: StackFit.expand,
      children: [image, Center(child: _playBadge())],
    );
  }

  Widget _playBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
    );
  }
}
