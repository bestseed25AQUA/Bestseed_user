import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_icon_appbar.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/updates/model/hatchery_update_model.dart';
import 'package:seedsuser/app/updates/view/hatchery_details_screen.dart';
import 'package:seedsuser/app/updates/view/widgets/post_shimmer_widget.dart';
import 'package:seedsuser/app/utils/app_size.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:readmore/readmore.dart';

class UpdatesScreen extends StatefulWidget {
  UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());

  @override
  void initState() {
    super.initState();
    initunc();
  }

  initunc() async {
    // await hatcheryUpdatesController.fetchBanners();
    if (hatcheryUpdatesController.hatcheryData.value == null) {
      await hatcheryUpdatesController.fetchHatcheryUpdates();
    }
  }

  final dashboardCtrl = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          dashboardCtrl.changeIndex(0);
        }
      },

      child: Scaffold(
        appBar: CustomIconAppbar(title: 'Updates', showBackButton: false),
        backgroundColor: Colors.white,
        body: CustomRefereshIndicator(
          onRefresh: () async {
            await hatcheryUpdatesController.fetchHatcheryUpdates();
          },

          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // SizedBox(height: 16),
                // Obx(() {
                //   return Container(
                //     decoration: BoxDecoration(color: Colors.grey.withOpacity(.3)),
                //     child: MediaCarouselWidget(
                //       mediaUrls: List.generate(
                //         hatcheryUpdatesController.banners.length,
                //         (index) => hatcheryUpdatesController.banners[index].url,
                //       ),

                //       mediaTypes: List.generate(
                //         hatcheryUpdatesController.banners.length,
                //         (index) => hatcheryUpdatesController.banners[index].type,
                //       ),
                //     ),
                //   );
                // }),
                SizedBox(height: 5),
                Obx(() {
                  if (hatcheryUpdatesController.isLoading.value ||
                      hatcheryUpdatesController.hatcheryData.value?.data ==
                          null) {
                    return Column(
                      children: List.generate(4, (index) => postShimmerCard()),
                    );
                  }

                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        hatcheryUpdatesController
                            .hatcheryData
                            .value
                            ?.data
                            ?.length ??
                        0,
                    itemBuilder: (context, index) {
                      return PostWidget(
                        postData: hatcheryUpdatesController
                            .hatcheryData
                            .value
                            ?.data?[index],
                        ontap: () {
                          Get.to(
                            () => HatcheryDetailsScreen(
                              id:
                                  hatcheryUpdatesController
                                      .hatcheryData
                                      .value
                                      ?.data?[index]
                                      .hatcheryId
                                      ?.toString() ??
                                  '',
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatefulWidget {
  final HatcheryData? postData;

  final VoidCallback? ontap;
  const PostWidget({super.key, required this.postData, this.ontap});

  @override
  // ignore: library_private_types_in_public_api
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 0.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.ontap,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.postData?.thumbnail ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.person),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              (widget.postData?.hatcheryName?.isEmpty ?? true)
                                  ? Container(
                                      height: 15,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.1),
                                      ),
                                    )
                                  : Text(
                                      widget.postData?.hatcheryName ?? '',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.postData?.title ?? '',
                                      style: GoogleFonts.roboto(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.postData?.postedOn ?? '',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey,
                                      fontSize: 14,
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
                ),
                // Post Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ReadMoreText(
                    widget.postData?.caption ?? '',
                    trimLines: 2,
                    colorClickableText: Colors.blue,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' View More',
                    trimExpandedText: ' View Less',
                    style: GoogleFonts.roboto(fontSize: 14),
                    moreStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    lessStyle: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Builder(
                    builder: (context) {
                      final tags = widget.postData?.hashtags ?? [];
                      final formatted = tags.toString();
                      return Text(
                        formatted.replaceAll('[', '').replaceAll(']', ''),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Post Header
          // Media Carousel
          Container(
            height: AppSize.height * .25,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(color: Colors.black.withOpacity(.1)),
            child: Builder(
              builder: (context) {
                final urls =
                    widget.postData?.mediaFiles
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                final types =
                    widget.postData?.mediaTypes
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];
                return MediaCarouselWidget(
                  title: widget.postData?.hatcheryName ?? '',
                  mediaUrls: urls,
                  mediaTypes: types,
                  mediaType: widget.postData?.mediaType ?? "",
                  height: 350,
                  borderRadius: 0,
                );
              },
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final phone =
                            widget.postData?.callUrl ??
                            "0000000000"; // Replace key if needed
                        final Uri callUri = Uri(scheme: 'tel', path: phone);

                        if (await canLaunchUrl(callUri)) {
                          await launchUrl(
                            callUri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cannot make call")),
                          );
                        }
                      },
                      child: Image.asset('assets/images/call.png', height: 38),
                    ),

                    const SizedBox(width: 12),

                    // WHATSAPP BUTTON
                    InkWell(
                      onTap: () async {
                        final phone =
                            widget.postData?.whatsappUrl ??
                            ""; // Should be number only
                        final whatsappUrl = "https://wa.me/$phone";

                        final Uri uri = Uri.parse(whatsappUrl);

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cannot launch WhatsApp"),
                            ),
                          );
                        }
                      },
                      child: Image.asset(
                        'assets/images/whatsApp.png',
                        height: 32,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // FACEBOOK BUTTON
                    IconButton(
                      icon: const Icon(Icons.facebook),
                      color: Colors.blue,
                      onPressed: () async {
                        final fbPage =
                            widget.postData?.facebookUrl ??
                            ""; // Example: https://facebook.com/xyz
                        final Uri uri = Uri.parse(fbPage);

                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cannot open Facebook"),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Share.share(
                      widget.postData?.shareLink ?? '',
                      subject: 'Vehicle Tracking Info',
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
