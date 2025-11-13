import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/updates/model/hatchery_update_model.dart';
import 'package:seedsuser/app/updates/view/hatchery_details_screen.dart';
import 'package:seedsuser/app/updates/widget/updates_banner_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatesScreen extends StatefulWidget {
  UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());

  @override
  void initState() {
    // TODO: implement initState
    hatcheryUpdatesController.fetchHatcheryUpdates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
        title: Text(
          'Updates',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Get.to(() => LanguageSelectionScreen());
            },
            child: Image.asset('assets/images/lan_image.png', height: 32),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => NotificationsScreen());
            },
            child: Image.asset('assets/images/notification.png', height: 32),
          ),
          SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => ProfileScreen());
            },
            child: Image.asset('assets/images/person.png', height: 32),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Image.asset('assets/images/us.png'),
            // ),
            // CarouselCardsScreen(),
            SizedBox(height: 16),
            UpdatesBannerWidget(),
            Obx(() {
              if (hatcheryUpdatesController.isLoading.value) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * .3,
                  ),
                  child: CircularProgressIndicator(),
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
                      hatcheryUpdatesController.fetchHatcherySpecificUpdates(
                        hatcheryUpdatesController
                                .hatcheryData
                                .value
                                ?.data?[index]
                                .id
                                .toString() ??
                            '',
                      );
                      Get.to(() => HatcheryDetailsScreen());
                    },
                  );
                },
              );
            }),
          ],
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
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.ontap,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 0.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(.1),
                    backgroundImage: AssetImage(
                      widget.postData?.profileImage ?? "",
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (widget.postData?.hatcheryName?.isEmpty ?? true)
                          ? Container(
                              height: 15,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.1),
                              ),
                            )
                          : Text(
                              widget.postData?.hatcheryName ?? '',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                      Text(
                        widget.postData?.postedOn ?? '',
                        style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Post Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                widget.postData?.caption ?? '',
                style: GoogleFonts.roboto(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            // Media Carousel
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.1),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.postData?.mediaFiles?.length,
                    itemBuilder: (context, index) {
                      return CustomNetworkImage(
                        imageUrl: widget.postData?.mediaFiles?[index] ?? '',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                // Page Indicator Dots
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.postData?.mediaFiles?.length ?? 0,
                      (index) => buildDot(index),
                    ),
                  ),
                ),
              ],
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // CALL BUTTON
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
                        child: Image.asset(
                          'assets/images/call.png',
                          height: 38,
                        ),
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
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 6,
      width: _currentPage == index ? 12 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
