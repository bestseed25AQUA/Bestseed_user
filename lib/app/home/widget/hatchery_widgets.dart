import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class HatcheryWidget extends StatelessWidget {
  final VoidCallback onViewAllTap;

  HatcheryWidget({super.key, required this.onViewAllTap});

  final HomeController _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2); // Responsive width
    final cardHeight = cardWidth * 1.35; // auto height

    return Obx(() {
      if (_homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_homeController.hatcheries.isEmpty) {
        return const SizedBox();
      }

      final list = _homeController.hatcheries.length > 6
          ? _homeController.hatcheries.sublist(0, 6)
          : _homeController.hatcheries;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12,bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hatcheries',
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                _AnimatedViewAll(onTap: onViewAllTap),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 10, right: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.73, // adjust based on your design
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return HatcheryCard(
                index: index,
                width: cardWidth,
                height: cardHeight,
                imagePath: item.imagePath,
                title: item.title,
                location: item.location,
                type: item.categoryNames, // Show all categories
                categoryCount: item.categoryCount,
                id: item.id.toString(),
                uniqueId: item.uniqueId, // Pass uniqueId for API calls
                status: item.status,
                statusColor: getHatcheryStatusColor(item.statusCode),
                availableUntil: item.availableUntil,
              );
            },
          ),
        ],
      );
    });
  }

  Color getHatcheryStatusColor(int statusCode) {
    switch (statusCode) {
      case 1:
        return const Color(0xff25A652); // Available
      case 2:
        return const Color(0xff007DFE); // Coming Soon
      case 3:
        return const Color(0xff6F42C1); // Upcoming
      case 4:
        return const Color(0xffF4A100); // Shortly Available
      default:
        return const Color(0xffE31B1B); // Closed
    }
  }
}

class HatcheryCard extends StatelessWidget {
  final double width;
  final double height;
  final String imagePath;
  final String title;
  final String location;
  final String type;
  final int categoryCount;
  final String status;
  final Color statusColor;
  final String? availableUntil;
  final String? id;
  final String? uniqueId; // Unique identifier for API calls
  final int index;
  final VoidCallback? ontap;

  const HatcheryCard({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.type,
    this.categoryCount = 1,
    required this.status,
    required this.statusColor,
    this.availableUntil,
    this.id,
    this.uniqueId,
    this.ontap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Safety: ensure imagePath has base URL
    final resolvedImagePath = imagePath.isNotEmpty && !imagePath.startsWith('http')
        ? '${NetworkConfig.imageURL}/$imagePath'
        : imagePath;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // onTap: () => Get.to(() => HatcheryDetailScreen()),
      onTap:
          ontap ??
          () {
            print('HatcheryCard$index');
            print('ontap ok');
            // Use uniqueId for API call, fallback to id if uniqueId is not available
            final hatcheryIdForApi = (uniqueId != null && uniqueId!.isNotEmpty) ? uniqueId! : id.toString();
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 600), // smooth
                reverseTransitionDuration: const Duration(milliseconds: 600),
                pageBuilder: (_, __, ___) => HatcheryCateogryScreen(
                  hatcheryId: hatcheryIdForApi,
                  hatcheryName: title,
                  tag: 'HatcheryCard$id$index',
                ),
              ),
            );

            print('ontap on');
          },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withOpacity(.16),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: const Color(0xff000000).withOpacity(.16),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, -3),
            ),
          ],
        ),

        // ⭐ FULL RESPONSIVE PADDING
        padding: EdgeInsets.all(screenWidth * 0.02),

        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height for content
            final availableHeight = constraints.maxHeight;
            final imageHeight = (availableHeight * 0.55).clamp(80.0, 120.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Hero(
                        tag: 'HatcheryCard$id$index',
                        child: CachedNetworkImage(
                          imageUrl: resolvedImagePath,
                          width: double.infinity,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (_, __) => SizedBox(
                            height: imageHeight,
                            child: CustomShimmer(),
                          ),
                          errorWidget: (_, __, ___) {
                            final fallbackPath =
                                resolvedImagePath.contains('category_media')
                                ? resolvedImagePath.replaceFirst(
                                    'category_media',
                                    'hatcheries',
                                  )
                                : resolvedImagePath;

                            if (fallbackPath == resolvedImagePath) {
                              return SizedBox(
                                height: imageHeight,
                                child: CustomShimmer(),
                              );
                            }

                            return CachedNetworkImage(
                              imageUrl: fallbackPath,
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              placeholder: (_, __) => SizedBox(
                                height: imageHeight,
                                child: CustomShimmer(),
                              ),
                              errorWidget: (_, __, ___) => SizedBox(
                                height: imageHeight,
                                child: CustomShimmer(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // STATUS BADGE
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.015,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                        child: Text(
                          status.isEmpty
                              ? 'closed'
                              : status.length <= 15
                              ? status
                              : status.substring(0, 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.008),

                // Content area with flexible height
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.004),

                      // Location Row
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: const Color(0xff525050),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: screenHeight * 0.003),

                      // Type/Categories Row
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 14,
                            color: const Color(0xff525050),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              categoryCount > 1
                                  ? '$categoryCount Categories'
                                  : type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: categoryCount > 1
                                    ? const Color(0xff0076BE)
                                    : Colors.grey,
                                fontWeight: categoryCount > 1
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedViewAll extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedViewAll({required this.onTap});

  @override
  State<_AnimatedViewAll> createState() => _AnimatedViewAllState();
}

class _AnimatedViewAllState extends State<_AnimatedViewAll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _arrowSlide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _arrowSlide = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Opacity(
          opacity: _fade.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "View all",
                style: GoogleFonts.roboto(
                  color: const Color(0xff0076BE),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Transform.translate(
                offset: Offset(_arrowSlide.value, 0),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xff0076BE),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
