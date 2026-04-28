import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/view/booking_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/controller/logout_controller.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/profile/view/edit_profile_screen.dart';
import 'package:seedsuser/app/vehicle_tracking/view/booking_vehicle_list_screen.dart';
import 'package:seedsuser/app/common/terms_and_conditions_screen.dart';
import 'package:seedsuser/app/common/privacy_policy_screen.dart';
import 'package:seedsuser/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LogoutController logoutController = Get.put(LogoutController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Blue Header with curve ────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ProfileHeaderBackground(
                    profileController: profileController),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
                // Title
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 56,
                  child: Text(
                    'Profile',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Quick Actions floating card
                Positioned(
                  bottom: -36,
                  left: 20,
                  right: 20,
                  child: _quickActions(context),
                ),
              ],
            ),

            const SizedBox(height: 56),

                // Settings Section
                _settingsSection(context),

                const SizedBox(height: 12),

                // Logout
                _logoutSection(context),

                const SizedBox(height: 30),

                // App version
                Text(
                  'Bestseed v1.0.0',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Quick Action Cards ─────────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _quickActionItem(
              icon: Icons.receipt_long_rounded,
              label: 'Bookings',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyBookingScreen()),
              ),
            ),
            _quickActionItem(
              icon: Icons.local_shipping_rounded,
              label: 'Tracking',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VehicleTrackingPage()),
              ),
            ),
            _quickActionItem(
              icon: Icons.headset_mic_rounded,
              label: 'Help',
              color: const Color(0xFFF59E0B),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings Section ───────────────────────────────────────────────
  Widget _settingsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.notifications_none_rounded,
            title: AppLocalizations.of(context).notifications,
            onTap: () => Get.to(() => NotificationsScreen()),
          ),
          _divider(),
          _menuTile(
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context).terms_conditions,
            onTap: () => Get.to(() => const TermsAndConditionsScreen()),
          ),
          _divider(),
          _menuTile(
            icon: FontAwesomeIcons.language,
            title: AppLocalizations.of(context).change_languages,
            onTap: () => Get.to(() => LanguageSelectionScreen()),
          ),
          _divider(),
          _menuTile(
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context).privacy_policy,
            onTap: () => Get.to(() => const PrivacyPolicyScreen()),
          ),
          _divider(),
          _menuTile(
            icon: Icons.star_border_rounded,
            title: AppLocalizations.of(context).rate_us,
            onTap: () {},
          ),
          _divider(),
          _menuTile(
            icon: Icons.share_outlined,
            title: AppLocalizations.of(context).share_app,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey.shade600).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: iconColor ?? Colors.grey.shade700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  // ── Logout Section ─────────────────────────────────────────────────
  Widget _logoutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        if (logoutController.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return InkWell(
          onTap: () => _showLogoutSheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 14),
                Text(
                  AppLocalizations.of(context).logout,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF4444), size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              "Logout",
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Are you sure you want to logout?",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      logoutController.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Logout",
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
      isDismissible: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE HEADER BACKGROUND — shown inside SliverAppBar
// ═══════════════════════════════════════════════════════════════════════════
class _ProfileHeaderBackground extends StatelessWidget {
  final ProfileController profileController;

  const _ProfileHeaderBackground({required this.profileController});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 60,
          bottom: 90,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0077C8), Color(0xFF3FA9F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Obx(() {
            final profile = profileController.profile.value;
            final isLoading = profileController.isLoading.value;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final name = profile != null &&
                    (profile.firstName != null || profile.lastName != null)
                ? "${profile.firstName ?? ''} ${profile.lastName ?? ''}".trim()
                : "No name available";

            return Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    backgroundImage: (profile?.profileImage != null &&
                            profile!.profileImage!.isNotEmpty)
                        ? NetworkImage(profile.profileImage!)
                        : null,
                    child: (profile?.profileImage == null ||
                            profile!.profileImage!.isEmpty)
                        ? const Icon(Icons.person_rounded,
                            size: 36, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Name + Phone + Edit
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.mobile ?? "N/A",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => Get.to(() => EditProfileScreen()),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// Curved bottom clipper for the blue header
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Keep ProfileMenuItem for backward compatibility (used elsewhere)
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isShow;
  final Color? iconColor;
  final Color? titleColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isShow = true,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? Colors.black54),
      title: Text(
        title,
        style: GoogleFonts.roboto(fontSize: 14, color: titleColor),
      ),
      trailing: isShow
          ? const Icon(Icons.arrow_forward, size: 24, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
