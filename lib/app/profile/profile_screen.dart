import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/booking/booking_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/edit_profile_screen.dart';
import 'package:seedsuser/app/tracking/vehicle_tracking_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                    height: kToolbarHeight + 38,
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
                title: 'Notification',
                onTap: () {
                  Get.to(() => NotificationsScreen());
                },
              ),
              ProfileMenuItem(
                icon: Icons.fire_truck_outlined,
                title: 'Tracking',
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: Icons.menu,
                title: 'My bookings',
                onTap: () {
                  Get.to(() => MyBookingScreen());
                },
              ),
              ProfileMenuItem(
                icon: Icons.headset_mic_outlined,
                title: 'Customer support',
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: Icons.description_outlined,
                title: 'Terms and conditions',
                onTap: () {
                  Get.to(() => VehicleTrackingPage());
                },
              ),
              ProfileMenuItem(
                icon: FontAwesomeIcons.language,
                title: 'Change language',
                onTap: () {
                  Get.to(() => LanguageSelectionScreen());
                },
              ),
              ProfileMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.star_border,
                title: 'Rate us',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.share_outlined,
                title: 'Share app',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {},
                isShow: false,
              ),
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
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'B Subbu',
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '+918977778784',
                style: GoogleFonts.roboto(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
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
