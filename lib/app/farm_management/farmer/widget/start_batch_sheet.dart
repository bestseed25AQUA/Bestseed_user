import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';

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
Future<StartBatchResult?> showStartBatchSheet(
  BuildContext context, {
  required String tankName,
}) {
  return showModalBottomSheet<StartBatchResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _StartBatchSheet(tankName: tankName),
  );
}

class _StartBatchSheet extends StatefulWidget {
  final String tankName;

  const _StartBatchSheet({required this.tankName});

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

  DateTime? get _picked => DateTime.tryParse(_date.text.trim());

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
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(picked.year, picked.month, picked.day))
            .inDays +
        1;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      // Capped at today: a crop cannot already have been stocked on a date
      // that has not arrived, and the server rejects one.
      lastDate: today,
      initialDate: _picked ?? today,
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

    _date.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-"
        "${picked.day.toString().padLeft(2, '0')}";

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
        stockingDate: _date.text.trim(),
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
        builder: (sheetContext) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
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
                        'Start a new batch',
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
                Text(
                  '${widget.tankName} starts again from zero. Its previous '
                  'batch is kept and stays available to download.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
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
                      'Start batch',
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
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
