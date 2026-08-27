import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

/// Record today's feed, tank by tank.
///
/// A day is a LIST of meals, not one figure. This screen used to show a single
/// Meals / Feed Quantity pair per tank, prefilled from `tank.feed` — the tank's
/// most recent entry of ANY date — beside a button that read "Edit" whenever
/// the tank had ever been fed. So a farmer recording a second meal overwrote
/// the first, and a tank last fed a week ago showed that week-old figure as if
/// it were today's.
///
/// Now each card lists everything recorded today and Save ADDS another entry,
/// which is what the tank history screen has always done.
class FeedUpdateScreen extends StatefulWidget {
  const FeedUpdateScreen({
    super.key,
    required this.farmId,
    this.access = const FarmAccess.ownerFallback(),
  });
  final String farmId;

  /// Recording a meal needs create access, correcting one needs edit and
  /// removing one needs delete — the three endpoints behind this screen are
  /// gated on exactly those, so the controls follow.
  final FarmAccess access;

  @override
  State<FeedUpdateScreen> createState() => _FeedUpdateScreenState();
}

class _FeedUpdateScreenState extends State<FeedUpdateScreen> {
  // find() throws if nothing registered the controller first. That holds today
  // only because the farm list screen happens to put() it; reached any other
  // way this screen died on construction.
  final TankController tankController = Get.isRegistered<TankController>()
      ? Get.find<TankController>()
      : Get.put(TankController());

  /// One pair of inputs per tank, keyed by tank id so they survive the refresh
  /// after a save — keying by list index would hand a tank the box its
  /// neighbour was typing into if the order ever changed.
  final Map<int, TextEditingController> _mealControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  /// The entry loaded into each tank's fields for correction, by tank id.
  /// Absent means that card is in "add another meal" mode.
  final Map<int, TodayFeedEntry> _editing = {};

  @override
  void initState() {
    super.initState();
    tankController.isAddingTodayTankQuntity(false);
    tankController.getTankList(widget.farmId);
  }

  @override
  void dispose() {
    for (final c in _mealControllers.values) {
      c.dispose();
    }
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _mealController(int tankId) =>
      _mealControllers.putIfAbsent(tankId, () => TextEditingController());

  TextEditingController _quantityController(int tankId) =>
      _quantityControllers.putIfAbsent(tankId, () => TextEditingController());

  /// Load an existing entry into this tank's fields for correction.
  ///
  /// No dialog: the card already has Meals and Feed Quantity boxes, so the
  /// values go straight into them and Save becomes Update until it is saved or
  /// the correction is abandoned.
  void _beginEdit(int tankId, TodayFeedEntry entry) {
    if (entry.id == null) return;

    setState(() {
      _editing[tankId] = entry;
      _mealController(tankId).text = entry.meals;
      _quantityController(tankId).text = entry.feedQuantity;
    });
  }

  void _cancelEdit(int tankId) {
    setState(() {
      _editing.remove(tankId);
      _mealController(tankId).clear();
      _quantityController(tankId).clear();
    });
  }

  /// Remove a recorded entry, after confirming.
  Future<void> _deleteEntry(int tankId, TodayFeedEntry entry) async {
    final historyId = entry.id;
    if (historyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete entry?',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${entry.meals} meals · ${entry.feedQuantity} kg will be removed '
          "from today and from the tank total.",
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await tankController.deleteFeedEntry(
      historyId: historyId,
      tankId: tankId.toString(),
    );

    if (!ok || !mounted) return;

    // If the row just deleted was the one loaded for correction, drop that too
    // — otherwise Update would post against a row that no longer exists.
    if (_editing[tankId]?.id == historyId) _cancelEdit(tankId);

    await tankController.getTankList(widget.farmId, silent: true);
  }

  /// Save the card's fields — as a correction when an entry is loaded,
  /// otherwise as another meal for today.
  Future<void> _save(TankModel tank) async {
    final tankId = tank.id;
    if (tankId == null) return;

    final meals = _mealController(tankId).text.trim();
    final quantity = _quantityController(tankId).text.trim();

    if (meals.isEmpty || quantity.isEmpty) {
      CustomToast.show(message: 'Enter meals and feed quantity');
      return;
    }

    if (double.tryParse(meals) == null || double.tryParse(quantity) == null) {
      CustomToast.show(message: 'Meals and quantity must be numbers');
      return;
    }

    if (tankController.isAddingTodayTankQuntity.value) return;

    final editing = _editing[tankId];

    final bool ok;
    if (editing?.id != null) {
      // Correcting: the endpoint keeps `feeds` and `tank_feed_histories` in
      // step and recomputes the tank's total, so this cannot be a local edit.
      ok = await tankController.updateFeedEntry(
        historyId: editing!.id!,
        tankId: tankId.toString(),
        meals: meals,
        feedQuantity: quantity,
      );
    } else {
      // Adding: no feed id, so the API creates a new row rather than replacing
      // one — the same call the tank history screen makes to add a meal.
      //
      // farmId deliberately omitted: passing it makes the controller fire its
      // own un-awaited refresh, which would race the awaited one below and
      // could land the older response last.
      ok = await tankController.addTodayTankQuntity(
        feedQty: quantity,
        mealQty: meals,
        tankId: tankId.toString(),
      );
    }

    if (!ok || !mounted) return;

    // Clear the boxes so the next meal starts from empty, and re-read so the
    // entry just saved joins the list above it.
    _cancelEdit(tankId);
    await tankController.getTankList(widget.farmId, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adding feed'),
      ),
      body: Obx(() {
        if (tankController.isLoading.value) {
          return const TankGridShimmer();
        }

        final tanks = tankController.farmList.value?.data ?? [];

        if (tanks.isEmpty) {
          return const Center(child: Text("No Tank Found"));
        }

        final now = DateTime.now();

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Today's feed Update",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Center(
                    child: Text(
                      "${now.day}/${now.month}/${now.year}",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  ListView.builder(
                    itemCount: tanks.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final tank = tanks[index];
                      final tankId = tank.id ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FeedUpdateCard(
                          tankName: tank.tankName ?? "",
                          dayInfo: "${tank.day ?? 0} Day",
                          entries: tank.todaysFeed,
                          totalMeals: tank.todaysMeals,
                          totalQuantity: tank.todaysQuantity,
                          mealController: _mealController(tankId),
                          quantityController: _quantityController(tankId),
                          isSaving:
                              tankController.isAddingTodayTankQuntity.value,
                          onSave: () => _save(tank),
                          isEditing: _editing.containsKey(tankId),
                          onCancelEdit: () => _cancelEdit(tankId),
                          // Null hides the control: the endpoints behind them
                          // require edit and delete access respectively, and a
                          // button that can only ever come back 403 is worse
                          // than no button.
                          onEditEntry: widget.access.canEdit
                              ? (entry) => _beginEdit(tankId, entry)
                              : null,
                          onDeleteEntry: widget.access.canDelete
                              ? (entry) => _deleteEntry(tankId, entry)
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (tankController.isAddingTodayTankQuntity.value)
              Positioned.fill(
                child: Container(
                  color: Colors.grey.withValues(alpha: .3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class FeedUpdateCard extends StatelessWidget {
  final String tankName;
  final String dayInfo;

  /// Everything already recorded for this tank today.
  final List<TodayFeedEntry> entries;
  final num totalMeals;
  final num totalQuantity;

  final TextEditingController mealController;
  final TextEditingController quantityController;
  final bool isSaving;
  final VoidCallback onSave;

  /// True while one of today's entries is loaded into the fields above.
  final bool isEditing;

  /// Abandons the correction and clears the fields.
  final VoidCallback? onCancelEdit;

  /// Null when the viewer may not correct entries.
  final void Function(TodayFeedEntry entry)? onEditEntry;

  /// Null when the viewer may not remove entries.
  final void Function(TodayFeedEntry entry)? onDeleteEntry;

  const FeedUpdateCard({
    super.key,
    required this.tankName,
    required this.dayInfo,
    required this.entries,
    required this.totalMeals,
    required this.totalQuantity,
    required this.mealController,
    required this.quantityController,
    required this.isSaving,
    required this.onSave,
    this.isEditing = false,
    this.onCancelEdit,
    this.onEditEntry,
    this.onDeleteEntry,
  });

  /// Whole numbers read better without a trailing ".00".
  static String _fmt(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Tank Name and Day Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Expanded: a long tank name and the day count together were
                // wider than the card and the row overflowed.
                Expanded(
                  child: Text(
                    tankName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dayInfo,
                  style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── What has already gone in today ──
            _todaysEntries(),

            const SizedBox(height: 16),

            Text(
              'Meals',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4.0),
            TextField(
              controller: mealController,
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration('0'),
            ),

            const SizedBox(height: 16.0),

            Text(
              'Feed Quantity',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _fieldDecoration('0.00'),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Fixed unit rather than a dropdown.
                //
                // The dropdown offered Kgs / Grams / Lbs but its onChanged did
                // nothing and the unit was never sent, so picking Grams saved
                // the number as kilos. Every figure in this app is kilos.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Kgs',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // ── Save / Update ──
            //
            // "Save" ADDS another meal; it only reads "Update" while one of
            // today's entries is actually loaded for correction. The old button
            // read "Edit" whenever the tank had ever been fed — including on a
            // day nothing had been recorded — and saving replaced the earlier
            // entry instead of adding to it.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEditing && onCancelEdit != null)
                  TextButton(
                    onPressed: isSaving ? null : onCancelEdit,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(color: Colors.black54),
                    ),
                  ),
                if (isEditing) const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: Icon(isEditing ? Icons.check : Icons.add, size: 18),
                  label: Text(isEditing ? 'Update' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: .5,
                    ),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
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

  Widget _todaysEntries() {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No feed recorded today yet',
          style: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's meals",
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // Numbered, so "the third meal" on screen matches what the farmer
          // actually gave third.
          ...entries.asMap().entries.map((e) {
            final index = e.key + 1;
            final entry = e.value;

            // An entry with no history id cannot be addressed by the edit or
            // delete endpoints, so it is shown but not offered as editable.
            final canTouch = entry.id != null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$index.',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.meals} meals',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.feedQuantity} kg',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  if (canTouch && onEditEntry != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => onEditEntry!(entry),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],

                  if (canTouch && onDeleteEntry != null) ...[
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => onDeleteEntry!(entry),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const Divider(height: 16),

          Row(
            children: [
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  'Total  ${_fmt(totalMeals)} meals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_fmt(totalQuantity)} kg',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 10.0,
      ),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
    );
  }
}
