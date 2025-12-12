import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Text? title;
  final String? titleString;
  final Widget? titleWidget;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final double elevation;
  final Color? backgroundColor;
  final Color? backgroundColorActual;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;
  final ShapeBorder? shape;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final IconThemeData? iconTheme;
  final TextTheme? textTheme;
  final Brightness? brightness;

  const CustomAppBar({
    super.key,
    this.title,this.titleString,
    this.centerTitle = false,
    this.leading,
    this.actions,
    this.elevation = 0,
    this.backgroundColor = Colors.white, // DEFAULT WHITE
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.shape,
    this.titleSpacing,
    this.toolbarHeight = kToolbarHeight,
    this.iconTheme,
    this.textTheme,
    this.foregroundColor,
    this.titleWidget,
    this.brightness, this.backgroundColorActual,
  });

  @override
  Widget build(BuildContext context) {
    String myText = title?.data ?? "";

    return AppBar(
      title:
          titleWidget ??
          Text(
           titleString?? myText,
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
      centerTitle: centerTitle,
      // leading: leading,
      // leading: ,
      actions: actions,
      elevation: elevation,
      backgroundColor: backgroundColorActual?? Colors.white,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      shape: shape,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      iconTheme: iconTheme,
      foregroundColor: foregroundColor,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
}
