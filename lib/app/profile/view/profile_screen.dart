import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/view/booking_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/controller/logout_controller.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/profile/view/edit_profile_screen.dart'; 
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_screen.dart';
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
      body: CustomScrollView(
        slivers: [
          /// Collapsible SliverAppBar
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Get.back();
              },
            ),
            title: Text(
              'Profile',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: const [
                  SizedBox(
                    height: kToolbarHeight + 0,
                  ), // leave space for status bar & toolbar
                  ProfileHeader(),
                ],
              ),
            ),
          ),

          /// Body List
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              ProfileMenuItem(
                icon: Icons.notifications_none,
                title: AppLocalizations.of(context).notifications,
                onTap: () {
                  Get.to(() => NotificationsScreen());
                },
              ),
              ProfileMenuItem(
                icon: Icons.fire_truck_outlined,
                title: AppLocalizations.of(context).tracking,
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: Icons.menu,
                title: AppLocalizations.of(context).my_bookings,
                onTap: () {
                  Get.to(() => MyBookingScreen());
                },
              ),
               ProfileMenuItem(
                icon: Icons.menu,
                title: "Vehicle availability",
                onTap: () {
                  Get.to(() => VehicleAvailabilityScreen());
                },
              ),
               ProfileMenuItem(
                icon: Icons.menu,
                title: "Vehicle tracking",
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: Icons.headset_mic_outlined,
                title: AppLocalizations.of(context).customer_support,
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context).terms_conditions,
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: FontAwesomeIcons.language,
                title: AppLocalizations.of(context).change_languages,
                onTap: () {
                  Get.to(() => LanguageSelectionScreen());
                },
              ),
              ProfileMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: AppLocalizations.of(context).privacy_policy,
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.star_border,
                title: AppLocalizations.of(context).rate_us,
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.share_outlined,
                title: AppLocalizations.of(context).share_app,
                onTap: () {},
              ),
              Obx(() {
                return logoutController.isLoading.value
                    ? Center(child: CircularProgressIndicator())
                    : ProfileMenuItem(
                        icon: Icons.logout,
                        title: AppLocalizations.of(context).logout,
                        onTap: () {
                          Get.bottomSheet(
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Are you sure you want to logout?",
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Get.back(); // close bottom sheet
                                          },
                                          child: const Text("Cancel"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Get.back();
                                            logoutController.logout();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text("Logout"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                            isDismissible: true,
                          );
                        },
                        isShow: false,
                      );
              }),
            ]),
          ),
        ],
      ),
    );
  }
}

// Profile Header Widget
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Obx(() {
      final profile = controller.profile.value;

      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 👤 Profile Image
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  (profile?.profileImage != null &&
                      profile!.profileImage!.isNotEmpty)
                  ? NetworkImage(profile.profileImage!)
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
            ),

            const SizedBox(width: 16),

            // 🧾 Name and Mobile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile != null &&
                            (profile.firstName != null ||
                                profile.lastName != null)
                        ? "${profile.firstName ?? ''} ${profile.lastName ?? ''}"
                              .trim()
                        : "No name available",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.mobile ?? "N/A",
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ✏️ Edit button
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => EditProfileScreen());
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Reusable Menu Item Widget
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isShow;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isShow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: isShow
          ? const Icon(Icons.arrow_forward, size: 24, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
