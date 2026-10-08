import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:seedsuser/app/subscription/model/subscription_models.dart';
import 'package:seedsuser/app/subscription/view/subscription_plans_sheet.dart';

/// The once-a-day expiry popup on Farm Management.
///
/// The banner under the app bar stays up the whole time; this is the louder
/// reminder that fires when the screen opens. Shown at most once per calendar
/// day per subscription, and the marker is written to disk, so killing the app
/// and reopening it does not bring it back until tomorrow.
class SubscriptionExpiryReminder {
  SubscriptionExpiryReminder._();
  static final SubscriptionExpiryReminder instance =
      SubscriptionExpiryReminder._();

  static const String _key = 'subscription_expiry_notice_shown';

  final GetStorage _box = GetStorage();

  bool _showing = false;

  /// Renewing re-arms the reminder: a new subscription id is a new marker.
  String _markerFor(SubscriptionDetails subscription) {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');

    return '${subscription.id}|${today.year}-$month-$day';
  }

  Future<void> maybeShow(
    BuildContext context,
    SubscriptionStatus status,
  ) async {
    if (_showing) return;

    final subscription = status.subscription;
    final message = subscription?.warning;

    if (subscription == null || message == null) return;

    final marker = _markerFor(subscription);
    if (_box.read<String>(_key) == marker) return;

    _showing = true;
    await _box.write(_key, marker);

    if (!context.mounted) {
      _showing = false;
      return;
    }

    final renew = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          _ExpiryDialog(message: message, expired: subscription.isExpired),
    );

    _showing = false;

    if (renew == true && context.mounted) {
      await showSubscriptionPlansSheet(context, status);
    }
  }
}

class _ExpiryDialog extends StatelessWidget {
  final String message;
  final bool expired;

  const _ExpiryDialog({required this.message, required this.expired});

  @override
  Widget build(BuildContext context) {
    final accent = expired ? Colors.red.shade700 : Colors.orange.shade800;
    final tint = expired ? Colors.red.shade50 : Colors.orange.shade50;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(
                expired ? Icons.error_outline_rounded : Icons.schedule_rounded,
                size: 32,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              expired ? 'Subscription ended' : 'Subscription ending',
              style: GoogleFonts.roboto(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View packages',
                  style: GoogleFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not now',
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
