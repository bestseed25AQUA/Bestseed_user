import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/utils/full_screen_video.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  final String title;
  final double? height;
  final Function(bool isPlaying)? onPlayStateChanged;
  final bool isActive;

  /// Dashboard tab this player lives in. When non-null the player only plays
  /// while that tab is selected (and releases the decoder otherwise). Leave
  /// null when the player is shown on a pushed route that isn't a dashboard
  /// tab (e.g. vehicle availability / hatchery screens) so the video isn't
  /// gated on the underlying tab — otherwise it would never leave the shimmer.
  final int? tabIndex;

  const InlineVideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.height,
    this.onPlayStateChanged,
    this.isActive = true,
    this.tabIndex,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isReady = false;
  bool _userPaused = false;

  // Buffering debounce
  bool _showBuffering = false;
  Timer? _bufferingDebounce;
  bool _lastRawBuffering = false;

  // Stall recovery
  Timer? _stallTimer;
  Duration _lastKnownPosition = Duration.zero;
  int _stallCount = 0;

  // Lifecycle
  bool _wasPlayingBeforeBackground = false;

  // Tab awareness
  Worker? _tabWorker;
  bool _tabVisible = true;

  // *** PLAY/STOP TRACKING ***
  bool _lastPlayingState = false;

  String get _tag => '▶ InlineVP[${widget.url.split('/').last.split('?').first}]';

  void _logPlayState(String reason) {
    final c = _controller;
    if (c == null) return;
    final v = c.value;
    final playing = v.isPlaying;
    if (playing != _lastPlayingState) {
      debugPrint('$_tag: ${playing ? "▶ PLAYING" : "⏸ STOPPED"} reason=$reason '
          'pos=${v.position.inMilliseconds}ms '
          'buffering=${v.isBuffering} '
          'hasError=${v.hasError} '
          'userPaused=$_userPaused '
          'tabVisible=$_tabVisible '
          'isActive=${widget.isActive}');
      _lastPlayingState = playing;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.tabIndex == null) {
      // Not bound to a dashboard tab (pushed route) — always treat as visible.
      _tabVisible = true;
      debugPrint('$_tag: initState — no tabIndex, assuming tabVisible=true');
    } else {
      try {
        final dashCtrl = Get.find<DashboardController>();
        _tabVisible = dashCtrl.currentIndex.value == widget.tabIndex;
        debugPrint('$_tag: initState — tabVisible=$_tabVisible (currentTab=${dashCtrl.currentIndex.value}, myTab=${widget.tabIndex})');
        _tabWorker = ever(dashCtrl.currentIndex, (int idx) {
          final nowVisible = idx == widget.tabIndex;
          if (nowVisible && !_tabVisible) {
            debugPrint('$_tag: TAB VISIBLE (idx=$idx)');
            _tabVisible = true;
            if (widget.isActive && _controller == null && !_hasError) {
              _initializeVideo();
            } else if (_controller != null && _isReady && !_userPaused) {
              _controller!.play();
              _startStallDetection();
              _logPlayState('tab-became-visible');
            }
          } else if (!nowVisible && _tabVisible) {
            debugPrint('$_tag: TAB HIDDEN (idx=$idx) — releasing decoder');
            _tabVisible = false;
            _releaseController();
          }
        });
      } catch (e) {
        _tabVisible = true;
        debugPrint('$_tag: initState — no DashboardController ($e), assuming tabVisible=true');
      }
    }

    if (widget.isActive && _tabVisible) {
      debugPrint('$_tag: initState — active + tab visible → delay 2s then init');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.isActive && _tabVisible) _initializeVideo();
      });
    } else {
      debugPrint('$_tag: initState — SKIP init (active=${widget.isActive}, tabVisible=$_tabVisible)');
    }
  }

  @override
  void didUpdateWidget(covariant InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      debugPrint('$_tag: carousel → ACTIVE (tabVisible=$_tabVisible)');
      if (_controller == null && !_hasError && _tabVisible) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && widget.isActive && _tabVisible) _initializeVideo();
        });
      } else if (_controller != null && _isReady && !_userPaused) {
        _controller!.play();
        _startStallDetection();
        _logPlayState('carousel-became-active');
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      debugPrint('$_tag: carousel → INACTIVE — releasing decoder');
      _releaseController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_isReady) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasPlayingBeforeBackground = c.value.isPlaying;
      debugPrint('$_tag: LIFECYCLE → background (wasPlaying=$_wasPlayingBeforeBackground)');
      if (_wasPlayingBeforeBackground) {
        c.pause();
        _logPlayState('app-went-background');
      }
      _stopStallDetection();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('$_tag: LIFECYCLE → resumed');
      if (_wasPlayingBeforeBackground && !_userPaused) {
        c.play();
        _startStallDetection();
        _logPlayState('app-resumed');
      }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;

    // Track play/stop transitions from ExoPlayer (audio focus, internal pause, etc.)
    if (v.isInitialized && _isReady) {
      final playing = v.isPlaying;
      if (playing != _lastPlayingState) {
        // We didn't trigger this — ExoPlayer changed state on its own
        debugPrint('$_tag: ${playing ? "▶ PLAYING" : "⏸ STOPPED"} reason=EXOPLAYER_INTERNAL '
            'pos=${v.position.inMilliseconds}ms '
            'buffering=${v.isBuffering} '
            'hasError=${v.hasError}');
        _lastPlayingState = playing;
      }
    }

    // Debounced buffering
    final rawBuffering = v.isBuffering;
    if (rawBuffering != _lastRawBuffering) {
      _lastRawBuffering = rawBuffering;
      _bufferingDebounce?.cancel();
      if (rawBuffering) {
        _bufferingDebounce = Timer(const Duration(milliseconds: 800), () {
          if (mounted && _lastRawBuffering) {
            debugPrint('$_tag: BUFFERING >800ms at pos=${v.position.inMilliseconds}ms');
            setState(() => _showBuffering = true);
          }
        });
      } else {
        if (_showBuffering) {
          debugPrint('$_tag: BUFFERING ended at pos=${v.position.inMilliseconds}ms');
          setState(() => _showBuffering = false);
        }
      }
    }

    // First ready
    if (!_isReady &&
        v.isInitialized &&
        !v.hasError &&
        v.size.width > 0 &&
        v.size.height > 0) {
      debugPrint('$_tag: READY (${v.size.width}x${v.size.height}) tabVisible=$_tabVisible');
      setState(() => _isReady = true);
      c.setLooping(true);
      c.setVolume(0);
      if (_tabVisible) {
        c.play();
        _startStallDetection();
        _logPlayState('first-play-after-init');
      } else {
        debugPrint('$_tag: READY but tab hidden — NOT starting playback');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPlayStateChanged?.call(true);
      });
    }

    // Error
    if (!_hasError && v.hasError) {
      debugPrint('$_tag: ⏸ STOPPED reason=CONTROLLER_ERROR desc=${v.errorDescription}');
      setState(() {
        _hasError = true;
        _errorMessage = v.errorDescription ?? 'Video error';
      });
    }
  }

  void _startStallDetection() {
    _stopStallDetection();
    _lastKnownPosition = _controller?.value.position ?? Duration.zero;
    _stallCount = 0;
    _stallTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final c = _controller;
      if (c == null || !mounted) return;
      final v = c.value;
      if (!v.isPlaying || _userPaused) return;

      if (v.position == _lastKnownPosition && !v.isBuffering) {
        _stallCount++;
        debugPrint('$_tag: STALL #$_stallCount pos=${v.position.inMilliseconds}ms (not advancing, not buffering)');
        if (_stallCount <= 3) {
          c.seekTo(v.position).then((_) => c.play());
        } else {
          debugPrint('$_tag: STALL persistent — seek +500ms');
          c.seekTo(v.position + const Duration(milliseconds: 500)).then((_) => c.play());
          _stallCount = 0;
        }
      } else {
        if (_stallCount > 0) {
          debugPrint('$_tag: STALL recovered pos=${v.position.inMilliseconds}ms');
        }
        _stallCount = 0;
      }
      _lastKnownPosition = v.position;
    });
  }

  void _stopStallDetection() {
    _stallTimer?.cancel();
    _stallTimer = null;
  }

  Future<void> _initializeVideo() async {
    if (_controller != null) return;
    if (!_tabVisible) {
      debugPrint('$_tag: _initializeVideo SKIPPED — tab not visible');
      return;
    }

    final videoUrl = widget.url.trim();
    if (videoUrl.isEmpty) {
      debugPrint('$_tag: ERROR — URL empty');
      if (mounted) setState(() { _hasError = true; _errorMessage = 'Video URL is empty'; });
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(videoUrl);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) throw FormatException('Invalid URL scheme');
    } catch (e) {
      debugPrint('$_tag: ERROR — Invalid URL');
      if (mounted) setState(() { _hasError = true; _errorMessage = 'Invalid video URL'; });
      return;
    }

    try {
      debugPrint('$_tag: INIT starting...');
      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Connection': 'keep-alive',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller!.addListener(_onControllerUpdate);
      await _controller!.initialize();
      debugPrint('$_tag: INIT complete — duration=${_controller!.value.duration.inSeconds}s, size=${_controller!.value.size}');
      if (!widget.isActive) {
        debugPrint('$_tag: became inactive DURING init — releasing');
        _releaseController();
        return;
      }
      if (!_tabVisible) {
        debugPrint('$_tag: tab hidden DURING init — releasing');
        _releaseController();
        return;
      }
      _onControllerUpdate();
    } catch (e) {
      debugPrint('$_tag: INIT FAILED: $e');
      if (mounted) {
        String message = e.toString();
        if (message.contains('EXCEEDS_CAPABILITIES') || message.contains('DecoderInitializationException')) {
          message = 'Video resolution too high for this device';
        }
        setState(() { _hasError = true; _errorMessage = message; });
      }
    }
  }

  void _releaseController() {
    debugPrint('$_tag: RELEASE controller (had controller=${_controller != null})');
    _stopStallDetection();
    _bufferingDebounce?.cancel();
    _lastRawBuffering = false;
    _showBuffering = false;
    _lastPlayingState = false;
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    _isReady = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    debugPrint('$_tag: DISPOSE');
    WidgetsBinding.instance.removeObserver(this);
    _tabWorker?.dispose();
    _stopStallDetection();
    _bufferingDebounce?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    final willPlay = !c.value.isPlaying;
    _userPaused = !willPlay;
    if (willPlay) {
      c.play();
      _startStallDetection();
      _logPlayState('user-tapped-play');
    } else {
      c.pause();
      _stopStallDetection();
      _logPlayState('user-tapped-pause');
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPlayStateChanged?.call(willPlay);
    });
  }

  void _openFullscreen() {
    final wasPlaying = _controller?.value.isPlaying ?? false;
    debugPrint('$_tag: FULLSCREEN open (wasPlaying=$wasPlaying) — releasing inline controller');
    // FULLY DISPOSE the inline controller before pushing the full-screen
    // player. Previously we only paused it, and because both controllers
    // used `mixWithOthers: true`, Android ExoPlayer kept both decoders
    // alive → the fullscreen player would auto-play while the inline
    // controller stayed loaded in the background, giving a dual-playback
    // effect (audible on some OEMs). Disposing here guarantees exactly
    // one active decoder for this video URL at any time.
    _releaseController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(url: widget.url, title: widget.title),
      ),
    ).then((_) {
      debugPrint('$_tag: FULLSCREEN closed (shouldResume=$wasPlaying, userPaused=$_userPaused, mounted=$mounted)');
      if (!mounted) return;
      // Re-initialize the inline player so the poster/thumbnail restores
      // if the tab is still visible. Autoplay behaviour on return matches
      // the tab's original active state — same as first open.
      _initializeVideo();
      // If it was actively playing before fullscreen (and the user hadn't
      // manually paused), resume once init completes. _initializeVideo
      // handles the auto-start once ready, so we don't force play here.
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return GestureDetector(
        onTap: _openFullscreen,
        child: SizedBox(
          height: widget.height ?? 110,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomShimmer(height: widget.height ?? 110, width: double.infinity, borderRadius: BorderRadius.zero),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, color: Colors.grey.shade600, size: 40),
                    const SizedBox(height: 4),
                    Text('Tap to play', style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _controller == null) {
      return CustomShimmer(height: widget.height ?? 110, width: double.infinity, borderRadius: BorderRadius.zero);
    }

    final isPlaying = _controller!.value.isPlaying;

    return SizedBox(
      height: widget.height ?? 110,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller!),
          if (_showBuffering)
            const Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))),
          GestureDetector(
            onTap: _togglePlay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: _showBuffering ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
