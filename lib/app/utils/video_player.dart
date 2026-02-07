import 'package:flutter/material.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
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
    // Show error state with play button overlay (tap to open fullscreen)
    if (_hasError) {
      return GestureDetector(
        onTap: _openFullscreen,
        child: Container(
          height: widget.height ?? 110,
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                const SizedBox(height: 4),
                Text(
                  'Tap to play',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: widget.height ?? 110,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
