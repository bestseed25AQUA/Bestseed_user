import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/home/carousel_slider_options_card.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/wanted/wanted_screen.dart';

class SeedPriceItem {
  final String count;
  final String price;

  SeedPriceItem({required this.count, required this.price});
}

class SeedPricesScreen extends StatefulWidget {
  const SeedPricesScreen({super.key});

  @override
  State<SeedPricesScreen> createState() => _SeedPricesScreenState();
}

class _SeedPricesScreenState extends State<SeedPricesScreen> {
  String selectedValue = "Vannamei";
  String selected = "East Godavari";
  final List<SeedPriceItem> seedPrices = [
    SeedPriceItem(count: '100C', price: '₹220'),
    SeedPriceItem(count: '90C', price: '₹230'),
    SeedPriceItem(count: '80C', price: '₹240'),
    SeedPriceItem(count: '70C', price: '₹260'),
    SeedPriceItem(count: '60C', price: '₹290'),
    SeedPriceItem(count: '48C-50C', price: '₹320'),
    SeedPriceItem(count: '46C-47C', price: '₹325'),
    SeedPriceItem(count: '43C-45C', price: '₹325'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
        title: Text(
          'Seed Prices',
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
          SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => ProfileScreen());
            },
            child: Image.asset('assets/images/person.png', height: 32),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselCardsScreen(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Card: From Hatchery to Farmer
                  // Image.asset('assets/images/image.png'),
                  const SizedBox(height: 12),
                  // Location Dropdowns
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDropdownButton(
                          selected,
                          ["East Godavari", "West Godavari"],
                          (newValue) {
                            setState(() {
                              selected = newValue!;
                            });
                          },
                        ),
                      ),
                      Expanded(child: const SizedBox()),
                      Expanded(
                        flex: 2,
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
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Price List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Count',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Today's Prices",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...seedPrices.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16,
                      ),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.count,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            item.price,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  const SizedBox(height: 20),
                  // Bottom Card: Wanted: Crop Buyers
                  InkWell(
                    onTap: () {
                      Get.to(() => WantedCropBuyersScreen());
                    },
                    child: Image.asset('assets/images/us.png'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
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
}
