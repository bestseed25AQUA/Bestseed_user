import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/hatchery_category_detail_screen.dart';
import 'package:seedsuser/app/home/model/hatchery_category_model.dart';
import 'package:seedsuser/app/home/widget/hachery_category_banner_widget.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';
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

  final HomeController _homeController = Get.find<HomeController>();
  @override
  void initState() {
    initCall();
    super.initState();
  }

  initCall() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await hatcheryCategoryController.fetchBanners(widget.hatcheryId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      hatcheryCategoryController.fetchHetcheryCategory(widget.hatcheryId);
      // hatcheryCategoryController.fetchHetcheryCategory('50');
    });
  }

  // Resolve category name from HomeController.categories (Category.id)
  String resolvedCategoryName(SimilarHatchery hatchery) {
    try {
      final cat = _homeController.categories.firstWhere(
        (c) => c.id == (hatchery.categoryId),
        // orElse: () => Category(id: -1, categoryName: ''),
      );
      return cat.id == -1 ? '' : cat.categoryName;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Builder(
        builder: (context) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                HatcheryCategoryBannerWidget(),
                SizedBox(height: 20),
                Obx(() {
                  if (hatcheryCategoryController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .data
                      .isEmpty) {
                    return const Center(
                      child: Text('No categories for this hatchery'),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 20),
                    child: Column(
                      children: List.generate(
                        hatcheryCategoryController
                            .hatcheryCateogoryData
                            .value
                            .data
                            .length,
                        (index) {
                          final item = hatcheryCategoryController
                              .hatcheryCateogoryData
                              .value
                              .data[index];
                          return InkWell(
                            onTap: () {
                              print(widget.hatcheryId);
                              print(
                                hatcheryCategoryController
                                        .hatcheryCategoryDetailData
                                        .value
                                        .data
                                        ?.category
                                        ?.id
                                        ?.toString() ??
                                    '',
                              );
                              // return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HatcheryCategoryDetailScreen(
                                        videoUrl: 'assets/videos/sample.mp4',
                                        hatcheryId: widget.hatcheryId,
                                        categoryId: hatcheryCategoryController
                                            .hatcheryCateogoryData
                                            .value
                                            .data[index]
                                            .categories
                                            .id
                                            .toString(),
                                        // hatcheryId: widget.hatcheryId,
                                        // categoryId: hatcheryCategoryController
                                        // .hatcheryCateogoryData
                                        // .value.id.toString(),
                                      ),
                                ),
                              );
                              // Get.to(
                              //   () => HatcheryCategoryDetailScreen(
                              //     videoUrl: 'assets/videos/sample.mp4',
                              //     hatcheryId: widget.hatcheryId,
                              //     categoryId:
                              //         hatcheryCategoryController
                              //             .hatcheryCateogoryData
                              //             .value
                              //             .data[index]
                              //             .categories
                              //             .id
                              //             .toString() ??
                              //         '',
                              //     // hatcheryId: widget.hatcheryId,
                              //     // categoryId: hatcheryCategoryController
                              //     // .hatcheryCateogoryData
                              //     // .value.id.toString(),
                              //   ),
                              // );
                            },

                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: HarcheryCardWidget(
                                categoryId: item.category?.id.toString() ?? "",
                                hatcheryName: item.hatcheryName,
                                categoryName: item.category?.name ?? "",
                                imageUrl: (item.images.isEmpty)
                                    ? ""
                                    : item.images.first,

                                /// units safe parsing
                                unit1Location: item.units.isNotEmpty
                                    ? item.units[0].branchName
                                    : "",
                                unit2Location: item.units.length > 1
                                    ? item.units[1].branchName
                                    : "",

                                /// broodstock safe
                                broodstockCount: item.broodstock.toString(),

                                price: item.price,
                                availableDate: item.availableOn,
                                callUrl: item.callUrl,
                                whatsappUrl: item.whatsappUrl,
                                hatcheryId: item.id.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20),
                // ignore: prefer_is_empty

                //  Text(( hatcheryCategoryController
                //                 .hatcheryCateogoryData
                //                 .value
                //                 .similarHatcheries
                //                 ?.length ??
                //             0).toString()),
                Obx(() {
                  final similarList = hatcheryCategoryController
                      .hatcheryCateogoryData
                      .value
                      .similarHatcheries;

                  if (similarList.isEmpty) return SizedBox();

                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Similar Hatcheries',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(similarList.length, (index) {
                            final hatchery = similarList[index];

                            // ⭐ PRE-COMPUTE SAFE VALUES
                            final String categoryName = resolvedCategoryName(
                              hatchery,
                            ); // your helper function
                            final String locationName =
                                hatchery.location ?? ''; // your helper function

                            // ⭐ IMAGE SAFE
                            final String image = hatchery.image ?? "";

                            // ⭐ DATE SAFE
                            final String? availableDate =
                                hatchery.availableOn != null &&
                                    hatchery.availableOn!.trim().isNotEmpty
                                ? hatchery.availableOn
                                : null;

                            // ⭐ STATUS COLOR SAFE
                            final String statusLower = hatchery.status
                                .toLowerCase();

                            final Color statusColor = statusLower == "open"
                                ? const Color(0xff25A652)
                                : statusLower == "coming soon"
                                ? const Color(0xff007DFE)
                                : const Color(0xffE31B1B);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                              child: SizedBox(
                                height: 230,
                                width: 160,

                                child: HatcheryCard(
                                  width: 160,
                                  height: 295,
                                  ontap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HatcheryCateogryScreen(
                                              hatcheryId: hatchery.id
                                                  .toString(),
                                            ),
                                      ),
                                    );
                                  },

                                  /// ⭐ No nullable — model is safe
                                  id: hatchery.id.toString(),
                                  imagePath: image,

                                  title: hatchery.hatcheryName,
                                  location: locationName,
                                  type: categoryName,
                                  status: hatchery.status,
                                  statusColor: statusColor,
                                  availableUntil: availableDate,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HarcheryCardWidget extends StatefulWidget {
  final String hatcheryName;
  final String categoryName;
  final String unit1Location;
  final String unit2Location;
  final String imageUrl;
  final String categoryId;

  final String? availableDate;
  final String broodstockCount;
  final String price;
  final String? callUrl;
  final String? whatsappUrl;
  final String hatcheryId;

  const HarcheryCardWidget({
    super.key,
    required this.hatcheryName,
    required this.categoryName,
    required this.unit1Location,
    required this.unit2Location,
    required this.imageUrl,
    required this.broodstockCount,
    required this.price,
    required this.hatcheryId,
    this.availableDate,
    this.callUrl,
    this.whatsappUrl,
    required this.categoryId,
  });

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

  // final SeedsPriceController controller = Get.put(SeedsPriceController());
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            child: Image.network(
              widget.imageUrl,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                color: Colors.grey.withOpacity(.2),
                height: 160,
                width: double.infinity,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME + (removed badge same as original)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.hatcheryName,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // CATEGORY NAME
                Text(
                  widget.categoryName,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 8),

                // LOCATION ROWS
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .4,
                      child: _buildInfoRow(
                        Icons.location_on,
                        "Unit-1",
                        widget.unit1Location,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .4,
                      child: _buildInfoRow(
                        Icons.location_on,
                        "Unit-2",
                        widget.unit2Location,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BROODSTOCK + DATE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow(
                      Icons.water_drop_outlined,
                      "${widget.broodstockCount} Pieces",
                      "Broodstock",
                    ),

                    if (widget.availableDate != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        "Available Date",
                        widget.availableDate!,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // PRICE
                Row(
                  children: [
                    _buildInfoRow(Icons.timer, "Price", "₹ ${widget.price}"),
                  ],
                ),

                const SizedBox(height: 20),

                // ACTION BUTTONS
                Row(
                  children: [
                    _actionButton(
                      label: "Call Now",
                      icon: "assets/images/phone.png",
                      color: AppColors.primary,
                      onTap: () => _makePhoneCall(widget.callUrl),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 4),

                    _actionButton(
                      label: "WhatsApp",
                      icon: "assets/images/whatsApp.png",
                      color: Colors.white,
                      textColor: Colors.green,
                      borderColor: Colors.green,
                      onTap: () =>
                          _launchUrl(widget.whatsappUrl ?? '', context),
                    ),

                    const SizedBox(width: 4),

                    _actionButton(
                      label: "Book Now",
                      icon: "assets/images/Lightning.png",
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
                                categoryId: widget.categoryId,
                                hatcheryId: widget.hatcheryId,
                                hatcheryName: widget.hatcheryName,
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
