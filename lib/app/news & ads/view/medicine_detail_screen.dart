import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/full_media_screen.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/single_new_detail_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;
  const MedicineDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tag,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final singleNewDetailController = Get.put(SingleNewDetailController());

  // Guards against re-opening the fullscreen route on every Obx rebuild
  // (isLoading→false transitions, controller refreshes, etc.). Same pattern
  // as TrendingUpdatesDetailsScreen.
  bool _didAutoOpenFullscreen = false;

  // Check if URL is a video
  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m3u8') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');
  }

  /// If the post's first media is a video, auto-push the full-screen player
  /// once so the user lands in fullscreen immediately after tapping a card
  /// on the medicine-news View All list. Back button returns them to this
  /// detail screen (small preview + description).
  void _maybeAutoOpenFullscreen(List<String> mediaUrls, List<String> mediaTypes) {
    if (_didAutoOpenFullscreen) return;
    if (mediaUrls.isEmpty) return;
    final firstType = (mediaTypes.isNotEmpty ? mediaTypes.first : '').toLowerCase();
    final firstUrl = mediaUrls.first;
    final isVideo = firstType.contains('video') || _isVideoUrl(firstUrl);
    if (!isVideo) return;
    _didAutoOpenFullscreen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullMediaScreen(
            mediaUrls: mediaUrls,
            mediaTypes: mediaTypes,
            initialIndex: 0,
            title: widget.title,
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    singleNewDetailController.fetch(type: "medicine news", id: widget.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        backgroundColor: Colors.blue[800],
        // automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
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
      body: Column(
        children: <Widget>[
          // Scrollable content area
          Obx(() {
            // if (singleNewDetailController.singleDetailData.value == null ||
            //     singleNewDetailController.isLoading.value) {
            //   return medicineShimmer();
            // }
            final data = singleNewDetailController.singleDetailData.value;

            // Build media arrays from detail API with fallback
            final mediaUrls =
                (data?.data?.mediaFiles != null &&
                    data!.data!.mediaFiles!.isNotEmpty)
                ? data.data!.mediaFiles!
                : [widget.imageUrl];
            final mediaTypes =
                (data?.data?.mediaTypes != null &&
                    data!.data!.mediaTypes!.isNotEmpty)
                ? data.data!.mediaTypes!
                : [_isVideoUrl(widget.imageUrl) ? 'video' : 'image'];

            // Auto-open full-screen player once, if the first media is a video.
            _maybeAutoOpenFullscreen(mediaUrls, mediaTypes);

            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Media Carousel Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MediaCarouselWidget(
                        mediaUrls: mediaUrls,
                        mediaTypes: mediaTypes,
                        borderRadius: 16,
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Title and Brand
                    Text(
                      widget.title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (widget.title.isNotEmpty) const SizedBox(height: 4.0),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    if (widget.subtitle.isNotEmpty) const SizedBox(height: 8.0),

                    // Description/Details Section
                    Builder(
                      builder: (context) {
                        if (singleNewDetailController.isLoading.value) {
                          return medicineShimmer();
                        }
                        return HtmlWidget(
                          data?.data?.description ?? '',
                          textStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final data = singleNewDetailController.singleDetailData.value?.data;
        final callNum = data?.callNumber ?? '';
        final whatsappUrl = data?.whatsappNumber ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 30),
          child: Row(
            children: <Widget>[
              // Call Now Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: callNum.isNotEmpty
                      ? () => _makePhoneCall(callNum)
                      : null,
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text(
                    'Call Now',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // WhatsApp Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: whatsappUrl.isNotEmpty
                      ? () => _launchWhatsApp(whatsappUrl)
                      : null,
                  icon: Image.asset(
                    'assets/images/whatsApp.png',
                    height: 20,
                    width: 20,
                  ),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.roboto(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _launchWhatsApp(String whatsappUrl) async {
    final Uri launchUri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String callUrl) async {
    final Uri launchUri = Uri.parse(callUrl);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // Helper function to build the bulleted list section
  Widget _buildIngredientSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: GoogleFonts.roboto(fontSize: 15)),
                Expanded(
                  child: Text(item, style: GoogleFonts.roboto(fontSize: 15)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

Widget medicineShimmer() {
  return Column(
    children: List.generate(5, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }),
  );
}
