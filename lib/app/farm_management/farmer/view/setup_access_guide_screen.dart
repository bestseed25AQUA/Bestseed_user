import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farmer/view/access_management_screen.dart';

class SetupAccessGuideScreen extends StatelessWidget {
  const SetupAccessGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 220;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue header with app bar + image
            Container(
              width: double.infinity,
              height: headerHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, Color(0xFF0060A0)],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Access Setup',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Image
                  Expanded(
                    child: Image.asset(
                      'assets/images/access_granted.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            // White card content - overlaps blue header
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height - headerHeight + 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  children: [
                    Text(
                      "Follow These Steps to Give Access",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Step 1
                    _buildStep(
                      stepNumber: "1",
                      title: "Step 1",
                      items: [
                        _StepItem(
                          title: "Set Access",
                          description:
                              "Choose who you want to give access to  Manager or Partner",
                        ),
                        _StepItem(
                          title: "Select what they can do",
                          description: "View / Edit / Add",
                        ),
                        _StepItem(
                          title: "Set how long the access should stay active",
                          description: "Choose Days or Weeks",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Step 2
                    _buildStep(
                      stepNumber: "2",
                      title: "Step 2",
                      items: [
                        _StepItem(
                          title: "Create a QR code with a PIN",
                          description:
                              "We'll generate a QR code and password. Share both with the person to give them access.",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Step 3
                    _buildStep(
                      stepNumber: "3",
                      title: "Step 3",
                      items: [
                        _StepItem(
                          title: "Send the QR code and password on WhatsApp.",
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccessManagementScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Setup access",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String stepNumber,
    required String title,
    required List<_StepItem> items,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepItem {
  final String title;
  final String? description;
  _StepItem({required this.title, this.description});
}
