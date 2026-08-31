import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/access_management_screen.dart';

class SetupAccessGuideScreen extends StatelessWidget {
  /// Farm the access is being granted for — access grants are per-farm.
  final int farmId;

  /// What the logged-in farmer holds on that farm — passed straight through so
  /// the access screen knows which permissions it may hand out.
  final FarmAccess access;

  /// Manager or Partner. Chosen on the farm's options sheet and carried all
  /// the way through, so this screen, the access list and the add form all
  /// speak about one role and never ask for it again.
  final FarmRole role;

  const SetupAccessGuideScreen({
    Key? key,
    required this.farmId,
    required this.role,
    this.access = const FarmAccess.ownerFallback(),
  }) : super(key: key);

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
                        Expanded(
                          child: Text(
                            'Access Setup — ${role.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
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
                      "Follow These Steps to Give ${role.label} Access",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Step 1 no longer says "choose the role" — the role was
                    // chosen on the farm's options sheet to get here, and the
                    // steps below name it rather than asking again.
                    //
                    // Steps 2 and 3 used to cover generating a QR code with a
                    // PIN and sending both on WhatsApp. Access is now given
                    // directly to a person, so there is nothing to share.
                    _buildStep(
                      stepNumber: "1",
                      title: "Step 1",
                      items: [
                        _StepItem(
                          title: "Pick the people",
                          description:
                              "Search by name or mobile number and choose who "
                              "you want to make a ${role.label.toLowerCase()}.",
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
                          title: "Set how long the access should stay active",
                          description: "Choose Days or Weeks",
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
                          title: "Select what they can do",
                          description:
                              "View / Edit / Add / Delete. They get access "
                              "straight away — the farm appears in their app.",
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
                              builder: (_) =>
                                  AccessManagementScreen(
                                    farmId: farmId,
                                    access: access,
                                    role: role,
                                  ),
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
                              "Setup ${role.label} access",
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
