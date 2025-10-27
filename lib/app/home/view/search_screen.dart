import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/filter_controller.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Voice
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = "";

  // Controller
  final FilterController _filterController = Get.find<FilterController>();

  // Multiple selection sets
  final RxSet<int> selectedCategoryIds = <int>{}.obs;
  final RxSet<int> selectedLocationIds = <int>{}.obs;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (_filterController.isLoading.value &&
            (_filterController.categories.isEmpty ||
                _filterController.locations.isEmpty)) {
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
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

              // Dynamic Category Section
              _buildDynamicSection(
                title: "Category",
                items: _filterController.categories
                    .map((e) => e.categoryName)
                    .toList(),
                ids: _filterController.categories.map((e) => e.id).toList(),
                selectedIds: selectedCategoryIds,
              ),

              // Dynamic Location Section
              _buildDynamicSection(
                title: "Location",
                items: _filterController.locations
                    .map((e) => e.locationName)
                    .toList(),
                ids: _filterController.locations.map((e) => e.id).toList(),
                selectedIds: selectedLocationIds,
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyFilters,
        label: const Text("Apply Filters"),
        icon: const Icon(Icons.check),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.white,
    );
  }

  /// 🔹 Build section for categories/locations dynamically
  Widget _buildDynamicSection({
    required String title,
    required List<String> items,
    required List<int> ids,
    required RxSet<int> selectedIds,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(items.length, (index) {
                final id = ids[index];
                final name = items[index];
                final isSelected = selectedIds.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                    }
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

  /// 🔹 Handle Apply Filters Action
  void _applyFilters() {
    final selectedCats = _filterController.categories
        .where((c) => selectedCategoryIds.contains(c.id))
        .map((c) => c.categoryName)
        .toList();

    final selectedLocs = _filterController.locations
        .where((l) => selectedLocationIds.contains(l.id))
        .map((l) => l.locationName)
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Applied Filters:\nCategories: ${selectedCats.join(', ')}\nLocations: ${selectedLocs.join(', ')}",
        ),
      ),
    );

    print("Selected Category IDs: $selectedCategoryIds");
    print("Selected Location IDs: $selectedLocationIds");
  }

  /// 🔹 Voice Input Logic
  Future<void> _toggleVoiceInput() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceText = val.recognizedWords;
              _searchController.text = _voiceText;
            });
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
}
