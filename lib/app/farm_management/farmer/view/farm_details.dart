import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_feed_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/harvest_bottom.dart';

class AquacultureScreen extends StatelessWidget {
  const AquacultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A list of the tank status data. Note that Tank 1, 2, 3, 6 are ON (true)
    // and Tank 5, 4, 7, 8 are OFF (false) to match the image.
    final List<Map<String, dynamic>> tankData = [
      {'name': 'Tank 1', 'status': true, 'kg': 250, 'day': 20},
      {'name': 'Tank 2', 'status': true, 'kg': 250, 'day': 20},
      {'name': 'Tank 3', 'status': true, 'kg': 250, 'day': 20},
      {'name': 'Tank 6', 'status': true, 'kg': 250, 'day': 20},
      {'name': 'Tank 5', 'status': false, 'kg': 250, 'day': 20},
      {'name': 'Tank 4', 'status': false, 'kg': 250, 'day': 20},
      {'name': 'Tank 7', 'status': false, 'kg': 250, 'day': 20},
      {'name': 'Tank 8', 'status': false, 'kg': 250, 'day': 20},
    ];

    // Split the list into pairs for the grid layout
    final List<List<Map<String, dynamic>>> tankPairs = [];
    for (int i = 0; i < tankData.length; i += 2) {
      tankPairs.add(
        tankData.sublist(i, i + 2 > tankData.length ? tankData.length : i + 2),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Sattamma Thalli - A section',
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Total Feed Used and Store Section ---
            const FeedStoreCard(),
            const SizedBox(height: 16),

            // --- Tank Status Grid Section ---
            ...tankPairs.map((pair) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TankStatusCard(
                        name: pair[0]['name']!,
                        status: pair[0]['status']!,
                        kgs: pair[0]['kg']!,
                        day: pair[0]['day']!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TankStatusCard(
                        name: pair[1]['name']!,
                        status: pair[1]['status']!,
                        kgs: pair[1]['kg']!,
                        day: pair[1]['day']!,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- Widget for Total Feed Used and Store Card ---
class FeedStoreCard extends StatelessWidget {
  const FeedStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary, // Blue background
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Total Feed Used
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Total feed used',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2500',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    EditButton(),
                  ],
                ),
              ),
              // Separator
              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
              // Store
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Store',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '500',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    EditButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Shared Edit Button Widget ---
class EditButton extends StatelessWidget {
  const EditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const HarvestBottomSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 16),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: GoogleFonts.roboto(color: AppColors.primary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget for a single Tank Status Card ---
class TankStatusCard extends StatelessWidget {
  final String name;
  final bool status;
  final int kgs;
  final int day;

  const TankStatusCard({
    super.key,
    required this.name,
    required this.status,
    required this.kgs,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    // Define colors based on the status
    final Color switchColor = status ? Colors.green : Colors.red;
    // final Color borderColor = status ? const Color(0xFF1976D2) : Colors.red;

    return InkWell(
      onTap: () {
        Get.to(() => TankFeedScreen());
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Tank Name Button Style
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1976D2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: GoogleFonts.roboto(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Toggle Switch
                Switch(
                  value: status,
                  onChanged: (bool newValue) {
                    // In a real app, you'd update the state here.
                    // print('$name status changed to $newValue');
                  },
                  activeColor: switchColor, // The thumb color when on
                  inactiveThumbColor: switchColor, // The thumb color when off
                  activeTrackColor: switchColor.withOpacity(
                    0.5,
                  ), // The track color when on
                  inactiveTrackColor: switchColor.withOpacity(
                    0.5,
                  ), // The track color when off
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // Compacts the switch
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kgs and Day Info
            Row(
              children: <Widget>[
                Text(
                  '$kgs.Kgs',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'Day.$day',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
