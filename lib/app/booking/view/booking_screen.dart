import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/spot_hatchery/view/spot_hatchery_detail_screen.dart';
import 'package:seedsuser/app/spot_hatchery/controller/spot_hatchery_controller.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_detail_screen.dart';
import 'package:seedsuser/app/home/controller/vehicle_availabilitys_controller.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final MyBookingController controller = Get.put(MyBookingController());
  final ProfileController profileController = Get.put(ProfileController());
  String selected = "Filter";

  @override
  void initState() {
    super.initState();

    _initSpeech();
    // fetchBookings() is already called in controller's onInit()

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels != 0) {
          controller.loadMore();
        }
      }
    });
  }

  final ScrollController _scrollController = ScrollController();

  //// voice
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 🎤 Speech
  late stt.SpeechToText _speech;
  bool _isAvailable = false;
  String _speechStatus = "notListening";
  String fullText = "";

  BuildContext? dialogContext;
  void Function(void Function())? dialogSetState;

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

  void applyFilter(String filter) async {
    DateTime now = DateTime.now();
    if (filter == "Today") {
      controller.selectedDate.value =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";
    } else if (filter == "This Month") {
      controller.selectedMonth.value = now.month.toString();
      controller.selectedYear.value = now.year.toString();
      controller.selectedDate.value = "";
    } else if (filter == "This Year") {
      controller.selectedMonth.value = "";
      controller.selectedYear.value = now.year.toString();
      controller.selectedDate.value = "";
    } else if (filter == "Custom Date") {
      pickDate();
      return;
    } else if (filter == "Clear Filters") {
      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";
      controller.selectedDate.value = "";
    }

    controller.fetchBookings();
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.selectedDate.value =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      controller.selectedMonth.value = "";
      controller.selectedYear.value = "";

      controller.fetchBookings();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.90,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------- DRAG HANDLE -------
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // ------- TITLE -------
                  Text(
                    "Filter Bookings",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ------- MONTH PICKER -------
                  Text(
                    "Select Month",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      return _monthChip(month);
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ------- YEAR PICKER -------
                  Text(
                    "Select Year",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 45,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(15, (index) {
                        final year = 2018 + index;
                        return _yearChip(year);
                      }),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------- CUSTOM DATE -------
                  Text(
                    "Custom Date",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            controller.selectedDate.value.isNotEmpty
                                ? controller.selectedDate.value
                                : "Select date",
                            style: GoogleFonts.roboto(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------- CLEAR FILTER -------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        controller.selectedMonth.value = "";
                        controller.selectedYear.value = "";
                        controller.selectedDate.value = "";
                        controller.fetchBookings();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Clear Filters",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _monthChip(int month) {
    return Obx(() {
      final isSelected = controller.selectedMonth.value == month.toString();
      return InkWell(
        onTap: () {
          controller.selectedMonth.value = month.toString();
          controller.selectedDate.value = "";
          controller.fetchBookings();
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade300 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 : Colors.blue.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            _monthName(month),
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.blue.shade700,
            ),
          ),
        ),
      );
    });
  }

  String _monthName(int m) {
    return [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ][m - 1];
  }

  Widget _yearChip(int year) {
    return Obx(() {
      final isSelected = controller.selectedYear.value == year.toString();
      return InkWell(
        onTap: () {
          controller.selectedMonth.value = "";
          controller.selectedDate.value = "";
          controller.selectedYear.value = year.toString();
          controller.fetchBookings();
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade400 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.green.shade700 : Colors.green.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            "$year",
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.green.shade700,
            ),
          ),
        ),
      );
    });
  }

  String selectedFilter = "All";
  Widget buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });

        // CALL YOUR FILTER LOGIC HERE
        if (label == "All") {
          controller.filterType.value = "";
        } else if (label == "Hatchery") {
          controller.filterType.value = "hatchery";
        } else if (label == "Spot Hatchery") {
          controller.filterType.value = "spot";
        }

        controller.fetchBookings(); // refresh bookings
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          RefreshButton(
            onTap: () {
              controller.fetchBookings();
            },
          ),
          GestureDetector(
            onTap: () => showFilterSheet(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    "Filters",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
        // bottom: PreferredSize(
        //   preferredSize: Size(double.infinity, 60),
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        //     child: Row(
        //       children: [
        //         buildFilterChip("All"),
        //         const SizedBox(width: 10),
        //         buildFilterChip("Hatchery"),
        //         const SizedBox(width: 10),
        //         buildFilterChip("Spot Hatchery"),
        //       ],
        //     ),
        //   ),
        // ),
      ),
      body: Builder(
        builder: (context) {
          return CustomRefereshIndicator(
            onRefresh: () async {
              await controller.fetchBookings();
            },
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return bookingCardShimmer();
                  },
                );
              }
              if (controller.bookingList.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * .3,
                  ),
                  child: Center(
                    child: Text(
                      "No bookings found",
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
                );
              }

              final query = _searchController.text.trim().toLowerCase();

              final filteredList = controller.bookingList.where((item) {
                if (query.isEmpty) return true;
                return item.bookingId.toString().contains(query) ||
                    item.bookingUid.toLowerCase().contains(query) ||
                    item.hatcheryName.toLowerCase().contains(query) ||
                    item.droppingLocation.toLowerCase().contains(query);
              }).toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSearchBar(
                      focusNode: _focusNode,
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
                              // border: Border.all(color: Colors.blue),
                            ),
                            child: InkWell(
                              onTap: startRecording,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 3,
                                  right: 3,
                                  bottom: 3,
                                  top: 3,
                                ),
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                              ),
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
                  Expanded(
                    child: filteredList.isEmpty && query.isNotEmpty
                        ? Center(
                            child: Text(
                              "No bookings found",
                              style: GoogleFonts.roboto(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount:
                                filteredList.length +
                                (query.isEmpty && controller.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < filteredList.length) {
                                final booking = filteredList[index];
                                return _buildBookingCard(
                                  booking,
                                  () {
                                    Get.to(
                                      BookingDetailScreen(
                                        hatcheryName: booking.hatcheryName,
                                        bookingId: booking.bookingId.toString(),
                                      ),
                                    );
                                  },
                                  () async {
                                    // Navigate to correct screen based on booking type
                                    if (booking.isSpot?.value == 1) {
                                      // Spot Hatchery - fetch data and navigate to detail
                                      final spotController = Get.put(
                                        SpotHatcheryController(),
                                      );
                                      if (spotController.spotHatchery.isEmpty) {
                                        await spotController
                                            .fetchSpotHatcheries();
                                      }
                                      final spotHatchery = spotController
                                          .spotHatchery
                                          .firstWhereOrNull(
                                            (s) =>
                                                s.hatcheryId ==
                                                booking.hatcheryId,
                                          );
                                      if (spotHatchery != null) {
                                        Get.to(
                                          () => SpotHatcheryDetailScreen(
                                            spotHatchery: spotHatchery,
                                          ),
                                        );
                                      } else {
                                        CustomToast.error(
                                          "Spot hatchery not found",
                                        );
                                      }
                                    } else if (booking.isSpot?.value == 2) {
                                      // Vehicle Availability - fetch data and navigate to detail
                                      final vehicleController = Get.put(
                                        VehicleAvailabilitysController(),
                                      );
                                      if (vehicleController
                                          .vehicleList
                                          .isEmpty) {
                                        await vehicleController
                                            .fetchVehicleAvailability();
                                      }
                                      final vehicle = vehicleController
                                          .vehicleList
                                          .firstWhereOrNull(
                                            (v) =>
                                                v.vehicleId ==
                                                booking.hatcheryId,
                                          );
                                      if (vehicle != null) {
                                        Get.to(
                                          () => VehicleAvailabilityDetailScreen(
                                            vehicleAvailability: vehicle,
                                          ),
                                        );
                                      } else {
                                        CustomToast.error("Vehicle not found");
                                      }
                                    } else {
                                      // Regular Hatchery
                                      Get.to(
                                        () => HatcheryCateogryScreen(
                                          hatcheryId: booking.hatcheryId
                                              .toString(),
                                          hatcheryName: booking.hatcheryName,
                                          useHatcheryId: true,
                                        ),
                                      );
                                    }
                                  },
                                );
                              } else {
                                // LOAD MORE LOADER
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar({
    required VoidCallback onMicTap,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required Widget suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: Color(0xffE5E7EB)),
      ),
      child: SizedBox(
        height: 42,
        child: TextField(
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          onTapOutside: (event) {
            focusNode.unfocus();
          },
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: Colors.grey, size: 20),
            hintText: 'Search by ID, name or location...',
            hintStyle: const TextStyle(fontSize: 14),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }

  // 🔹 Dropdown for filters
  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // 🔹 Booking Card UI
  Widget _buildBookingCard(
    BookingData data,
    VoidCallback ontap,
    VoidCallback ontapTryAgain,
  ) {
    final String status = data.status?['label']?.toString() ?? '';
    final statusLower = status.toLowerCase();

    // Status styling
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    if (statusLower == "pending") {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFFF7ED);
      statusIcon = Icons.schedule_rounded;
    } else if (statusLower == "cancelled") {
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEE2E2);
      statusIcon = Icons.cancel_outlined;
    } else if (statusLower == "delivered") {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (statusLower == "in journey" || statusLower == "in progress" || statusLower == "in journey") {
      statusColor = const Color(0xFF3B82F6);
      statusBg = const Color(0xFFDBEAFE);
      statusIcon = Icons.local_shipping_rounded;
    } else {
      statusColor = const Color(0xFF0077C8);
      statusBg = const Color(0xFFE0F2FE);
      statusIcon = Icons.info_outline_rounded;
    }

    final isCancelled = statusLower == "cancelled";

    return InkWell(
      onTap: isCancelled ? ontapTryAgain : ontap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header: Type + Status ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.isSpot?.value == 1
                          ? "Spot Hatchery"
                          : data.isSpot?.value == 2
                              ? "Vehicle"
                              : 'Hatchery',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "#${data.bookingId}",
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.capitalizeFirst ?? '',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hatchery name + delivery date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.hatcheryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (data.categoryName.isNotEmpty)
                              Text(
                                data.categoryName,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (data.deliveryDatetime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                data.deliveryDatetime,
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Info chips row
                  Row(
                    children: [
                      _bookingInfoChip(
                        Icons.inventory_2_outlined,
                        "${data.noOfPieces} pcs",
                      ),
                      const SizedBox(width: 8),
                      if (data.packingDate.isNotEmpty)
                        _bookingInfoChip(
                          Icons.event_outlined,
                          data.packingDate,
                        ),
                      const SizedBox(width: 8),
                      if (data.droppingLocation.isNotEmpty)
                        Expanded(
                          child: _bookingInfoChip(
                            Icons.location_on_outlined,
                            data.droppingLocation,
                            expanded: true,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: isCancelled
                        ? OutlinedButton.icon(
                            onPressed: ontapTryAgain,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              "Try Again",
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side:
                                  const BorderSide(color: Color(0xFFEF4444)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: ontap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F7FF),
                              foregroundColor: const Color(0xFF0077C8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "View Details",
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingInfoChip(IconData icon, String text, {bool expanded = false}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return expanded ? child : child;
  }
}

String formatDateDMY(String dateString) {
  try {
    DateTime date = DateTime.parse(dateString);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  } catch (e) {
    return ""; // return empty if error
  }
}

Widget bookingCardShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TOP ROW ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 120, height: 16),
              _shimmerBox(width: 80, height: 24, radius: 20),
            ],
          ),

          const SizedBox(height: 14),

          // ---------------- ID + DATE ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 160, height: 14),
              _shimmerBox(width: 100, height: 14),
            ],
          ),

          const SizedBox(height: 14),

          // ---------------- HATCHERY NAME ----------------
          _shimmerBox(width: double.infinity, height: 18),
          const SizedBox(height: 6),
          _shimmerBox(width: 140, height: 14),

          const SizedBox(height: 14),

          // ---------------- PIECES + DATE ----------------
          Row(
            children: [
              _shimmerCircle(size: 24),
              const SizedBox(width: 8),
              _shimmerBox(width: 80, height: 14),
              const Spacer(),
              _shimmerCircle(size: 18),
              const SizedBox(width: 6),
              _shimmerBox(width: 70, height: 14),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------- LOCATION ----------------
          Row(
            children: [
              _shimmerCircle(size: 20),
              const SizedBox(width: 8),
              Expanded(child: _shimmerBox(height: 14)),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------- BUTTON ----------------
          _shimmerBox(width: double.infinity, height: 44, radius: 20),
        ],
      ),
    ),
  );
}

Widget _shimmerBox({
  double width = 100,
  double height = 12,
  double radius = 8,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget _shimmerCircle({double size = 20}) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}
