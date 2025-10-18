import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class HatcheryDetail extends StatefulWidget {
  final String videoUrl;
  const HatcheryDetail({super.key, required this.videoUrl});

  @override
  State<HatcheryDetail> createState() => _HatcheryDetailState();
}

class _HatcheryDetailState extends State<HatcheryDetail> {
  late VideoPlayerController _controller;
  bool videoStarted = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller in initState
    _controller = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(false);
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
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Seven star Hatcheries",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            // Video Section
            GestureDetector(
              onTap: () async {
                setState(() => videoStarted = true);
                _controller = VideoPlayerController.asset(widget.videoUrl);
                setState(() {}); // show loading indicator
                await _controller.initialize();
                _controller.setLooping(false);
                _controller.play();

                // Listener to update UI and detect end
                _controller.addListener(() {
                  if (_controller.value.position >=
                      _controller.value.duration) {
                    setState(() {
                      videoStarted = false;
                    });
                  } else {
                    setState(() {}); // update position/time
                  }
                });

                setState(() {}); // refresh UI after initialization
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hatchery Name and Report Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Syqua",
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.report_outlined, size: 18),
                        label: const Text("Report"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    "Syqua seeds – known for their excellent survival rates, fast growth, and disease resistance. Our hatchery follows strict biosecurity protocols and quality control to ensure you get only the best.",
                    style: GoogleFonts.roboto(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Location and Availability Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.location_on,
                              "Unit - 1",
                              'Kakinada',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.water_drop_outlined,
                              "Broodstock",
                              "1200 Pieces",
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.timer, "Price", "₹0.36"),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,

                          children: [
                            _buildInfoRow(
                              Icons.location_on,
                              "Unit - 2",
                              'Godavari',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              "Available Date",
                              "27 Sep 2024",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Gallery Section
                  Text(
                    "Gallery",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 108,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: _buildGalleryImage(
                            imageUrl:
                                'assets/images/WhatsApp Image 2025-10-04 at 11.11.43 AM.jpeg',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _makePhoneCall('+918977778784');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                topLeft: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/phone.png',
                                  height: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Call Now',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final whatsappUrl =
                                "https://wa.me/${'+918977778784'.replaceAll('+', '')}";
                            final Uri uri = Uri.parse(whatsappUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cannot launch WhatsApp"),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),

                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/whatsApp.png',
                                  height: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'WhatsApp',
                                  style: GoogleFonts.roboto(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),

                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showBookingBottomSheet(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),

                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/images/Lightning.png',
                                  height: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Book Now',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove any non-digit characters except +)
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanedNumber.isEmpty) {
      debugPrint("Invalid phone number: $phoneNumber");
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch phone dialer for: $cleanedNumber");
        // Optional: Show a snackbar or dialog to the user
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Cannot make phone call to $cleanedNumber')),
        // );
      }
    } catch (e) {
      debugPrint("Error making phone call: $e");
      // Optional: Show error to user
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error making phone call: $e')),
      // );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryImage({required String imageUrl}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Image.asset(imageUrl, fit: BoxFit.cover, height: 108, width: 104),
    );
  }
}
