import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';

class CustomIconAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomIconAppbar({
    super.key,
    required this.title,
    this.bottom,
    this.toolbarHeight = kToolbarHeight, this.ontapBack,
  });

  final String title;

  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final Function()? ontapBack;

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(icon: Icon(Icons.arrow_back,color: Colors.black,), onPressed: ontapBack,),
      titleWidget: Text(
        title,
        style: GoogleFonts.roboto(
          color: Colors.black,
          fontWeight: FontWeight.bold,fontSize: 17
        ),
      ),
      titleSpacing: 0,
      // titleWidget: Text(
      //   title,
      //   style: GoogleFonts.roboto(
      //     color: Colors.white,
      //     fontWeight: FontWeight.bold,fontSize: 15
      //   ),
      // ),
      actions: [
        OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedShape: const CircleBorder(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) {
            return Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Image.asset('assets/images/lan_image.png', height: 24),
            );
          },
          openBuilder: (context, action) {
            return LanguageSelectionScreen();
          },
        ),
        const SizedBox(width: 16),
        OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedShape: const CircleBorder(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) {
            return Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Image.asset('assets/images/notification.png', height: 24),
            );
          },
          openBuilder: (context, action) {
            return const NotificationsScreen();
          },
        ),
        const SizedBox(width: 16),
        OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedShape: const CircleBorder(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) {
            return Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Image.asset('assets/images/person.png', height: 24),
            );
          },
          openBuilder: (context, action) {
            return const ProfileScreen();
          },
        ),
        // InkWell(
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       AppAnimations.circularRevealRoute(
        //         const ProfileScreen(),
        //         center: Alignment.topCenter,
        //       ),
        //     );
        //   },
        //   child: Image.asset(
        //     'assets/images/person.png',
        //     height: 32,
        //   ),
        // ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
}
