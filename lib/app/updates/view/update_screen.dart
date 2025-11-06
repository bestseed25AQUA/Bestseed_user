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

class UpdatesScreen extends StatelessWidget {
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());
  UpdatesScreen({super.key});

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

  const PostWidget({super.key, required this.postData});

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
      onTap: () {
        Get.to(() => HatcheryDetailsScreen());
      },
      child: Card(
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
                    backgroundImage: AssetImage(
                      widget.postData?.profileImage ?? "",
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                SizedBox(
                  height: 250,
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
                      Image.asset('assets/images/call.png', height: 38),
                      InkWell(
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
                        child: Image.asset(
                          'assets/images/whatsApp.png',
                          height: 32,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.facebook),
                        onPressed: () {},
                        color: Colors.blue.shade800,
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Share.share(
                        'Check out this delivery tracking app: https://example.com',
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
