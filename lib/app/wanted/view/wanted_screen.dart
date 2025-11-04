import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/view/full_video_screen.dart';
import 'package:seedsuser/app/home/widget/home_banner_carousel.dart';
import 'package:seedsuser/app/model/wanted_crop_model.dart';
import 'package:seedsuser/app/wanted/controller/wanted_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _selectFilter(String? filter) {
    setState(() {
      if (selectedFilter == filter) {
        selectedFilter = null;
      } else {
        selectedFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 8),
            _buildFilterChips(),
            const SizedBox(height: 8),
            _buildFilterSection(),
            const SizedBox(height: 16),

            // ✅ Use GetX to show real-time data
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.wantedCropsList.isEmpty) {
                  return const Center(child: Text("No wanted crops found."));
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
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final crop = filteredList[index];
                    return _buildHatcheryCard(crop);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[800],
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

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "Search buyers...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: ["Vannamei", "Tiger", "Shrimp"].map((type) {
        final isSelected = selectedFilter == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          selectedColor: Colors.green,
          backgroundColor: Colors.grey[200],
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (_) => _selectFilter(type),
        );
      }).toList(),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownButton(
            selected,
            ["East Godavari", "Krishna", "Kereal"],
            (newValue) {
              setState(() {
                selected = newValue!;
              });
            },
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          child: _buildDropdownButton(
            selectedValue,
            ["Vannamei", "Tiger", "Shrimp"],
            (newValue) {
              setState(() {
                selectedValue = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ✅ Dynamic hatchery card using real API data
  Widget _buildHatcheryCard(WantedCrop crop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
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
                  Get.to(() => FullScreenVideoPlayer(videoUrl: crop.mediaUrl));
                },
                child: VideoPlayerBanner(url: crop.mediaUrl),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final whatsappUrl =
                              "https://wa.me/${'+91${crop.contact}'.replaceAll('+', '')}";
                          final Uri uri = Uri.parse(whatsappUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            CustomToast.error("Cannot launch WhatsApp");
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/whatsApp.png',
                                height: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WhatsApp',
                                style: GoogleFonts.roboto(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
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
                                'Call',
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
