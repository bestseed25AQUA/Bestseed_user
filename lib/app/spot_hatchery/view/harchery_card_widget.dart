import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/hatchery_category_detail_screen.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class HarcheryCardWidget extends StatefulWidget {
  const HarcheryCardWidget({super.key, required this.spotHatchery});

  final SpotHatchery spotHatchery;

  @override
  State<HarcheryCardWidget> createState() => _HarcheryCardWidgetState();
}

class _HarcheryCardWidgetState extends State<HarcheryCardWidget> {
  VideoPlayerController? _controller;
  bool videoStarted = false;
  bool isPressed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  final SeedsPriceController controller = Get.put(SeedsPriceController());
  @override
  Widget build(BuildContext context) {
    final hatchery = widget.spotHatchery;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      onTap: () {
        Get.to(
          () => HatcheryCategoryDetailScreen(
            hatcheryName: hatchery.hatcheryName,
            videoUrl: '',
            hatcheryId: hatchery.hatcheryId.toString(),
            
            categoryId: hatchery.categoryId.toString(),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              child: Image.network(
                (hatchery.images.isNotEmpty) ? hatchery.images.first : '',
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  color: Colors.grey.withOpacity(.2),
                  height: 160,
                  width: MediaQuery.of(context).size.width * .9,
                ),
              ),
            ),
            // else
            // GestureDetector(
            //   onTap: () async {
            //     setState(() => videoStarted = true);
            //     _controller = VideoPlayerController.asset(
            //       'assets/videos/sample.mp4',
            //     );

            //     await _controller!.initialize();
            //     _controller!.setLooping(false);
            //     _controller!.play();

            //     _controller!.addListener(() {
            //       if (_controller!.value.position >=
            //           _controller!.value.duration) {
            //         setState(() => videoStarted = false);
            //       } else {
            //         setState(() {});
            //       }
            //     });
            //     setState(() {});
            //   },
            //   child: ClipRRect(
            //     borderRadius: const BorderRadius.only(
            //       topLeft: Radius.circular(12.0),
            //       topRight: Radius.circular(12.0),
            //     ),
            //     child: SizedBox(
            //       width: double.infinity,
            //       height: 200,
            //       child: _controller?.value.isInitialized ?? false
            //           ? Stack(
            //               alignment: Alignment.center,
            //               children: [
            //                 AspectRatio(
            //                   aspectRatio: _controller!.value.aspectRatio,
            //                   child: VideoPlayer(_controller!),
            //                 ),
            //                 GestureDetector(
            //                   onTap: () {
            //                     setState(() {
            //                       _controller!.value.isPlaying
            //                           ? _controller!.pause()
            //                           : _controller!.play();
            //                     });
            //                   },
            //                   child: Icon(
            //                     _controller!.value.isPlaying
            //                         ? Icons.pause_circle_filled
            //                         : Icons.play_circle_fill,
            //                     color: Colors.white,
            //                     size: 60,
            //                   ),
            //                 ),
            //                 Positioned(
            //                   bottom: 8,
            //                   right: 8,
            //                   child: Container(
            //                     padding: const EdgeInsets.symmetric(
            //                       horizontal: 6,
            //                       vertical: 2,
            //                     ),
            //                     decoration: BoxDecoration(
            //                       color: Colors.black54,
            //                       borderRadius: BorderRadius.circular(4),
            //                     ),
            //                     child: Text(
            //                       '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
            //                       style: GoogleFonts.roboto(
            //                         color: Colors.white,
            //                         fontSize: 12,
            //                       ),
            //                     ),
            //                   ),
            //                 ),
            //               ],
            //             )
            //           : const Center(
            //               child: CircularProgressIndicator(
            //                 color: AppColors.primary,
            //               ),
            //             ),
            //     ),
            //   ),
            // ),

            // ✅ Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          hatchery.hatcheryName,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .34,
                              child: Text(
                                "Available on ${hatchery.availableOn}",
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    hatchery.categoryName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // // Location
                  // if (hatchery.locationName?.isNotEmpty ?? false)
                  Builder(
                    builder: (context) {
                      Location? location;
                      try {
                        location = controller.locations.firstWhere(
                          (e) =>
                              e.id.toString() == hatchery.locationId.toString(),
                        );
                      } catch (e) {}

                      return _buildInfoRow(
                        Icons.location_on,
                        location != null ? location.title : '',
                      );
                    },
                  ),
                  // if (hatchery.locationName?.isNotEmpty ?? false)
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _actionButton(
                        label: "Call Now",
                        icon: 'assets/images/phone.png',
                        color: AppColors.primary,
                        onTap: () => _makePhoneCall(hatchery.callUrl),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        label: "WhatsApp",
                        icon: 'assets/images/whatsApp.png',
                        color: Colors.white,
                        textColor: Colors.green,
                        borderColor: Colors.green,
                        onTap: () =>
                            _launchUrl(hatchery.whatsappUrl ?? '', context),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        label: "Book Now",
                        icon: 'assets/images/Lightning.png',
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20.0),
                                  ),
                                ),
                                child: BookingBottomSheet(
                                  price: '',
                                  categoryId: widget.spotHatchery.categoryId.toString(),
                                  isSpotHatchery: false,
                                  hatcheryId: hatchery.hatcheryId.toString(),
                                  hatcheryName: hatchery.hatcheryName,
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required String icon,
    required Color color,
    Color? textColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, height: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: textColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String? url) async {
    if (url == null) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot launch URL")));
    }
  }
}
