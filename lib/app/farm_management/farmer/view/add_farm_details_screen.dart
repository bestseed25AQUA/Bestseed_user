import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/request_sent_dialog.dart';
import 'package:seedsuser/app/farm_management/farmer/util/date_format.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class AddFarmerDetailsFormScreen extends StatefulWidget {
  const AddFarmerDetailsFormScreen({super.key, this.farmData});
  final FarmData? farmData;

  @override
  State<AddFarmerDetailsFormScreen> createState() =>
      _AddFarmerDetailsFormScreenState();
}

class _AddFarmerDetailsFormScreenState
    extends State<AddFarmerDetailsFormScreen> {
  final FarmListController controller = farmListController;

  final TextEditingController farmName = TextEditingController();
  final TextEditingController stockingDate = TextEditingController();
  final TextEditingController store = TextEditingController();
  final TextEditingController lowFeedLimit = TextEditingController();

  /// Farm-level prior feed. Edit only — create asks per tank instead.
  final TextEditingController feedUsedBefore = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  List<Map<String, String>> images = [];
  int? selectedTanks;

  final List<int> tankOptions = List.generate(50, (i) => i + 1);

  // ── Per-tank stocking dates and prior feed ─────────────────────────────
  //
  // Tanks are stocked as ponds are prepared, not all on one day, so each
  // carries its own date. A tank stocked in the PAST also has feed history the
  // app knows nothing about, so that tank — and only that tank — asks for the
  // total already used.
  //
  // Two parallel lists rather than a list of objects: the text controllers
  // have to outlive rebuilds, and resizing them together is the whole job.

  /// `yyyy-MM-dd` per tank. Empty until the farmer picks one.
  ///
  /// On CREATE these are the farm's tanks. On EDIT they are only the tanks
  /// being ADDED — the ones already on the farm are listed above, read-only.
  final List<TextEditingController> _tankDates = [];

  /// Feed already used, per tank. Only read when that tank's date is past.
  final List<TextEditingController> _tankFeedUsed = [];

  /// Tanks the farm already has, loaded when editing.
  ///
  /// Editable, both the date and the prior-feed figure. Changing either makes
  /// the server rewrite that tank's GENERATED history from the new values;
  /// feed the farmer recorded by hand is untouched, because only generated
  /// rows carry the backfill mark.
  List<TankModel> _existingTanks = [];
  bool _loadingTanks = false;

  /// Editable date and prior-feed per EXISTING tank, keyed by tank id.
  ///
  /// Keyed by id rather than position so a reload cannot shuffle one tank's
  /// typed figure onto another.
  final Map<int, TextEditingController> _existingDates = {};
  final Map<int, TextEditingController> _existingFeedUsed = {};

  TextEditingController _existingDateController(TankModel tank) =>
      _existingDates.putIfAbsent(tank.id ?? 0, () {
        final existing = parseDisplayDate(tank.effectiveStockingDate);
        return TextEditingController(
          text: existing == null ? '' : displayDate(existing),
        );
      });

  TextEditingController _existingFeedController(TankModel tank) =>
      _existingFeedUsed.putIfAbsent(tank.id ?? 0, () {
        final used = tank.feedUsedBefore;
        return TextEditingController(
          text: used > 0
              ? (used % 1 == 0
                    ? used.toStringAsFixed(0)
                    : used.toStringAsFixed(2))
              : '',
        );
      });

  /// True when this existing tank's date is in the past — the only case where
  /// a prior-feed figure means anything.
  bool _existingIsPast(TankModel tank) {
    final picked = parseDisplayDate(_existingDateController(tank).text);
    if (picked == null) return false;

    final now = DateTime.now();
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Pick a new stocking date for a tank the farm already has.
  /// Same field, same rule as [_pickTankDate] — a stocking date may be in the
  /// future, for a pond prepared ahead of time.
  Future<void> _pickExistingDate(TankModel tank) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = parseDisplayDate(_existingDateController(tank).text);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDate: current ?? today,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    _existingDateController(tank).text = displayDate(picked);

    // Moved to today or later: there is no past left to account for, so the
    // figure goes with it rather than being sent for a date it cannot apply to.
    if (!_existingIsPast(tank)) _existingFeedController(tank).clear();

    setState(() {});
  }

  /// Where the numbering for a newly added tank starts.
  int get _existingTankCount => _existingTanks.length;

  /// Load the farm's current tanks so the edit form can show them and number
  /// anything new from the end.
  Future<void> _loadExistingTanks(int farmId) async {
    setState(() => _loadingTanks = true);

    await controller.fetchFarmTanks(farmId);

    if (!mounted) return;
    setState(() {
      _existingTanks = controller.farmTanks;
      _loadingTanks = false;
    });
  }

  /// Append one blank tank row.
  void _addTankRow() {
    setState(() {
      _tankDates.add(TextEditingController());
      _tankFeedUsed.add(TextEditingController());
    });
  }

  /// Drop the last added row — only ever a row added in this session, never a
  /// tank the farm already has.
  void _removeTankRow(int i) {
    setState(() {
      _tankDates.removeAt(i).dispose();
      _tankFeedUsed.removeAt(i).dispose();
    });
  }

  /// Grow or shrink the per-tank rows to match the chosen tank count.
  ///
  /// Existing rows keep what has been typed into them, so changing 2 tanks to
  /// 3 does not clear the two dates already chosen.
  void _syncTankRows(int count) {
    while (_tankDates.length < count) {
      _tankDates.add(TextEditingController());
      _tankFeedUsed.add(TextEditingController());
    }

    while (_tankDates.length > count) {
      _tankDates.removeLast().dispose();
      _tankFeedUsed.removeLast().dispose();
    }
  }

  /// The date chosen for tank [i], or null when it has not been set.
  DateTime? _tankDate(int i) {
    if (i >= _tankDates.length) return null;
    return parseDisplayDate(_tankDates[i].text);
  }

  /// True when tank [i] was stocked before today, which is what makes its
  /// "already used" figure meaningful. A tank stocked today or later has no
  /// past to account for.
  bool _tankIsPast(int i) {
    final picked = _tankDate(i);
    if (picked == null) return false;

    final now = DateTime.now();
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Days from tank [i]'s stocking date to today, inclusive. 0 when not past.
  int _tankDays(int i) {
    final picked = _tankDate(i);
    if (picked == null || !_tankIsPast(i)) return 0;

    final now = DateTime.now();
    return DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(picked.year, picked.month, picked.day)).inDays +
        1;
  }

  /// Pick a stocking date for tank [i].
  ///
  /// Future dates are allowed: a pond is often set up before it is stocked.
  /// No history is generated for a date that has not arrived, and the tank
  /// reads Day 0 until it does.
  Future<void> _pickTankDate(int i) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDate: _tankDate(i) ?? today,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    _tankDates[i].text = displayDate(picked);

    // A past date reveals that tank's "already used" box; today's hides it,
    // and anything typed into it is dropped so a stale figure cannot be sent.
    if (!_tankIsPast(i)) _tankFeedUsed[i].clear();

    setState(() {});
  }

  Future<void> pickImages() async {
    // Downscale and re-encode at pick time. A straight camera-roll photo is
    // ~4 MB, which silently exceeded the server's upload_max_filesize: PHP
    // discarded the file, hasFile() came back false, and the farm was created
    // with NO image while the API still reported success. These limits keep a
    // photo well under any sane server cap and cut upload time on mobile data.
    final List<XFile>? files = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (files != null && files.isNotEmpty) {
      // Capped to match the server's `farm_image|max:20`. Without this the
      // picker let a farmer select thirty photos, upload them all, and get back
      // a bare validation error after the wait.
      const maxImages = 20;
      final room = maxImages - images.length;

      if (room <= 0) {
        CustomToast.show(message: 'You can add up to $maxImages photos');
        return;
      }

      if (files.length > room) {
        CustomToast.show(message: 'Only the first $room photos were added');
      }

      setState(() {
        for (var value in files.take(room)) {
          images.add({'local': value.path});
        }
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? pick = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pick != null) {
      stockingDate.text = displayDate(pick);
      // Refresh: a past date reveals the "feed already used" field below Store.
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.farmData != null) {
      farmName.text = widget.farmData!.farmName ?? "";
      final farmDate = parseDisplayDate(widget.farmData!.stockingDate);
      stockingDate.text = farmDate == null ? "" : displayDate(farmDate);
      // Stock in the shed NOW, not the figure typed when the farm was set up.
      // `store` itself is the total ever put in, so it stays at 10,000 while
      // the farm is down to 9,900 — see the same prefill on the feed sheet.
      store.text =
          widget.farmData!.remainingStore?.toString() ??
          widget.farmData!.store ??
          "";
      lowFeedLimit.text = widget.farmData!.lowFeedLimit ?? "";
      selectedTanks = widget.farmData!.noOfTanks;

      // Prefill with the figure the farmer entered. Farms created before that
      // figure was recorded fall back to their running total, so the box shows
      // something meaningful instead of sitting empty next to weeks of history.
      final entered =
          widget.farmData!.feedUsedBefore ??
          widget.farmData!.totalFeedUsed ??
          0;
      if (entered > 0) {
        feedUsedBefore.text = entered.toString();
      }
      if (widget.farmData!.images?.imagesList != null) {
        for (var value in widget.farmData!.images!.imagesList!) {
          images.add({'network': value});
        }
      }

      // The farm's current tanks, so the form can list them and number
      // anything added from the end. FarmData carries only a count.
      final farmId = widget.farmData!.id;
      if (farmId != null) _loadExistingTanks(farmId);
    }
  }

  @override
  void dispose() {
    // The form's controllers were never disposed. Harmless while there were
    // five of them; a farm with twenty tanks now creates forty more.
    farmName.dispose();
    stockingDate.dispose();
    store.dispose();
    lowFeedLimit.dispose();
    feedUsedBefore.dispose();

    for (final c in _tankDates) {
      c.dispose();
    }
    for (final c in _tankFeedUsed) {
      c.dispose();
    }
    for (final c in _existingDates.values) {
      c.dispose();
    }
    for (final c in _existingFeedUsed.values) {
      c.dispose();
    }

    super.dispose();
  }

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.farmData != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => safeBack(),
        ),
        title: Text(
          "Fill form",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Farm Images
                Text(
                  "Upload Farm Images",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildImageUploadArea(),
                const SizedBox(height: 24),

                // Farm Name
                _buildLabel("Farm Name"),
                const SizedBox(height: 8),
                _buildTextField(controller: farmName, hint: "Enter Farm Name"),
                const SizedBox(height: 20),

                // No. of Tanks FIRST, because everything below it is per tank.
                //
                // There is no farm-level Stocking Date on either path. Tanks
                // are stocked as ponds are prepared, so one date for the whole
                // farm made a tank stocked last week and one stocked today the
                // same age, and the history generated from it was wrong for
                // both.
                _buildLabel("No. of Tanks"),
                const SizedBox(height: 8),

                // CREATE picks a count from the dropdown. EDIT shows the count
                // it has with a + beside it: the dropdown never created a tank,
                // it only wrote a number to the farm, so raising 5 to 6 changed
                // a label and nothing else.
                if (isEdit) _buildTankCountWithAdd() else _buildTanksDropdown(),
                const SizedBox(height: 16),

                // Every tank, in one list and one style: the ones the farm
                // already has first — shown exactly like the others but not
                // editable — then any being added, numbered on from them.
                if (isEdit) ..._buildExistingTanks(),
                ..._buildTankRows(startNumber: isEdit ? _existingTankCount : 0),

                if (isEdit) const SizedBox(height: 4),

                // Store
                _buildLabel("Store"),
                const SizedBox(height: 8),
                // Optional: a farm can be set up before any feed has been
                // delivered, so there is no stock figure to give yet. Left
                // blank the server stores NULL, and it can be filled in later
                // from the farm's feed-store card.
                _buildTextField(
                  controller: store,
                  hint: "Enter Store",
                  keyboardType: TextInputType.number,
                  isRequired: false,
                ),
                const SizedBox(height: 20),

                // Low Feed Limit with info tooltip
                Row(
                  children: [
                    _buildLabel("Low feed Limit"),
                    const SizedBox(width: 6),
                    Tooltip(
                      message:
                          "Once the feed limit is reached, all farm\npartners and managers will get a notification",
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: lowFeedLimit,
                  hint: "Enter Low Feed Limit",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 36),

                // Save Button
                Obx(() {
                  return CustomButton(
                    text: isEdit ? "Update" : "Save",
                    isLoading: controller.isOverlay.value,
                    borderRadius: 12,
                    onPressed: () async {
                      // Put the keyboard away before anything else.
                      //
                      // It used to stay up through the whole save and close
                      // itself only once the farm list had replaced this
                      // screen, so the list was laid out at the shorter
                      // keyboard height for a frame and then jumped — which is
                      // where the empty state's overflow came from.
                      FocusScope.of(context).unfocus();

                      if (!_formKey.currentState!.validate()) return;

                      if (images.isEmpty) {
                        CustomToast.show(
                          message: "Please upload at least 1 image",
                        );
                        return;
                      }

                      if (!isEdit && selectedTanks == null) {
                        CustomToast.show(
                          message: "Please select number of tanks",
                        );
                        return;
                      }

                      // Every tank being added needs a stocking date, and one
                      // stocked in the past needs its prior feed — that figure
                      // is what builds its history, and a blank one leaves the
                      // tank reading "0 kgs" for weeks it was actually fed.
                      //
                      // Checked here rather than with the field validators
                      // because the rule spans two fields per row, and the
                      // message has to name which tank is at fault.
                      //
                      // Runs on BOTH paths: create sizes the rows from the
                      // dropdown, edit grows them a tap at a time, but a row is
                      // a row and an added tank needs the same answers.
                      final startNumber = isEdit ? _existingTankCount : 0;
                      final rowCount = isEdit
                          ? _tankDates.length
                          : (selectedTanks ?? 0);

                      for (int i = 0; i < rowCount; i++) {
                        final label = 'Tank ${startNumber + i + 1}';

                        if (_tankDate(i) == null) {
                          CustomToast.show(
                            message: "Select the stocking date for $label",
                          );
                          return;
                        }

                        if (!_tankIsPast(i)) continue;

                        final used = _tankFeedUsed[i].text.trim();
                        if (used.isEmpty) {
                          CustomToast.show(
                            message: "Enter the feed already used for $label",
                          );
                          return;
                        }

                        final parsed = double.tryParse(used);
                        if (parsed == null || parsed < 0) {
                          CustomToast.show(
                            message: "Feed used for $label must be a number",
                          );
                          return;
                        }
                      }

                      bool success = false;

                      if (isEdit) {
                        // `id!` threw here for a farm the API returned without
                        // one, losing everything the form had been filled with.
                        final farmId = widget.farmData?.id;
                        if (farmId == null) {
                          CustomToast.error('This farm is missing its id');
                          return;
                        }

                        // Tanks being ADDED. The server appends them after the
                        // existing ones.
                        final newTanksMeta = [
                          for (int i = 0; i < _tankDates.length; i++)
                            {
                              'stocking_date': isoDate(_tankDates[i].text),
                              'feed_used_before': _tankIsPast(i)
                                  ? _tankFeedUsed[i].text.trim()
                                  : '0',
                            },
                        ];

                        // Corrections to the tanks the farm already has. Sent
                        // for all of them; the server compares against what it
                        // holds and only rewrites the ones that changed.
                        final existingTanksMeta = [
                          for (final tank in _existingTanks)
                            if (tank.id != null)
                              {
                                'id': tank.id.toString(),
                                'stocking_date': isoDate(
                                  _existingDateController(tank).text,
                                ),
                                'feed_used_before': _existingIsPast(tank)
                                    ? _existingFeedController(tank).text.trim()
                                    : '0',
                              },
                        ];

                        success = await controller.updateFarmData(
                          farmId: farmId,
                          farmName: farmName.text,
                          // ISO, not what the field holds: it shows
                          // dd-MM-yyyy, so posting it raw would hand the API
                          // "02-09-2026" for a column that reads yyyy-MM-dd.
                          stockingDate: isoDate(stockingDate.text),
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          // What the farm will have once the additions land.
                          tanks: (_existingTankCount + _tankDates.length)
                              .toString(),
                          newTanksMeta: newTanksMeta,
                          existingTanksMeta: existingTanksMeta,
                          imagePaths: images
                              .where((item) => item.containsKey('local'))
                              .map((item) => item['local'].toString())
                              .toList(),
                        );
                      } else {
                        // Per-tank dates and prior feed, as JSON. A multipart
                        // form cannot carry nested arrays cleanly, so the
                        // server decodes this one field — see tanksMetaFrom().
                        final tanksMeta = [
                          for (int i = 0; i < (selectedTanks ?? 0); i++)
                            {
                              'stocking_date': isoDate(_tankDates[i].text),
                              // Only for a tank stocked in the past; a tank
                              // stocked today has nothing to account for.
                              'feed_used_before': _tankIsPast(i)
                                  ? _tankFeedUsed[i].text.trim()
                                  : '0',
                            },
                        ];

                        success = await controller.uploadFarmData(
                          farmName: farmName.text,
                          // The earliest tank date, so the farm's own date
                          // stays meaningful for older screens. The server
                          // derives the same thing; this is belt and braces.
                          stockingDate: _earliestTankDate(),
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: selectedTanks.toString(),
                          tanksMeta: tanksMeta,
                          imagePaths: images
                              .where((item) => item.containsKey('local'))
                              .map((item) => item['local'].toString())
                              .toList(),
                        );
                      }
                      if (success) {
                        // Only a newly submitted farm is a "request"; an edit
                        // just saves, so it skips the confirmation popup.
                        if (!isEdit && context.mounted) {
                          await showRequestSentDialog(context);
                        }

                        // Refresh BEFORE popping. Popping first left the
                        // previous screen rebuilding against a stale, empty
                        // list, so a farm that had just been created still
                        // showed the "no farms yet" screen.
                        await farmListController.fetchFarmList();
                        safeBack();
                      }
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Image Upload Area ───
  Widget _buildImageUploadArea() {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: pickImages,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Upload Images",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "PNG, JPEG",
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CarouselSlider.builder(
            itemCount: images.length + 1,
            options: CarouselOptions(
              height: 180,
              enlargeCenterPage: true,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              if (index == images.length) {
                return GestureDetector(
                  onTap: pickImages,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add More",
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var map = images[index];
              bool isLocal = map.containsKey('local');
              bool isNetwork = map.containsKey('network');

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isLocal
                        ? Image.file(
                            File(map['local'].toString()),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(height: 180);
                            },
                          )
                        : isNetwork
                        ? CustomNetworkImage(
                            // Stored urls may still name an old deployment host.
                            imageUrl: resolveMediaUrl(map['network']),
                            width: double.infinity,
                            height: 180,
                            // Without a fit the image drew at its natural size
                            // and sat letterboxed inside the grey box, unlike
                            // the locally picked images beside it.
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                  ),
                  // Delete Button
                  if (isLocal)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            images.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Image Counter
                  if (images.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${currentIndex + 1}/${images.length}",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Label Widget ───
  /// The earliest date across the tanks — the day the farm started operating.
  ///
  /// Sent as the farm's own `stocking_date` so reports and the admin panel,
  /// which still read one date per farm, keep working.
  String _earliestTankDate() {
    // Converted to ISO before sorting, twice over: the field holds dd-MM-yyyy,
    // which sorts by DAY — "02-09-2026" would come out ahead of "16-08-2026" —
    // and the farm's date has to leave here in the form the server reads.
    final dates = [
      for (int i = 0; i < (selectedTanks ?? 0); i++)
        if (isoDate(_tankDates[i].text).isNotEmpty) isoDate(_tankDates[i].text),
    ]..sort();

    return dates.isEmpty ? '' : dates.first;
  }

  /// The tanks the farm already has, read-only.
  ///
  /// Listed so the farmer can see what is there before adding to it, and so
  /// the numbering of anything new is obvious. Not editable: a tank's stocking
  /// date is what its generated history was built from, and removing a tank
  /// would take every feed row recorded against it.
  List<Widget> _buildExistingTanks() {
    if (_loadingTanks) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_existingTanks.isEmpty) return const [];

    // The same editable block a tank being added gets, so the whole list reads
    // as one set of tanks. Changing a date or a figure here makes the server
    // rewrite that tank's generated history from the new values.
    return [
      for (final tank in _existingTanks)
        Builder(
          builder: (context) {
            final isPast = _existingIsPast(tank);
            final days = _existingDays(tank);

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tank.tankName ?? 'Tank',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$days days',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Same fixed split as an added tank, so the date field does
                  // not change width as the feed box comes and goes.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel("Stocking date"),
                            const SizedBox(height: 4),
                            _buildTextField(
                              controller: _existingDateController(tank),
                              hint: "Select date",
                              readOnly: true,
                              dense: true,
                              onTap: () => _pickExistingDate(tank),
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey.shade500,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPast)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Feed used"),
                              const SizedBox(height: 4),
                              _buildTextField(
                                controller: _existingFeedController(tank),
                                hint: "kg",
                                keyboardType: TextInputType.number,
                                dense: true,
                                isRequired: false,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(flex: 4),
                    ],
                  ),

                  if (isPast)
                    Builder(
                      builder: (context) {
                        final total =
                            double.tryParse(
                              _existingFeedController(tank).text.trim(),
                            ) ??
                            0;

                        if (total <= 0 || days <= 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "${(total / days).toStringAsFixed(2)} kg/day "
                            "across $days days",
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
    ];
  }

  /// Days from an existing tank's chosen date to today, inclusive.
  int _existingDays(TankModel tank) {
    final picked = parseDisplayDate(_existingDateController(tank).text);
    if (picked == null || !_existingIsPast(tank)) return 0;

    final now = DateTime.now();
    return DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(picked.year, picked.month, picked.day)).inDays +
        1;
  }

  /// The tank count on EDIT: what the farm has, with a + to add one.
  ///
  /// Deliberately not a dropdown. The count is not something a farmer picks
  /// when editing — it is the number of tanks that exist, and it changes by
  /// adding one, which is what the + does. A dropdown here also implied the
  /// count could be lowered, which would mean deleting a tank and every feed
  /// row recorded against it.
  Widget _buildTankCountWithAdd() {
    final total = _existingTankCount + _tankDates.length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _loadingTanks ? 'Loading…' : '$total',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Square, matching the field's height, so the row reads as one control.
        InkWell(
          onTap: _addTankRow,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  /// A block per tank being added: stocking date, then the prior-feed box when
  /// that date is in the past.
  ///
  /// [startNumber] is how many tanks the farm already has, so an added tank is
  /// labelled Tank 6 on a farm with five rather than Tank 1.
  ///
  /// On create, returns nothing until a tank count is chosen — there is
  /// nothing to ask about yet, and an empty framed section reads as a fault.
  List<Widget> _buildTankRows({int startNumber = 0}) {
    final isEdit = widget.farmData != null;

    // Which mode we are in is decided by `farmData`, NOT by whether the
    // existing tanks have arrived.
    //
    // This used to fall back to the create branch whenever `_existingTanks`
    // was empty — which it is for the first moment of every edit, while the
    // tanks are still loading. `selectedTanks` was already prefilled with the
    // farm's count, so _syncTankRows() built that many blank rows, and once
    // the real tanks landed they were relabelled Tank 4, Tank 5, Tank 6 and
    // sat there empty. Editing adds nothing until the farmer taps +.
    final count = isEdit ? _tankDates.length : (selectedTanks ?? 0);

    if (count <= 0) return const [];

    if (!isEdit) _syncTankRows(count);

    return [
      for (int i = 0; i < count; i++) ...[
        // Compact on purpose. Each tank was a padded card with its own
        // headings and a paragraph of explanation under the feed box; five
        // tanks ran to several screens of mostly whitespace. The tank number
        // sits on the same line as the date, and the day count is a chip
        // beside it rather than a sentence below.
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    // Numbered on from the tanks the farm already has, so a
                    // farm with five gains "Tank 6" — the same name the
                    // server gives it.
                    'Tank ${startNumber + i + 1}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  if (_tankIsPast(i)) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_tankDays(i)} days',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Only a row added in this session can be taken back off —
                  // never a tank the farm already has.
                  if (isEdit)
                    InkWell(
                      onTap: () => _removeTankRow(i),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Side by side rather than one full-width field above another:
              // a date and a quantity are both short values, and stacking them
              // made each stretch the whole card for no reason.
              //
              // The date keeps the SAME width either way — the space the feed
              // box will occupy is held empty until a past date is picked, so
              // the field does not stretch across the card and then snap back
              // to half of it the moment a date is chosen.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // The date needs the greater share — it carries a calendar
                    // icon as well as the value.
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Stocking date"),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _tankDates[i],
                          hint: "Select date",
                          readOnly: true,
                          dense: true,
                          onTap: () => _pickTankDate(i),
                          suffixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade500,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Only for a tank stocked in the PAST. A tank stocked today
                  // has no history to account for, so asking would invite a
                  // figure that means nothing.
                  if (_tankIsPast(i))
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Feed used"),
                          const SizedBox(height: 4),
                          _buildTextField(
                            controller: _tankFeedUsed[i],
                            hint: "kg",
                            keyboardType: TextInputType.number,
                            dense: true,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(flex: 4),
                ],
              ),

              // What the figure works out to once it is spread across the
              // days and meals since stocking — the farmer's check that they
              // have typed a sensible number.
              if (_tankIsPast(i))
                Builder(
                  builder: (context) {
                    final days = _tankDays(i);
                    final total =
                        double.tryParse(_tankFeedUsed[i].text.trim()) ?? 0;

                    if (total <= 0 || days <= 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${(total / days).toStringAsFixed(2)} kg/day "
                        "across $days days",
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    ];
  }

  /// Small label above a field inside a tank block.
  ///
  /// Lighter than [_buildLabel]: these sit two to a row inside an already
  /// framed block, so the form's usual heading weight would compete with the
  /// tank name above them.
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // ─── Text Field Widget ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    bool isRequired = true,

    /// Tighter padding, for the per-tank rows where several fields stack up
    /// and the form's usual roominess turns into a lot of scrolling.
    bool dense = false,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      validator: (value) {
        // Every field here is mandatory except where a screen says otherwise.
        if (!isRequired) return null;

        if (value == null || value.trim().isEmpty) {
          return "$hint is required";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          fontSize: dense ? 13 : 14,
          color: Colors.grey.shade400,
        ),
        suffixIcon: suffixIcon,
        suffixIconConstraints: dense
            ? const BoxConstraints(minWidth: 38, minHeight: 32)
            : null,
        isDense: dense,
        filled: true,
        fillColor: dense ? Colors.white : Colors.grey.shade50,
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // ─── Tanks Dropdown Widget ───
  Widget _buildTanksDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTanks,
      hint: Text(
        "Select No. of Tanks",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade400),
      ),
      style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      items: tankOptions.map((int value) {
        return DropdownMenuItem<int>(value: value, child: Text("$value"));
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedTanks = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return "Please select number of tanks";
        }
        return null;
      },
    );
  }
}
