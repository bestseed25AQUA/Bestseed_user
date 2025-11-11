import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  // late ScrollController _scrollController;
  // bool _isScrolling = true;
  // Timer? _scrollTimer;

  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController = ScrollController();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _startAutoScroll();
  //   });
  // }

  // void _startAutoScroll() {
  //   _scrollTimer?.cancel();
  //   _scrollTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
  //     if (!mounted || !_isScrolling) return;

  //     final maxScroll = _scrollController.position.maxScrollExtent;
  //     final currentScroll = _scrollController.offset;

  //     if (currentScroll >= maxScroll) {
  //       _scrollController.jumpTo(0);
  //     } else {
  //       _scrollController.jumpTo(currentScroll + 3); // 8 pixels per frame
  //     }
  //   });
  // }

  // void _pauseScrolling() {
  //   if (mounted) {
  //     setState(() {
  //       _isScrolling = false;
  //     });
  //   }
  // }

  // void _resumeScrolling() {
  //   if (mounted) {
  //     setState(() {
  //       _isScrolling = true;
  //     });
  //   }
  // }

  // Future<void> _launchWhatsApp() async {
  //   _pauseScrolling();

  //   try {
  //     final Uri whatsappUri = Uri.parse(
  //       "https://wa.me/918977778784?text=Hello,%20I%20have%20a%20query",
  //     );
  //     if (await canLaunchUrl(whatsappUri)) {
  //       await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  //     } else {
  //       print("Could not open WhatsApp.");
  //     }
  //   } catch (e) {
  //     print("Error launching WhatsApp  ");
  //   } finally {
  //     // Add a small delay before resuming to ensure the external app has opened
  //     await Future.delayed(const Duration(seconds: 1));
  //     _resumeScrolling();
  //   }
  // }

  // Future<void> _launchPhoneCall() async {
  //   _pauseScrolling();

  //   try {
  //     final Uri phoneUri = Uri(scheme: 'tel', path: '+918977778784');
  //     if (await canLaunchUrl(phoneUri)) {
  //       await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  //     } else {
  //       print("Could not launch phone call.");
  //     }
  //   } catch (e) {
  //     print("Error launching phone call  ");
  //   } finally {
  //     // Add a small delay before resuming to ensure the external app has opened
  //     await Future.delayed(const Duration(seconds: 1));
  //     _resumeScrolling();
  //   }
  // }

  // @override
  // void dispose() {
  //   _scrollTimer?.cancel();
  //   _scrollController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber =
        "+918977778784"; // Replace with actual phone number
    final String whatsappNumber = "+918977778784";
    return Column(
      // clipBehavior: Clip.none,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container(
        //   color: AppColors.primary,
        //   child: Image.asset('assets/images/contact_us.png'),
        // ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Phone Call Card
            Expanded(
              child: buildContactCard(
                title: "Call",
                subtitle: phoneNumber,
                imagePath: 'assets/images/phone.png',
                color: Colors.black,
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
                color: Colors.black,
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

        // SingleChildScrollView(
        //   controller: _scrollController,
        //   scrollDirection: Axis.horizontal,
        //   physics:
        //       const NeverScrollableScrollPhysics(), // Disable manual scrolling
        //   child: Row(
        //     children: [
        //       _buildWhatsAppSection(),
        //       const SizedBox(width: 20),
        //       _buildPhoneSection(),
        //       const SizedBox(width: 20),
        //       _buildWhatsAppSection(), // Duplicate for continuous scroll
        //       const SizedBox(width: 20),
        //       _buildPhoneSection(), // Duplicate for continuous scroll
        //     ],
        //   ),
        // ),
        // Positioned(
        //   top: 6,
        //   left: 0,
        //   right: 0,
        //   child: Align(
        //     alignment: Alignment.topCenter,
        //     child: Text(
        //       '* Contact us *',
        //       style: GoogleFonts.roboto(
        //         color: Colors.white,
        //         fontSize: 16,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget buildContactCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity, // smaller width
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (title == 'Call')
                  Icon(Icons.phone, color: Colors.blue, size: 18)
                else
                  Image.asset(imagePath, height: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildWhatsAppSection() {
  //   return InkWell(
  //     onTap: _launchWhatsApp,
  //     child: Container(
  //       margin: const EdgeInsets.only(right: 20, top: 44),
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF1E2749),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           Image.asset('assets/images/whatsApp.png', height: 20),
  //           const SizedBox(width: 10),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Have a question?',
  //                 style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
  //               ),
  //               Text(
  //                 'Message us on WhatsApp',
  //                 style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(width: 15),
  //           InkWell(
  //             onTap: _launchWhatsApp,
  //             borderRadius: BorderRadius.circular(30),
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 12,
  //                 vertical: 6,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.green,
  //                 borderRadius: BorderRadius.circular(30),
  //               ),
  //               child: Text(
  //                 'Chat',
  //                 style: GoogleFonts.roboto(
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildPhoneSection() {
  //   return InkWell(
  //     onTap: _launchPhoneCall,
  //     child: Container(
  //       margin: const EdgeInsets.only(right: 20, top: 44),
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF1E2749),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           Image.asset('assets/images/phone.png', height: 24),
  //           const SizedBox(width: 10),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Need Help? ',
  //                 style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
  //               ),
  //               Text(
  //                 'Call Us Now! We\'re happy to talk with you',
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(width: 15),
  //           InkWell(
  //             onTap: _launchPhoneCall,
  //             borderRadius: BorderRadius.circular(30),
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 12,
  //                 vertical: 6,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.green,
  //                 borderRadius: BorderRadius.circular(30),
  //               ),
  //               child: Text(
  //                 'Call',
  //                 style: GoogleFonts.roboto(
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
