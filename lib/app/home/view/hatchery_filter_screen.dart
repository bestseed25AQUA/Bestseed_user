import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/common/voice_mic_button.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/harchery_details_screen.dart';
import 'package:seedsuser/app/home/model/hatchery_filter_model.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/home/widget/hatchery_widgets.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2); // Responsive width
    final cardHeight = cardWidth * 1.35;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          widget.title ?? ((widget.title?.isEmpty ?? true) ? "Hatcheries" : ''),
        ),
        backgroundColorActual: Colors.white,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (contxt) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6), // ⭐ space for top shadow
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
                    contentPadding: EdgeInsets.only(top: 5),
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
                              filterHatcheryController.query = '';
                              filterHatcheryController.applyFilter();
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

              const SizedBox(height: 10),
              Obx(() {
                if (controller.isLoading.value) {
                  return Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio:
                                0.8, // adjust based on your card height
                          ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return AnimatedAppearance(
                          child: hatcheryCardGridShimmer(cardHeight),
                        );
                      },
                    ),
                  );
                }

                if (controller.hatcherFilteredData.value?.data == null ||
                    controller.hatcherFilteredData.value.data.isEmpty) {
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

                final list = controller
                    .hatcherFilteredData
                    .value
                    .data; // filterByName();
                return Expanded(
                  child: AnimatedAppearance(
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio:
                                0.8, // adjust based on your card height
                          ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return HatcheryCard(
                          index: index,
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: item.image,
                          title: item.hatcheryName,
                          location: item.location,
                          type: item.category,
                          status: item.status,
                          availableUntil: item.availableOn,
                          statusColor: item.status.toLowerCase() == "available"
                              ? const Color(0xff25A652)
                              : item.status.toLowerCase() == "coming soon" ||
                                    item.status.toLowerCase() == "-"
                              ? const Color(0xff007DFE)
                              : item.status.toLowerCase() == "upcoming"
                              ? const Color(0xff6F42C1)
                              : item.status.toLowerCase() == "shortly available"
                              ? const Color(0xffF4A100)
                              : item.status.toLowerCase() == "closed"
                              ? const Color(0xffE31B1B)
                              : const Color(0xffE31B1B),
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HatcheryCateogryScreen(
                                  hatcheryId: item.id.toString(),
                                  hatcheryName: item.hatcheryName.toString(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

Widget hatcheryCardGridShimmer(double height) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 IMAGE AREA
          Container(
            height: height * 0.45,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 12),

          // 🔵 TITLE
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 10),

          // 🔵 LOCATION ROW
          Row(
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 164, 141, 141),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),

          // const SizedBox(height: 10),

          // 🔵 TYPE ROW
          // Row(
          //   children: [
          //     Container(
          //       height: 14,
          //       width: 14,
          //       decoration: const BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: Colors.white,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     Expanded(
          //       child: Container(
          //         height: 14,
          //         decoration: BoxDecoration(
          //           color: const Color.fromARGB(255, 164, 141, 141),
          //           borderRadius: BorderRadius.circular(4),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    ),
  );
}
