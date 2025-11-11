import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class HatcheryDetailsScreen extends StatefulWidget {
  const HatcheryDetailsScreen({super.key});

  @override
  State<HatcheryDetailsScreen> createState() => _HatcheryDetailsScreenState();
}

class _HatcheryDetailsScreenState extends State<HatcheryDetailsScreen> {
  int _currentIndex = 0;

  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());

  final List<String> imageList = [
    'assets/images/WhatsApp Image 2025-10-04 at 1.24.19 PM.jpeg',
    'assets/images/WhatsApp Image 2025-10-04 at 1.24.17 PM.jpeg',
    'assets/images/rama.png',
    'assets/images/rama.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return CustomScrollView(
          slivers: [
            /// HEADER SLIVER APPBAR
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/rama.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hatcheryUpdatesController
                                        .hatcherySpecificUpdateData
                                        .value
                                        ?.data
                                        ?.hatcheryName ??
                                    '',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Color(0xFF0076BE), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                hatcheryUpdatesController
                                        .hatcherySpecificUpdateData
                                        .value
                                        ?.data
                                        ?.location ??
                                    '',
                                style: GoogleFonts.roboto(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// LOADING STATE
            if (hatcheryUpdatesController.isHatcherySpecificUpdateLoading.value)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .35),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else
              /// MAIN POST LIST
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/rama.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hatcheryUpdatesController
                                        .hatcherySpecificUpdateData
                                        .value
                                        ?.data
                                        ?.hatcheryName ??
                                    '',
                                style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                'Posted 2 days ago',
                                style: GoogleFonts.roboto(color: Colors.grey),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Rama Hatchery\'s new crop SyAqua farming 🦐..... #Aquaculture #Shrimp #Water #PremiumQuality',
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),

                          const SizedBox(height: 16),

                          CarouselSlider(
                            items: imageList.map((imagePath) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  imagePath,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                            options: CarouselOptions(
                              height: 250,
                              viewportFraction: 1,
                              autoPlay: true,
                              onPageChanged: (index, reason) {
                                setState(() => _currentIndex = index);
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: List.generate(
                              imageList.length,
                              (dotIndex) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentIndex == dotIndex ? 10 : 8,
                                height: _currentIndex == dotIndex ? 10 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentIndex == dotIndex
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final callUrl =
                                          "tel:${hatcheryUpdatesController.hatcherySpecificUpdateData.value?.data?.vendorMobile ?? ''}";
                                      final uri = Uri.parse(callUrl);
                                      if (await canLaunchUrl(uri)) {
                                        launchUrl(uri);
                                      }
                                    },
                                    child: Image.asset('assets/images/call.png',
                                        height: 38),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      final whatsappUrl =
                                          hatcheryUpdatesController
                                                  .hatcherySpecificUpdateData
                                                  .value
                                                  ?.data
                                                  ?.whatsappUrl ??
                                              '';
                                      final uri = Uri.parse(whatsappUrl);
                                      if (await canLaunchUrl(uri)) {
                                        launchUrl(uri);
                                      }
                                    },
                                    child: Image.asset(
                                        'assets/images/whatsApp.png',
                                        height: 32),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.facebook),
                                    onPressed: () {},
                                    color: Colors.blue.shade800,
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: 8,
                ),
              ),
          ],
        );
      }),
    );
  }
}
