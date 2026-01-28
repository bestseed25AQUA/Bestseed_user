import 'package:flutter/material.dart';
import 'package:seedsuser/app/utils/full_screen_video.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String title; // hatchery name or any title
  final double? height;

  const InlineVideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.height,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
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
    if (!_controller.value.isInitialized) {
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
          VideoPlayer(_controller),

          /// ▶️ Play / Pause (tap video)
          GestureDetector(
            onTap: _togglePlay,
            child: Center(
              child: Icon(
                _controller.value.isPlaying
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
