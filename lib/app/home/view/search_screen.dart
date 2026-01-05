import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/voice_mic_button.dart';
import 'package:seedsuser/app/home/view/hatchery_filter_screen.dart';
import 'package:seedsuser/app/home/view/home_appbar_widget.dart';
import 'package:seedsuser/app/utils/voice_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

//  NEW CONTROLLER
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
  bool _isAvailable = false;

  //  Replace old controllers with this controller
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
    _initSpeech();
  }

  void startListening() {
    if (!_isAvailable) {
      print("Speech engine not available");
      return;
    }

    fullText = "";
    print("🎤 Listening started...");

    _speech.listen(
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        fullText = result.recognizedWords;
        print("Heard: $fullText");
        if (fullText.isNotEmpty) {
          stopListening(); // stop immediately when text detected

          Navigator.pop(context); // close dialog
          _searchController.text = fullText;
          filterHatcheryController.query = fullText;
          _applyFilters();
        }

        // If you want live update uncomment below
        // setState(() {});
      },

      listenOptions: stt.SpeechListenOptions(),
    );
  }

  // it is for storing dialogSetState
  void Function(void Function())? dialogSetState;

  void stopListening() {
    print("🎤 Listening stopped.");
    _speech.stop();
  }

  String _speechStatus = "notListening";

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print("STATUS: $status");
          _speechStatus = status;
          if (dialogSetState != null) {
            dialogSetState!(() {}); // updates dialog immediately
          }
        },
        onError: (error) {
          print("ERROR: $error");
        },
      );
      print("Mic available = $_isAvailable");
    } catch (e) {
      print("Speech init error: $e");
    }
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
    });
  }

  void _applyFilters() {
    filterHatcheryController.applyFilter();
    Navigator.push(context, zoomOutFadeRoute(HatcheryFilterScreen()));
    // Get.to(HatcheryFilterScreen());
  }

  bool isRecording = false;
  String fullText = "";
  void startRecording() {
    showVoiceDialog();
  }

  void showVoiceDialog() {
    // start listening when dialog opens
    startListening();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          dialogSetState = setState;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Container(
              padding: const EdgeInsets.all(30),
              width: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Voice assistance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 25),

                  // MIC UI
                  Container(
                    height: 110,
                    width: 110,
                    decoration: _speechStatus == "listening"
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade100,
                                Colors.blue.shade300,
                              ],
                            ),
                          )
                        : BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                    child: InkWell(
                      onTap: () {
                        startListening();
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(
                          Icons.mic,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    fullText.isEmpty ? "Listening..." : fullText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      filterHatcheryController.categories.map((e) => e.id.toString()).toList(),
      '',
    );

    final brandList = filterItemsWithIds(
      filterHatcheryController.brands.map((e) => e.brandName).toList(),
      filterHatcheryController.brands.map((e) => e.id.toString()).toList(),
      '',
      // _searchController.text,
    );

    filterItemsWithIds(
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
        body: Obx(() {
          // if (filterHatcheryController.isLoading.value &&
          //     (filterHatcheryController.categories.isEmpty ||
          //         filterHatcheryController.locations.isEmpty ||
          //         filterHatcheryController.brands.isEmpty)) {
          //   return const Center(child: CircularProgressIndicator());
          // }
          if (filterHatcheryController.brands.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  Text(
                    "Search",
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Container(
                  margin: const EdgeInsets.only(
                    top: 6,
                  ), // ⭐ space for top shadow
                  height: 37,
                  width: MediaQuery.of(context).size.width * .9,
                  decoration: BoxDecoration(
                    color: Colors.white, // ⭐ MUST
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, -2), // 🔥 TOP shadow
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 2), // bottom shadow
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'homeAppBarSearch',
                    child: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        height: 40,
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
                            contentPadding: EdgeInsets.only(top: 5),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: .1,
                                color: Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: .1,
                                color: Colors.grey,
                              ),
                            ),
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
                                // IconButton(
                                //   icon: Icon(
                                //     _isListening ? Icons.mic_none : Icons.mic,
                                //     color: _isListening
                                //         ? Colors.red
                                //         : Colors.grey,
                                //   ),
                                //   onPressed: _toggleVoiceInput,
                                // ),
                                VoiceMicButton(onStart: startRecording),
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
                  ),
                ),
              ),

              // const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ⭐ CATEGORY SECTION
                      _buildDynamicSection(
                        title: "",
                        items: categoryList.map((e) => e["name"]!).toList(),
                        ids: categoryList.map((e) => e["id"]!).toList(),
                        selectedIds:
                            filterHatcheryController.selectedCategoryIds,
                        sectionKey: 'category',
                      ),
                      SizedBox(height: 40),
                      // ⭐ Hatchery Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: List.generate(
                            filterHatcheryController.hatcheryNames.length,
                            (index) {
                              return FilterChip(
                                label: Text(
                                  filterHatcheryController.hatcheryNames[index],
                                  style: TextStyle(fontSize: 14),
                                ),
                                color: WidgetStateProperty.all(Colors.white),
                                // selected: selectedIds.contains(id),
                                onSelected: (bool selected) {
                                  filterHatcheryController.query =
                                      filterHatcheryController
                                          .hatcheryNames[index];
                                  _applyFilters();
                                },
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blue,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      // _buildDynamicSection(
                      //   title: "Hatchery Names",
                      //   items: filterHatcheryController.hatcheryNames,
                      //   ids: filterHatcheryController.hatcheryNames
                      //       .map((e) => e)
                      //       .toList(),
                      //   selectedIds:
                      //       filterHatcheryController.selectedCategoryIds,
                      //   sectionKey: 'hatcheryNames',
                      // ),
                    ],
                  ),
                ),
              ),

              // // ⭐ BRAND SECTION
              // _buildDynamicSection(
              //   title: "",
              //   items: brandList.map((e) => e["name"]!).toList(),
              //   ids: brandList.map((e) => e["id"]!).toList(),
              //   selectedIds: filterHatcheryController.selectedBrandIds,
              //   sectionKey: 'brand',
              // ),

              // // ⭐ LOCATION SECTION
              // _buildDynamicSection(
              //   title: "Location",
              //   items: locationList.map((e) => e["name"]!).toList(),
              //   ids: locationList.map((e) => e["id"]!).toList(),
              //   selectedIds: filterHatcheryController.selectedLocationIds,
              //   sectionKey: 'location',
              // ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 0),
      child: Obx(() {
        // FIX: display only filtered list, not based on original
        int total = items.length;
        int displayCount =
            total; // showAllFlag.value ? total : (total > 4 ? 4 : total);

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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // if (total > 4)
                  //   TextButton(
                  //     onPressed: () {
                  //       showAllFlag.value = !showAllFlag.value;
                  //     },
                  //     child: Text(
                  //       showAllFlag.value ? "View less" : "View all",
                  //       style: GoogleFonts.roboto(
                  //         color: AppColors.primary,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: List.generate(displayCount, (index) {
                final id = ids[index];
                final name = items[index];

                return FilterChip(
                  label: Text(name, style: TextStyle(fontSize: 14)),
                  color: WidgetStateProperty.all(Colors.white),
                  selected: selectedIds.contains(id),
                  onSelected: (bool selected) {
                    filterHatcheryController.query = '';
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
