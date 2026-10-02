import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_intro_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Watch how this works" — shown only to a farmer with no farms yet.
///
/// The link is set in the admin panel, so the video can be re-cut or replaced
/// without a store release. It disappears the moment the farmer has a farm:
/// at that point they have worked out how to start one, and the card would
/// only be in the way of the list.
class FarmDemoVideoCard extends StatelessWidget {
  const FarmDemoVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final video = farmIntroController.demoVideo.value;

      // The server already decides this — it returns the video ONLY when the
      // farmer has no farms. Checked again here because the list on screen is
      // the more recent truth: a farmer who has just created their first farm
      // should not still be offered the introduction.
      if (video == null ||
          !video.isUsable ||
          farmIntroController.hasFarms.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: InkWell(
          onTap: () => _open(video.url),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watch a short video before you start',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      CustomToast.error('That video link is not valid.');
      return;
    }

    try {
      // Externally: these are YouTube links, and the YouTube app plays them
      // better than an in-app web view does.
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) CustomToast.error('Could not open the video.');
    } catch (e) {
      CustomToast.error('Could not open the video.');
    }
  }
}
