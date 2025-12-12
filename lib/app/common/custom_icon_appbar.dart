
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';

class CustomIconAppbar extends StatelessWidget  implements PreferredSizeWidget {
  const CustomIconAppbar({super.key, required this.title, this.bottom,this.toolbarHeight = kToolbarHeight, });

  final String title;
  
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        InkWell(
          onTap: () => Get.to(() => LanguageSelectionScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/lan_image.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => NotificationsScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/notification.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => ProfileScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/person.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
}