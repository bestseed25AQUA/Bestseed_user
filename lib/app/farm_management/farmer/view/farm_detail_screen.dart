import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_history_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/harvest_bottom.dart';
import 'package:seedsuser/main.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FarmTankListScreen extends StatefulWidget {
  final String farmId;
  const FarmTankListScreen({super.key, required this.farmId});

  @override
  State<FarmTankListScreen> createState() => _FarmTankListScreenState();
}

class _FarmTankListScreenState extends State<FarmTankListScreen> {
  final TankController tankController = Get.put(TankController());

  @override
  void initState() {
    super.initState();
    tankController.getTankList(widget.farmId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Sattamma Thalli - A section',
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: Obx(() {
        if (tankController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final tanks = tankController.farmList.value?.data ?? [];

        if (tanks.isEmpty) {
          return const Center(child: Text("No Tanks Available"));
        }

        // split into 2-card rows
        final List<List<TankModel>> tankPairs = [];
        for (int i = 0; i < tanks.length; i += 2) {
          tankPairs.add(
            tanks.sublist(i, i + 2 > tanks.length ? tanks.length : i + 2),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const FeedStoreCard(),
                    const SizedBox(height: 16),

                    ...tankPairs.map((pair) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TankStatusCard(
                                tank: pair[0],
                                controller: tankController,
                                farmId: widget.farmId,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // if odd number → show empty box
                            Expanded(
                              child: pair.length > 1
                                  ? TankStatusCard(
                                      tank: pair[1],
                                      controller: tankController,
                                      farmId: widget.farmId,
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            if (tankController.isUpdatingTankStatus.value)
              Positioned.fill(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// --- Widget for Total Feed Used and Store Card ---
class FeedStoreCard extends StatelessWidget {
  const FeedStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary, // Blue background
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Total Feed Used
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Total feed used',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2500',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    EditButton(),
                  ],
                ),
              ),
              // Separator
              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
              // Store
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Store',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '500',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    EditButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Shared Edit Button Widget ---
class EditButton extends StatelessWidget {
  const EditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, color: AppColors.primary, size: 16),
          SizedBox(width: 4),
          Text(
            'Edit',
            style: GoogleFonts.roboto(color: AppColors.primary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class TankStatusCard extends StatelessWidget {
  final TankModel tank;
  final TankController controller;
  final String farmId;

  const TankStatusCard({
    super.key,
    required this.tank,
    required this.controller,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = tank.status == 1;

    return InkWell(
      onTap: () {
        Get.to(() => TankFeedScreen(tankId: tank.id.toString()));
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(.2), width: .5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // tank name
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tank.tankName ?? "Tank",
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF1976D2),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // switch
                Switch(
                  value: isActive,
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  activeTrackColor: Colors.green.withOpacity(.5),
                  inactiveTrackColor: Colors.red.withOpacity(.5),
                  onChanged: (value) async {
                    if (value) {
                      controller.updateTankStatus(
                        status: 1,
                        tankId: tank.id.toString(),
                        farmId: farmId,
                      );
                    } else {
                      bool isUpdated = false;

                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => HarvestBottomSheet(
                          tank: tank,
                          statusToUpdate: value ? 1 : 0,
                          onSubmit: () async {
                            isUpdated = await controller.updateTankStatus(
                              status: 0,
                              tankId: tank.id.toString(),
                              farmId: farmId,
                            );
                            Get.back();
                          },
                        ),
                      );

                      await Future.delayed(Duration(seconds: 2));

                      if (isUpdated) {
                        String? report = await controller.getReport(
                          tankId: tank.id.toString(),
                        );

                        // ✅ Use global safe context (never disposed)
                        final safeContext = navigatorKey.currentContext!;

                        showReportPopup(
                          safeContext,
                          () async {
                            downloadReport(report ?? '');
                          },
                          () {
                            shareReport(report ?? '');
                          },
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // feed + days
            Row(
              children: [
                Text(
                  "${tank.feedQuantity ?? "0"} Kgs",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "Day. ${tank.meals ?? 0}",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black54,
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

void showReportPopup(
  BuildContext context,
  VoidCallback ontapDownload,
  VoidCallback ontapShare,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: Container(
            margin: EdgeInsets.only(left: 10, right: 10),
            // width: 356,
            height: 371,
            padding: const EdgeInsets.only(left: 22, right: 17, bottom: 23),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Extra-large
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skip button (top right)
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 10, right: 10),
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Report Image
                Image.asset(
                  "assets/images/report.png",
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 10),

                // Title
                const Text(
                  "Tank 1 Feed Report Document",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 18),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// DOWNLOAD BUTTON
                    Expanded(
                      child: Container(
                        width: 150,
                        height: 45,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1.63,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffD9F1FF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: InkWell(
                          onTap: ontapDownload,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/download.png",
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Download",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),

                    /// SHARE BUTTON
                    Expanded(
                      child: Container(
                        width: 150,
                        height: 45,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1.63,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: InkWell(
                          onTap: ontapShare,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/share.png",
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Share",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> downloadReport(String url) async {
  try {
    await Permission.manageExternalStorage.request();

    if (!await Permission.manageExternalStorage.isGranted) {
      await openAppSettings();
    }

    // FIX URL ISSUE
    if (url.startsWith("https:/") && !url.startsWith("https://")) {
      url = url.replaceFirst("https:/", "https://");
    }

    // Get downloads directory
    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String filePath = "${directory!.path}/feed_report.pdf";

    // Download File
    await Dio().download(url, filePath);

    // Check if file exists
    final file = File(filePath);
    bool exists = file.existsSync();

    if (!exists) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    CustomToast.success('Feed Report Document Downloaded Successfully');

    return filePath;
  } catch (e) {
    return null;
  }
}

Future<void> shareReport(String url) async {
  try {
    await Share.share(url, subject: "Feed Report Link");
  } catch (e) {}
}
