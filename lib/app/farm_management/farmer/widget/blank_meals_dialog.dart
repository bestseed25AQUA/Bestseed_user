import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

/// Asks before saving meals the farmer left blank.
///
/// Leaving a meal empty used to be a hard error — "Enter a quantity for meal
/// 1" — which refused the whole save even when a later meal had a real figure
/// in it. But a blank meal is a perfectly ordinary thing to mean: the tank was
/// not fed at that sitting. The farmer still has to SEE it, in case the box is
/// empty because they forgot rather than because it was skipped.
///
/// So it asks once, naming the meals, and saves them as 0 on confirmation.
/// Nothing is asked when every meal has a figure, which is the usual case.
///
/// Returns true to go ahead, false to go back and fill them in.
Future<bool> confirmBlankMeals(
  BuildContext context,
  List<String> mealNumbers,
) async {
  if (mealNumbers.isEmpty) return true;

  final many = mealNumbers.length > 1;

  // "1 and 2" rather than "1, 2" — it is read aloud as a sentence.
  final list = mealNumbers.length == 1
      ? mealNumbers.first
      : '${mealNumbers.sublist(0, mealNumbers.length - 1).join(', ')}'
            ' and ${mealNumbers.last}';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              many ? 'Meals with no quantity' : 'Meal with no quantity',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        many
            ? 'Meals $list have no quantity. They will be saved as 0 kg.'
            : 'Meal $list has no quantity. It will be saved as 0 kg.',
        style: GoogleFonts.roboto(fontSize: 13.5, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Go back',
            style: GoogleFonts.roboto(color: Colors.grey.shade700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            'Save anyway',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  // Dismissed by tapping outside counts as "go back": saving zeros is not
  // something to do on an ambiguous gesture.
  return result ?? false;
}
