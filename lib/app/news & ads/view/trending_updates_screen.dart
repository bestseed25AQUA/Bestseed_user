import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/trending_updates_details_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/widget/news_banner_widget.dart';
import 'package:video_player/video_player.dart';

class TrendingUpdatesScreen extends StatefulWidget {
  const TrendingUpdatesScreen({super.key});

  @override
  State<TrendingUpdatesScreen> createState() => _TrendingUpdatesScreenState();
}

class _TrendingUpdatesScreenState extends State<TrendingUpdatesScreen> {
  late VideoPlayerController _controller;
  bool videoStarted = false;
  final newsSpecificController = Get.put(NewsSpecificController());

  @override
  void initState() {
    super.initState();
    newsSpecificController.fetch('trending updates');
    // Initialize controller in initState
    // _controller =
    //     VideoPlayerController.asset('assets/images/video_20250921_103157.mp4')
    //       ..initialize().then((_) {
    //         setState(() {});
    //       })
    //       ..setLooping(false);
    // _controller.addListener(() {
    //   if (mounted) setState(() {});
    // });
  }

  void checkAsset() async {
    try {
      await rootBundle.load('assets/images/video_20250921_103157.mp4');
      debugPrint("Asset exists and loaded");
    } catch (e) {
      debugPrint("Asset not found: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        // automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'Trending updates',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            if (newsSpecificController.isLoading.value) {
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * .3,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if ((newsSpecificController.newsSpecificData.value?.data?.length ??
                    0) ==
                0) {
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * .3,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text('No Trending Updates Availables'),
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  newsSpecificController.newsSpecificData.value?.data?.length ??
                      0,

                  (index) {
                    final data = newsSpecificController
                        .newsSpecificData
                        .value
                        ?.data?[index];
                    if (data?.mediaType == "image") {
                      return GestureDetector(
                        onTap: () {},
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data?.mediaPath ?? "",
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox();
                            },
                          ),
                        ),
                      );
                    } else if (data?.mediaType == "video") {
                      return GestureDetector(
                        onTap: () {
                          Get.to(
                            () => FullScreenVideoPlayer(
                              videoUrl: data?.mediaPath ?? '',
                            ),
                          );
                        },
                        child: VideoPlayerBanner(url: data?.mediaPath ?? ''),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return InkWell(
      onTap: () {
        Get.to(
          () => const TrendingUpdatesDetailsScreen(
            title: 'Fish Farming and Aquaculture',
            videoUrl: 'assets/images/video_20250921_103157.mp4',
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              setState(() => videoStarted = true);
              _controller = VideoPlayerController.asset(
                'assets/images/video_20250921_103157.mp4',
              );
              setState(() {}); // show loading indicator
              await _controller.initialize();
              _controller.setLooping(false);
              _controller.play();

              // Listener to update UI and detect end
              _controller.addListener(() {
                if (_controller.value.position >= _controller.value.duration) {
                  setState(() {
                    videoStarted = false; // video ended
                  });
                } else {
                  setState(() {}); // update position/time
                }
              });

              setState(() {}); // refresh UI after initialization
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: _controller.value.isInitialized
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video Player
                          SizedBox(
                            width: double.infinity,
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                          // Play/Pause Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          // Video Progress / Time
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fish Farming and Aquaculture',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format duration as mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
