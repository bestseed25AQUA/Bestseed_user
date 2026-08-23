import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

/// Warns the farmer that a farm's feed store has fallen below its limit.
class FeedLowAlertDialog extends StatelessWidget {
  /// Remaining feed in the store, in kilograms.
  final num remainingKgs;
  final VoidCallback onContactDealer;

  const FeedLowAlertDialog({
    super.key,
    required this.remainingKgs,
    required this.onContactDealer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20),
                ),
              ),
            ),
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Colors.brown.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'Feed Low Alert',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your feed store has dropped below $remainingKgs kgs. '
              'Please refill soon to avoid shortages.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContactDealer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Contact Dealer',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [FeedLowAlertDialog]; returns once dismissed.
Future<void> showFeedLowAlert(
  BuildContext context, {
  required num remainingKgs,
  required VoidCallback onContactDealer,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => FeedLowAlertDialog(
      remainingKgs: remainingKgs,
      onContactDealer: onContactDealer,
    ),
  );
}
