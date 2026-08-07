import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_filter_sheet.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/voice_mic_button.dart';
import 'package:seedsuser/app/spot_hatchery/controller/spot_hatchery_controller.dart';
import 'package:seedsuser/app/spot_hatchery/view/harchery_card_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpotHatcheryScreen extends StatefulWidget {
  const SpotHatcheryScreen({super.key});

  @override
  State<SpotHatcheryScreen> createState() => _SpotHatcheryScreenState();
}

class _SpotHatcheryScreenState extends State<SpotHatcheryScreen> {
  final SpotHatcheryController controller = Get.put(SpotHatcheryController());

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Filters chosen in the bottom sheet — empty means "show everything".
  FilterSelection _filters = const FilterSelection();

  /// User's coordinates, needed by the "Nearby" chip. Resolved lazily the
  /// first time it's tapped so the screen never asks for location permission
  /// unless the user actually wants it.
  double? _currentLat;
  double? _currentLng;

  /// True while the "Nearby" chip is active — the list is then limited to
  /// hatcheries within [kNearbyRadiusKm], nearest first.
  bool _nearbyOnly = false;
  bool _isLoadingLocation = false;

  /// "Nearby" needs a fix on the user first. If that fails the chip stays off
  /// rather than silently showing an unfiltered list under a "Nearby" label.
  Future<void> _onNearbyTapped() async {
    if (_nearbyOnly) return;

    if (_currentLat == null) {
      setState(() => _isLoadingLocation = true);
      final located = await _resolveCurrentLocation();
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      if (!located) {
        CustomToast.error(
          'Location is needed to show nearby hatcheries. '
          'Please enable it and try again.',
        );
        return;
      }
    }
    setState(() => _nearbyOnly = true);
  }

  Future<void> _openFilterSheet() async {
    final result = await showSpotHatcheryFilterSheet(
      context,
      hatcheries: controller.spotHatchery.toList(),
      initial: _filters,
      // Reset clears the list immediately rather than waiting for Apply.
      onReset: (cleared) => setState(() => _filters = cleared),
    );
    // null = dismissed without applying, so keep the current filters.
    if (result == null) return;
    if (mounted) setState(() => _filters = result);
  }

  /// Chip above the list. Mirrors the Vehicle Availability screen's chips so
  /// the two listings look and behave the same.
  Widget _buildLocationChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
              ],
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isSelected ? Colors.white : Colors.blue,
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns true once [_currentLat]/[_currentLng] hold a usable position.
  Future<bool> _resolveCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return false;
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      debugPrint('📍 [SPOT-SORT] located at $_currentLat,$_currentLng');
      return true;
    } catch (e) {
      debugPrint('📍 [SPOT-SORT] location failed: $e');
      return false;
    }
  }

  // 🎤 Speech
  late stt.SpeechToText _speech;
  bool _isAvailable = false;
  String _speechStatus = "notListening";
  String fullText = "";

  BuildContext? dialogContext;
  void Function(void Function())? dialogSetState;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

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
          if (dialogContext != null && mounted && Navigator.canPop(context)) {
            Navigator.pop(dialogContext!);
          } // close dialog
          _searchController.text = fullText;
          _searchController.text = fullText;
          setState(() {});
          // _applyFilters();
        }

        // If you want live update uncomment below
        // setState(() {});
      },
      listenOptions: stt.SpeechListenOptions(),
    );
  }

  // it is for storing dialogSetState

  void stopListening() {
    print("🎤 Listening stopped.");
    _speech.stop();
  }

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
                    // Close button — the dialog is barrierDismissible: false,
                    // so without this there is no way out but the back gesture.
                    // The leading gap balances the icon so the title stays
                    // optically centred.
                    Row(
                      children: [
                        const SizedBox(width: 28),
                        const Expanded(
                          child: Text(
                            "Voice assistance",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // Stop the mic before closing, or it keeps
                            // listening with no UI to show for it.
                            stopListening();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Spot Hatcheries",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomRefereshIndicator(
        onRefresh: () async {
          await controller.fetchSpotHatcheries();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchBar(
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

                  Container(
                    padding: EdgeInsets.only(
                      left: 3,
                      right: 3,
                      bottom: 0,
                      top: 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: InkWell(
                      onTap: startRecording,
                      child: Icon(Icons.mic, color: Colors.blue, size: 30),
                    ),
                  ),
                ],
              ),
              controller: _searchController,
              onMicTap: showVoiceDialog,
              onChanged: (_) {
                setState(() {});
              },
            ),
                  ),
                  const SizedBox(width: 10),
                  FilterIconButton(
                    activeCount: _filters.activeCount,
                    onTap: _openFilterSheet,
                  ),
                ],
              ),
            ),

            // 📍 All / Nearby chips — same pattern as Vehicle Availability.
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _buildLocationChip(
                      label: "All",
                      isSelected: !_nearbyOnly,
                      onTap: () => setState(() => _nearbyOnly = false),
                    ),
                    _buildLocationChip(
                      label: "Nearby $kNearbyRadiusKm km",
                      icon: Icons.my_location,
                      isSelected: _nearbyOnly,
                      isLoading: _isLoadingLocation,
                      onTap: _onNearbyTapped,
                    ),
                  ],
                ),
              ),
            ),

          /// 📃 LIST
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value || controller.isError.value) {
                return ListView.builder(
                  itemCount: 3,
                  itemBuilder: (_, __) => hatcheryCardFullShimmer(),
                );
              }

              final query = _searchController.text.trim().toLowerCase();

              var filteredList = controller.spotHatchery.where((item) {
                final matchesSearch = query.isEmpty ||
                    item.hatcheryName.toString().toLowerCase().contains(query);
                // A default FilterSelection matches everything, so this is a
                // no-op until the user picks something in the sheet.
                return matchesSearch &&
                    spotHatcheryMatchesFilters(item, _filters);
              }).toList();

              // "Nearby" chip — keep only hatcheries within 150 km, nearest
              // first. "All" leaves the list exactly as the filters left it.
              if (_nearbyOnly) {
                filteredList = applyNearbyFilter(
                  filteredList,
                  userLat: _currentLat,
                  userLng: _currentLng,
                );
              }

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nearbyOnly
                            ? "No hatcheries within $kNearbyRadiusKm km"
                            : "No hatcheries found",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      // "Nearby" can legitimately match nothing, which would
                      // otherwise be a dead end — offer the way back to All.
                      if (_nearbyOnly) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _nearbyOnly = false),
                          icon: const Icon(Icons.public_rounded, size: 18),
                          label: const Text('Show all hatcheries'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                      // Without this an over-narrow filter looks like "there
                      // are no hatcheries at all" with no way back.
                      if (!_filters.isEmpty) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _filters = const FilterSelection()),
                          icon: const Icon(Icons.filter_alt_off_rounded,
                              size: 18),
                          label: const Text('Clear filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HarcheryCardWidget(
                      spotHatchery: filteredList[index],
                    ),
                  );
                },
              );
            }),
          ),
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildSearchBar({
    required VoidCallback onMicTap,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Widget suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: Color(0xffE5E7EB)),
      ),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: controller,
          onChanged: onChanged,

          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: suffixIcon,
            hintText: 'Search for hatcherie...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }
}

Widget hatcheryCardFullShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 Image placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              color: Colors.white,
            ),
          ),

          // ⚪ Padding Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔵 Title + Available chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Container(
                      height: 30,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔵 Category Name Placeholder
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔵 Location Row Placeholder
                Row(
                  children: [
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔵 Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
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
