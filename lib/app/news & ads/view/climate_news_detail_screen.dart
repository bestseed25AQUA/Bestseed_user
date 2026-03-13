import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/single_new_detail_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';

import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ClimateDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;
  const ClimateDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl, required this.tag,
  });

  @override
  State<ClimateDetailScreen> createState() => _ClimateDetailScreenState();
}

class _ClimateDetailScreenState extends State<ClimateDetailScreen> {
  final String _whatsappNumber = '918977778784';

  // Optional: Define a pre-filled message
  final String _initialMessage =
      'Hello, I am interested in the Probiotic Powder.';
  final singleNewDetailController = Get.put(SingleNewDetailController());

  // Check if URL is a video
  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m3u8') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');
  }

  @override
  void initState() {
    singleNewDetailController.fetch(type: "climate news", id: widget.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        
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
            //   return Padding(
            //     padding: EdgeInsets.only(
            //       top: MediaQuery.of(context).size.height * .3,
            //     ),
            //     child: Align(
            //       alignment: Alignment.center,
            //       child: CircularProgressIndicator(),
            //     ),
            //   );
            // }

            final data = singleNewDetailController.singleDetailData.value;

            // Build media arrays from detail API with fallback
            final mediaUrls = (data?.data?.mediaFiles != null && data!.data!.mediaFiles!.isNotEmpty)
                ? data.data!.mediaFiles!
                : [widget.imageUrl];
            final mediaTypes = (data?.data?.mediaTypes != null && data!.data!.mediaTypes!.isNotEmpty)
                ? data.data!.mediaTypes!
                : [_isVideoUrl(widget.imageUrl) ? 'video' : 'image'];

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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Description/Details Section
                    Builder(
                      builder: (context) {
                        if (singleNewDetailController.isLoading.value) {
                          return medicineShimmer();
                        }
                        return HtmlWidget(
                          data?.data?.description ?? '',
                          textStyle: GoogleFonts.roboto(
                            fontSize: 12,
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
    );
  }

  // Function to launch WhatsApp
  Future<void> _launchWhatsApp() async {
    // Use the wa.me link for maximum compatibility
    final String url =
        'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(_initialMessage)}';

    final Uri launchUri = Uri.parse(url);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: Show an error if WhatsApp can't be opened
      // You might show a snackbar or dialog here
      throw 'Could not launch WhatsApp for $_whatsappNumber';
    }
  }

  Future<void> _makePhoneCall(String url) async {
    final Uri launchUri = Uri(
      scheme: 'tel', // The 'tel' scheme is used for phone numbers
      path: url,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Optionally, show a snackbar or alert if the dialer can't be launched
      throw 'Could not launch $launchUri';
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

Widget climateShimmer() {
  return Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SHIMMER
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TITLE SHIMMER
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 22,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // CAPTION SHIMMER
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 16,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // MULTILINE DESCRIPTION SHIMMER
          ...List.generate(6, (index) {
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
        ],
      ),
    ),
  );
}
