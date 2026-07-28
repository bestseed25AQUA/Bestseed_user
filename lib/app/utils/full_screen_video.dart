import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const FullScreenVideoPlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _wasPlayingBeforePause = false;

  String get _tag => 'FullScreenVideo[${widget.url.split('/').last.split('?').first}]';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('$_tag: initState');
    _initializeVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _videoPlayerController;
    if (c == null || !c.value.isInitialized) return;
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

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final videoUrl = widget.url.trim();
    if (videoUrl.isEmpty) {
      debugPrint('$_tag: ERROR — URL is empty');
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
      debugPrint('$_tag: initializing...');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
        // mixWithOthers: false takes exclusive audio focus on Android — if
        // any other video_player instance (an inline carousel that didn't
        // dispose cleanly, for instance) is still running, Android's audio
        // focus system will silence it. Belt-and-suspenders alongside the
        // inline-controller dispose in _openFullscreen().
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await _videoPlayerController!.initialize();
      debugPrint('$_tag: initialized — duration=${_videoPlayerController!.value.duration.inSeconds}s');

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text(
                  'Unable to play video',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
      debugPrint('$_tag: playback started');
    } catch (e) {
      debugPrint('$_tag: initialization FAILED: $e');
      if (mounted) {
        String message = e.toString();
        if (message.contains('EXCEEDS_CAPABILITIES') ||
            message.contains('DecoderInitializationException')) {
          message = 'Video resolution too high for this device. Please ask admin to upload a lower resolution video.';
        }
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = message;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('$_tag: dispose');
    WidgetsBinding.instance.removeObserver(this);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Unable to play video',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage.length > 100
                          ? '${_errorMessage.substring(0, 100)}...'
                          : _errorMessage,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeVideo,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 40,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : SizedBox.shrink(),
          ),

          // Back + Title
          Positioned(
            top: 40,
            left: 12,
            right: 12,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
