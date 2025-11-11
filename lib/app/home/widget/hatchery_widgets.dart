import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart'; 

class HatcheryWidget extends StatefulWidget {
  const HatcheryWidget({super.key});

  @override
  State<HatcheryWidget> createState() => _HatcheryWidgetState();
}

class _HatcheryWidgetState extends State<HatcheryWidget> {
  final HomeController _homeController = Get.find<HomeController>();
  final ScrollController _scrollController = ScrollController();

  var canScrollLeft = false.obs;
  var canScrollRight = true.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_scrollListener);
    });

    // Call API if needed
    _homeController.getHatcheries();
  }

  void _scrollListener() {
    canScrollLeft.value = _scrollController.offset > 0;
    canScrollRight.value =
        _scrollController.offset < _scrollController.position.maxScrollExtent;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_homeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_homeController.hatcheries.isEmpty) {
        return const SizedBox(); // empty UI
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _homeController.hatcheries.length,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              itemBuilder: (context, index) {
                final h = _homeController.hatcheries[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: _buildHatcheryCard(
                      imagePath: h.imagePath,
                      title: h.title,
                      location: h.location,
                      type: h.type,
                      status: h.status,
                      statusColor: h.status.toLowerCase() == "coming soon"
                          ? Colors.orange
                          : Colors.green,
                      availableUntil: h.availableUntil,
                    ),
                  ),
                );
              },
            ),
          ),

          // LEFT BUTTON
          Obx(() => canScrollLeft.value
              ? Positioned(
                  left: 0,
                  child: GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset - 200,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.ease,
                      );
                    },
                    child: _roundArrow(Icons.arrow_back_ios),
                  ),
                )
              : const SizedBox()),

          // RIGHT BUTTON
          Obx(() => canScrollRight.value
              ? Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset + 200,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.ease,
                      );
                    },
                    child: _roundArrow(Icons.arrow_forward_ios),
                  ),
                )
              : const SizedBox()),
        ],
      );
    });
  }

  // Reusable arrow UI
  Widget _roundArrow(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, size: 18),
    );
  }
}


  Widget _buildHatcheryCard({
    required String imagePath,
    required String title,
    required String location,
    required String type,
    required String status,
    required Color statusColor,
    String? availableUntil,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 2,bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => HatcheryDetailScreen());
        },
        child: Card(
          margin: EdgeInsets.only(),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image on the left
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        imagePath,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.withOpacity(.1),
                             height: 100,
                          );
                        },
                      ),
                    ),
                    if (availableUntil != null)
                      Positioned(
                        left: 12,
                        bottom: 8,
                        child: Text(
                          availableUntil,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.6),
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Details on the right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.roboto(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(type, style: GoogleFonts.roboto(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
