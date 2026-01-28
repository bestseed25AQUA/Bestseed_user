import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/view/booking_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_best_seed_background.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/controller/logout_controller.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/profile/view/edit_profile_screen.dart';
import 'package:seedsuser/app/vehicle_tracking/view/booking_vehicle_list_screen.dart';
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
    Widget divider = Divider(height: 1);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 90),
          child: Column(
            children: const [
              // leave space for status bar & toolbar
              ProfileHeader(),
              SizedBox(height: 20),
            ],
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: SizedBox(height: 0),
          // background: Column(
          //   children: const [
          //     SizedBox(
          //       height: kToolbarHeight + 0,
          //     ), // leave space for status bar & toolbar
          //     ProfileHeader(),
          //   ],
          // ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 5),

            // / Collapsible SliverAppBar
            // SliverAppBar(
            //   pinned: true,
            //   expandedHeight: 180,
            //   backgroundColor: AppColors.primary,
            //   leading: IconButton(
            //     icon: const Icon(Icons.arrow_back, color: Colors.white),
            //     onPressed: () {
            //       Get.back();
            //     },
            //   ),
            //   title: Text(
            //     'Profile',
            //     style: GoogleFonts.roboto(
            //       color: Colors.white,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   flexibleSpace: FlexibleSpaceBar(
            //     background: Column(
            //       children: const [
            //         SizedBox(
            //           height: kToolbarHeight + 0,
            //         ), // leave space for status bar & toolbar
            //         ProfileHeader(),
            //       ],
            //     ),
            //   ),
            // ),
            // ProfileHeader(),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 15, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _menuItem(
                    'assets/images/booking_icon.png',
                    'Bookings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MyBookingScreen()),
                      );
                    },
                  ),
                  _menuItem(
                    'assets/images/vehicle_icon.png',
                    'Vehicle Tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleTrackingPage()),
                      );
                    },
                  ),
                  _menuItem(
                    'assets/images/help_icon.png',
                    'Help',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            /// Body List
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.only(bottom: 10, left: 15, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, -2), // 🔥 TOP shadow
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 2), // bottom shadow
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ProfileMenuItem(
                    icon: Icons.notifications_none,
                    title: AppLocalizations.of(context).notifications,
                    onTap: () {
                      Get.to(() => NotificationsScreen());
                    },
                  ),
                  divider,
                  ProfileMenuItem(
                    icon: Icons.description_outlined,
                    title: AppLocalizations.of(context).terms_conditions,
                    onTap: () {
                      // Get.to(() => VehicleTrackingPage());
                    },
                  ),
                  divider,
                  ProfileMenuItem(
                    icon: FontAwesomeIcons.language,
                    title: AppLocalizations.of(context).change_languages,
                    onTap: () {
                      Get.to(() => LanguageSelectionScreen());
                    },
                  ),
                  divider,
                  ProfileMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: AppLocalizations.of(context).privacy_policy,
                    onTap: () {},
                  ),
                  divider,
                  ProfileMenuItem(
                    icon: Icons.star_border,
                    title: AppLocalizations.of(context).rate_us,
                    onTap: () {},
                  ),
                  divider,
                  ProfileMenuItem(
                    icon: Icons.share_outlined,
                    title: AppLocalizations.of(context).share_app,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, -2), // 🔥 TOP shadow
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(0, 2), // bottom shadow
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Obx(() {
                return logoutController.isLoading.value
                    ? Center(child: CircularProgressIndicator())
                    : ProfileMenuItem(
                        iconColor: AppColors.primary,
                        titleColor: AppColors.primary,
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
                        isShow: true,
                      );
              }),
            ),
            SizedBox(height: 15),
            CustomBestSeedBackground(),
            SizedBox(height: 15),
          ],
        ),
        // SliverList(
        //   delegate: SliverChildListDelegate([
        //     const SizedBox(height: 16),
        //     ProfileMenuItem(
        //       icon: Icons.notifications_none,
        //       title: AppLocalizations.of(context).notifications,
        //       onTap: () {
        //         Get.to(() => NotificationsScreen());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.fire_truck_outlined,
        //       title: AppLocalizations.of(context).tracking,
        //       onTap: () {
        //         Get.to(() => VehicleTrackingPage());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.menu,
        //       title: AppLocalizations.of(context).my_bookings,
        //       onTap: () {
        //         Get.to(() => MyBookingScreen());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.menu,
        //       title: "Vehicle availability",
        //       onTap: () {
        //         Get.to(() => VehicleAvailabilityScreen());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.menu,
        //       title: "Vehicle tracking",
        //       onTap: () {
        //         Get.to(() => VehicleTrackingPage());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.headset_mic_outlined,
        //       title: AppLocalizations.of(context).customer_support,
        //       onTap: () {
        //         Get.to(() => VehicleTrackingPage());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.description_outlined,
        //       title: AppLocalizations.of(context).terms_conditions,
        //       onTap: () {
        //         Get.to(() => VehicleTrackingPage());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: FontAwesomeIcons.language,
        //       title: AppLocalizations.of(context).change_languages,
        //       onTap: () {
        //         Get.to(() => LanguageSelectionScreen());
        //       },
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.privacy_tip_outlined,
        //       title: AppLocalizations.of(context).privacy_policy,
        //       onTap: () {},
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.star_border,
        //       title: AppLocalizations.of(context).rate_us,
        //       onTap: () {},
        //     ),
        //     ProfileMenuItem(
        //       icon: Icons.share_outlined,
        //       title: AppLocalizations.of(context).share_app,
        //       onTap: () {},
        //     ),
        //     Obx(() {
        //       return logoutController.isLoading.value
        //           ? Center(child: CircularProgressIndicator())
        //           : ProfileMenuItem(
        //               icon: Icons.logout,
        //               title: AppLocalizations.of(context).logout,
        //               onTap: () {
        //                 Get.bottomSheet(
        //                   Container(
        //                     padding: const EdgeInsets.all(16),
        //                     decoration: BoxDecoration(
        //                       color: Colors.white,
        //                       borderRadius: const BorderRadius.vertical(
        //                         top: Radius.circular(20),
        //                       ),
        //                     ),
        //                     child: Column(
        //                       mainAxisSize: MainAxisSize.min,
        //                       children: [
        //                         Text(
        //                           "Are you sure you want to logout?",
        //                           style: GoogleFonts.roboto(
        //                             fontSize: 16,
        //                             fontWeight: FontWeight.bold,
        //                           ),
        //                         ),
        //                         const SizedBox(height: 20),
        //                         Row(
        //                           children: [
        //                             Expanded(
        //                               child: OutlinedButton(
        //                                 onPressed: () {
        //                                   Get.back(); // close bottom sheet
        //                                 },
        //                                 child: const Text("Cancel"),
        //                               ),
        //                             ),
        //                             const SizedBox(width: 10),
        //                             Expanded(
        //                               child: ElevatedButton(
        //                                 onPressed: () {
        //                                   Get.back();
        //                                   logoutController.logout();
        //                                 },
        //                                 style: ElevatedButton.styleFrom(
        //                                   backgroundColor: AppColors.primary,
        //                                   foregroundColor: Colors.white,
        //                                 ),
        //                                 child: const Text("Logout"),
        //                               ),
        //                             ),
        //                           ],
        //                         ),
        //                         const SizedBox(height: 10),
        //                       ],
        //                     ),
        //                   ),
        //                   isDismissible: true,
        //                 );
        //               },
        //               isShow: false,
        //             );
        //     }),
        //   ]),
        // ),  G
      ),
    );
  }

  Widget _menuItem(String image, String label, {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(image, width: 43, height: 43, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
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
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, -2), // 🔥 TOP shadow
              blurRadius: 3,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 2), // bottom shadow
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            // 👤 Profile Image
            CircleAvatar(
              radius: 30,
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
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.mobile ?? "N/A",
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // ✏️ Edit button
            SizedBox(
              // width: 90,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => EditProfileScreen());
                },

                icon: const Icon(Icons.edit, size: 16),

                label: Text('Edit', style: GoogleFonts.roboto(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
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
