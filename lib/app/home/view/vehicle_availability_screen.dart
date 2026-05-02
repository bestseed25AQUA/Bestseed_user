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

  /// Vehicles whose nearest visited location is within this many km of the
  /// user are shown when "Current Location" is selected.
  static const double _radiusKm = 100;

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

  /// True if any of the vehicle's locations (or its primary location) lies
  /// within `_radiusKm` of the user.
  bool _isWithinRadius(VehicleAvailability v) {
    if (_currentLat == null || _currentLng == null) return false;
    final ulat = _currentLat!;
    final ulng = _currentLng!;
    for (final loc in v.locations) {
      if (loc.latitude == null || loc.longitude == null) continue;
      if (_distanceKm(ulat, ulng, loc.latitude!, loc.longitude!) <= _radiusKm) {
        return true;
      }
    }
    if (v.latitude != null && v.longitude != null) {
      if (_distanceKm(ulat, ulng, v.latitude!, v.longitude!) <= _radiusKm) {
        return true;
      }
    }
    return false;
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

    return controller.vehicleList.where((item) {
      final matchesSearch =
          query.isEmpty || item.hatcheryName.toLowerCase().contains(query);

      bool matchesLocation = true;

      if (_selectedLocation == "current") {
        // 100 km radius from user's current GPS position. Replaces the old
        // string-equality check against `administrativeArea` which never
        // matched (vehicle locations are villages/towns, not state names).
        matchesLocation = _isWithinRadius(item);
      } else if (_selectedLocation != null && _selectedLocation != "current") {
        matchesLocation =
            item.locationName?.toLowerCase() ==
            _selectedLocation?.toLowerCase();
      }

      return matchesSearch && matchesLocation;
    }).toList();
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
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
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
                return const Center(
                  child: Text(
                    "No Vehicles found",
                    style: TextStyle(color: Colors.grey),
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
