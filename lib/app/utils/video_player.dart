import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/utils/full_screen_video.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String title; // hatchery name or any title
  final double? height;
  final Function(bool isPlaying)? onPlayStateChanged; // Callback when play/pause state changes

  const InlineVideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.height,
    this.onPlayStateChanged,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  String _errorMessage = '';
  // True only when the controller has both initialized AND a real frame
  // available to paint. Until then we keep the shimmer up so the user
  // never sees the bare black VideoPlayer surface.
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;
    if (!_isReady &&
        v.isInitialized &&
        !v.hasError &&
        v.size.width > 0 &&
        v.size.height > 0) {
      setState(() => _isReady = true);
      // Auto-play the moment the first frame is paintable so the user sees
      // the video running as soon as the shimmer goes away — no manual tap
      // required.
      c.setLooping(true);
      c.setVolume(0);
      c.play();
      widget.onPlayStateChanged?.call(true);
    }
    if (!_hasError && v.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = v.errorDescription ?? 'Video error';
      });
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.url.trim();

    // Validate URL
    if (videoUrl.isEmpty) {
      print('InlineVideoPlayer: ERROR - Video URL is empty!');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
        });
      }
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(videoUrl);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) {
        throw FormatException('Invalid URL scheme');
      }
    } catch (e) {
      print('InlineVideoPlayer: ERROR - Invalid URL: $videoUrl');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid video URL';
        });
      }
      return;
    }

    try {
      print('InlineVideoPlayer: Initializing video: $videoUrl');
      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
      );
      _controller!.addListener(_onControllerUpdate);
      await _controller!.initialize();
      // _onControllerUpdate flips _isReady to true once the first frame is
      // actually available (size > 0). Run a one-shot check now in case the
      // listener already fired before we attached above.
      _onControllerUpdate();
      print('InlineVideoPlayer: Video initialized successfully');
    } catch (e) {
      print('InlineVideoPlayer: Video initialization error: $e');
      if (mounted) {
        String message = e.toString();
        if (message.contains('EXCEEDS_CAPABILITIES') ||
            message.contains('DecoderInitializationException')) {
          message = 'Video resolution too high for this device';
        }
        setState(() {
          _hasError = true;
          _errorMessage = message;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    final willPlay = !_controller!.value.isPlaying;
    setState(() {
      willPlay ? _controller!.play() : _controller!.pause();
    });
    // Notify parent about play state change
    widget.onPlayStateChanged?.call(willPlay);
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullScreenVideoPlayer(url: widget.url, title: widget.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show error state with play button overlay (tap to open fullscreen).
    // Background is the same shimmer used during loading so the banner area
    // never goes black — failures stay visually consistent with the rest of
    // the data-loading UI.
    if (_hasError) {
      return GestureDetector(
        onTap: _openFullscreen,
        child: SizedBox(
          height: widget.height ?? 110,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomShimmer(
                height: widget.height ?? 110,
                width: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline,
                        color: Colors.grey.shade600, size: 40),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to play',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _controller == null) {
      // Match the data-loading shimmer used elsewhere in the app so the
      // banner doesn't pop a black box while the video is still buffering.
      return CustomShimmer(
        height: widget.height ?? 110,
        width: double.infinity,
        borderRadius: BorderRadius.zero,
      );
    }

    return SizedBox(
      height: widget.height ?? 110,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller!),

          /// ▶️ Play / Pause (tap video)
          GestureDetector(
            onTap: _togglePlay,
            child: Center(
              child: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

          /// ⛶ Fullscreen (bottom-right)
          Positioned(
            bottom: 6,
            right: 6,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
              onPressed: _openFullscreen,
            ),
          ),
        ],
      ),
    );
  }
}
