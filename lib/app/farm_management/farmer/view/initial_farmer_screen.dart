// first_screen.dart
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/farm_home/farm_home_screen.dart';
import 'package:seedsuser/app/farm_management/farm_home/notify_us_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/scanner_guide_screen.dart';

class InitialFarmScreen extends StatefulWidget {
  const InitialFarmScreen({super.key});

  @override
  State<InitialFarmScreen> createState() => _InitialFarmScreenState();
}

class _InitialFarmScreenState extends State<InitialFarmScreen> {
  /// Guards the one-way handover so it cannot fire twice.
  bool _handedOver = false;

  @override
  void initState() {
    super.initState();
    // Deferred: fetchFarmList() flips an observable, and doing that while an
    // ancestor Obx is mid-build trips "!_dirty is not true".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) farmListController.fetchFarmList();
    });
  }

  /// Re-check after any screen we opened closes.
  ///
  /// Every route out of here can end with a farm existing — the add form
  /// directly, or Contact Us -> Fill Form, or scanning a QR that grants access
  /// to someone else's farm. Without this the user came back to "no farms yet"
  /// even though they had just created one.
  Future<void> _openThenRefresh(Widget screen) async {
    await Get.to(() => screen);
    await farmListController.fetchFarmList();
  }

  @override
  Widget build(BuildContext context) {
    // This is the "you have no farms yet" screen. Adding a farm used to pop
    // straight back here, so a farm that had just been created still showed the
    // empty state. Watching the list means the moment one exists we hand over
    // to the real screen — whichever way the user got back here.
    return Obx(() {
      final farms = farmListController.farmList.value?.data;

      // Farms exist now — REPLACE this route rather than rendering the other
      // screen inside this one. Rendering it nested made the two screens build
      // each other in a loop, hammering /farm-lists and crashing the frame.
      if (farms != null && farms.isNotEmpty && !_handedOver) {
        _handedOver = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FarmManagementScreen()),
          );
        });
      }

      return _buildEmptyState(context);
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => safeBack(),
        ),
        title: Text(
          'Farmer',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          // This chip had no tap handler at all — it was decoration. Scanning
          // matters most here: a manager or partner with no farm of their own
          // reaches this screen, and the QR is how they get access to one.
          InkWell(
            onTap: () => _openThenRefresh(const ScannerGuideScreen()),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 16.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan',
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top content: Image and text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/image 76.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Add Farm Details',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your farm's details to get started.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    onPressed: () =>
                        _openThenRefresh(AddFarmerDetailsFormScreen()),
                    text: 'Add Farm Details',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _openThenRefresh(const NotifyUsScreen()),
                  child: Text(
                    'Contact Us',
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
