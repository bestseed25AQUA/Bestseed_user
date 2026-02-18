import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/widget/home_banner_carousel.dart';
import 'package:seedsuser/app/model/wanted_crop_model.dart';
import 'package:seedsuser/app/wanted/controller/wanted_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';

class WantedCropBuyersScreen extends StatefulWidget {
  const WantedCropBuyersScreen({super.key});

  @override
  State<WantedCropBuyersScreen> createState() => _WantedCropBuyersScreenState();
}

class _WantedCropBuyersScreenState extends State<WantedCropBuyersScreen> {
  final WantedCropController controller = Get.put(WantedCropController());
  String selectedValue = "Vannamei";
  String selected = "East Godavari";
  TextEditingController searchController = TextEditingController();
  String? selectedFilter;
  final SeedsPriceController seedController = Get.put(SeedsPriceController());

  @override
  void initState() {
    super.initState();

    // Load banners
    // controller.fetchWantedBanners();

    // Load crops default
    controller.getDefaultCrops();
  }

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              // Obx(() {
              //   return Container(
              //     decoration: BoxDecoration(
              //       // ignore: deprecated_member_use
              //       color: Colors.grey.withOpacity(.3),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: MediaCarouselWidget(
              //       borderRadius: 12,
              //       mediaUrls: List.generate(
              //         controller.bannerList.length,
              //         (index) => controller.bannerList[index].url,
              //       ),
              //       mediaTypes: List.generate(
              //         controller.bannerList.length,
              //         (index) => controller.bannerList[index].type,
              //       ),
              //     ),
              //   );
              // }),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final locations = controller.apiLocations.isNotEmpty
                          ? controller.apiLocations
                          : seedController.locations;
                      if (locations.isEmpty) {
                        return const SizedBox();
                      }
                      return CustomDropdown<Location>(
                        selectedValue: controller.selectedLocation.value,
                        items: locations,
                        itemLabel: (loc) => loc.title,
                        backgroundColor: Color(0xffF3F4F6),
                        hintText: "Select Location",
                        onChanged: (loc) {
                          controller.selectedLocation.value = loc;
                          controller.fetchCrops();
                        },
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      final categories = controller.apiCategories.isNotEmpty
                          ? controller.apiCategories
                          : seedController.categories;
                      if (categories.isEmpty) {
                        return const SizedBox();
                      }
                      return CustomDropdown<Category>(
                        selectedValue: controller.selectedCategory.value,
                        items: categories,
                        itemLabel: (cat) => cat.categoryName,
                        backgroundColor: Color(0xffF3F4F6),
                        hintText: "Select Category",
                        onChanged: (cat) {
                          controller.selectedCategory.value = cat;
                          controller.fetchCrops();
                        },
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.wantedCropsList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * .2,
                      ),
                      child: Text("No wanted crops available now.", style: GoogleFonts.roboto(
                                fontSize: 14, 
                                color: Colors.black,
                              ),),
                    ),
                  );
                }

                // Optional: apply search/filtering in the UI
                final filteredList = controller.wantedCropsList.where((item) {
                  final matchesFilter =
                      selectedFilter == null ||
                      item.category.toLowerCase().contains(
                        selectedFilter!.toLowerCase(),
                      );
                  final matchesSearch = item.hatcheryName
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase());
                  return matchesFilter && matchesSearch;
                }).toList();

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final crop = filteredList[index];
                    return _buildHatcheryCard(crop);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  CustomAppBar _buildAppBar() {
    return CustomAppBar(
        
      foregroundColor: Colors.white,
      title: Text(
        'Wanted Crops',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget _buildSearchField() {
  //   return TextField(
  //     controller: searchController,
  //     onChanged: (_) => setState(() {}),
  //     decoration: InputDecoration(
  //       hintText: "Search buyers...",
  //       prefixIcon: const Icon(Icons.search),
  //       filled: true,
  //       fillColor: Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 16,
  //         vertical: 12,
  //       ),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildFilterChips() {
  //   return Wrap(
  //     spacing: 8,
  //     children: ["Vannamei", "Tiger", "Shrimp"].map((type) {
  //       final isSelected = selectedFilter == type;
  //       return ChoiceChip(
  //         label: Text(type),
  //         selected: isSelected,
  //         selectedColor: Colors.green,
  //         backgroundColor: Colors.grey[200],
  //         checkmarkColor: Colors.white,
  //         labelStyle: TextStyle(
  //           color: isSelected ? Colors.white : Colors.black,
  //         ),
  //         onSelected: (_) => _selectFilter(type),
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildFilterSection() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _buildDropdownButton(
  //           selected,
  //           ["East Godavari", "Krishna", "Kereal"],
  //           (newValue) {
  //             setState(() {
  //               selected = newValue!;
  //             });
  //           },
  //         ),
  //       ),
  //       const SizedBox(width: 64),
  //       Expanded(
  //         child: _buildDropdownButton(
  //           selectedValue,
  //           ["Vannamei", "Tiger", "Shrimp"],
  //           (newValue) {
  //             setState(() {
  //               selectedValue = newValue!;
  //             });
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildHatcheryCard(WantedCrop crop) {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              offset: Offset(1, 3),
              spreadRadius: 0,
              blurRadius: 2,
            ),
          ],
          border: Border.all(width: .2),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or Video preview (simplified as image here)
            if (crop.mediaType == 'image')
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  crop.mediaUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/hatchery.png',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (crop.mediaType != 'image')
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => FullScreenVideoPlayer(videoUrl: crop.mediaUrl),
                    );
                  },
                  child: VideoPlayerBanner(url: crop.mediaUrl,height: 160,),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.category.toUpperCase(),
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            crop.location,
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            crop.packingDate,
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crop.description,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoColumn('Tons', crop.tons.toString()),
                      _infoColumn('Payment', crop.payment),
                      _infoColumn('Price', '₹${crop.price}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // Expanded(
                      //   child: InkWell(
                      //     onTap: () async {
                      //       final whatsappUrl =
                      //           "https://wa.me/${'+91${crop.contact}'.replaceAll('+', '')}";
                      //       final Uri uri = Uri.parse(whatsappUrl);
                      //       if (await canLaunchUrl(uri)) {
                      //         await launchUrl(uri);
                      //       } else {
                      //         CustomToast.error("Cannot launch WhatsApp");
                      //       }
                      //     },
                      //     child: Container(
                      //       height: 48,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(16),
                      //         border: Border.all(
                      //           color: Colors.green,
                      //           width: 1.5,
                      //         ),
                      //       ),
                      //       child: Row(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           Image.asset(
                      //             'assets/images/whatsApp.png',
                      //             height: 18,
                      //           ),
                      //           const SizedBox(width: 6),
                      //           Text(
                      //             'WhatsApp',
                      //             style: GoogleFonts.roboto(
                      //               color: Colors.green,
                      //               fontSize: 13,
                      //               fontWeight: FontWeight.bold,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final phoneNumber = "tel:${crop.contact}";
                            if (await canLaunch(phoneNumber)) {
                              await launch(phoneNumber);
                            } else {
                              CustomToast.error("Cannot launch call");
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/customer_call.png',
                                  height: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Call & Book seeds',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _infoColumn(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
