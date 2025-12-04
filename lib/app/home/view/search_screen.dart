import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ⭐ NEW CONTROLLER ⭐
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = "";

  // ⭐ Replace old controllers with this controller
  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );

  // Multiple selection sets (UI purpose only)

  // Show all toggles for each section (Category / Brand / Location)
  final RxBool _showAllCategory = false.obs;
  final RxBool _showAllBrand = false.obs;
  final RxBool _showAllLocation = false.obs;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ⭐ PART 3 — APPLY FILTERS + VOICE + CLOSE CLASS

  Timer? _debounceTimer;
  bool _skipTextDebounce = false;

  void doAfterDelay() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(seconds: 1), () {
      print("hi");
      _applyFilters();
      // Yaha aap API / filter apply call kar sakte ho
      // filterHatcheryController.applyFilter();
    });
  }

  /// 🔹 Handle Apply Filters Action
  void _applyFilters() {
    filterHatcheryController.applyFilter();
    Get.to(() => HatcheryFilterScreen());
  }

  /// 🔹 Voice Input Logic
  Future<void> _toggleVoiceInput() async {
    if (!_isListening){
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
         _speech.listen(
          onResult: (val) {
            setState((){
              _voiceText = val.recognizedWords;
              _searchController.text = _voiceText;
              filterHatcheryController.query = _voiceText;
            });
             _applyFilters();
          },
        );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Speech recognition not available")),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  List<String> filterList(List<String> list, String query) {
    if (query.trim().isEmpty) return list;

    return list
        .where(
          (item) => item.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
  }

  List<Map<String, String>> filterItemsWithIds(
    List<String> names,
    List<String> ids,
    String query,
  ) {
    List<Map<String, String>> combined = [];

    for (int i = 0; i < names.length; i++) {
      combined.add({"name": names[i], "id": ids[i]});
    }

    if (query.trim().isEmpty) return combined;

    return combined
        .where(
          (e) => e["name"]!.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryList = filterItemsWithIds(
      filterHatcheryController.categories.map((e) => e.categoryName).toList(),
      filterHatcheryController.categories.map((e) => e.id.toString()).toList(),''
      // _searchController.text,
    );

    final brandList = filterItemsWithIds(
      filterHatcheryController.brands.map((e) => e.brandName).toList(),
      filterHatcheryController.brands.map((e) => e.id.toString()).toList(),''
      // _searchController.text,
    );

    final locationList = filterItemsWithIds(
      filterHatcheryController.locations
          .map((e) => extractLastValue(e.locationName))
          .toList(),
      filterHatcheryController.locations.map((e) => e.id.toString()).toList(),
      _searchController.text,
    );
    return WillPopScope(
      onWillPop: () async {
        filterHatcheryController.resetFilters();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Search"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Obx(() {
          if (filterHatcheryController.isLoading.value &&
              (filterHatcheryController.categories.isEmpty ||
                  filterHatcheryController.locations.isEmpty ||
                  filterHatcheryController.brands.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(height: 60, color: AppColors.primary),
                    Positioned(
                      bottom: -28,
                      left: 16,
                      right: 16,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: TextField(
                          focusNode: _focusNode,
                          onTapOutside: (event) {
                            _focusNode.unfocus();
                          },
                          onChanged: (value) {
                            // setState(() {});
                            filterHatcheryController.query = value;
                            if (_skipTextDebounce) {
                              // Reset flag so next user typing will work
                              _skipTextDebounce = false;
                              return;
                            }
                            doAfterDelay();
                          },
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Search...",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      filterHatcheryController.query = '';
                                      setState(() => _searchController.clear());
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic_none : Icons.mic,
                                    color: _isListening
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: _toggleVoiceInput,
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ⭐ CATEGORY SECTION
                _buildDynamicSection(
                  title: "",
                  items: categoryList.map((e) => e["name"]!).toList(),
                  ids: categoryList.map((e) => e["id"]!).toList(),
                  selectedIds: filterHatcheryController.selectedCategoryIds,
                  sectionKey: 'category',
                ),

                // // ⭐ BRAND SECTION
                _buildDynamicSection(
                  title: "",
                  items: brandList.map((e) => e["name"]!).toList(),
                  ids: brandList.map((e) => e["id"]!).toList(),
                  selectedIds: filterHatcheryController.selectedBrandIds,
                  sectionKey: 'brand',
                ),

                // // ⭐ LOCATION SECTION
                // _buildDynamicSection(
                //   title: "Location",
                //   items: locationList.map((e) => e["name"]!).toList(),
                //   ids: locationList.map((e) => e["id"]!).toList(),
                //   selectedIds: filterHatcheryController.selectedLocationIds,
                //   sectionKey: 'location',
                // ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: _applyFilters,
        //   label: const Text("Apply Filters"),
        //   icon: const Icon(Icons.check),
        //   backgroundColor: AppColors.primary,
        //   foregroundColor: Colors.white,
        // ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ⭐ PART 2 of 3 — UPDATED DYNAMIC SECTION
  Widget _buildDynamicSection({
    required String title,
    required List<String> items,
    required List<String> ids,
    required RxSet<String> selectedIds,
    required String sectionKey,
  }) {
    RxBool showAllFlag;

    if (sectionKey == 'category') {
      showAllFlag = _showAllCategory;
    } else if (sectionKey == 'brand') {
      showAllFlag = _showAllBrand;
    } else {
      showAllFlag = _showAllLocation;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Obx(() {
        // FIX: display only filtered list, not based on original
        int total = items.length;
        int displayCount = showAllFlag.value ? total : (total > 4 ? 4 : total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + View All
            if (total > 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (total > 4)
                    TextButton(
                      onPressed: () {
                        showAllFlag.value = !showAllFlag.value;
                      },
                      child: Text(
                        showAllFlag.value ? "View less" : "View all",
                        style: GoogleFonts.roboto(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            if (total > 4) const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(displayCount, (index) {
                final id = ids[index];
                final name = items[index];

                return FilterChip(
                  label: Text(name),
                  color: WidgetStateProperty.all(Colors.white),
                  selected: selectedIds.contains(id),
                  onSelected: (bool selected) {
                    // Only controller handles state changes
                    if (sectionKey == 'category') {
                      filterHatcheryController.toggleCategory(id);
                    } else if (sectionKey == 'brand') {
                      filterHatcheryController.toggleBrand(id);
                    } else {
                      filterHatcheryController.toggleLocation(id);
                    }
                    _skipTextDebounce = true;
                    doAfterDelay();
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue,
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

String extractLastValue(String input) {
  try {
    if (input.trim().isEmpty) return "";

    // Split by comma
    List<String> parts = input.split(",");

    // Trim and remove all empty values
    parts = parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // If nothing left, return empty
    if (parts.isEmpty) return "";

    // Return last cleaned part → ALWAYS CORRECT
    return parts.last;
  } catch (e) {
    print("❌ extractLastValue Error: $e");
    return "";
  }
}
