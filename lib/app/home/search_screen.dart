import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(
    text: "Nearby me, Kona Bay",
  );

  // Sample filter lists
  List<String> categories = ["Size PL", "SIS Hardline", "Hardline Plus"];
  List<String> brands = ["Syaqua", "SIS Hardlines", "Kona Bay"];
  List<String> locations = ["Nearby me", "Vizag", "Bapatla"];

  // Track selected items
  Set<String> selectedFilters = {"Nearby me", "Kona Bay"};

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = "";

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with floating search bar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(color: AppColors.primary),
                ),
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
                                color: _isListening ? Colors.red : Colors.grey,
                              ),
                              onPressed: () async {
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
                                      const SnackBar(
                                        content: Text(
                                          "Speech recognition not available",
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() => _isListening = false);
                                  _speech.stop();
                                }
                              },
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

            // Category section
            _buildSection("Category", categories),

            // Locations section
            _buildSection("Locations", locations),

            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),

      // Floating Apply Filters button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Handle apply filters action
          print("Selected Filters: $selectedFilters");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Applied: ${selectedFilters.join(", ")}")),
          );
        },
        label: const Text("Apply Filters"),
        icon: const Icon(Icons.check),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
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
            children: items.map((item) {
              final isSelected = selectedFilters.contains(item);
              return FilterChip(
                label: Text(item),
                selected: isSelected,
                onSelected: (bool value) {
                  setState(() {
                    if (isSelected) {
                      selectedFilters.remove(item);
                    } else {
                      selectedFilters.add(item);
                    }
                  });
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
