// import 'package:flutter/material.dart';
// import 'package:seedsuser/app/common/custom_appbar.dart';
// import 'package:get/get.dart';
// import 'package:seedsuser/app/common/app_color.dart';
// import 'package:seedsuser/app/home/controller/vehicle_availability_controller.dart';
// import 'package:seedsuser/app/home/widget/vehicle_card.dart';
// import 'package:seedsuser/app/home/widget/vehicle_shimmer_card.dart';

// class VehicleAvailabilityScreen extends StatelessWidget {
//   VehicleAvailabilityScreen({super.key});

//   final VehicleController controller = Get.put(VehicleController());
//   final TextEditingController searchController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: CustomAppBar(
//         title: const Text('Vehicle availability'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Vehicle list
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   itemCount: 5, // show 5 shimmer cards
//                   itemBuilder: (context, index) => const Padding(
//                     padding: EdgeInsets.only(bottom: 16),
//                     child: VehicleCardShimmer(),
//                   ),
//                 );
//               }

//               if (controller.vehicles.isEmpty) {
//                 return const Center(child: Text('No vehicles found'));
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 itemCount: controller.vehicles.length,
//                 itemBuilder: (context, index) {
//                   final vehicle = controller.filteredVehicles[index];
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 16.0),
//                     child: VehicleCard(vehicle: vehicle),
//                   );
//                 },
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/voice_mic_button.dart';
import 'package:seedsuser/app/home/controller/vehicle_availabilitys_controller.dart';
import 'package:seedsuser/app/home/view/vehicle_hatchery_card_widget.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';
import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/home/widget/vehicle_filter_sheet.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
import 'package:seedsuser/app/spot_hatchery/controller/spot_hatchery_controller.dart';
import 'package:seedsuser/app/spot_hatchery/view/harchery_card_widget.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VehicleAvailabilityScreen extends StatefulWidget {
  const VehicleAvailabilityScreen({super.key});

  @override
  State<VehicleAvailabilityScreen> createState() =>
      _VehicleAvailabilityScreenState();
}

class _VehicleAvailabilityScreenState extends State<VehicleAvailabilityScreen> {
  final VehicleAvailabilitysController controller = Get.put(
    VehicleAvailabilitysController(),
  );

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Filters chosen in the bottom sheet — empty means "show everything".
  FilterSelection _filters = const FilterSelection();

  Future<void> _openFilterSheet() async {
    final result = await showVehicleFilterSheet(
      context,
      vehicles: controller.vehicleList.toList(),
      initial: _filters,
      // Reset clears the list immediately rather than waiting for Apply.
      onReset: (cleared) => setState(() => _filters = cleared),
    );
    // null = dismissed without applying, so keep the current filters.
    if (result != null) setState(() => _filters = result);
  }

  // 🎤 Speech
  late stt.SpeechToText _speech;
  bool _isAvailable = false;
  String _speechStatus = "notListening";
  String fullText = "";

  BuildContext? dialogContext;
  void Function(void Function())? dialogSetState;

  // 📍 Location Filter
  String?
  _selectedLocation; // null means "All", "current" means current location filter
  double? _currentLat;
  double? _currentLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // The controller is created once via Get.put and reused across visits, so
    // onInit's fetch only runs the first time. On a reopen the instance still
    // holds stale data with isLoading=false, which showed the old list with no
    // shimmer until a manual refresh. Re-fetch here when not already loading so
    // the shimmer appears immediately and the list is fresh on every open.
    if (!controller.isLoading.value) {
      controller.fetchVehicleAvailability();
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print("STATUS: $status");
          _speechStatus = status;
          if (dialogSetState != null) {
            dialogSetState!(() {});
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

  // 📍 Get Current Location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomToast.error("Location permission denied");
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        CustomToast.error("Location permission permanently denied");
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position — only lat/lng is needed for the radius filter.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('📍 [VEHICLE-FILTER] Current Location tapped → '
          'lat=${position.latitude}, lng=${position.longitude}');

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _selectedLocation = "current";
        _isLoadingLocation = false;
      });
    } catch (e) {
      print("Location error: $e");
      CustomToast.error("Failed to get current location");
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// Haversine distance in km between two lat/lng points.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    double toRad(double deg) => deg * (3.141592653589793 / 180.0);
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            (math.sin(dLng / 2) * math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Shortest distance in km from point P (the user) to the travel segment
  /// A→B (two consecutive route stops). Uses a local equirectangular
  /// projection to km, which is accurate enough at the ~100 km filter scale.
  /// This is what makes the filter route-aware: a post is relevant when the
  /// user is near the PATH between stops, not only near a stop itself.
  double _distanceToSegmentKm(
    double pLat, double pLng,
    double aLat, double aLng,
    double bLat, double bLng,
  ) {
    const kmPerDegLat = 111.32;
    double toRad(double d) => d * (3.141592653589793 / 180.0);
    final kmPerDegLng = 111.32 * math.cos(toRad((aLat + bLat) / 2));

    // Project to planar km coordinates relative to A.
    final bx = (bLng - aLng) * kmPerDegLng;
    final by = (bLat - aLat) * kmPerDegLat;
    final px = (pLng - aLng) * kmPerDegLng;
    final py = (pLat - aLat) * kmPerDegLat;

    final segLenSq = bx * bx + by * by;
    // Project P onto AB, clamped to the segment ends (t in [0,1]).
    final t = segLenSq == 0
        ? 0.0
        : ((px * bx + py * by) / segLenSq).clamp(0.0, 1.0);
    final closestX = t * bx;
    final closestY = t * by;
    final dx = px - closestX;
    final dy = py - closestY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Shortest distance (km) from the user to ANY point on the vehicle's
  /// route — stops + travel segments + fallback primary location.
  ///
  /// Returns `double.infinity` when the user has no GPS or the vehicle has
  /// no usable coordinates, so callers can push those items to the end of
  /// a nearest-first sort without special casing.
  double _shortestDistanceKm(VehicleAvailability v) {
    if (_currentLat == null || _currentLng == null) return double.infinity;
    final ulat = _currentLat!;
    final ulng = _currentLng!;

    var best = double.infinity;

    final route = <VehicleLocation>[
      for (final loc in v.locations)
        if (loc.latitude != null && loc.longitude != null) loc,
    ];

    for (final loc in route) {
      final d = _distanceKm(ulat, ulng, loc.latitude!, loc.longitude!);
      if (d < best) best = d;
    }

    for (var i = 0; i < route.length - 1; i++) {
      final a = route[i];
      final b = route[i + 1];
      final d = _distanceToSegmentKm(
        ulat, ulng,
        a.latitude!, a.longitude!,
        b.latitude!, b.longitude!,
      );
      if (d < best) best = d;
    }

    if (v.latitude != null && v.longitude != null) {
      final d = _distanceKm(ulat, ulng, v.latitude!, v.longitude!);
      if (d < best) best = d;
    }

    return best;
  }


  // 📍 Get unique locations from data
  List<String> _getUniqueLocations() {
    final locations = <String>{};

    for (var item in controller.vehicleList) {
      if (item.locationName != null && item.locationName!.isNotEmpty) {
        locations.add(item.locationName!);
      }
    }

    return locations.toList()..sort();
  }

  // 📍 Filter data based on selected location
  List<VehicleAvailability> _getFilteredList() {
    final query = _searchController.text.trim().toLowerCase();

    final result = controller.vehicleList.where((item) {
      final matchesSearch =
          query.isEmpty || item.hatcheryName.toLowerCase().contains(query);

      bool matchesLocation = true;

      if (_selectedLocation != null && _selectedLocation != "current") {
        // Explicit named-location chip (state/town) — still an exact match.
        matchesLocation =
            item.locationName?.toLowerCase() ==
            _selectedLocation?.toLowerCase();
      }
      // "current" chip intentionally does NOT filter — we show ALL vehicles
      // and let the sort below push the nearest ones to the top. This way
      // farther vehicles are still visible (just lower down) instead of
      // being hidden entirely by a radius cut-off.

      // Bottom-sheet filters (route / category / hatchery / date range).
      // A default VehicleFilters matches everything, so this is a no-op
      // until the user actually picks something.
      return matchesSearch && matchesLocation && vehicleMatchesFilters(item, _filters);
    }).toList();

    if (_selectedLocation == "current") {
      // Sort nearest-first so vehicles close to the user's GPS bubble up to
      // the top of the list. The backend still returns newest-first; we
      // override that here only when the user explicitly asked for nearby.
      // Vehicles with no usable coordinates get `double.infinity` from
      // _shortestDistanceKm and fall to the end. Ties fall back to the
      // backend's newest-first order because Dart's sort is stable.
      result.sort((a, b) => _shortestDistanceKm(a).compareTo(_shortestDistanceKm(b)));
      debugPrint('📍 [VEHICLE-FILTER] sorted nearest-first from '
          '($_currentLat,$_currentLng): ${result.length} vehicles');
    }
    return result;
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
          stopListening();
          if (dialogContext != null && mounted && Navigator.canPop(context)) {
            Navigator.pop(dialogContext!);
          }
          _searchController.text = fullText;
          setState(() {});
        }
      },
      listenOptions: stt.SpeechListenOptions(),
    );
  }

  void stopListening() {
    print("🎤 Listening stopped.");
    _speech.stop();
  }

  void showVoiceDialog() {
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
          "Vehicle availability",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomRefereshIndicator(
        onRefresh: () async {
          await controller.fetchVehicleAvailability();
        },
        child: Column(
          children: [
            // 🔍 Search Bar + Filter button
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

          // 📍 Location Filter Chips (All + Current Location only)
          Obx(() {
            if (controller.isLoading.value) {
              return const SizedBox.shrink();
            }

            return Container(
              height: 50,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _buildLocationChip(
                    label: "All",
                    isSelected: _selectedLocation == null,
                    onTap: () {
                      setState(() {
                        _selectedLocation = null;
                      });
                    },
                  ),
                  _buildLocationChip(
                    label: "Current Location",
                    icon: Icons.my_location,
                    isSelected: _selectedLocation == "current",
                    isLoading: _isLoadingLocation,
                    onTap: () {
                      _getCurrentLocation();
                    },
                  ),
                ],
              ),
            );
          }),

          // 📃 LIST
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value || controller.isError.value) {
                return ListView.builder(
                  itemCount: 3,
                  itemBuilder: (_, __) => hatcheryCardFullShimmer(),
                );
              }

              final filteredList = _getFilteredList();

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "No Vehicles found",
                        style: TextStyle(color: Colors.grey),
                      ),
                      // Without this an over-narrow filter looks like "there
                      // are no vehicles at all" with no way back.
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
                    child: VehicleHatcheryCardWidget(
                      vehicleAvailability: filteredList[index],
                      currentLat: _currentLat,
                      currentLng: _currentLng,
                      highlightNearby: _selectedLocation == "current",
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

  // 📍 Location Chip Widget
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
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
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
            hintText: 'Search for Vehicles...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }
}
