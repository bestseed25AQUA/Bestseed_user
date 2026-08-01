import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String currentVersion;
  final String minRequiredVersion;
  final String storeUrlAndroid;
  final String storeUrlIos;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
  });

  Future<void> _openStore() async {
    final url = Platform.isIOS ? storeUrlIos : storeUrlAndroid;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope with canPop=false blocks the Android back button (including
    // predictive-back gesture) and if the system tries to pop anyway (some
    // OEM launchers do), we call SystemNavigator.pop() to exit the app —
    // the user has NO way to bypass this screen and reach the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bestseed brand logo — prominent, replaces the generic
                // system-update glyph the earlier design used. The circular
                // primary-tinted halo behind the logo gives it a "featured"
                // look and separates it visually from a normal splash.
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 118,
                      height: 118,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.system_update_alt_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Update Required',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A newer version of Bestseed is available.\n'
                  'Please update to continue using the app.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (minRequiredVersion.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Your version: $currentVersion  •  Required: $minRequiredVersion',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 36),
                // Prominent Update button — full width, primary color, tall
                // tap target, elevated shadow so the "one thing you can do"
                // is impossible to miss.  No Cancel / Later / Skip button
                // anywhere on this screen by design.
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CustomButton(
                      onPressed: _openStore,
                      borderRadius: 14,
                      backgroundColor: AppColors.primary,
                      verticalPadding: 14,
                      text: Platform.isIOS
                          ? 'Update from App Store'
                          : 'Update from Play Store',
                      textStyle: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
