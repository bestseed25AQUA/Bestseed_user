import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farm_home/form_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_details.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/chat_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/contact_us_dialog.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_options.dart';

// --- Data Model for a Farm Section ---
class FarmSection {
  final String name;
  final String feedUsed;
  final String store;
  final int activeCount;
  final int inactiveCount;
  final String imageUrl;

  FarmSection({
    required this.name,
    required this.feedUsed,
    required this.store,
    required this.activeCount,
    required this.inactiveCount,
    required this.imageUrl,
  });
}

// --- Main Farm Management Screen Widget ---
class FarmManagementScreen extends StatefulWidget {
  FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  // Sample data to populate the list
  final List<FarmSection> farmSections = [
    FarmSection(
      name: 'Sattamma Thalli Farm - A Section',
      feedUsed: '2500kgs',
      store: '500kgs',
      activeCount: 8,
      inactiveCount: 2,
      // Placeholder image URL - replace with a real asset or network image
      imageUrl: 'assets/images/farmer_fish.png',
    ),
    FarmSection(
      name: 'Sattamma Thalli Farm - B Section',
      feedUsed: '2500kgs',
      store: '500kgs',
      activeCount: 8,
      inactiveCount: 2,
      imageUrl: 'assets/images/farmer_fish.png',
    ),
  ];

  bool _isChatbotOpen = false;

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(
      0xFF007BFF,
    ); // The blue color from the app bar

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Farm Management',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.headset_mic_outlined,
                color: Colors.black,
                size: 20,
              ), // Headset icon for Help
              onPressed: () {
                showContactUsDialog(context);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: farmSections.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FarmCard(farm: farmSections[index]),
              );
            },
          ),
          if (_isChatbotOpen)
            Positioned(
              bottom: 120, // Position the chatbot card above the main FAB
              right: 16,
              child: const ChatbotWidget(),
            ),

          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chatbot/Help button (This button controls the visibility)
                FloatingActionButton(
                  heroTag: 'chatbotFab',
                  backgroundColor: _isChatbotOpen ? Colors.white : primaryBlue,
                  onPressed: _toggleChatbot,
                  child: Icon(
                    _isChatbotOpen ? Icons.close : Icons.smart_toy_outlined,
                    color: _isChatbotOpen ? primaryBlue : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Main FAB (Add button)
                FloatingActionButton(
                  heroTag: 'addFab',
                  backgroundColor: primaryBlue,
                  onPressed: () {
                    Get.to(() => FarmDetailsFormScreen());
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Farm Card Widget ---
class FarmCard extends StatelessWidget {
  final FarmSection farm;
  const FarmCard({super.key, required this.farm});

  // A small reusable chip widget for status
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => AquacultureScreen());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and More Options Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://media.smallbiztrends.com/2021/06/fish-farming-1.png',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _showFarmOptions(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors
                              .black54, // Semi-transparent background for button
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _showFarmOptions(context);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Chips
                  Row(
                    children: [
                      _buildStatusChip(
                        'Active - ${farm.activeCount}',
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        'Inactive - ${farm.inactiveCount}',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Farm Name/Section
                  Text(
                    farm.name,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Feed and Store Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Feed Used
                      Expanded(
                        flex: 2,
                        child: Row(
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Feed Used - ',
                              style: GoogleFonts.roboto(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              farm.feedUsed,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Store
                      Expanded(
                        child: Row(
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store  ',
                              style: GoogleFonts.roboto(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              farm.store,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  void _showFarmOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the sheet to be full-height if content is tall
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return const FarmOptionsBottomSheet();
      },
    );
  }
}

class ChatbotWidget extends StatelessWidget {
  const ChatbotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary color to match the app's theme
    const Color primaryBlue = Color(0xFF007BFF);

    return Container(
      // Margin to slightly lift it above the floating action buttons
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16.0),
      width: 320, // Set a fixed width for the card (adjust as needed)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Shadow to make the card look elevated, matching the visual style
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // Ensures the column only takes needed vertical space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Robot Icon and Title
          Row(
            children: [
              const Icon(
                Icons.smart_toy_outlined,
                color: primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Hi ! I\'m Best Seeds Bot',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description/Greeting Message
          Text(
            'I am here to help you – what do you need today?',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Chat and Voice assist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Chat Button
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Get.to(() => ChatBotScreen());
                },
              ),
              // Voice Assist Button
              OutlinedButton.icon(
                icon: const Icon(Icons.mic_none),
                label: const Text('Voice assist'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _showVoiceAssistanceModal(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVoiceAssistanceModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        // Use a semi-transparent background over the content
        return const VoiceAssistanceModal();
      },
    );
  }
}

class VoiceAssistanceModal extends StatelessWidget {
  const VoiceAssistanceModal({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget renders the floating card on top of the underlying screen.
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header Row (Voice assistance title and close button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice assistance',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Microphone Icon (Pulsating effect simulation)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade100.withOpacity(0.5),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade600,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 35),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Listening/Recognized Text
              Text(
                'Show ...',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
