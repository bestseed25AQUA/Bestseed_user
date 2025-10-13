import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class WantedCropBuyersScreen extends StatefulWidget {
  const WantedCropBuyersScreen({super.key});

  @override
  State<WantedCropBuyersScreen> createState() => _WantedCropBuyersScreenState();
}

class _WantedCropBuyersScreenState extends State<WantedCropBuyersScreen> {
  String selectedValue = "Vannamei";
  String selected = "East Godavari";

  // Controller for search text
  TextEditingController searchController = TextEditingController();

  String? selectedFilter;

  void _selectFilter(String? filter) {
    setState(() {
      if (selectedFilter == filter) {
        selectedFilter = null; // toggle off
      } else {
        selectedFilter = filter;
      }
    });
    // _filterBuyers(searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: "Search buyers...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter chips
            Wrap(
              spacing: 8,
              children: ["Vannamei", "Fish", "Tiger"].map((type) {
                final isSelected = selectedFilter == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey[200],
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) => _selectFilter(type),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            _buildFilterSection(),

            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return _buildHatcheryCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A helper method to build the app bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      title: Text(
        'Wanted',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
            selected,
            ["East Godavari", "Monodon", "Scampi"],
            (newValue) {
              setState(() {
                selected = newValue!;
              });
            },
          ),
        ),
        const SizedBox(width: 64),
        Expanded(
          child: _buildDropdownButton(
            selectedValue,
            ["Vannamei", "Monodon", "March 2025"],
            (newValue) {
              setState(() {
                selectedValue = newValue!;
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
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VANNAMEI',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          'Prakasam,Anakapalli',
                          style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          '25/06/2025',
                          style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  'Popular shrimp species, fast-growing and high market demand.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: selectedFilter == "Vannamei"
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text('Tons'),
                          Text(
                            'Minimum 5-20',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text('Payment'),
                          Text(
                            'Offline',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price'),
                          Text(
                            '₹50,000',
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
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              final phoneNumber = "tel:+918977778784";
              if (await canLaunch(phoneNumber)) {
                await launch(phoneNumber);
              } else {
                print("Could not launch phone call.");
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/customer_call.png', height: 28),
                  SizedBox(width: 12),
                  Text(
                    'Call & Book seeds',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // Future<void> _makePhoneCall(String phoneNumber) async {
  //   final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  //   if (await canLaunchUrl(launchUri)) {
  //     await launchUrl(launchUri);
  //   } else {
  //     throw 'Could not launch $phoneNumber';
  //   }
  // }
}
