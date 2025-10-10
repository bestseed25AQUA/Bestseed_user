import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/hatchery_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class HarcheryCardWidget extends StatefulWidget {
  const HarcheryCardWidget({
    super.key,
    required this.hatcheryName,
    required this.videoUrl,
    required this.unit1,
    required this.unit2,
    required this.broadstock,
    required this.availableDate,
    required this.pricePerPiece,
    required this.status,
    required this.statusColor,
    this.nextAvailable,
    this.imageUrl,
  });
  final String hatcheryName;
  final String videoUrl;
  final String unit1;
  final String unit2;
  final String broadstock;
  final String availableDate;
  final String pricePerPiece;
  final String status;
  final Color statusColor;
  final String? nextAvailable;
  final String? imageUrl;

  @override
  State<HarcheryCardWidget> createState() => _HarcheryCardWidgetState();
}

class _HarcheryCardWidgetState extends State<HarcheryCardWidget> {
  late VideoPlayerController _controller;
  bool videoStarted = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller in initState
    _controller = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI when initialized
      })
      ..setLooping(false); // No looping
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
    return InkWell(
      onTap: () {
        Get.to(() => HatcheryDetail(videoUrl: widget.videoUrl));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Status Overlay
            if (widget.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
                child: Image.asset(
                  widget.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
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
                    if (_controller.value.position >=
                        _controller.value.duration) {
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
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                    ),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rama',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(
                            30.0,
                          ), // Highly rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24.0,
                            ),

                            const SizedBox(width: 10.0),

                            // Availability Text
                            Text(
                              "Available on 28/06/2025",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.hatcheryName,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildInfoRow(
                        Icons.location_on,
                        "Kakinda,Bogapuram,viziangaram ",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _makePhoneCall("+918977778784");
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
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

Widget _buildInfoRow(IconData icon, String label) {
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
        ],
      ),
    ],
  );
}
