import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FullMediaScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final int initialIndex;
  final String? title;

  const FullMediaScreen({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<FullMediaScreen> createState() => _FullMediaScreenState();
}

class _FullMediaScreenState extends State<FullMediaScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // Video controllers map for each video index
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};
  final Map<int, bool> _videoLoading = {};
  final Map<int, bool> _videoError = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize video if current is video
    if (_isVideo(_currentIndex)) {
      _initializeVideo(_currentIndex);
    }
  }

  bool _isVideo(int index) {
    if (index < 0 || index >= widget.mediaTypes.length) return false;
    return widget.mediaTypes[index] == 'video';
  }

  Future<void> _initializeVideo(int index) async {
    if (_videoControllers.containsKey(index)) return;

    setState(() {
      _videoLoading[index] = true;
      _videoError[index] = false;
    });

    final videoUrl = widget.mediaUrls[index].trim();
    if (videoUrl.isEmpty) {
      setState(() {
        _videoError[index] = true;
        _videoLoading[index] = false;
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
      );

      await controller.initialize();

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: index == _currentIndex,
        looping: true,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );

      if (mounted) {
        setState(() {
          _videoControllers[index] = controller;
          _chewieControllers[index] = chewieController;
          _videoLoading[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError[index] = true;
          _videoLoading[index] = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    // Pause previous video if it was playing
    if (_isVideo(_currentIndex) && _chewieControllers.containsKey(_currentIndex)) {
      _chewieControllers[_currentIndex]?.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    // Initialize and play new video if needed
    if (_isVideo(index)) {
      if (!_videoControllers.containsKey(index)) {
        _initializeVideo(index);
      } else {
        _chewieControllers[index]?.play();
      }
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.mediaUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMedia = widget.mediaUrls.length;
    final showNavigation = totalMedia > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: totalMedia,
            itemBuilder: (context, index) {
              if (_isVideo(index)) {
                return _buildVideoView(index);
              } else {
                return _buildImageView(index);
              }
            },
          ),

          // Top bar with back button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Media counter
                  if (showNavigation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $totalMedia',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Previous button
          if (showNavigation && _currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _goToPrevious,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Next button
          if (showNavigation && _currentIndex < totalMedia - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _goToNext,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom indicator dots
          if (showNavigation)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalMedia, (index) {
                  return Container(
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageView(int index) {
    final imageUrl = widget.mediaUrls[index];
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.network(
          imageUrl,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, color: Colors.white54, size: 60),
              const SizedBox(height: 10),
              Text(
                'Failed to load image',
                style: GoogleFonts.roboto(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoView(int index) {
    if (_videoLoading[index] == true) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_videoError[index] == true) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 10),
            Text(
              'Failed to load video',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _videoControllers.remove(index);
                _chewieControllers.remove(index);
                _initializeVideo(index);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chewieControllers.containsKey(index)) {
      return Center(
        child: Chewie(controller: _chewieControllers[index]!),
      );
    }

    // Not yet initialized
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}
