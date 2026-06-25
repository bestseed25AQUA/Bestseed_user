import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
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


class UpdatesScreen extends StatefulWidget {
  UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initunc();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      hatcheryUpdatesController.fetchMoreHatcheryUpdates();
    }
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
            controller: _scrollController,
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
                Obx(() {
                  if (!hatcheryUpdatesController.isLoadingMoreUpdates.value) {
                    return const SizedBox.shrink();
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
  bool _isExpanded = false;
  bool _needsExpand = false;
  final GlobalKey _htmlKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsExpand();
    });
  }

  void _checkIfNeedsExpand() {
    final renderBox = _htmlKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final contentHeight = renderBox.size.height;
      if (contentHeight > 42 && !_needsExpand) {
        setState(() {
          _needsExpand = true;
        });
      }
    }
  }

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
                              widget.postData?.profileImage ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: Text(
                                    (widget.postData?.hatcheryName ?? '').isNotEmpty
                                        ? widget.postData!.hatcheryName![0].toUpperCase()
                                        : 'B',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
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
                if (widget.postData?.caption != null && widget.postData!.caption!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isExpanded && _needsExpand)
                        SizedBox(
                          height: 42,
                          child: Wrap(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              HtmlWidget(
                                widget.postData?.caption ?? '',
                                textStyle: GoogleFonts.roboto(fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      else
                        HtmlWidget(
                          key: _needsExpand ? null : _htmlKey,
                          widget.postData?.caption ?? '',
                          textStyle: GoogleFonts.roboto(fontSize: 14),
                        ),
                      if (_needsExpand)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Text(
                            _isExpanded ? ' View Less' : ' View More',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.postData?.caption != null && widget.postData!.caption!.trim().isNotEmpty)
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
                        final callUrl = widget.postData?.callUrl?.toString() ?? '';
                        if (callUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Contact number not available")),
                          );
                          return;
                        }
                        final Uri callUri = Uri.parse(callUrl);

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
                        final whatsappUrl = widget.postData?.whatsappUrl?.toString() ?? '';
                        if (whatsappUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("WhatsApp number not available")),
                          );
                          return;
                        }
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
                            widget.postData?.facebookUrl?.toString() ?? '';
                        if (fbPage.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Facebook link not available"),
                            ),
                          );
                          return;
                        }
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
                    final link = widget.postData?.shareLink ?? '';
                    if (link.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Share link not available"),
                        ),
                      );
                      return;
                    }
                    Share.share(
                      link,
                      subject: widget.postData?.hatcheryName ?? 'Bestseed Update',
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
