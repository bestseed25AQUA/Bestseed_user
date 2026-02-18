import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/home/controller/contact_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final ContactController _contactController = Get.put(ContactController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_contactController.isLoading.value) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // If no contacts available, show nothing
      if (!_contactController.hasContacts) {
        return const SizedBox.shrink();
      }

      final String phoneNumber = _contactController.phoneNumber;
      final String whatsappNumber = _contactController.whatsappNumber;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Phone Call Card
              if (phoneNumber.isNotEmpty)
                Expanded(
                  child: buildContactCard(
                    title: "Call",
                    subtitle: " +91${phoneNumber}",
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
              if (phoneNumber.isNotEmpty && whatsappNumber.isNotEmpty)
                const SizedBox(width: 8),

              // WhatsApp Card
              if (whatsappNumber.isNotEmpty)
                Expanded(
                  child: buildContactCard(
                    title: "WhatsApp",
                    subtitle: " +91${whatsappNumber}",
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
                          const SnackBar(
                            content: Text("Cannot launch WhatsApp"),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      );
    });
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
