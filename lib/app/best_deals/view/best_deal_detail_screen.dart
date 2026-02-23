import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/best_deals/controller/best_deals_controller.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class BestDealDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  const BestDealDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  State<BestDealDetailScreen> createState() => _BestDealDetailScreenState();
}

class _BestDealDetailScreenState extends State<BestDealDetailScreen> {
  final controller = Get.put(BestDealsController());

  @override
  void initState() {
    super.initState();
    controller.fetchDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        backgroundColor: Colors.blue[800],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Obx(() {
            final data = controller.bestDealDetail.value?.data;

            final mediaUrls =
                (data?.mediaFiles != null && data!.mediaFiles!.isNotEmpty)
                ? data.mediaFiles!
                : [widget.imageUrl];
            final mediaTypes =
                (data?.mediaTypes != null && data!.mediaTypes!.isNotEmpty)
                ? data.mediaTypes!
                : ['image'];

            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media Carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MediaCarouselWidget(
                        mediaUrls: mediaUrls,
                        mediaTypes: mediaTypes,
                        borderRadius: 16,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Title
                    Text(
                      data?.title ?? widget.title,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if ((data?.subtitle ?? widget.subtitle).isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        data?.subtitle ?? widget.subtitle,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.0),
                    // Description
                    Builder(
                      builder: (context) {
                        if (data == null && controller.isDetailLoading.value) {
                          return _descriptionShimmer();
                        }
                        return HtmlWidget(
                          data?.description ?? '',
                          textStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.black45,
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
        final data = controller.bestDealDetail.value?.data;
        final callNum = data?.callNumber ?? '';
        final whatsappUrl = data?.whatsappNumber ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 30),
          child: Row(
            children: [
              // Enquiry Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: callNum.isNotEmpty
                      ? () => _makePhoneCall(callNum)
                      : null,
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text(
                    'Enquiry',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _descriptionShimmer() {
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
}
