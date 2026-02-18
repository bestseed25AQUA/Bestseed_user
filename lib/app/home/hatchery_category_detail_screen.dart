import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/home/booking_hatchery_widget.dart';
import 'package:seedsuser/app/home/controller/hatchery_category_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HatcheryCategoryDetailScreen extends StatefulWidget {
  final String videoUrl;
  final String hatcheryId;
  final String categoryId;
  final String hatcheryName;

  const HatcheryCategoryDetailScreen({
    super.key,
    required this.videoUrl,
    required this.hatcheryId,
    required this.categoryId,
    required this.hatcheryName,
  });

  @override
  State<HatcheryCategoryDetailScreen> createState() =>
      _HatcheryCategoryDetailScreenState();
}

class _HatcheryCategoryDetailScreenState
    extends State<HatcheryCategoryDetailScreen> {
  bool videoStarted = false;
  late ScrollController _unitScrollController;
  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.mkv');
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Available';
      case 2:
        return 'Coming Soon';
      case 3:
        return 'Upcoming';
      case 4:
        return 'Shortly Available';
      default:
        return 'Closed';
    }
  }

  final hatcheryCategoryController = Get.put(HatcheryCategoryController());

  @override
  void initState() {
    super.initState();

    _unitScrollController = ScrollController();

    hatcheryCategoryController.getHatcheryCategoryDetail(
      widget.hatcheryId,
      widget.categoryId,
    );

    // _controller = VideoPlayerController.asset(widget.videoUrl)
    //   ..initialize().then((_) {
    //     setState(() {});
    //   });
  }

  @override
  void dispose() {
    _unitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: Text(
          widget.hatcheryName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (hatcheryCategoryController.detailLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final detail =
            hatcheryCategoryController.hatcheryCategoryDetailData.value.data;

        if (detail == null) {
          return const Center(child: Text("No data found"));
        }

        final List<String> validImages = detail.images ?? [];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (validImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 110,
                    child: MediaCarouselWidget(
                      mediaUrls: validImages,
                      mediaTypes: validImages.map((url) => _isVideo(url) ? 'video' : 'image').toList(),
                      height: 110,
                      borderRadius: 14,
                      title: widget.hatcheryName,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.hatcheryName ?? "",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),
                    if (detail.description != null &&
                        detail.description!.isNotEmpty)
                      Text(
                        detail.description ?? "",
                        style: GoogleFonts.roboto(fontSize: 14, height: 1.4),
                      ),
                    const SizedBox(height: 20),

                    /// 🏷️ Category Name (only show name, not description/gallery/report)
                    if (detail.category != null) ...[
                      Text(
                        detail.category!.name ?? "",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    /// 📄 Hatchery Report
                    if (detail.report != null &&
                        detail.report!.isNotEmpty) ...[
                      Text(
                        "Hatchery Report",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () {
                          _launchUrl(detail.report!, context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.picture_as_pdf, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                "View Report",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(height: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((detail.units?.isNotEmpty ?? false))
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.black, Colors.transparent],
                                stops: [0.9, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: SingleChildScrollView(
                                controller: _unitScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: _buildInfoUnitRow(
                                    "assets/images/unit_icon.png",
                                    "Units",
                                    detail.units!
                                        .where(
                                          (u) => (u.branch!.name!.isNotEmpty),
                                        )
                                        .map((u) => u.branch!.name ?? '')
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              Icons.water_drop_outlined,
                              "Broodstock",
                              "${detail.broodstock ?? 0} Pieces",
                            ),

                            _buildInfoRow(
                              Icons.date_range,
                              "Available Date ",
                              detail.availableOn != null
                                  ? formatDate(detail.availableOn!)
                                  : '',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              Icons.money,
                              "Price",
                              "₹${detail.price ?? ''}",
                            ),

                            if (detail.status != null)
                              _buildInfoRow(
                                Icons.info_outline,
                                "Status",
                                _getStatusText(detail.status!),
                              ),
                          ],
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
                          onTap: () => _makePhoneCall(detail.callUrl),
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
                              _launchUrl(detail.whatsappUrl ?? '', context),
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
                                    price: detail.price?.toString() ?? '',
                                    categoryId: widget.categoryId,
                                    hatcheryId: detail.id.toString(),
                                    hatcheryName: detail.hatcheryName ?? '',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoUnitRow(
    String assetPath,
    String label,
    List<String> branches,
  ) {
    if (branches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 16,
              height: 16,
              color: Colors.grey, // optional
            ),
            const SizedBox(width: 6),
            Text(
              branches.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .3,
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

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
          height: 37,
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
                  fontSize: 14,
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

Future<void> _makePhoneCall(String phoneNumber) async {
  // Clean the phone number (remove any non-digit characters except +)
  final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

  if (cleanedNumber.isEmpty) {
    debugPrint("Invalid phone number: $phoneNumber");
    return;
  }

  final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch phone dialer for: $cleanedNumber");
      // Optional: Show a snackbar or dialog to the user
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Cannot make phone call to $cleanedNumber')),
      // );
    }
  } catch (e) {
    debugPrint("Error making phone call  ");
    // Optional: Show error to user
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Error making phone call  ')),
    // );
  }
}

Widget _buildGalleryImage({required String imageUrl}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16.0),
    child: Image.asset(imageUrl, fit: BoxFit.cover, height: 108, width: 104),
  );
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}

// Future<void> _makePhoneCall(String phoneNumber) async {
//   // Clean the phone number (remove any non-digit characters except +)
//   final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

//   if (cleanedNumber.isEmpty) {
//     debugPrint("Invalid phone number: $phoneNumber");
//     return;
//   }

//   final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);

//   try {
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       debugPrint("Could not launch phone dialer for: $cleanedNumber");
//       // Optional: Show a snackbar or dialog to the user
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('Cannot make phone call to $cleanedNumber')),
//       // );
//     }
//   } catch (e) {
//     debugPrint("Error making phone call  ");
//     // Optional: Show error to user
//     // ScaffoldMessenger.of(context).showSnackBar(
//     //   SnackBar(content: Text('Error making phone call  ')),
//     // );
//   }
// }

// Widget _buildInfoRow(IconData icon, String label, String value) {
//   return Row(
//     children: [
//       Icon(icon, size: 18, color: AppColors.primary),
//       const SizedBox(width: 8),
//       Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
//           ),
//           Text(
//             value,
//             style: GoogleFonts.roboto(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     ],
//   );
// }

// Widget _buildGalleryImage({required String imageUrl}) {
//   return ClipRRect(
//     borderRadius: BorderRadius.circular(16.0),
//     child: Image.asset(imageUrl, fit: BoxFit.cover, height: 108, width: 104),
//   );
// }

class HatcheryGalleryCarousel extends StatefulWidget {
  final List<String> images;

  const HatcheryGalleryCarousel({super.key, required this.images});

  @override
  State<HatcheryGalleryCarousel> createState() =>
      _HatcheryGalleryCarouselState();
}

class _HatcheryGalleryCarouselState extends State<HatcheryGalleryCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    print(widget.images.isEmpty);
    if (widget.images.isEmpty) {
      return const Center(child: Text("No images available"));
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            final img = widget.images[index];

            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                img,
                height: 1500,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.withOpacity(.3),
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            // viewportFraction: 0.75,
            autoPlay: false,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),

        const SizedBox(height: 10),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.images.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 10 : 8,
              height: _currentIndex == entry.key ? 10 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key ? Colors.blue : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
