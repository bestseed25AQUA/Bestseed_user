import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/help/contact_labels.dart';
import 'package:seedsuser/app/common/app_globals.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/farm_management/farmer/util/feed_report.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/feed_update_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_history_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/harvest_bottom.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/start_batch_sheet.dart';
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

  /// Whether THIS screen is showing its shimmer.
  ///
  /// Deliberately NOT `tankController.isLoading`. That controller is shared
  /// with FeedUpdateScreen and the tank history screen, which are pushed on top
  /// of this one while it stays mounted underneath — so their fetches flipped
  /// the flag under us, several times, faster than the 350ms cross-fade below.
  ///
  /// The switcher is keyed on this flag, so re-entering a state it was still
  /// animating out of put TWO children with the same key in its Stack
  /// ("Duplicate keys found"), and with both of them being the content branch,
  /// two scroll views bound to one ScrollController ("attached to more than one
  /// ScrollPosition"). Coming back from Add today's quantity crashed the screen
  /// to white on exactly that.
  ///
  /// Owned here, it only ever changes in [_load] — which holds each state for
  /// at least 700ms — so the switcher can never re-enter a state mid-animation.
  bool _showShimmer = true;

  /// Guards against a second load starting while one is running.
  bool _loading = false;

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

    // Through _load, like every other read on this screen, so the first paint
    // is driven by [_showShimmer] too. Calling the controller directly here
    // left the opening shimmer depending on the SHARED isLoading flag, which
    // another screen could clear while this one was still fetching.
    _load();

    if (_farmIdNum != null) {
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

  /// Record today's feed for every tank on this farm.
  ///
  /// NAVIGATES to [FeedUpdateScreen] rather than putting the form in a sheet
  /// here. That screen already lists every tank, remembers the meal number per
  /// tank, checks the figure against the store and enforces the same create
  /// access — a second copy of that on this screen would be a second set of
  /// rules to keep in step, and they would drift the first time one changed.
  ///
  /// Same destination as "Add today's tanks quantity" on the farm card's
  /// options sheet, so both routes land on one screen.
  Future<void> _openTodaysQuantity() async {
    // Warm the list so the screen opens with tanks rather than a spinner.
    // `silent`, or it fires its own "Tank Fetched Successfully" toast as the
    // next screen is already sliding in.
    tankController.getTankList(widget.farmId, silent: true);

    await Get.to(
      () => FeedUpdateScreen(farmId: widget.farmId, access: widget.access),
    );

    // Feed recorded there moves this screen's store and every tank total, so
    // re-read on the way back rather than leaving stale figures on screen.
    //
    // _load, not _refresh: _refresh announces the farm name, which belongs to a
    // deliberate tap on the refresh button, not to coming back from a save.
    if (mounted) await _load();
  }

  /// The button under the store card.
  ///
  /// Masked rather than hidden without create access, matching the options
  /// sheet: a manager should see that recording feed is a thing this farm does
  /// and that they were not given it, instead of a screen that simply lacks the
  /// button.
  Widget _addTodaysQuantityButton() {
    // create OR edit, matching the endpoint behind it — recording a meal and
    // correcting one are the same action to the server now.
    final allowed = widget.access.canCreate || widget.access.canEdit;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: allowed
            ? _openTodaysQuantity
            : () => CustomToast.info(
                "You don't have create access to this farm, so you can't record feed.",
              ),
        icon: Icon(allowed ? Icons.layers : Icons.lock_outline, size: 20),
        label: Text(
          "Add today's tanks quantity",
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          // Kept enabled even when denied, so the tap can explain itself —
          // a truly disabled button swallows the press and says nothing. The
          // greys below are what make it read as unavailable.
          backgroundColor: allowed ? AppColors.primary : Colors.grey.shade200,
          foregroundColor: allowed ? Colors.white : Colors.grey.shade500,
          elevation: allowed ? 1 : 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: allowed
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  /// Re-read this farm's tanks and its feed store, showing the shimmer while
  /// it happens.
  ///
  /// Same two calls initState makes. The low-feed check is deliberately left
  /// out: it opens a dialog, and having one appear on every manual refresh
  /// would fight the farmer rather than inform them.
  Future<void> _refresh() async {
    // Show the farm's full name.
    //
    // The app bar truncates it — "Sattamma Thalli - A..." — so on a farm with
    // a long name there is otherwise nowhere in this screen that says which
    // farm is open. Shown immediately rather than after the reload, so it
    // answers the tap straight away.
    final name = widget.farmName.trim();
    if (name.isNotEmpty) {
      CustomToast.info(name);
    }

    await _load();
  }

  /// Read this farm's tanks and its feed store, with the shimmer up.
  ///
  /// The one place [_showShimmer] moves, so every load — first and refresh —
  /// holds the shimmer for the same minimum spell and the cross-fade can never
  /// be re-entered mid-animation.
  ///
  /// The fetches stay `silent`: a non-silent call raises the CONTROLLER's
  /// isLoading (shared with other screens) and fires its own "Tank Fetched
  /// Successfully" toast, which landed on top of the farm-name one and cut it
  /// off.
  Future<void> _load() async {
    // A second load while one is running would flip the flag out of turn.
    if (_loading) return;
    _loading = true;

    if (mounted) setState(() => _showShimmer = true);
    final startedAt = DateTime.now();

    try {
      await tankController.getTankList(widget.farmId, silent: true);

      // Guarded exactly as initState is: a farm that reached this screen
      // without an id arrives as the literal "null", and int.parse would throw
      // straight out of the button's callback.
      final farmIdNum = _farmIdNum;
      if (farmIdNum != null) {
        await tankController.getFeedStore(farmIdNum, silent: true);
      }
    } finally {
      // Hold the shimmer for a minimum spell before revealing the data.
      //
      // Against a local server both requests come back in single-digit
      // milliseconds, so the flag went true and false inside one frame and the
      // shimmer never rendered at all — the refresh looked like nothing but a
      // toast. Waiting out the remainder gives it time to be seen and lets the
      // cross-fade actually play. On a slow connection the requests already
      // exceed this, so nothing is added to the wait.
      const minimumShimmer = Duration(milliseconds: 700);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minimumShimmer) {
        await Future.delayed(minimumShimmer - elapsed);
      }

      _loading = false;

      // finally, so a failed request cannot strand the screen in shimmer.
      if (mounted) setState(() => _showShimmer = false);
    }
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
        showDialog(
          context: context,
          builder: (_) => const ContactUsDialog(
            preferredLabel: ContactLabels.farmManagementHelp,
          ),
        );
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
          actions: [
            // The shared button, as used on the booking screens: it spins for
            // as long as the future it is given takes, so the busy state comes
            // from the work itself rather than a separate flag.
            RefreshButton(onTap: _refresh),
            // Extra breathing room at the edge, as the booking screens do
            // after the same button — its own 10px margin alone leaves it
            // sitting tight against the right of the bar.
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: Obx(() {
        // Read the observables UNCONDITIONALLY, before any branch.
        //
        // Obx subscribes to whatever it touches WHILE building, and the shimmer
        // branch below returns early. With the reads left inside that branch
        // the first build — which starts in shimmer — would subscribe to
        // nothing and GetX throws "improper use of a GetX". It was safe before
        // only because the switcher read `isLoading.value` first, and that read
        // has just been replaced by a plain field.
        final tanks = tankController.farmList.value?.data ?? <TankModel>[];
        final updatingStatus = tankController.isUpdatingTankStatus.value;

        // Cross-fade the shimmer into the tanks instead of swapping them in
        // one frame, which read as a flicker on a fast local response.
        // Keyed on the loading flag so the switcher knows the two apart.
        Widget buildBody() {
          if (_showShimmer) {
            return const TankGridShimmer();
          }

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
                        const SizedBox(height: 12),
                        _addTodaysQuantityButton(),
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
              if (updatingStatus)
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
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(_showShimmer), child: buildBody()),
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
                    // No Edit button on this side: Total Feed Used is the sum
                    // of what has been recorded, not something to type over.
                    // The 8px gap that used to reserve room for one is gone
                    // with it — it left this column bottom-padded against a
                    // button that is not there.
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
                    // The store has its own permission — /update-total-feed
                    // sits behind `farm.access:total_feed`, not plain edit.
                    //
                    // Shown either way, masked when it is not held: a manager
                    // who cannot change the store should still see that the
                    // store IS editable and that they were not given it,
                    // rather than a header with no button and no explanation.
                    InkWell(
                      onTap: access.canEditTotalFeed
                          ? () => showEditFeedBottomSheet(
                              context,
                              farmId.toString(),
                            )
                          : () => CustomToast.info(
                              "You don't have access to change this farm's feed store.",
                            ),
                      child: EditButton(enabled: access.canEditTotalFeed),
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
  const EditButton({super.key, this.enabled = true});

  /// False renders the button MASKED — faded, with a padlock in place of the
  /// pencil — instead of removing it. It sits on the coloured farm header, so
  /// the fade is done with opacity on the whole pill rather than a grey that
  /// would read as a different button.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.edit : Icons.lock_outline,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Edit',
              style: GoogleFonts.roboto(color: AppColors.primary, fontSize: 14),
            ),
          ],
        ),
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
                // A tap on the MASKED switch says why nothing happened. A
                // disabled Switch has no gesture recogniser of its own, so the
                // tap reaches this; when the switch is live the null onTap
                // leaves the gesture to the switch itself.
                GestureDetector(
                  onTap: access.canChangeTankStatus
                      ? null
                      : () => CustomToast.info(
                          "You don't have access to change this tank's status.",
                        ),
                  child: SwitchTheme(
                    data: SwitchThemeData(
                      // The disabled cases come FIRST. These resolvers only
                      // ever looked at `selected`, so a switch that could not
                      // be moved still painted full green or red — it looked
                      // exactly like a working one and simply ignored taps.
                      // Faded, it reads as present but not yours to touch,
                      // while still showing whether the tank is running.
                      thumbColor: MaterialStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        final off = states.contains(MaterialState.disabled);
                        if (states.contains(MaterialState.selected)) {
                          return off ? Colors.green.shade200 : Colors.green;
                        }
                        return off ? Colors.red.shade200 : Colors.red;
                      }),
                      trackColor: MaterialStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        final off = states.contains(MaterialState.disabled);
                        if (states.contains(MaterialState.selected)) {
                          return Colors.green.withOpacity(off ? .18 : .5);
                        }
                        return Colors.red.withOpacity(off ? .18 : .5);
                      }),
                    ),
                    child: Switch(
                      value: isActive,
                      // Null disables the switch rather than hiding it: the
                      // colour still tells a view-only partner whether the tank
                      // is running, which is the point of the card. /tank/status
                      // requires `farm.access:tank_status`.
                      onChanged: !access.canChangeTankStatus
                          ? null
                          : (value) async {
                              if (value) {
                                // Activating starts a NEW crop, not a
                                // resumption: ask when it went in, and what it
                                // has already been fed if that was before today.
                                // Without a date the tank would read as day 1
                                // with no way to record what it had already had.
                                final batch = await showStartBatchSheet(
                                  context,
                                  tankName: tank.tankName ?? 'This tank',
                                );

                                // Cancelled — leave the tank as it was.
                                if (batch == null) return;

                                await controller.updateTankStatus(
                                  status: 1,
                                  tankId: tank.id.toString(),
                                  farmId: farmId,
                                  stockingDate: batch.stockingDate,
                                  feedUsedBefore: batch.feedUsedBefore,
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
                                      onSubmit: (harvestQuantity) async {
                                        isUpdated = await controller
                                            .updateTankStatus(
                                              status: 0,
                                              tankId: tank.id.toString(),
                                              farmId: farmId,
                                              harvestQuantity: harvestQuantity,
                                            );
                                        safeBack();
                                      },
                                    ),
                                  ),
                                );

                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );

                                if (isUpdated) {
                                  String? report = await controller.getReport(
                                    tankId: tank.id.toString(),
                                  );

                                  // No link means the report was not generated —
                                  // getReport has already said so. Offering Download
                                  // and Share for a link that does not exist only
                                  // produces a second, more confusing failure.
                                  final safeContext =
                                      navigatorKey.currentContext;
                                  if (report == null ||
                                      report.isEmpty ||
                                      safeContext == null) {
                                    return;
                                  }

                                  showReportPopup(
                                    safeContext,
                                    tankName: tank.tankName ?? 'Tank',
                                    () async {
                                      downloadReport(
                                        report,
                                        tankName: tank.tankName,
                                      );
                                    },
                                    () {
                                      shareReport(
                                        report,
                                        tankName: tank.tankName,
                                      );
                                    },
                                  );
                                }
                              }
                            },
                    ),
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

void showEditFeedBottomSheet(BuildContext context, String farmId) {
  final TankController controller = Get.find();

  final totalFeedController = TextEditingController(
    text: controller.feedStoreData.value?.totalFeedUsed.toString(),
  );
  // What is in the shed NOW, matching the Remaining Stock the header shows —
  // not the figure typed when the farm was created.
  //
  // The raw store column is the total ever put in, so a farm holding 9,900 of
  // an original 10,000 opened this field on 10,000 and invited the farmer to
  // correct a number that was not wrong. They edit this when they buy more or
  // count what is left, and both of those are about stock on hand.
  final storeController = TextEditingController(
    text:
        (controller.feedStoreData.value?.remainingStore ??
                controller.feedStoreData.value?.feedStore)
            ?.toString() ??
        '',
  );
  final lowFeedController = TextEditingController(
    text: controller.feedStoreData.value?.lowFeedLimit?.toString() ?? '',
  );

  // Flutter's own sheet, not Get.bottomSheet.
  //
  // GetX lays this out through a CustomSingleChildLayout of its own, and with a
  // keyboard open it put the sheet at the TOP of the screen, clipped — the
  // fields visible but the close button above the screen edge and the Save
  // button below the fold. Every other sheet in this module already uses
  // showModalBottomSheet and none of them does that.
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Transparent, so the only thing painted is the rounded white container
    // inside; otherwise the sheet's own background shows as a slab behind it.
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => SafeArea(
      // top: false. This sheet sits at the BOTTOM of the screen, but SafeArea
      // reads the whole window's insets, so it was also padding the sheet by
      // the status bar height — a band of the sheet's own background above the
      // rounded corners, with nothing in it.
      top: false,
      // Builder, for a context below the sheet's route: the keyboard's height
      // has to be read from it. Three text fields with no allowance for the
      // keyboard meant tapping one pushed the Save button off the bottom and
      // the sheet reported an overflow instead of scrolling.
      child: Builder(
        builder: (sheetContext) => Padding(
          // OUTSIDE the white container, not inside it.
          //
          // As the container's own bottom padding, the keyboard's height became
          // part of the sheet: 600-odd pixels of white below the fields, the
          // sheet grown taller than the screen, and the close button and first
          // field pushed off the top. What the farmer saw was a mostly empty
          // white page above the keypad.
          //
          // Out here it is the GAP between the sheet and the keyboard, so the
          // white box hugs its content and sits directly on top of the keypad.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                    child: Text(
                      "Store",
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
    ),
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
        // Unit selector.
        //
        // Was a Text plus a static chevron with no handler, so tapping it did
        // nothing. Kilograms is the only unit this module has — no unit column
        // exists on feeds, farms or tanks, and every figure is kg — so the menu
        // lists one option, ticked.
        //
        // PopupMenuButton, not DropdownButton: the latter focuses its selected
        // item as the menu opens and paints a full-bleed grey slab behind it
        // that ignores the menu's rounded corners. focusColor did not clear it,
        // because the highlight is painted by the menu's internals rather than
        // that property. A popup menu draws a plain list and leaves the row
        // alone. `initialValue` is deliberately NOT set — it would reintroduce
        // the same highlight.
        PopupMenuButton<String>(
          color: Colors.white,
          elevation: 4,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
          tooltip: 'Unit',
          onSelected: (_) {},
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'Kgs',
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kgs',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Kgs',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
