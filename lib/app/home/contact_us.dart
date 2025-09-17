import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto scrolling after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() async {
    while (mounted) {
      try {
        // Scroll to the end
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 8),
          curve: Curves.linear,
        );

        // Jump back instantly to the start (loop effect)
        _scrollController.jumpTo(0);
      } catch (_) {
        break; // Prevent error if widget is disposed
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: AppColors.primary,
          child: Image.asset('assets/images/contact_us.png'),
        ),

        // 👇 Auto-scrolling WhatsApp + Phone sections
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildWhatsAppSection(),
              const SizedBox(width: 20),
              _buildPhoneSection(),
              const SizedBox(width: 20),
              _buildWhatsAppSection(), // duplicate for smoother loop
              const SizedBox(width: 20),
              _buildPhoneSection(),
            ],
          ),
        ),

        // Top title
        Positioned(
          top: 6,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              '* Contact us *',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppSection() {
    return Container(
      margin: const EdgeInsets.only(right: 20, top: 44),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2749),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/whatsApp.png', height: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Have a question?',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Message us on WhatsApp',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Chat',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Container(
      margin: const EdgeInsets.only(right: 20, top: 44),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2749),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/phone.png', height: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need Help? ',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Call Us Now!  We’re happy to talk with you',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Call',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
