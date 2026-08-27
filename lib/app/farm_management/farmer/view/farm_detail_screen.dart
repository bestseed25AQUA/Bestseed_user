import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/app_globals.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_history_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/harvest_bottom.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/contact_us_dialog.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/feed_low_alert_dialog.dart';

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

class FarmTankListScreen extends StatefulWidget {
  final String farmId;
  final String farmName;

  /// What the logged-in farmer may do with this farm.
  ///
  /// Every write below is gated server-side by `farm.access:*`. Showing the
  /// controls regardless meant a partner with view access could flip a tank to
  /// harvested and be told "Failed to update tank" — a 403 dressed up as a
  /// fault, with no hint that they were never allowed to.
  final FarmAccess access;

  const FarmTankListScreen({
    super.key,
    required this.farmId,
    required this.farmName,
    this.access = const FarmAccess.ownerFallback(),
  });

  @override
  State<FarmTankListScreen> createState() => _FarmTankListScreenState();
}

class _FarmTankListScreenState extends State<FarmTankListScreen> {
  final TankController tankController = Get.put(TankController());

  /// The farm id as a number, or null when it is not one.
  ///
  /// The id arrives as a string built with `e.id.toString()`, so a farm the
  /// API returned without an id reaches this screen as the literal "null".
  /// `int.parse` threw on that from initState — an exception with no catch
  /// around it, so the screen came up as a red error page. The calls that
  /// need a number are skipped instead.
  int? get _farmIdNum => int.tryParse(widget.farmId);

  /// True while the low-feed dialog is up, or after it has been shown for the
  /// current low spell. Reset once the store recovers, so the farmer is warned
  /// again the next time it drops rather than nagged every rebuild.
  bool _lowFeedWarned = false;
  Worker? _storeWatcher;

  /// Shared by the scroll view and its Scrollbar, so the thumb tracks the list.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Clear the busy flags before anything else.
    //
    // TankController is shared across four screens and outlives any one of
    // them, so a spinner raised by an earlier action — a status toggle whose
    // request stalled, or a save the user backed out of — was still set when
    // this screen opened, leaving it dimmed under a spinner that nothing was
    // going to clear. A screen that has just opened is not busy.
    tankController.isUpdatingTankStatus(false);
    tankController.isAddingTodayTankQuntity(false);
    tankController.isOverlay(false);

    tankController.getTankList(widget.farmId);

    final farmIdNum = _farmIdNum;
    if (farmIdNum != null) {
      tankController.getFeedStore(farmIdNum);
      _maybeWarnLowFeed();
    }

    // Re-check whenever the store figure changes — editing the store or
    // recording feed both land here — so the alert appears the moment stock
    // drops below the limit, not only on the next visit to this screen.
    _storeWatcher = ever(tankController.feedStoreData, (_) {
      _maybeWarnLowFeed();
    });
  }

  @override
  void dispose() {
    _storeWatcher?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Surfaces the low-feed alert once the screen has settled, so the dialog
  /// does not race the first frame.
  Future<void> _maybeWarnLowFeed() async {
    final farmIdNum = _farmIdNum;
    if (farmIdNum == null) return;

    final limit = await Get.put(
      FarmAccessController(),
    ).checkFeedLimit(farmIdNum);

    if (!mounted) return;

    // Not low (or the check failed): arm the alert for the next drop.
    if (limit == null) {
      _lowFeedWarned = false;
      return;
    }

    if (_lowFeedWarned) return;
    _lowFeedWarned = true;

    await showFeedLowAlert(
      context,
      remainingKgs: limit,
      onContactDealer: () {
        Navigator.of(context).pop();
        showDialog(context: context, builder: (_) => const ContactUsDialog());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: CustomAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.farmName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: Obx(() {
        if (tankController.isLoading.value) {
          return const TankGridShimmer();
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
              // A visible thumb down the right edge: with a dozen tanks there
              // is no other clue as to how much list is left below the fold.
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 4,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FeedStoreCard(
                        farmId: widget.farmId,
                        access: widget.access,
                      ),
                      const SizedBox(height: 16),

                      ...tankPairs.map((pair) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TankStatusCard(
                                  farmName: widget.farmName,
                                  access: widget.access,
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
                                        farmName: widget.farmName,
                                        access: widget.access,
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

class FeedStoreCard extends StatelessWidget {
  const FeedStoreCard({
    super.key,
    required this.farmId,
    this.access = const FarmAccess.ownerFallback(),
  });
  final String farmId;
  final FarmAccess access;

  @override
  Widget build(BuildContext context) {
    final TankController controller = Get.find();

    return Obx(() {
      if (controller.isFeedLoading.value) {
        return const TankGridShimmer();
      }

      final data = controller.feedStoreData.value;

      return Card(
        color: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOTAL FEED USED
              //
              // Flexible: the two labels and a five-figure total are wider
              // than a narrow phone once the system font size is turned up,
              // and the row overflowed rather than wrapping.
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Total feed used",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data?.totalFeedUsed.toString() ?? "0",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // InkWell(
                    //   onTap: () {
                    //     showEditFeedBottomSheet(farmId.toString());
                    //   },
                    //   child: EditButton(),
                    // ),
                  ],
                ),
              ),

              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                width: 30,
              ),

              // FEED STORE
              Flexible(
                child: Column(
                  children: [
                    Text(
                      "Remaining Stock",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // What is LEFT, not what was put in: the raw store figure
                    // never moves as feed is recorded, so it read as though
                    // nothing had been used.
                    // An em dash, not "0": the store is optional, and a farm
                    // whose stock nobody has entered yet has an UNKNOWN
                    // remainder, not a remainder of nothing. Tapping Edit is
                    // how the farmer fills it in.
                    Text(
                      (data?.remainingStore ?? data?.feedStore)?.toString() ??
                          '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Changing the store is an edit — /update-total-feed sits
                    // behind `farm.access:edit`.
                    if (access.canEdit)
                      InkWell(
                        onTap: () => showEditFeedBottomSheet(farmId.toString()),
                        child: const EditButton(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
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
  final String farmName;
  final FarmAccess access;

  const TankStatusCard({
    super.key,
    required this.tank,
    required this.controller,
    required this.farmId,
    required this.farmName,
    this.access = const FarmAccess.ownerFallback(),
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = tank.status == 1;

    return InkWell(
      onTap: () async {
        await Get.to(
          () => TankFeedScreen(
            tankId: tank.id.toString(),
            tankName: tank.tankName ?? '',
            farmName: farmName,
            access: access,
          ),
        );

        // Feed recorded on the history screen changes this tank's total and the
        // farm's store, so re-read on the way back. Without this the card still
        // showed the figures from when the screen first opened.
        //
        // Silent: no shimmer, no scroll jump — the numbers just update.
        await controller.getTankList(farmId, silent: true);

        // tryParse, not parse: a farm that came back without an id reaches
        // here as "null" and the throw would escape this callback unhandled.
        final farmIdNum = int.tryParse(farmId);
        if (farmIdNum != null) {
          await controller.getFeedStore(farmIdNum, silent: true);
        }
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
                //
                // Flexible, because the card is half the screen wide and the
                // switch beside it is a fixed ~60dp: on a narrow phone the
                // name and the switch together were wider than the card and
                // the row overflowed. The name gives way instead.
                Flexible(
                  child: Container(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF1976D2),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // switch
                // Switch(
                //   value: isActive,
                //   activeThumbColor: Colors.green,
                //   inactiveThumbColor: Colors.red,
                //   activeTrackColor: Colors.green.withOpacity(.5),
                //   inactiveTrackColor: Colors.red.withOpacity(.5),
                //   onChanged: (value) async {
                //     if (value) {
                //       controller.updateTankStatus(
                //         status: 1,
                //         tankId: tank.id.toString(),
                //         farmId: farmId,
                //       );
                //     } else {
                //       bool isUpdated = false;

                //       await showModalBottomSheet(
                //         context: context,
                //         isScrollControlled: true,
                //         backgroundColor: Colors.transparent,
                //         builder: (_) => HarvestBottomSheet(
                //           tank: tank,
                //           statusToUpdate: value ? 1 : 0,
                //           onSubmit: () async {
                //             isUpdated = await controller.updateTankStatus(
                //               status: 0,
                //               tankId: tank.id.toString(),
                //               farmId: farmId,
                //             );
                //             safeBack();
                //           },
                //         ),
                //       );

                //       await Future.delayed(Duration(seconds: 2));

                //       if (isUpdated) {
                //         String? report = await controller.getReport(
                //           tankId: tank.id.toString(),
                //         );

                //         // ✅ Use global safe context (never disposed)
                //         final safeContext = navigatorKey.currentContext!;

                //         showReportPopup(
                //           safeContext,
                //           () async {
                //             downloadReport(report ?? '');
                //           },
                //           () {
                //             shareReport(report ?? '');
                //           },
                //         );
                //       }
                //     }
                //   },
                // ),
                SwitchTheme(
                  data: SwitchThemeData(
                    thumbColor: MaterialStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.green;
                      }
                      return Colors.red;
                    }),
                    trackColor: MaterialStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.green.withOpacity(.5);
                      }
                      return Colors.red.withOpacity(.5);
                    }),
                  ),
                  child: Switch(
                    value: isActive,
                    // Null disables the switch rather than hiding it: the
                    // colour still tells a view-only partner whether the tank
                    // is running, which is the point of the card. /tank/status
                    // requires `farm.access:edit`.
                    onChanged: !access.canEdit
                        ? null
                        : (value) async {
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
                                useSafeArea: true,
                                builder: (_) => SafeArea(
                                  top: false,
                                  child: HarvestBottomSheet(
                                    tank: tank,
                                    statusToUpdate: value ? 1 : 0,
                                    onSubmit: () async {
                                      isUpdated = await controller
                                          .updateTankStatus(
                                            status: 0,
                                            tankId: tank.id.toString(),
                                            farmId: farmId,
                                          );
                                      safeBack();
                                    },
                                  ),
                                ),
                              );

                              await Future.delayed(const Duration(seconds: 2));

                              if (isUpdated) {
                                String? report = await controller.getReport(
                                  tankId: tank.id.toString(),
                                );

                                // No link means the report was not generated —
                                // getReport has already said so. Offering Download
                                // and Share for a link that does not exist only
                                // produces a second, more confusing failure.
                                final safeContext = navigatorKey.currentContext;
                                if (report == null ||
                                    report.isEmpty ||
                                    safeContext == null) {
                                  return;
                                }

                                showReportPopup(
                                  safeContext,
                                  tankName: tank.tankName ?? 'Tank',
                                  () async {
                                    downloadReport(report);
                                  },
                                  () {
                                    shareReport(report);
                                  },
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // feed + days
            Row(
              children: [
                // total_feed_used, not the tank's feed_quantity column: that
                // column is never written to, so every tank read "0 Kgs" even
                // with weeks of feed recorded against it.
                // Expanded rather than a Spacer after it: a four-figure total
                // ("1,250.00 Kgs") plus the day label is wider than half a
                // narrow screen, and the row overflowed instead of trimming.
                Expanded(
                  child: Text(
                    "${tank.totalFeedUsed ?? "0"} Kgs",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // The API computes `day` as the number of distinct days fed.
                // This showed `meals` — a different, unset column — so it was
                // always "Day. 0".
                Text(
                  "Day. ${tank.day ?? 0}",
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
  VoidCallback ontapShare, {
  String tankName = 'Tank',
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        // Breathing room at the edges — the sheet used to run almost the full
        // width of the screen.
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Container(
            margin: EdgeInsets.zero,
            // width: 356,
            // Sized to its contents inside a scroll view rather than pinned to
            // 371: at a larger system font size the fixed box was shorter than
            // the text and image it holds, and the card overflowed.
            padding: const EdgeInsets.only(left: 22, right: 17, bottom: 23),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Extra-large
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  // Title — the tank the report is actually for. This read
                  // "Tank 1" for every tank on every farm.
                  Text(
                    "$tankName Feed Report Document",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
        ),
      );
    },
  );
}

Future<String?> downloadReport(String url) async {
  try {
    // FIX URL ISSUE
    if (url.startsWith("https:/") && !url.startsWith("https://")) {
      url = url.replaceFirst("https:/", "https://");
    }

    // Save into the app-owned external storage (Android: /Android/data/<pkg>/files)
    // or the app documents directory (iOS). Neither location requires a
    // runtime permission or MANAGE_EXTERNAL_STORAGE — Play Store rejected
    // the previous /storage/emulated/0/Download path because it needed
    // broad "All files access", which we're not entitled to use.
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    if (directory == null) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    final filePath = "${directory.path}/feed_report.pdf";
    await Dio().download(url, filePath);

    final file = File(filePath);
    if (!file.existsSync()) {
      CustomToast.error('Feed Report Document Failed To Download');
      return null;
    }

    CustomToast.success('Feed Report Document Downloaded Successfully');
    return filePath;
  } catch (e) {
    // Say so. A silent null here left the farmer tapping Download on a dialog
    // that never acknowledged the tap — no file, no message, nothing.
    CustomToast.error('Feed Report Document Failed To Download');
    return null;
  }
}

Future<void> shareReport(String url) async {
  if (url.isEmpty) {
    CustomToast.error('No report link to share');
    return;
  }

  try {
    await Share.share(url, subject: "Feed Report Link");
  } catch (e) {
    CustomToast.error('Could not share the report');
  }
}

void showEditFeedBottomSheet(String farmId) {
  final TankController controller = Get.find();

  final totalFeedController = TextEditingController(
    text: controller.feedStoreData.value?.totalFeedUsed.toString(),
  );
  final storeController = TextEditingController(
    text: controller.feedStoreData.value?.feedStore.toString(),
  );
  final lowFeedController = TextEditingController(
    text: controller.feedStoreData.value?.lowFeedLimit?.toString() ?? '',
  );

  Get.bottomSheet(
    SafeArea(
      // Builder, for a context below the sheet's route: the keyboard's height
      // has to be read from it. Three text fields with no allowance for the
      // keyboard meant tapping one pushed the Save button off the bottom and
      // the sheet reported an overflow instead of scrolling.
      child: Builder(
        builder: (sheetContext) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => safeBack(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Total feed used
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Total feed used",
                    style: GoogleFonts.roboto(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                feedInputField(totalFeedController, true),

                const SizedBox(height: 20),

                // Store
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Store", style: GoogleFonts.roboto(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                feedInputField(storeController, false),

                const SizedBox(height: 20),

                // Low feed limit — the threshold that triggers the alert.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Low feed limit",
                    style: GoogleFonts.roboto(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                feedInputField(lowFeedController, false),

                const SizedBox(height: 30),

                // Save Button
                Obx(() {
                  return GestureDetector(
                    onTap: () async {
                      // Don't fire a second request while one is in flight — a
                      // double tap on Save sent the update twice.
                      if (controller.isOverlay.value) return;

                      final store = storeController.text.trim();
                      final lowLimit = lowFeedController.text.trim();

                      // The server rejects a non-numeric store with a 422 the
                      // screen reports only as "Failed to update feed". Say what
                      // is actually wrong, before sending it.
                      if (store.isEmpty || double.tryParse(store) == null) {
                        CustomToast.error('Enter the store quantity in Kgs');
                        return;
                      }
                      if (lowLimit.isNotEmpty &&
                          double.tryParse(lowLimit) == null) {
                        CustomToast.error('Enter the low feed limit in Kgs');
                        return;
                      }

                      bool ok = await controller.updateFeedStore(
                        farmId: farmId,
                        totalFeedUsed: totalFeedController.text.trim(),
                        feedStore: store,
                        lowFeedLimit: lowLimit,
                      );

                      if (ok) {
                        safeBack();
                        controller.getFeedStore(farmId);
                      }
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: controller.isOverlay.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Widget feedInputField(TextEditingController controller, bool disable) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: disable,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const Text("Kgs", style: TextStyle(color: Colors.black54)),
        const SizedBox(width: 5),
        const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
      ],
    ),
  );
}
