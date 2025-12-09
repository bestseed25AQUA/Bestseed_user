import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/common/voice_mic_button.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/model/hatchery_filter_model.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class HatcheryFilterScreen extends StatefulWidget {
  const HatcheryFilterScreen({super.key, this.title});
  final String? title;

  @override
  State<HatcheryFilterScreen> createState() => _HatcheryFilterScreenState();
}

class _HatcheryFilterScreenState extends State<HatcheryFilterScreen> {
  final FilterHatcheryController controller =
      Get.find<FilterHatcheryController>();

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;
  String _voiceText = "";
  late stt.SpeechToText _speech;
  bool _isAvailable = false;

  @override
  void initState() {
    // TODO: implement initState
    _searchController.text = controller.query;
    super.initState();
    _initSpeech();
  }

  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );
  void _applyFilters() {
    filterHatcheryController.applyFilter();
  }

  String fullText = "";
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

          if (dialogContext != null) {
            Navigator.pop(dialogContext!);
          } // close dialog
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

  void startRecording() {
    showVoiceDialog();
  }

  BuildContext? dialogContext;
  void showVoiceDialog() {
    // start listening when dialog opens
    startListening();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return StatefulBuilder(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
        );
      },
    );
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
        title: Text(
          widget.title ?? ((widget.title?.isEmpty ?? true) ? "Hatcheries" : ''),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (contxt) {
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
                            filterHatcheryController.query = value;
                            filterHatcheryController.applyFilter();
                          },
                          onSubmitted: (value) {},
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
                  ],
                ),

                const SizedBox(height: 40),
                Obx(() {
                  if (controller.isLoading.value) {
                    return SizedBox(
                      height: screenWidth,
                      child: const Center(
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (controller.hatcherFilteredData.value?.data == null ||
                      controller.hatcherFilteredData.value!.data.isEmpty) {
                    return SizedBox(
                      height: screenWidth,
                      child: const Center(
                        child: Text(
                          "No hatcheries found",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final list = filterByName();
                  return Padding(
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
                                                    hatcheryId: list[i1].id
                                                        .toString(),
                                                    hatcheryName: list[i1]
                                                        .hatcheryName
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
                                              availableUntil:
                                                  list[i2].availableOn,
                                              statusColor:
                                                  list[i2].status
                                                          .toLowerCase() ==
                                                      "open"
                                                  ? const Color(0xff25A652)
                                                  : list[i2].status
                                                            .toLowerCase() ==
                                                        "coming soon"
                                                  ? const Color(0xff007DFE)
                                                  : const Color(0xffE31B1B),
                                              ontap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        HatcheryCateogryScreen(
                                                          hatcheryId: list[i2]
                                                              .id
                                                              .toString(),
                                                          hatcheryName: list[i2]
                                                              .hatcheryName
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
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
