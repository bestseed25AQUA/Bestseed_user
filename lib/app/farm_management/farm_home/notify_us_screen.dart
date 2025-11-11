import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

import 'package:seedsuser/app/farm_management/farmer/controller/farm_list_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/initial_farmer_screen.dart';

class NotifyUsScreen extends StatefulWidget {
  const NotifyUsScreen({super.key});

  @override
  State<NotifyUsScreen> createState() => _NotifyUsScreenState();
}

class _NotifyUsScreenState extends State<NotifyUsScreen> {
  final FarmListController _farmController = Get.put(FarmListController());
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _farmController.fetchFarmList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.robotoTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notify Us'),
        // centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Farm Management',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Image.asset(
              "assets/images/farm_line.png",
              width: 180,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your farm and tank details to track feed usage easily and keep records updated.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 36),

            // --- Call Card ---
            NotifyActionCard(
              icon: Icons.call,
              title: 'Call',
              subtitle: 'Reach out — we’ll set up your farm',
              imagePath: 'assets/images/farm_call.png',
              onTap: () {
                // Example action
                Get.snackbar(
                  'Call Action',
                  'Connecting you with support...',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.blue.shade100,
                  colorText: Colors.black,
                );
              },
            ),
            const SizedBox(height: 20),

            // --- Fill Form Card ---
            NotifyActionCard(
              icon: Icons.assignment,
              title: 'Fill Form',
              subtitle: 'Just share details — we’ll do it for you',
              imagePath: 'assets/images/farm_fill.png',
              onTap: () async { 

                if (_farmController.farmList.value?.data?.isNotEmpty == true) {
                  Get.off(
                    () => FarmManagementScreen(),
                  ); // Replace current screen
                } else {
                  Get.to(
                    () => const InitialFarmScreen(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(milliseconds: 400),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotifyActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const NotifyActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.robotoTextTheme(Theme.of(context).textTheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.primary.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 28, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Illustration
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(imagePath, height: 160, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
