import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/meal_row_state.dart';
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
    this.access = const FarmAccess.ownerFallback(),
  });
  final String tankId;
  final String tankName;
  final String farmName;

  /// Recording feed needs create access, correcting an entry needs edit, and
  /// removing one needs delete — the three endpoints behind this screen are
  /// gated on exactly those. Offering all three to everyone turned a partner's
  /// missing permission into "Failed to save tank".
  final FarmAccess access;
  @override
  State<TankFeedScreen> createState() => _TankFeedScreenState();
}

class _TankFeedScreenState extends State<TankFeedScreen> {
  // Registered here when it is not already, rather than find()-ing blind:
  // find() throws when nothing put() the controller first, which killed this
  // screen on construction rather than showing anything.
  final TankController _tankController = Get.isRegistered<TankController>()
      ? Get.find<TankController>()
      : Get.put(TankController());
  // Mock data

  /// The meal lines on each day's card, keyed by date.
  ///
  /// A day opens with one line — meal 1 — or with a line per meal already
  /// recorded, and the farmer adds more as needed. Nothing is assumed about how
  /// many: the 2/3/4 schedule generates a plausible past history for a tank
  /// stocked before the farm was registered, it does not cap what happened.
  ///
  /// Keyed by DATE rather than card position: the list is rebuilt whenever the
  /// history reloads, and an index key handed a day the text typed into a
  /// different one as soon as the range shifted at midnight.
  final Map<String, List<MealRowState>> _rows = {};

  /// Dates the user has collapsed. Absent means expanded.
  final Map<String, bool> _collapsed = {};

  /// True for the card the farmer is most likely here to fill in.
  bool _isToday(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return false;

    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  /// Shared by the scroll view and its Scrollbar, so the thumb tracks the list.
  final ScrollController _scrollController = ScrollController();

  /// What the server last said about a day's meals, so a change can be seen.
  final Map<String, String> _seededFrom = {};

  /// A fingerprint of a day's recorded meals — ids, numbers and quantities.
  String _signature(List<MealEntry> entries) {
    final parts = [
      for (final e in entries) '${e.historyId}:${e.meal}:${e.quantity}',
    ]..sort();
    return parts.join('|');
  }

  /// The lines for one day, seeded from what is already recorded on it.
  ///
  /// Re-seeded whenever the SERVER data changes, not on a manual invalidation.
  ///
  /// Clearing the cache and then awaiting the refresh looked equivalent but was
  /// not: the controller drops its busy flag in a `finally`, which rebuilds
  /// this screen while the history still holds the OLD entries. The cache was
  /// refilled from those, and the newer response then found a populated cache
  /// and left it alone — so a meal saved fine and the card kept showing the
  /// previous set until the screen was reopened. Comparing a fingerprint cannot
  /// be raced: whichever build sees the new data re-seeds from it.
  List<MealRowState> _rowsFor(String date, List<MealEntry> entries) {
    final signature = _signature(entries);

    if (_seededFrom[date] != signature || _rows[date] == null) {
      for (final r in _rows[date] ?? const <MealRowState>[]) {
        r.dispose();
      }

      final sorted = [...entries]
        ..sort(
          (a, b) => (int.tryParse(a.meal) ?? 0).compareTo(
            int.tryParse(b.meal) ?? 0,
          ),
        );

      _rows[date] = sorted.isEmpty
          // Nothing recorded on this day yet: one line, numbered 1.
          ? [MealRowState(number: '1')]
          : [
              for (final e in sorted)
                MealRowState(
                  historyId: e.historyId,
                  number: e.meal,
                  quantity: e.quantity,
                ),
            ];

      _seededFrom[date] = signature;
    }

    return _rows[date]!;
  }

  /// Add a blank line, numbered on from the highest already on the card.
  void _addRow(String date, List<MealEntry> entries) {
    final rows = _rowsFor(date, entries);

    var highest = 0;
    for (final r in rows) {
      final n = int.tryParse(r.number.text.trim()) ?? 0;
      if (n > highest) highest = n;
    }

    setState(() => rows.add(MealRowState(number: '${highest + 1}')));
  }

  /// Take an unsaved line off a card. The first line always stays.
  void _removeRow(String date, List<MealEntry> entries, int index) {
    final rows = _rowsFor(date, entries);
    if (index <= 0 || index >= rows.length || rows[index].isSaved) return;

    setState(() => rows.removeAt(index).dispose());
  }

  /// True while the app bar's refresh is in flight, so the button can show it.
  bool _refreshing = false;

  /// Re-read the tank's history from the server.
  ///
  /// Silent on purpose. The loading flag swaps the whole body for a shimmer,
  /// which throws away the scroll position — and this list runs one card per
  /// day since stocking, so a farmer refreshing near the bottom would be
  /// bounced back to the top. The spinner in the button is the feedback.
  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    await _tankController.getTankHistory(widget.tankId, silent: true);
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final rows in _rows.values) {
      for (final r in rows) {
        r.dispose();
      }
    }
    super.dispose();
  }

  @override
  void initState() {
    // The controller is shared and outlives this screen, so a spinner left up
    // by earlier work would dim a screen that has only just opened.
    _tankController.isAddingTodayTankQuntity(false);

    _tankController.getTankHistory(widget.tankId);
    super.initState();
  }

  /// Save every filled line on one day's card.
  ///
  /// A line with no record behind it is added; one whose number or quantity has
  /// changed is updated; an untouched line is skipped. Clearing a line does NOT
  /// delete the meal — that is the bin, so a stray backspace cannot erase a
  /// record.
  Future<void> _saveDay(String date, List<MealEntry> entries) async {
    if (_tankController.isAddingTodayTankQuntity.value) return;

    final rows = _rowsFor(date, entries);
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
        toUpdate.add(MapEntry(row.historyId!, MapEntry(number, quantity)));
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
      final ok = await _tankController.updateFeedEntry(
        historyId: e.key,
        tankId: widget.tankId,
        meals: e.value.key,
        feedQuantity: e.value.value,
      );
      if (ok) saved++;
    }

    for (final e in toAdd) {
      final ok = await _tankController.addTodayTankQuntity(
        feedQty: e.value,
        mealQty: e.key,
        tankId: widget.tankId,
        date: date,
      );
      if (ok) saved++;
    }

    if (!mounted || saved == 0) return;

    // No manual invalidation: _rowsFor re-seeds itself as soon as the
    // response changes this day's meals.
    //
    // Silent: keep the farmer where they were, so the next day's card is
    // still under their thumb instead of 20 cards up.
    await _tankController.getTankHistory(widget.tankId, silent: true);
  }

  /// Remove one recorded meal, after confirming.
  Future<void> _deleteRow(String date, MealRowState row) async {
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
          '${row.quantity.text.trim()} kg will be removed from this day and '
          'from the tank total.',
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
      historyId: historyId,
      tankId: widget.tankId,
    );

    if (!ok || !mounted) return;

    await _tankController.getTankHistory(widget.tankId, silent: true);
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
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshing ? null : _refresh,
              // Same 24dp footprint either way, so the icon does not jump as
              // it swaps to the spinner and back.
              icon: _refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final tankHistory = _tankController.tankHistoryData.value;
        if (_tankController.isTankHistoryLoading.value) {
          return const TankHistoryShimmer();
        }

        // Whether this tank's crop is still running. A harvested batch is
        // shown but not editable — see the banner and `canRecord` below.
        final batchActive = tankHistory?.batchActive ?? true;
        final batchNo = tankHistory?.batchNo;

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
        for (
          var d = today;
          !d.isBefore(cursor);
          d = d.subtract(const Duration(days: 1))
        ) {
          dates.add(
            byDate[key(d)] ?? TankDate(date: key(d), tankDateHistory: []),
          );
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
            // A visible thumb down the right edge: this list runs one card per
            // day since stocking, so there is otherwise no sense of its length.
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              thickness: 4,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        26.0,
                        16.0,
                        26.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.tankName,
                            style: GoogleFonts.roboto(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (batchNo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              batchActive
                                  ? 'Batch $batchNo · running'
                                  : 'Batch $batchNo · finished',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: batchActive
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // A harvested crop cannot be added to. Said once, at the
                    // top, rather than leaving the farmer to work out why every
                    // card below has no fields in it.
                    if (!batchActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This batch is finished. The records below '
                                  'are read-only, and the report is still '
                                  'available to download.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
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
                        final date = tankDate.date;

                        final entries = tankDate.tankDateHistory
                            .map(
                              (item) => MealEntry(
                                item.meals.toString(),
                                item.feedQuantity.toString(),
                                historyId: item.id,
                              ),
                            )
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DailyFeedCard(
                            isLoading:
                                _tankController.isAddingTodayTankQuntity.value,
                            record: DailyFeedRecord(
                              date: date,
                              isExpanded:
                                  !(_collapsed[date] ?? !_isToday(date)),
                              entries: entries,
                            ),
                            rows: _rowsFor(date, entries),
                            onTapHeader: () => setState(() {
                              _collapsed[date] =
                                  !(_collapsed[date] ?? !_isToday(date));
                            }),
                            onSave: () => _saveDay(date, entries),
                            // Null hides the control entirely — the card falls
                            // back to a read-only record of the day, which is
                            // exactly what view-only access means.
                            //
                            // Correcting a meal is the same box as recording
                            // one, so the boxes need create OR edit.
                            //
                            // A FINISHED batch is read-only whatever the
                            // viewer holds: the crop has been harvested, so
                            // there is nothing left to record against it. The
                            // records stay visible and the report stays
                            // downloadable.
                            canRecord:
                                batchActive &&
                                (widget.access.canCreate ||
                                    widget.access.canEdit),
                            onAddRow: batchActive && widget.access.canCreate
                                ? () => _addRow(date, entries)
                                : null,
                            onRemoveRow: (i) => _removeRow(date, entries, i),
                            onDeleteRow: widget.access.canDelete
                                ? (row) => _deleteRow(date, row)
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
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

/// One day of a tank's feed: a header that stays visible when collapsed, and —
/// when open — a line per meal, each with its number and its quantity.
///
/// A day opens with one line and the farmer adds another for each further meal
/// they gave. Both halves of a line are typed, the meal NUMBER included, so a
/// meal recorded out of order can still be called what it was.
class DailyFeedCard extends StatelessWidget {
  final DailyFeedRecord record;

  /// The meal lines, in the order they are shown.
  final List<MealRowState> rows;

  final VoidCallback onTapHeader;
  final VoidCallback onSave;

  /// False for view-only access: the card becomes a read-only record of the
  /// day, with no fields and no Save.
  final bool canRecord;

  /// Adds a blank line. Null when the viewer may not record feed.
  final VoidCallback? onAddRow;

  /// Takes an unsaved line off the card.
  final void Function(int index) onRemoveRow;

  /// Deletes a saved meal. Null when the viewer may not remove one.
  final void Function(MealRowState row)? onDeleteRow;

  final bool isLoading;

  const DailyFeedCard({
    super.key,
    required this.record,
    required this.rows,
    required this.onTapHeader,
    required this.onSave,
    required this.onRemoveRow,
    required this.isLoading,
    this.canRecord = true,
    this.onAddRow,
    this.onDeleteRow,
  });

  /// Feed recorded on this day, summed across its meals.
  String _totalQuantity(List<MealEntry> entries) {
    final total = entries.fold<double>(
      0,
      (sum, e) => sum + (double.tryParse(e.quantity) ?? 0),
    );

    // Whole numbers read better without a trailing .00.
    return total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final recorded = record.entries.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            spreadRadius: 0,
            blurRadius: 22,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: record.isExpandable ? onTapHeader : null,
            child: Padding(
              // A closed card is only this header, so it carries its own
              // bottom padding; an open one leaves it to the fields below.
              padding: EdgeInsets.fromLTRB(
                16,
                record.isExpanded ? 16 : 20,
                16,
                record.isExpanded ? 0 : 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flexible: the date, the day's total and the chevron
                  // together are wider than the card at a larger system font
                  // size, and the header overflowed rather than trimming.
                  Flexible(
                    child: Text(
                      formatDate(record.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Centred in the gap between the date and the chevron, so a
                  // collapsed card still says what happened that day.
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_totalQuantity(record.entries)} kg",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            recorded == 1 ? "1 meal" : "$recorded meals",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
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

          if (record.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: canRecord ? _editable() : _readOnly(),
            ),
        ],
      ),
    );
  }

  Widget _editable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column headings, once — the lines below are two bare fields.
        Row(
          children: [
            SizedBox(width: 78, child: _heading('Meal no.')),
            const SizedBox(width: 8),
            Expanded(child: _heading('Quantity')),
            const SizedBox(width: 34),
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
              onPressed: isLoading ? null : onAddRow,
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

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: .5),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// View-only: what was fed, with nothing to type into.
  Widget _readOnly() {
    if (record.entries.isEmpty) {
      return Text(
        'Nothing recorded on this day.',
        style: GoogleFonts.roboto(fontSize: 13, color: Colors.black45),
      );
    }

    final sorted = [...record.entries]
      ..sort(
        (a, b) =>
            (int.tryParse(a.meal) ?? 0).compareTo(int.tryParse(b.meal) ?? 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    'Meal ${e.meal}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${e.quantity} kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
              child: Icon(Icons.delete_outline, size: 22, color: Colors.red),
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
              child: Icon(Icons.close, size: 22, color: Colors.grey.shade600),
            ),
          ),
        ] else
          const SizedBox(width: 34),
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
      hintStyle: GoogleFonts.roboto(
        color: const Color(0xff908A8A),
        fontSize: 13,
      ),
      suffixText: suffix,
      suffixStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
      filled: true,
      // A saved line reads as settled; a new one as still to do.
      fillColor: recorded
          ? AppColors.primary.withValues(alpha: 0.05)
          : Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: recorded
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
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
