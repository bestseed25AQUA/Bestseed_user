import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farmer/view/feed_update_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/partners_screen.dart';
import 'package:seedsuser/app/farm_management/manager/manager_screen.dart';

class FarmOptionsBottomSheet extends StatelessWidget {
  const FarmOptionsBottomSheet({super.key});

  // Reusable widget for each menu item
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Divider to separate menu items
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Divider(
        height: 0,
        thickness: 1,
        color: Color.fromARGB(255, 230, 230, 230),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Essential for bottom sheet height
        children: <Widget>[
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sattamma Thalli Farm - A Section',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context), // Close button
                ),
              ],
            ),
          ),

          // Menu Options
          _buildOptionTile(
            icon: Icons.layers_outlined, // Icon for 'Add tanks quantity'
            title: "Add today's tanks quantity",
            onTap: () {
              Get.to(() => const FeedUpdateScreen());
            },
          ),
          _buildDivider(),

          _buildOptionTile(
            icon: Icons.group_outlined, // Icon for 'Partners'
            title: 'Partners',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const PartnersScreen());
            },
          ),
          _buildDivider(),

          _buildOptionTile(
            icon: Icons.person_add_alt_1_outlined, // Icon for 'Manager'
            title: 'Manager',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ManagerScreen());
            },
          ),
          _buildDivider(),

          _buildOptionTile(
            icon: Icons.edit_outlined, // Icon for 'Edit farm Details'
            title: 'Edit farm Details',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDivider(),

          _buildOptionTile(
            icon: Icons.delete_outline, // Icon for 'Delete farm'
            title: 'Delete farm',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(context);
              // Show confirmation dialog here
            },
          ),
          const SizedBox(height: 10), // Padding at the bottom
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return const CustomConfirmationDialog();
      },
    );
  }
}

// --- Custom Confirmation Dialog Widget ---
class CustomConfirmationDialog extends StatelessWidget {
  const CustomConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // The shape defines the rounded corners for the entire dialog box
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // Use a custom child widget to build the content
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep the dialog size minimal
          children: <Widget>[
            // 1. Large Red Icon (The central "X")
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935), // A strong red color
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close, // Or Icons.clear, which looks like a cross
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),

            // 2. Confirmation Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Are you sure you want to delete this Farm',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. Action Buttons (Yes/No)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // No Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // Pop with 'false'
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'No',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Yes Button (The image style suggests it's a solid/primary color button)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // Pop with 'true'
                        // Execute delete logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFE3F2FD,
                        ), // A very light blue
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF64B5F6),
                        ), // Medium blue border
                      ),
                      child: Text(
                        'Yes',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Color(0xFF1976D2),
                        ), // Darker blue text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
