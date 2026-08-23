import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_feed_history_response.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

// Data model for a single meal entry
class MealEntry {
  final String meal;
  final String quantity;

  /// Row id in tank_feed_histories — what the edit endpoint updates.
  final int? historyId;

  MealEntry(this.meal, this.quantity, {this.historyId});
}

// Data model for a daily feed record
class DailyFeedRecord {
  final String date;
  final bool isExpandable;
  bool isExpanded;
  final List<MealEntry> entries;
  final bool hasLink;

  DailyFeedRecord({
    required this.date,
    this.isExpandable = true,
    this.isExpanded = true,
    required this.entries,
    this.hasLink = false,
  });
}

class TankFeedScreen extends StatefulWidget {
  const TankFeedScreen({
    super.key,
    required this.tankId,
    required this.tankName,
    required this.farmName,
  });
  final String tankId;
  final String tankName;
  final String farmName;
  @override
  State<TankFeedScreen> createState() => _TankFeedScreenState();
}

class _TankFeedScreenState extends State<TankFeedScreen> {
  final TankController _tankController = Get.find<TankController>();
  // Mock data

  // Controllers for text fields per card
  final Map<int, TextEditingController> _mealControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  /// Dates the user has collapsed. Absent means expanded.
  final Map<String, bool> _collapsed = {};

  /// The entry currently loaded into each card's fields, by card index.
  /// Absent means the card is in "add" mode.
  final Map<int, MealEntry> _editing = {};

  @override
  void dispose() {
    for (var controller in _mealControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    _tankController.getTankHistory(widget.tankId);
    super.initState();
  }

  /// Load an existing entry into this card's fields for correction.
  ///
  /// No dialog: the card already has Meals and Feed Quantity inputs, so the
  /// values go straight into them and the Add button becomes Update until the
  /// change is saved.
  void _beginEdit(int index, MealEntry entry) {
    if (entry.historyId == null) return;

    setState(() {
      _editing[index] = entry;
      _mealControllers[index] ??= TextEditingController();
      _quantityControllers[index] ??= TextEditingController();
      _mealControllers[index]!.text = entry.meal;
      _quantityControllers[index]!.text = entry.quantity;
    });
  }

  /// Delete a recorded entry, after confirming.
  Future<void> _deleteEntry(int index, MealEntry entry) async {
    if (entry.historyId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete entry?',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${entry.meal} meals · ${entry.quantity} kg will be removed from '
          'this day and from the tank total.',
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

    final ok = await _tankController.deleteFeedEntry(
      historyId: entry.historyId!,
      tankId: widget.tankId,
    );

    if (ok) {
      // If the row being deleted was loaded for editing, drop that too.
      if (_editing[index]?.historyId == entry.historyId) {
        _mealControllers[index]?.clear();
        _quantityControllers[index]?.clear();
        setState(() => _editing.remove(index));
      }
      _tankController.getTankHistory(widget.tankId, silent: true);
    }
  }

  void _cancelEdit(int index) {
    setState(() {
      _editing.remove(index);
      _mealControllers[index]?.clear();
      _quantityControllers[index]?.clear();
    });
  }

  /// Save the card's fields — as a correction when a row is loaded, otherwise
  /// as a new entry for that date.
  Future<void> _submitEntry(int index, String date) async {
    final meal = _mealControllers[index]?.text.trim() ?? '';
    final quantity = _quantityControllers[index]?.text.trim() ?? '';

    if (meal.isEmpty || quantity.isEmpty) {
      CustomToast.show(message: 'Please enter meal and quantity');
      return;
    }

    final editing = _editing[index];

    final success = editing == null
        ? await _tankController.addTodayTankQuntity(
            feedQty: quantity,
            mealQty: meal,
            tankId: widget.tankId,
            date: date,
          )
        : await _tankController.updateFeedEntry(
            historyId: editing.historyId!,
            tankId: widget.tankId,
            meals: meal,
            feedQuantity: quantity,
          );

    if (success) {
      _mealControllers[index]?.clear();
      _quantityControllers[index]?.clear();
      setState(() => _editing.remove(index));
      // Silent: keep the farmer where they were, so the next day's card is
      // still under their thumb instead of 20 cards up.
      _tankController.getTankHistory(widget.tankId, silent: true);
    }
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
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.farmName,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: Obx(() {
        final tankHistory = _tankController.tankHistoryData.value;
        if (_tankController.isTankHistoryLoading.value) {
          return const TankHistoryShimmer();
        }

        // Every day from stocking to today gets a card, newest first —
        // including days with nothing recorded.
        //
        // Only dates that HAVE rows come back from the API, so a day the
        // farmer missed would simply vanish from the list and there would be
        // no way to enter it later. Building the range instead means yesterday
        // is still there to fill in tomorrow, or next week.
        final history = tankHistory?.dates ?? <TankDate>[];
        final byDate = {for (final d in history) d.date: d};

        String key(DateTime d) =>
            "${d.year.toString().padLeft(4, '0')}-"
            "${d.month.toString().padLeft(2, '0')}-"
            "${d.day.toString().padLeft(2, '0')}";

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final stocked = DateTime.tryParse(tankHistory?.stockingDate ?? '');
        var cursor = stocked == null
            ? today
            : DateTime(stocked.year, stocked.month, stocked.day);

        // Guard against a bad or far-past stocking date producing thousands of
        // cards; a year of history is already more than anyone scrolls.
        if (today.difference(cursor).inDays > 400) {
          cursor = today.subtract(const Duration(days: 400));
        }

        final dates = <TankDate>[];
        for (var d = today;
            !d.isBefore(cursor);
            d = d.subtract(const Duration(days: 1))) {
          dates.add(byDate[key(d)] ?? TankDate(date: key(d), tankDateHistory: []));
        }

        // Any recorded date outside that window (e.g. entered before the
        // stocking date was corrected) still deserves to be shown.
        for (final d in history) {
          if (!dates.any((x) => x.date == d.date)) dates.add(d);
        }

        // "Total feed Used" in the design — summed from the rows already
        // loaded, so it needs no extra request.
        final totalFeedUsed = history.fold<double>(
          0,
          (sum, d) =>
              sum +
              d.tankDateHistory.fold<double>(
                0,
                (s2, item) =>
                    s2 + (double.tryParse(item.feedQuantity.toString()) ?? 0),
              ),
        );

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 26.0, 16.0, 26.0),
                    child: Text(
                      widget.tankName,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${totalFeedUsed.toStringAsFixed(totalFeedUsed % 1 == 0 ? 0 : 2)} kgs",
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total feed Used",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: List.generate(dates.length, (index) {
                      final tankDate = dates[index];

                      if (!_mealControllers.containsKey(index)) {
                        _mealControllers[index] = TextEditingController();
                      }
                      if (!_quantityControllers.containsKey(index)) {
                        _quantityControllers[index] = TextEditingController();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DailyFeedCard(
                          isLoading:
                              _tankController.isAddingTodayTankQuntity.value,
                          record: DailyFeedRecord(
                            date: tankDate.date,
                            isExpanded: !(_collapsed[tankDate.date] ?? false),
                            entries: tankDate.tankDateHistory.map((item) {
                              return MealEntry(
                                item.meals.toString(),
                                item.feedQuantity.toString(),
                                historyId: item.id,
                              );
                            }).toList(),
                          ),
                          mealController:
                              _mealControllers[index] ??
                              TextEditingController(),
                          quantityController:
                              _quantityControllers[index] ??
                              TextEditingController(),
                          onTapHeader: () => setState(() {
                            _collapsed[tankDate.date] =
                                !(_collapsed[tankDate.date] ?? false);
                          }),
                          onAdd: () => _submitEntry(index, tankDate.date),
                          onEditEntry: (entry) => _beginEdit(index, entry),
                          isEditing: _editing.containsKey(index),
                          onCancelEdit: () => _cancelEdit(index),
                          onDeleteEntry: (entry) => _deleteEntry(index, entry),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (_tankController.isAddingTodayTankQuntity.value)
              Positioned(
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(.3)),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// --- Daily Feed Card ---
class DailyFeedCard extends StatelessWidget {
  final DailyFeedRecord record;
  final TextEditingController mealController;
  final TextEditingController quantityController;
  final VoidCallback onTapHeader;

  /// Called when the user taps an entry row to correct it.
  final void Function(MealEntry entry)? onEditEntry;

  /// True while an existing entry is loaded into the fields above.
  final bool isEditing;

  /// Abandons the correction and clears the fields.
  final VoidCallback? onCancelEdit;

  /// Called when the user asks to delete an entry row.
  final void Function(MealEntry entry)? onDeleteEntry;
  final VoidCallback onAdd;
  final bool isLoading;

  const DailyFeedCard({
    super.key,
    required this.record,
    required this.mealController,
    required this.quantityController,
    required this.onTapHeader,
    this.onEditEntry,
    this.isEditing = false,
    this.onCancelEdit,
    this.onDeleteEntry,
    required this.onAdd,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            spreadRadius: 0,
            blurRadius: 22,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: record.isExpandable ? onTapHeader : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        formatDate(record.date),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (record.hasLink)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.link,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  if (record.isExpandable)
                    Icon(
                      record.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black,
                    ),
                ],
              ),
            ),
          ),
          // Input Fields & Add Button
          // Input Fields & Add Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mealController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter Meals',
                      hintStyle: GoogleFonts.roboto(
                        color: Color(0xff908A8A),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200, // light grey fill
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none, // remove border
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(
                        color: Color(0xff908A8A),
                        fontSize: 13,
                      ),
                      hintText: 'Enter Feed Quantity',
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextButton.icon(
                    onPressed: !isLoading ? onAdd : null,
                    icon: Icon(
                      isEditing ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      isEditing ? 'Update' : 'Add',
                      style: GoogleFonts.roboto(color: Colors.white),
                    ),
                  ),
                ),
                if (isEditing && onCancelEdit != null)
                  IconButton(
                    tooltip: 'Cancel edit',
                    onPressed: onCancelEdit,
                    icon: const Icon(Icons.close, size: 20),
                  ),
              ],
            ),
          ),

          // Meal Entries
          if (record.isExpanded && record.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meals',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xff908A8A),
                        ),
                      ),
                      Text(
                        'Feed Quantity',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xff908A8A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ...record.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: [
                          // Tap a row to correct what was recorded.
                          InkWell(
                            onTap: onEditEntry == null
                                ? null
                                : () => onEditEntry!(entry),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.meal,
                                  style: GoogleFonts.roboto(
                                    color: Color(0xff908A8A),
                                    fontSize: 15,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      entry.quantity,
                                      style: GoogleFonts.roboto(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (onEditEntry != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                    if (onDeleteEntry != null) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => onDeleteEntry!(entry),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xffE4E4E4)),
                          SizedBox(height: 10),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String formatDate(String? date) {
  try {
    if (date == null || date.isEmpty) return "-";

    // Parse the input date (2025-08-09)
    DateTime parsed = DateTime.tryParse(date) ?? DateTime(0000);

    if (parsed.year == 0000) return "-";

    // Format to dd/MM/yyyy
    final String day = parsed.day.toString().padLeft(2, '0');
    final String month = parsed.month.toString().padLeft(2, '0');
    final String year = parsed.year.toString();

    return "$day/$month/$year";
  } catch (e) {
    return "-"; // safe fallback
  }
}
