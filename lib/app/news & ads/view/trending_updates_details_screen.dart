import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:video_player/video_player.dart';

class TrendingUpdatesDetailsScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  const TrendingUpdatesDetailsScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<TrendingUpdatesDetailsScreen> createState() =>
      _TrendingUpdatesDetailsScreenState();
}

class _TrendingUpdatesDetailsScreenState
    extends State<TrendingUpdatesDetailsScreen> {
  late VideoPlayerController _controller;
  bool videoStarted = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller in initState
    _controller =
        VideoPlayerController.asset('assets/images/video_20250921_103157.mp4')
          ..initialize().then((_) {
            setState(() {}); // Refresh UI when initialized
          })
          ..setLooping(false); // No looping
    // Add listener to update UI every frame
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
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
          widget.title,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildTrendingSection()],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
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
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Golden Mahaseer Recovery & SKOCH Gold Award  The Himachal Pradesh Fisheries Department won the SKOCH Gold Award 2025 for its captive breeding of the endangered Golden Mahaseer fish. They produced ~87,000 fingerlings in 2024–25, and released ~34,500 into wild waterbodies. The Times of IndiaEcolabelling for Lakshadweep Tuna Fisheries  The Indian government is pushing for global ecolabelling certification for traditional pole-and-line / hand-line tuna fisheries in Lakshadweep. This is to help fishers get better access to international markets and higher prices. The Times of IndiaIndia’s Fish Output Grows to 18.42 Million Tonnes  In 2024–25, India produced 18.42 million tonnes of fish, up from 17.5 million tonnes the year before. ICAR (Indian Council of Agricultural Research) is leading with research, genetic improvements, and tech adoption. https://agritimes.co.in/Modern Tech & Digital Tools in Indian AquacultureUse of drones for transporting live fish in difficult terrains.Satellite systems for resource mapping and safety.Smart harbours, advanced fish markets. ETGovernment.comGrowth of biofloc & RAS systems to improve yields and sustainability.',
        ),
      ],
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
