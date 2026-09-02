import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/meal_row_state.dart';
import 'package:seedsuser/app/farm_management/farmer/util/date_format.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

/// Record today's feed, tank by tank, one line per meal.
///
/// A card opens with a single line — meal 1 — and the farmer adds another for
/// each further meal they gave. Nothing is assumed about how many that will be:
/// the 2/3/4 schedule exists to generate a plausible past history for a tank
/// stocked before the farm was registered, not to decide what happened today.
///
/// Both halves of a line are typed: the meal NUMBER as well as the quantity, so
/// a meal recorded out of order can still be called what it was.
///
/// This screen used to show a single "Meals" count and one "Feed Quantity",
/// prefilled from `tank.feed` — the tank's most recent entry of ANY date —
/// beside a button that read "Edit" whenever the tank had ever been fed. So a
/// farmer recording a second meal overwrote the first, and a tank last fed a
/// week ago showed that week-old figure as if it were today's.
class FeedUpdateScreen extends StatefulWidget {
  const FeedUpdateScreen({
    super.key,
    required this.farmId,
    this.access = const FarmAccess.ownerFallback(),
  });

  final String farmId;

  /// Recording a meal needs create access, correcting one needs edit and
  /// removing one needs delete — the endpoints behind this screen are gated on
  /// exactly those, so the controls follow.
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

  /// The meal lines on each tank's card, keyed by tank id.
  ///
  /// Keyed by id rather than list position: keying by index handed a tank the
  /// text its neighbour was typing whenever the order changed.
  final Map<int, List<MealRowState>> _rows = {};

  @override
  void initState() {
    super.initState();
    tankController.isAddingTodayTankQuntity(false);
    tankController.getTankList(widget.farmId);
  }

  @override
  void dispose() {
    for (final rows in _rows.values) {
      for (final r in rows) {
        r.dispose();
      }
    }
    super.dispose();
  }

  /// What the server last said about a tank's meals, so a change can be seen.
  final Map<int, String> _seededFrom = {};

  /// A fingerprint of the recorded meals — ids, numbers and quantities.
  String _signature(List<TodayFeedEntry> entries) {
    final parts = [
      for (final e in entries) '${e.id}:${e.meals}:${e.feedQuantity}',
    ]..sort();
    return parts.join('|');
  }

  /// The lines for one tank, seeded from what is already recorded today.
  ///
  /// Re-seeded whenever the SERVER data changes, not on a manual invalidation.
  ///
  /// Clearing the cache and then awaiting the refresh looked equivalent but was
  /// not: the controller drops its busy flag in a `finally`, which rebuilds
  /// this screen while `farmList` still holds the OLD tanks. The cache was
  /// refilled from those, and the newer response then found a populated cache
  /// and left it alone — so a fifth meal saved fine and the card kept showing
  /// four until the screen was reopened. Comparing a fingerprint cannot be
  /// raced: whichever build sees the new data re-seeds from it.
  List<MealRowState> _rowsFor(TankModel tank) {
    final tankId = tank.id ?? 0;
    final signature = _signature(tank.todaysFeed);

    if (_seededFrom[tankId] != signature || _rows[tankId] == null) {
      for (final r in _rows[tankId] ?? const <MealRowState>[]) {
        r.dispose();
      }

      final entries = [...tank.todaysFeed]
        ..sort(
          (a, b) => (int.tryParse(a.meals) ?? 0).compareTo(
            int.tryParse(b.meals) ?? 0,
          ),
        );

      _rows[tankId] = entries.isEmpty
          // Nothing recorded yet: one line, numbered 1. Not the schedule's 2,
          // 3 or 4 — those are expectations, and an empty box for a meal that
          // has not happened is just something to scroll past.
          ? [MealRowState(number: '1')]
          : [
              for (final e in entries)
                MealRowState(
                  historyId: e.id,
                  number: e.meals,
                  quantity: e.feedQuantity,
                ),
            ];

      _seededFrom[tankId] = signature;
    }

    return _rows[tankId]!;
  }

  /// Add a blank line, numbered on from the highest already on the card.
  ///
  /// Pre-filled rather than left empty: the next meal is almost always the next
  /// number, and the field stays editable for the times it is not.
  void _addRow(TankModel tank) {
    final rows = _rowsFor(tank);

    var highest = 0;
    for (final r in rows) {
      final n = int.tryParse(r.number.text.trim()) ?? 0;
      if (n > highest) highest = n;
    }

    setState(() => rows.add(MealRowState(number: '${highest + 1}')));
  }

  /// Take a line off the card.
  ///
  /// Only a line that has not been saved — one that has is removed with the
  /// bin, which deletes the record. The first line always stays: a card with no
  /// lines has nothing to record into.
  void _removeRow(TankModel tank, int index) {
    final rows = _rowsFor(tank);
    if (index <= 0 || index >= rows.length || rows[index].isSaved) return;

    setState(() => rows.removeAt(index).dispose());
  }

  /// Save every filled line on one card.
  ///
  /// A line with no record behind it is added; one whose number or quantity has
  /// changed is updated; an untouched line is skipped. Clearing a line does NOT
  /// delete the meal — that is the bin, so a stray backspace cannot erase a
  /// record.
  Future<void> _save(TankModel tank) async {
    final tankId = tank.id;
    if (tankId == null) return;
    if (tankController.isAddingTodayTankQuntity.value) return;

    final rows = _rowsFor(tank);
    final toAdd = <MapEntry<String, String>>[];
    final toUpdate = <MapEntry<int, MapEntry<String, String>>>[];
    final seen = <int>{};

    for (final row in rows) {
      final number = row.number.text.trim();
      final quantity = row.quantity.text.trim();

      // A line the farmer left alone entirely.
      if (number.isEmpty && quantity.isEmpty) continue;

      final parsedNumber = int.tryParse(number);
      if (parsedNumber == null || parsedNumber < 1) {
        CustomToast.show(message: 'Enter a meal number, like 1 or 2');
        return;
      }

      if (quantity.isEmpty || double.tryParse(quantity) == null) {
        CustomToast.show(message: 'Enter a quantity for meal $number');
        return;
      }

      // Two lines claiming the same meal would race each other on the server
      // and leave whichever landed last.
      if (!seen.add(parsedNumber)) {
        CustomToast.show(message: 'Meal $number is listed twice');
        return;
      }

      if (row.historyId == null) {
        toAdd.add(MapEntry(number, quantity));
      } else {
        toUpdate.add(
          MapEntry(row.historyId!, MapEntry(number, quantity)),
        );
      }
    }

    if (toAdd.isEmpty && toUpdate.isEmpty) {
      CustomToast.show(message: 'Enter a quantity for at least one meal');
      return;
    }

    var saved = 0;

    // Sequential, not concurrent: each write recomputes the tank's running
    // total server-side, and firing them together made the last response win
    // with a total that had not seen the others.
    for (final e in toUpdate) {
      final ok = await tankController.updateFeedEntry(
        historyId: e.key,
        tankId: tankId.toString(),
        meals: e.value.key,
        feedQuantity: e.value.value,
      );
      if (ok) saved++;
    }

    for (final e in toAdd) {
      // farmId deliberately omitted: passing it makes the controller fire its
      // own un-awaited refresh, which would race the awaited one below.
      final ok = await tankController.addTodayTankQuntity(
        feedQty: e.value,
        mealQty: e.key,
        tankId: tankId.toString(),
      );
      if (ok) saved++;
    }

    if (!mounted || saved == 0) return;

    // No manual invalidation: _rowsFor re-seeds itself as soon as the
    // response changes the tank's meals.
    await tankController.getTankList(widget.farmId, silent: true);
  }

  /// Remove one recorded meal, after confirming.
  Future<void> _deleteRow(int tankId, MealRowState row) async {
    final historyId = row.historyId;
    if (historyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete meal ${row.number.text.trim()}?',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${row.quantity.text.trim()} kg will be removed from today and from '
          'the tank total.',
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

    // No manual invalidation: _rowsFor re-seeds itself as soon as the
    // response changes the tank's meals.
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
                      displayDate(now),
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
                          rows: _rowsFor(tank),
                          totalQuantity: tank.todaysQuantity,
                          isSaving:
                              tankController.isAddingTodayTankQuntity.value,
                          onSave: () => _save(tank),
                          // Null hides the control: the endpoints behind them
                          // require create and delete access respectively, and
                          // a button that can only come back 403 is worse than
                          // no button.
                          onAddRow: widget.access.canCreate
                              ? () => _addRow(tank)
                              : null,
                          onRemoveRow: (i) => _removeRow(tank, i),
                          onDeleteRow: widget.access.canDelete
                              ? (row) => _deleteRow(tankId, row)
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

  /// The meal lines, in the order they are shown.
  final List<MealRowState> rows;

  /// Today's total across every meal, summed server-side.
  final num totalQuantity;

  final bool isSaving;
  final VoidCallback onSave;

  /// Adds a blank line. Null when the viewer may not record feed.
  final VoidCallback? onAddRow;

  /// Takes an unsaved line off the card.
  final void Function(int index) onRemoveRow;

  /// Deletes a saved meal. Null when the viewer may not remove one.
  final void Function(MealRowState row)? onDeleteRow;

  const FeedUpdateCard({
    super.key,
    required this.tankName,
    required this.dayInfo,
    required this.rows,
    required this.totalQuantity,
    required this.isSaving,
    required this.onSave,
    required this.onRemoveRow,
    this.onAddRow,
    this.onDeleteRow,
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

            const SizedBox(height: 14),

            // Column headings, once — the lines below are two bare fields.
            Row(
              children: [
                SizedBox(width: 78, child: _heading('Meal no.')),
                const SizedBox(width: 8),
                Expanded(child: _heading('Quantity')),
                const SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 6),

            for (int i = 0; i < rows.length; i++) ...[
              _mealRow(i),
              if (i < rows.length - 1) const SizedBox(height: 10),
            ],

            if (onAddRow != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isSaving ? null : onAddRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add meal'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's total",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

            const SizedBox(height: 12),

            // One Save for the whole card — the farmer fills the meals they
            // have given and saves once, rather than once per meal.
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade700,
    ),
  );

  Widget _mealRow(int index) {
    final row = rows[index];

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: TextField(
            controller: row.number,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: _fieldDecoration(hint: '1', recorded: row.isSaved),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: row.quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              hint: '0.00',
              suffix: 'kg',
              recorded: row.isSaved,
            ),
          ),
        ),

        // A saved meal gets the bin, which deletes the record.
        if (row.isSaved && onDeleteRow != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onDeleteRow!(row),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
            ),
          ),
        ]
        // A line added here gets a ✕, which only takes the line away —
        // nothing is being deleted, because nothing has been saved. The first
        // line stays: a card with no lines has nothing to record into.
        else if (!row.isSaved && index > 0) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onRemoveRow(index),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
            ),
          ),
        ] else
          const SizedBox(width: 32),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required bool recorded,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500, fontSize: 13),
      suffixText: suffix,
      suffixStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 10.0,
      ),
      isDense: true,
      // A saved line reads as settled; a new one as still to do.
      filled: recorded,
      fillColor: AppColors.primary.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: recorded
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
    );
  }
}
