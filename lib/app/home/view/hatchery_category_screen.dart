import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:seedsuser/app/home/hatchery_details.dart';
import 'package:seedsuser/app/home/model/hatchery_category_model.dart';
import 'package:seedsuser/app/home/widget/hachery_category_banner_widget.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class HatcheryCateogryScreen extends StatefulWidget {
  const HatcheryCateogryScreen({super.key, required this.hatcheryId});
  final String hatcheryId;

  @override
  State<HatcheryCateogryScreen> createState() => _HatcheryCateogryScreenState();
}

class _HatcheryCateogryScreenState extends State<HatcheryCateogryScreen> {
  final HatcheryCategoryController hatcheryCategoryController = Get.put(
    HatcheryCategoryController(),
  );
  @override
  void initState() {
    hatcheryCategoryController.fetchBanners('50');
    hatcheryCategoryController.fetchHetcheryCategory('50');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hatchery Categories",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            HatcheryCategoryBannerWidget(),
            SizedBox(height: 20),
            Obx(() {
              if (hatcheryCategoryController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (hatcheryCategoryController.hatcheryCateogoryData.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      "No hatcheries found.",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(
                  hatcheryCategoryController.hatcheryCateogoryData.length,
                  (index) {
                    final hatcheryCat =
                        hatcheryCategoryController.hatcheryCateogoryData[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 20),
                      child: HarcheryCardWidget(hatcheryCategory: hatcheryCat),
                    );
                  },
                ),
              );
            }),

            // SizedBox(
            //   height: 400,
            //   child: Builder(
            //     builder: (context) {
            //       if (hatcheryCategoryController.isLoading.value) {
            //         return const Center(
            //           child: CircularProgressIndicator(
            //             color: AppColors.primary,
            //           ),
            //         );
            //       }

            //       if (hatcheryCategoryController
            //           .hatcheryCateogoryData
            //           .isEmpty) {
            //         return Center(
            //           child: Text(
            //             "No hatcheries found.",
            //             style: GoogleFonts.roboto(
            //               fontSize: 16,
            //               color: Colors.grey,
            //             ),
            //           ),
            //         );
            //       }
            //       return Center(
            //         child: Text(
            //           "No hatcheries found.",
            //           style: GoogleFonts.roboto(
            //             fontSize: 16,
            //             color: Colors.grey,
            //           ),
            //         ),
            //       );
            //       // return Row(
            //       //   children: List.generate(
            //       //     hatcheryCategoryController.hatcheryCateogoryData.length,
            //       //     (index) {
            //       //       return Padding(
            //       //         padding: const EdgeInsets.only(bottom: 6, top: 20),
            //       //         child: _HatcheryGridCard(
            //       //          hatchery: hatcheryCategoryController
            //       //           .hatcheryCateogoryData.,
            //       //         ),
            //       //       );
            //       //     },
            //       //   ),
            //       // );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class HarcheryCardWidget extends StatefulWidget {
  const HarcheryCardWidget({super.key, required this.hatcheryCategory});

  final HatcheryCategoryData hatcheryCategory;

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
    final hatchery = widget.hatcheryCategory;

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
        Get.to(() => HatcheryDetail(videoUrl: 'assets/videos/sample.mp4'));
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
              blurRadius: 16,
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
              child: InkWell(
                onTap: () {
                  print('image url');
                  print((
                    hatchery.images?.isEmpty ?? false ? hatchery.images : '',
                  ));
                },
                child: Image.network(
                  (hatchery.images?.isEmpty ?? false)
                      ? hatchery.toString()
                      : '',
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
            ),
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
                          hatchery.hatcheryName ?? '',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: Colors.green,
                      //     borderRadius: BorderRadius.circular(30.0),
                      //   ),
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 12,
                      //     vertical: 8,
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       const Icon(
                      //         Icons.check_circle,
                      //         color: Colors.white,
                      //         size: 18,
                      //       ),
                      //       const SizedBox(width: 6),
                      //       SizedBox(
                      //         width: MediaQuery.of(context).size.width * .34,
                      //         child: Text(
                      //           "Available on ${hatchery.availableOn}",
                      //           style: GoogleFonts.roboto(
                      //             color: Colors.white,
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    hatchery.category?.name ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .4,
                        child: _buildInfoRow(
                          Icons.location_on,
                          'Unit-1',
                          hatchery.location?.name ?? "",
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * .4,
                        child: _buildInfoRow(
                          Icons.location_on,
                          'Unit-2',
                          hatchery.location?.name ?? "",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoRow(
                        Icons.water_drop_outlined,
                        "${hatchery.broodstock?.length ?? ""} Pieces",
                        "Broodstock",
                      ),
                      if (hatchery.availableOn != null)
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Available Date",
                          formatDate(hatchery.availableOn ?? DateTime.now()),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildInfoRow(
                        Icons.timer,
                        "Price",
                        "₹${hatchery.prices?.first.price ?? ""}",
                      ),
                    ],
                  ),
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
                                  hatcheryId: hatchery.id.toString(),
                                  hatcheryName: hatchery.hatcheryName ?? '',
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .3,
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildInfoRow(IconData icon, String label) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 18, color: AppColors.primary),
  //       const SizedBox(width: 8),
  //       Flexible(
  //         child: Text(
  //           label,
  //           style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
  //         ),
  //       ),
  //     ],
  //   );
  // }

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

String formatDate(DateTime date) {
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  String day = date.day.toString().padLeft(2, '0');
  String month = months[date.month - 1];
  String year = date.year.toString();

  return "$day $month $year";
}

class _HatcheryGridCard extends StatelessWidget {
  final HatcheryCategoryData hatchery;

  const _HatcheryGridCard({required this.hatchery});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => HatcheryDetail(videoUrl: 'assets/videos/sample.mp4'));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Image.network(
                (hatchery.images?.isEmpty ?? true)
                    ? ""
                    : hatchery.images!.first,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 120, color: Colors.grey.withOpacity(.2)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HATCHERY NAME
                  Text(
                    hatchery.hatcheryName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // CATEGORY NAME
                  Text(
                    hatchery.category?.name ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // LOCATION
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          hatchery.location?.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // BROODSTOCK COUNT
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${hatchery.broodstock?.length ?? 0} Pieces",
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // AVAILABLE DATE
                  if (hatchery.availableOn != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(hatchery.availableOn!),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // PRICE
                  Text(
                    "₹${hatchery.prices?.first.price ?? ''}",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
}
