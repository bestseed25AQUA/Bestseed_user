import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/widget/home_banner_carousel.dart'
    hide VideoPlayerBanner;
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_ads_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_banner_controller.dart';
import 'package:seedsuser/app/news%20&%20ads/view/climate_news_detail_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/climate_news_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_detail_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_news_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/trending_updates_details_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/view/trending_updates_screen.dart';
import 'package:seedsuser/app/news%20&%20ads/widget/news_banner_widget.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:video_player/video_player.dart';

class NewsAdsScreen extends StatefulWidget {
  const NewsAdsScreen({super.key});

  @override
  State<NewsAdsScreen> createState() => _NewsAdsScreenState();
}

class _NewsAdsScreenState extends State<NewsAdsScreen> {
  late VideoPlayerController _controller;
  bool videoStarted = false;
  final newsAdsController = Get.put(NewsAdsController());
  final newsBannerController = Get.put(NewsBannerController());
  final locationController = Get.put(LocationController());
  final homeController = Get.put(HomeController());

  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    // Initialize controller in initState
    // newsBannerController.fetchBanners(
    //   homeController.selectedCategoryId.value,
    //   locationController.selectedLocationId.value,
    // );
    _controller =
        VideoPlayerController.asset('assets/images/video_20250921_103157.mp4')
          ..initialize().then((_) {
            setState(() {}); // Refresh UI when initialized
          })
          ..setLooping(false); // No looping
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void checkAsset() async {
    try {
      await rootBundle.load('assets/images/video_20250921_103157.mp4');
      debugPrint("Asset exists and loaded");
    } catch (e) {
      debugPrint("Asset not found  ");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
        title: Text(
          'News & Ads',
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
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => ProfileScreen());
            },
            child: Image.asset('assets/images/person.png', height: 32),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSectionHeader('Trending updates', () {
            //   Get.to(() => TrendingUpdatesScreen());
            // }),
            // _buildTrendingSection(),
            const SizedBox(height: 16),

            // NewsBannerWidget(),
            Obx(() {
              if (newsAdsController.newsAdsData.value?.data == null) {
                return Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .3,
                    ),
                    child: InkWell(
                      onTap: () {
                        Get.to(TrendingUpdatesDetailsScreen(id: '', title: '',));
                      },
                      child: CircularProgressIndicator()),
                  ),
                );
              }
              return Column(
                children: [
                  _buildSectionHeader('Trending Update', () {
                    Get.to(TrendingUpdatesScreen());
                  }),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider.builder(
                        itemCount:
                            newsAdsController
                                .newsAdsData
                                .value
                                ?.data
                                ?.trendingUpdate
                                ?.length ??
                            0,
                        itemBuilder: (context, index, realIndex) {
                          final data = newsAdsController
                              .newsAdsData
                              .value
                              ?.data
                              ?.trendingUpdate?[index];
                          if (data?.mediaType == "image") {
                            return GestureDetector(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(.7),
                                  border: Border.all(
                                    width: .1,
                                    color: Colors.grey,
                                  ),
                                  boxShadow: [BoxShadow(color: Colors.grey)],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    data?.mediaPath ?? '',
                                    width: double.infinity,
                                    height: 180,
                                    errorBuilder: (context, error, stackTrace) {
                                      return SizedBox(height: 180);
                                    },
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          } else if (data?.mediaType == "video") {
                            return GestureDetector(
                              onTap: () {
                                Get.to(
                                  () => FullScreenVideoPlayer(
                                    videoUrl: data?.mediaPath ?? "",
                                  ),
                                );
                              },
                              child: VideoPlayerBanner(
                                url: data?.mediaPath ?? "",
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                        options: CarouselOptions(
                          height: 160,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index; // update current index
                            });
                          },
                        ),
                      ),

                      // Indicator Dots
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Builder(
                          builder: (context) {
                            try {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    newsAdsController
                                            .newsAdsData
                                            ?.value
                                            ?.data
                                            ?.trendingUpdate
                                            ?.asMap()
                                            .entries
                                            .map((entry) {
                                              return Container(
                                                    width: 8.0,
                                                    height: 8.0,
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          _currentIndex ==
                                                              entry.key
                                                          ? Colors
                                                                .blue // Active dot
                                                          : Colors
                                                                .grey, // Inactive dot
                                                    ),
                                                  )
                                                  as Widget;
                                            })
                                            .toList()
                                        as List<Widget>,
                              );
                            } catch (e) {
                              SizedBox();
                            } finally {
                              // ignore: control_flow_in_finally
                              return SizedBox();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Medicine news', () {
                    Get.to(() => const MedicineNewsScreen());
                  }),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      children: List.generate(
                        newsAdsController
                                .newsAdsData
                                ?.value
                                ?.data
                                ?.medicineNews
                                ?.length ??
                            0,
                        (index) {
                          final data = newsAdsController
                              .newsAdsData
                              ?.value
                              ?.data
                              ?.medicineNews?[index];
                          return _buildNewsCard(
                            data?.medicineName ?? "",
                            data?.curesFor ?? "",
                            data?.mediaPath ?? "",
                            () {
                              Get.to(
                                () => MedicineDetailScreen(
                                  id: data?.id.toString() ?? '',
                                  title: data?.medicineName.toString() ?? '',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Climate news', () {
                    Get.to(ClimateNewsScreen());
                  }),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      children: List.generate(
                        newsAdsController
                                .newsAdsData
                                ?.value
                                ?.data
                                ?.climateNews
                                ?.length ??
                            0,
                        (index) {
                          final data = newsAdsController
                              .newsAdsData
                              .value
                              ?.data
                              ?.climateNews?[index];
                          return _buildNewsCard(
                            data?.title ?? "",
                            null,
                            data?.mediaPath ?? "",
                            () {
                              Get.to(
                                () => ClimateDetailScreen(
                                  id: data?.id.toString() ?? '',
                                  title: data?.title ?? '',
                                  // title: data?.n.toString() ?? '',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAllTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onViewAllTap,
            child: Text(
              'View All',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTrendingSection() {
  //   return GestureDetector(
  //     onTap: () async {
  //       setState(() => videoStarted = true);
  //       _controller = VideoPlayerController.asset(
  //         'assets/images/video_20250921_103157.mp4',
  //       );
  //       setState(() {}); // show loading indicator
  //       await _controller.initialize();
  //       _controller.setLooping(false);
  //       _controller.play();

  //       // Listener to update UI and detect end
  //       _controller.addListener(() {
  //         if (_controller.value.position >= _controller.value.duration) {
  //           setState(() {
  //             videoStarted = false; // video ended
  //           });
  //         } else {
  //           setState(() {}); // update position/time
  //         }
  //       });

  //       setState(() {}); // refresh UI after initialization
  //     },
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(16),
  //         child: SizedBox(
  //           width: double.infinity,
  //           height: 200,
  //           child: _controller.value.isInitialized
  //               ? Stack(
  //                   alignment: Alignment.center,
  //                   children: [
  //                     // Video Player
  //                     SizedBox(
  //                       width: double.infinity,
  //                       child: AspectRatio(
  //                         aspectRatio: _controller.value.aspectRatio,
  //                         child: VideoPlayer(_controller),
  //                       ),
  //                     ),
  //                     // Play/Pause Button
  //                     GestureDetector(
  //                       onTap: () {
  //                         setState(() {
  //                           _controller.value.isPlaying
  //                               ? _controller.pause()
  //                               : _controller.play();
  //                         });
  //                       },
  //                       child: Icon(
  //                         _controller.value.isPlaying
  //                             ? Icons.pause_circle_filled
  //                             : Icons.play_circle_fill,
  //                         color: Colors.white,
  //                         size: 60,
  //                       ),
  //                     ),
  //                     // Video Progress / Time
  //                     Positioned(
  //                       bottom: 8,
  //                       right: 8,
  //                       child: Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 6,
  //                           vertical: 2,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.black54,
  //                           borderRadius: BorderRadius.circular(4),
  //                         ),
  //                         child: Text(
  //                           '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
  //                           style: const TextStyle(color: Colors.white),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               // : Stack(
  //               //     alignment: Alignment.center,
  //               //     children: [
  //               //       const Icon(
  //               //         Icons.play_circle_fill,
  //               //         color: Colors.white,
  //               //         size: 60,
  //               //       ),
  //               //     ],
  //               //   )
  //               : const Center(
  //                   child: CircularProgressIndicator(color: AppColors.primary),
  //                 ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Helper to format duration as mm:ss
  // String _formatDuration(Duration duration) {
  //   String twoDigits(int n) => n.toString().padLeft(2, '0');
  //   final minutes = twoDigits(duration.inMinutes.remainder(60));
  //   final seconds = twoDigits(duration.inSeconds.remainder(60));
  //   return '$minutes:$seconds';
  // }

  Widget _buildNewsCard(
    String title,
    String? subtitle,
    String imageUrl,
    VoidCallback ontap,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: ontap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(.7),
                  border: Border.all(width: .1, color: Colors.grey),
                  boxShadow: [BoxShadow(color: Colors.grey)],
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(height: 120, width: 150);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
