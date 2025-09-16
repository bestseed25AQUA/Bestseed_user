import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Header Section
          const ProfileHeader(),
          const SizedBox(height: 16),
          // List of Menu Items
          ProfileMenuItem(
            icon: Icons.notifications_none,
            title: 'Notification',
            onTap: () {},
          ),
          ProfileMenuItem(
            icon: Icons.track_changes,
            title: 'Tracking',
            onTap: () {},
          ),
          ProfileMenuItem(
            icon: Icons.menu_open,
            title: 'My bookings',
            onTap: () {},
          ),
          ProfileMenuItem(
            icon: Icons.headset_mic_outlined,
            title: 'Customer support',
            onTap: () {},
          ),
          ProfileMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms and conditions',
            onTap: () {},
          ),
          ProfileMenuItem(
            icon: FontAwesomeIcons.language,
            title: 'Change language',
            onTap: () {},
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
          ProfileMenuItem(icon: Icons.logout, title: 'Logout', onTap: () {}),
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
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile_pic.png'),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'M.Ram kumar',
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '+91XXXXXX',
                style: GoogleFonts.roboto(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
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

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 24,
        color: AppColors.primary,
      ),
      onTap: onTap,
    );
  }
}
