import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:seedsuser/app/farm_management/farmer/model/farm_licence.dart';
import 'package:seedsuser/app/subscription/view/subscription_plans_sheet.dart';

/// One farm's standing, as the reminder needs it.
class FarmCoverEntry {
  final String name;
  final int? farmId;
  final FarmLicence licence;

  const FarmCoverEntry({
    required this.name,
    required this.licence,
    this.farmId,
  });
}

/// The once-a-day popup naming farms that are locked or running out.
///
/// The strip on each card is always there; this is the louder reminder when
/// Farm Management opens. Shown at most once per calendar day, and the marker
/// is written to disk so closing the app does not bring it back.
class FarmCoverReminder {
  FarmCoverReminder._();
  static final FarmCoverReminder instance = FarmCoverReminder._();

  static const String _key = 'farm_cover_notice_shown';

  final GetStorage _box = GetStorage();

  bool _showing = false;

  /// A farm renewed or newly expiring re-arms the reminder: the marker carries
  /// what it was shown for, not just the date.
  String _markerFor(List<FarmCoverEntry> farms) {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');

    final state = farms
        .map(
          (f) =>
              '${f.farmId}:${f.licence.isLocked ? 'L' : f.licence.daysRemaining}',
        )
        .join(',');

    return '${today.year}-$month-$day|$state';
  }

  Future<void> maybeShow(
    BuildContext context,
    List<FarmCoverEntry> allFarms,
  ) async {
    if (_showing) return;

    final affected = allFarms
        .where((f) => f.licence.isLocked || f.licence.isExpiringSoon)
        .toList();

    if (affected.isEmpty) return;

    final marker = _markerFor(affected);
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
      builder: (_) => _CoverDialog(farms: affected),
    );

    _showing = false;

    if (renew == true && context.mounted) {
      await offerSubscriptionPackages(context);
    }
  }
}

class _CoverDialog extends StatelessWidget {
  final List<FarmCoverEntry> farms;

  const _CoverDialog({required this.farms});

  @override
  Widget build(BuildContext context) {
    final anyLocked = farms.any((f) => f.licence.isLocked);
    final accent = anyLocked ? Colors.red.shade700 : Colors.orange.shade800;
    final tint = anyLocked ? Colors.red.shade50 : Colors.orange.shade50;

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
                anyLocked ? Icons.lock_outline : Icons.schedule_rounded,
                size: 32,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              anyLocked ? 'A farm needs renewing' : 'A farm is running out',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final farm in farms) _row(farm)],
                ),
              ),
            ),
            const SizedBox(height: 18),
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

  Widget _row(FarmCoverEntry farm) {
    final locked = farm.licence.isLocked;
    final colour = locked ? Colors.red.shade700 : Colors.orange.shade800;

    final detail = locked
        ? 'Read-only until renewed'
        : (farm.licence.expiryNote ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            locked ? Icons.lock_outline : Icons.schedule_rounded,
            size: 15,
            color: colour,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.name,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    height: 1.35,
                    color: colour,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
