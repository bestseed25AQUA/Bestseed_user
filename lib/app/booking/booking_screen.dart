import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  String selected = "Filter";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'My Bookings',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          SizedBox(
            width: 110,
            height: 36,
            child: _buildDropdownButton(selected, ["Filter"], (newValue) {
              setState(() {
                selected = newValue!;
              });
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: 8,
          itemBuilder: (context, index) {
            return _buildVehicleDetailsCard(context);
          },
        ),
      ),
    );
  }

  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildImageSection(), _buildInfoSection()],
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 135, // Fixed height to prevent layout issues
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
        child: Image.asset(
          'assets/images/seeds_image.png',
          height: 135,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 135,
            color: Colors.grey[300],
            child: Center(
              child: Text(
                'Image Placeholder',
                style: GoogleFonts.roboto(color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hatchery Name and Report Button
        const SizedBox(height: 4),
        Text(
          "Seven Star Hatchery seeds",
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        // Description
        Text(
          "Syqua ",
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Location and Availability Details
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.person, "Unit - 1", 'Subbu'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.water_drop_outlined,
                    "Broadstock",
                    "1200 Pieces",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Available Date",
                    "27 Sep 2024",
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,

                children: [
                  _buildInfoRow(Icons.phone, "Available Date", "+91xxxxxx"),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, "Unit - 2", 'Godavari'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
