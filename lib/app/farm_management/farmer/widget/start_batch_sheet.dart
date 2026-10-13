import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/util/date_format.dart';

/// What a farmer answers when starting a fresh crop in a tank.
class StartBatchResult {
  /// `yyyy-MM-dd`.
  final String stockingDate;

  /// Feed already given on this crop, when it went in before today.
  /// Empty when the tank was stocked today.
  final String feedUsedBefore;

  const StartBatchResult({
    required this.stockingDate,
    required this.feedUsedBefore,
  });
}

/// Asks for the new batch's stocking date, and its prior feed when that date
/// is in the past.
///
/// Re-activating a tank starts a NEW crop, not a resumption of the old one, so
/// it needs a date to count days from. Defaulting silently to today would make
/// a pond stocked three days ago read as day 1 and give it no way to record
/// what it has already been fed — the same reason a tank being added asks.
/// [earliestStockingDate] is the first day this farm's cover allows, as
/// `yyyy-MM-dd`, or null when there is no limit.
///
/// A farm on the free plan has none — a farmer's first farms are usually
/// catching the app up on ponds stocked weeks ago. A PAID farm cannot be
/// backdated before the term covering it, so the picker is bounded rather than
/// letting the farmer choose a day the server will then refuse.
Future<StartBatchResult?> showStartBatchSheet(
  BuildContext context, {
  required String tankName,
  String? earliestStockingDate,
}) {
  return showModalBottomSheet<StartBatchResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _StartBatchSheet(
      tankName: tankName,
      earliestStockingDate: earliestStockingDate,
    ),
  );
}

class _StartBatchSheet extends StatefulWidget {
  final String tankName;
  final String? earliestStockingDate;

  const _StartBatchSheet({required this.tankName, this.earliestStockingDate});

  @override
  State<_StartBatchSheet> createState() => _StartBatchSheetState();
}

class _StartBatchSheetState extends State<_StartBatchSheet> {
  final TextEditingController _date = TextEditingController();
  final TextEditingController _feedUsed = TextEditingController();

  @override
  void dispose() {
    _date.dispose();
    _feedUsed.dispose();
    super.dispose();
  }

  /// The field holds the DISPLAY form, so it is parsed rather than read raw.
  DateTime? get _picked => parseDisplayDate(_date.text);

  /// True when the crop went in before today — the only case where a figure
  /// for feed already given means anything.
  bool get _isPast {
    final picked = _picked;
    if (picked == null) return false;

    final now = DateTime.now();
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Days from the chosen date to today, inclusive.
  int get _days {
    final picked = _picked;
    if (picked == null || !_isPast) return 0;

    final now = DateTime.now();
    return DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(picked.year, picked.month, picked.day)).inDays +
        1;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // The first day this farm's cover allows. Falls back to 2000 when the
    // farm is free or the server said nothing — an unbounded picker is the
    // old behaviour, and the server is the backstop either way.
    final floor = widget.earliestStockingDate == null
        ? DateTime(2000)
        : (DateTime.tryParse(widget.earliestStockingDate!) ?? DateTime(2000));

    // A floor later than today would leave the picker with no selectable day
    // at all and throw. That happens when cover starts in the future, and
    // today is the only sensible answer.
    final firstDate = floor.isAfter(today) ? today : floor;

    final initial = (_picked ?? today).isBefore(firstDate) ? firstDate : (_picked ?? today);

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      // Capped at today: a crop cannot already have been stocked on a date
      // that has not arrived, and the server rejects one.
      lastDate: today,
      initialDate: initial.isAfter(today) ? today : initial,
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

    // Shown as dd-MM-yyyy; converted back to ISO in [_submit].
    _date.text = displayDate(picked);

    // Moved to today: there is no past left to account for.
    if (!_isPast) _feedUsed.clear();

    setState(() {});
  }

  void _submit() {
    if (_picked == null) {
      CustomToast.show(message: 'Select the stocking date');
      return;
    }

    final used = _feedUsed.text.trim();

    if (_isPast) {
      if (used.isEmpty) {
        CustomToast.show(message: 'Enter the feed already used');
        return;
      }

      final parsed = double.tryParse(used);
      if (parsed == null || parsed < 0) {
        CustomToast.show(message: 'Feed used must be a number');
        return;
      }
    }

    Navigator.pop(
      context,
      StartBatchResult(
        // ISO, not what the field shows: the API reads yyyy-MM-dd, and
        // "02-09-2026" would be rejected or read as a different day.
        stockingDate: isoDate(_date.text),
        feedUsedBefore: _isPast ? used : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Builder(
        // A context below the sheet's route, so the keyboard's height can be
        // read from it — three fields with no allowance for the keyboard push
        // the button off the bottom.
        builder: (sheetContext) => Padding(
          // OUTSIDE the white container: the gap between the sheet and the
          // keyboard, not part of the sheet. Applied as the container's own
          // padding it became 600-odd pixels of white below the fields, with
          // the sheet grown past the top of the screen.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Activate tank',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Says what to do, not what the system does behind it. This
                  // used to explain that the tank "starts again from zero" and
                  // that "its previous batch stays available to download" —
                  // bookkeeping the farmer has not asked about, in words they
                  // do not use.
                  Text(
                    'When was ${widget.tankName} stocked?',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _label('Stocking date'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _date,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: _decoration(
                      hint: 'Select date',
                      suffixIcon: Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                  if (_isPast) ...[
                    const SizedBox(height: 14),
                    _label('Feed already used'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _feedUsed,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: _decoration(hint: 'kg', suffixText: 'kg'),
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final total =
                            double.tryParse(_feedUsed.text.trim()) ?? 0;
                        if (total <= 0 || _days <= 0) {
                          return const SizedBox.shrink();
                        }

                        return Text(
                          '${(total / _days).toStringAsFixed(2)} kg/day '
                          'across $_days days',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Activate',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  InputDecoration _decoration({
    required String hint,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade400),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
