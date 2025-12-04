import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/model/hatchery_filter_model.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class HatcheryFilterScreen extends StatefulWidget {
  const HatcheryFilterScreen({super.key,  this.title});
  final String? title;

  @override
  State<HatcheryFilterScreen> createState() => _HatcheryFilterScreenState();
}

class _HatcheryFilterScreenState extends State<HatcheryFilterScreen> {
  final FilterHatcheryController controller =
      Get.find<FilterHatcheryController>();

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = "";

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

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<HatcheryFilterItem> filterByName() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return controller.hatcherFilteredData.value.data;
    }

    return controller.hatcherFilteredData.value.data
        .where((item) => item.hatcheryName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2); // Responsive width
    final cardHeight = cardWidth * 1.35;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:  Text(widget.title?? "Hatcheries"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hatcherFilteredData.value?.data == null ||
            controller.hatcherFilteredData.value!.data.isEmpty) {
          return const Center(
            child: Text(
              "No hatcheries found",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final list = filterByName();

        return SingleChildScrollView(
          // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            children: [
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
                          setState(() {});
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: list.isEmpty
                      ? [
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * .3,
                            ),
                            child: Text('Not found'),
                          ),
                        ]
                      : List.generate((list.length / 2).ceil(), (rowIndex) {
                          final i1 = rowIndex * 2;
                          final i2 = i1 + 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                // LEFT CARD
                                Expanded(
                                  child: HatcheryCard(
                                    width: cardWidth,
                                    height: cardHeight,
                                    imagePath: list[i1].image,
                                    title: list[i1].hatcheryName,
                                    location: list[i1].location,
                                    type: list[i1].category,
                                    status: list[i1].status,
                                    availableUntil: list[i1].availableOn,

                                    statusColor:
                                        list[i1].status.toLowerCase() == "open"
                                        ? const Color(0xff25A652)
                                        : list[i1].status.toLowerCase() ==
                                              "coming soon"
                                        ? const Color(0xff007DFE)
                                        : const Color(0xffE31B1B),
                                    ontap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HatcheryCateogryScreen(
                                                hatcheryId: list[i1].id
                                                    .toString(),
                                               hatcheryName: list[i1].hatcheryName
                                                  .toString(),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // RIGHT CARD
                                Expanded(
                                  child: i2 < list.length
                                      ? HatcheryCard(
                                          width: cardWidth,
                                          height: cardHeight,
                                          imagePath: list[i2].image,
                                          title: list[i2].hatcheryName,
                                          location: list[i2].location,
                                          type: list[i2].category,
                                          status: list[i2].status,
                                          availableUntil: list[i2].availableOn,
                                          statusColor:
                                              list[i1].status.toLowerCase() ==
                                                  "open"
                                              ? const Color(0xff25A652)
                                              : list[i1].status.toLowerCase() ==
                                                    "coming soon"
                                              ? const Color(0xff007DFE)
                                              : const Color(0xffE31B1B),
                                            ontap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HatcheryCateogryScreen(
                                                hatcheryId: list[i2].id
                                                    .toString(),
                                               hatcheryName: list[i2].hatcheryName
                                                  .toString(),
                                              ),
                                        ),
                                      );
                                    },
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          );
                        }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
