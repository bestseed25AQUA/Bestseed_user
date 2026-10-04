import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_intro_controller.dart';
import 'package:seedsuser/app/utils/full_screen_video.dart';
import 'package:video_player/video_player.dart';

/// "How Farm Management works" — shown only to a farmer with no farms yet.
///
/// The video plays INSIDE the app. It used to be a row with a play icon that
/// handed the URL to the browser, which threw the farmer out of the app at the
/// exact moment they were being taught how to use it.
///
/// The card shows a real first frame rather than a placeholder, so it is
/// obvious there is a video here and roughly what it is. Tapping opens the
/// full-screen player.
class FarmDemoVideoCard extends StatefulWidget {
  const FarmDemoVideoCard({super.key});

  @override
  State<FarmDemoVideoCard> createState() => _FarmDemoVideoCardState();
}

class _FarmDemoVideoCardState extends State<FarmDemoVideoCard> {
  VideoPlayerController? _preview;

  /// The URL the preview was built for, so a change in the admin panel
  /// rebuilds it instead of showing the old frame for ever.
  String? _loadedUrl;

  bool _failed = false;

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  /// Load just enough of the video to paint its first frame.
  ///
  /// Never autoplays: this sits above a list the farmer is reading, and a
  /// video starting on its own — with sound — is the kind of thing people
  /// close the app over. [initialize] fetches only the header and one frame,
  /// not the whole file.
  Future<void> _loadPreview(String url) async {
    if (_loadedUrl == url) return;

    _loadedUrl = url;
    _failed = false;

    final old = _preview;
    final next = VideoPlayerController.networkUrl(Uri.parse(url));
    _preview = next;

    try {
      await next.initialize();
      await next.setVolume(0);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[FARM DEMO] preview failed: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      await old?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final video = farmIntroController.demoVideo.value;

      // The server already withholds the video once the farmer has a farm.
      // Checked again here because the list on screen is the more recent
      // truth: somebody who has just created their first farm should not
      // still be offered the introduction.
      if (video == null ||
          !video.isUsable ||
          farmIntroController.hasFarms.value) {
        return const SizedBox.shrink();
      }

      // Kicked off after this frame, so build() stays free of side effects.
      if (_loadedUrl != video.url) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadPreview(video.url),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          // So the video's corners follow the card's.
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _preview16x9(video.url, video.title),
              _caption(video.title),
            ],
          ),
        ),
      );
    });
  }

  /// The video itself, in a fixed 16:9 frame.
  ///
  /// Fixed rather than the clip's own ratio, so the card does not jump to a
  /// new height the moment the first frame arrives.
  Widget _preview16x9(String url, String title) {
    final ready = _preview?.value.isInitialized ?? false;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () => _openFullScreen(url, title),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: ready
                  // The frame, cropped to fill rather than letterboxed —
                  // a portrait phone recording would otherwise be two black
                  // bars and a sliver of picture.
                  ? FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _preview!.value.size.width,
                        height: _preview!.value.size.height,
                        child: VideoPlayer(_preview!),
                      ),
                    )
                  : Center(
                      child: _failed
                          // A thumbnail that will not load must not hide the
                          // video: the play button still works.
                          ? Icon(
                              Icons.videocam_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 40,
                            )
                          : const SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white70,
                              ),
                            ),
                    ),
            ),

            // Darkened, so the play button reads against a bright frame.
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black26),
            ),

            Center(
              child: Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Title and hint, under the video.
  ///
  /// No fullscreen icon: the play button already opens the full-screen
  /// player, so a second control next to it only invited the question of
  /// what the difference was.
  Widget _caption(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Watch a short video before you start',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen(String url, String title) async {
    // Paused first, or two players hold the same stream and the preview's
    // audio can carry on underneath the full-screen one.
    await _preview?.pause();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(url: url, title: title),
      ),
    );
  }
}
