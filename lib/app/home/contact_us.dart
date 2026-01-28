import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  @override
  Widget build(BuildContext context) {
    final String phoneNumber =
        "+918977778784"; // Replace with actual phone number
    final String whatsappNumber = "+918977778784";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Phone Call Card
            Expanded(
              child: buildContactCard(
                title: "Call",
                subtitle: phoneNumber,
                imagePath: 'assets/images/phone.png',
                background: Colors.blue,
                onTap: () async {
                  final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(callUri)) {
                    await launchUrl(callUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cannot launch phone dialer"),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(width: 8),

            // WhatsApp Card
            Expanded(
              child: buildContactCard(
                title: "WhatsApp",
                subtitle: whatsappNumber,
                imagePath: 'assets/images/whatsApp.png',
                background: Colors.green,
                onTap: () async {
                  final whatsappUrl =
                      "https://wa.me/${whatsappNumber.replaceAll('+', '')}";
                  final Uri uri = Uri.parse(whatsappUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cannot launch WhatsApp")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildContactCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity, // smaller width
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: background.withOpacity(.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(imagePath, height: 28),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: background,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
