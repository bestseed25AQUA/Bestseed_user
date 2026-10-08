import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_intro_controller.dart';

/// The announcement popup for Farm Management.
///
/// Replaced the banner strip that used to sit across the top of the screen. A
/// banner is scenery: a notice about the stocking season was being scrolled
/// past without being read. This stands in front of the screen instead, and
/// shows the newest announcement every time the screen is opened.
class FarmAnnouncementDialog extends StatelessWidget {
  final FarmAnnouncement announcement;

  const FarmAnnouncementDialog({super.key, required this.announcement});

  /// Show it, unless one is already up.
  ///
  /// [takeAnnouncement] is what decides whether there is anything to show, so
  /// this never pops the same notice twice in one visit.
  /// True when a dialog was actually put on screen.
  static Future<bool> maybeShow(BuildContext context) async {
    final announcement = farmIntroController.takeAnnouncement();

    if (announcement == null) return false;
    if (!context.mounted) return false;

    await showDialog(
      context: context,
      // Dismissible: it is news, not a decision, and a farmer who has read it
      // should be able to get on with their work.
      barrierDismissible: true,
      builder: (_) => FarmAnnouncementDialog(announcement: announcement),
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (announcement.hasImage)
            // Fixed aspect so a tall image cannot push the buttons off the
            // bottom of a small screen.
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: announcement.image!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
                // An image that will not load is simply left out rather than
                // leaving a broken box above the text.
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    announcement.description,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
