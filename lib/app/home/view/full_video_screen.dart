import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  const FullScreenVideoPlayer({super.key, required this.videoUrl, this.title});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final videoUrl = widget.videoUrl.trim();
    if (videoUrl.isEmpty) {
      print('FullScreenVideoPlayer: ERROR - Video URL is empty!');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Video URL is empty';
        });
      }
      return;
    }

    try {
      print('FullScreenVideoPlayer: Initializing video: $videoUrl');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
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
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red, size: 60),
                SizedBox(height: 10),
                Text(
                  "Failed to load video",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('FullScreenVideoPlayer: Video initialized successfully');
    } catch (e) {
      print('FullScreenVideoPlayer: Video load error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 60),
                          SizedBox(height: 10),
                          Text(
                            "Failed to load video",
                            style: TextStyle(color: Colors.white),
                          ),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _errorMessage.length > 100
                                    ? '${_errorMessage.substring(0, 100)}...'
                                    : _errorMessage,
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeVideo,
                            child: Text('Retry'),
                          ),
                        ],
                      )
                    : _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : SizedBox.shrink(),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
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
                  size: 28,
                ),
              ),
            ),
          ),

          // Title
          if (widget.title != null && widget.title!.isNotEmpty)
            Positioned(
              top: 50,
              left: 80,
              right: 30,
              child: Text(
                widget.title!,
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
        ],
      ),
    );
  }
}
