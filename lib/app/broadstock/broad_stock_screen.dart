import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/profile_screen.dart';

class BroodStockScreen extends StatefulWidget {
  const BroodStockScreen({super.key});

  @override
  State<BroodStockScreen> createState() => _BroodStockScreenState();
}

class _BroodStockScreenState extends State<BroodStockScreen> {
  String selectedValue = "Vannamei";
  String selectedDate = "Jan 2025";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterSection(),
              const SizedBox(height: 24),
              _buildHatcheryListHeader(),
              const SizedBox(height: 16),
              _buildHatcheryCard(),
              const SizedBox(height: 16),
              _buildHatcheryCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // A helper method to build the app bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[800],
      automaticallyImplyLeading: false,
      title: Text(
        'Broad Stock',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        InkWell(
          onTap: () {
            Get.to(() => LanguageSelectionScreen());
          },
          child: Image.asset('assets/images/lan_image.png', height: 32),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {
            Get.to(() => NotificationsScreen());
          },
          child: Image.asset('assets/images/notification.png', height: 32),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {
            Get.to(() => ProfileScreen());
          },
          child: Image.asset('assets/images/person.png', height: 32),
        ),
        SizedBox(width: 16),
      ],
    );
  }

  // A helper method to build the search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search for hatcheries...',
          border: InputBorder.none,
          suffixIcon: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Icon(Icons.mic, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  // A helper method to build the filter section
  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownButton(
            selectedValue,
            ["Vannamei", "Monodon", "Scampi"],
            (newValue) {
              setState(() {
                selectedValue = newValue!;
              });
            },
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          child: _buildDropdownButton(
            selectedDate,
            ["Jan 2025", "Fru 2025", "March 2025"],
            (newValue) {
              setState(() {
                selectedDate = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  // A helper method to build a dropdown button
  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true, // takes full width
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

  // A helper method to build the header for the hatchery list
  Widget _buildHatcheryListHeader() {
    return Text(
      'Hatchery & Suppliers',
      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // A helper method to build a single hatchery card
  Widget _buildHatcheryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.asset(
                  'assets/images/hatchery.png',
                  height: 141,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Available on 23/06/2025',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Packing start date
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Packing Start From 25/06/2025',
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Hatchery details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NSR hatcheries',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Prakasam,Anakapalli',
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Syaqua Americas Inc, Florida',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Imported Date on 20/06/2025',
                  style: GoogleFonts.roboto(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text('Available Quantity'),
                Text(
                  '600 Pieces',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
