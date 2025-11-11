import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farm_home/form_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_list_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/former_details_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_details.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/chat_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/contact_us_dialog.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_options.dart';

class FarmSection {
  final String name;
  final String feedUsed;
  final String store;
  final int activeCount;
  final int inactiveCount;
  final List<String> imageUrl;
  final String id;
  final int noOfTanks;
  final String lowFeedLimit;

  FarmSection({
    required this.lowFeedLimit,
    required this.noOfTanks,
    required this.name,
    required this.feedUsed,
    required this.store,
    required this.activeCount,
    required this.inactiveCount,
    required this.imageUrl,
    required this.id,
  });
}

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  final FarmListController controller = Get.put(FarmListController());
  bool _isChatbotOpen = false;

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  List<FarmSection> get farmSections {
    final data = controller.farmList.value?.data ?? [] as List<FarmData>?;
    return data!.map((e) {
      return FarmSection(
        lowFeedLimit: e.lowFeedLimit ?? '',
        noOfTanks: e.noOfTanks ?? 0,
        name: e.farmName ?? "Unknown Farm",
        feedUsed: e.lowFeedLimit ?? "0 kgs",
        store: e.store ?? "0 kgs",
        activeCount: e.noOfTanks ?? 0,
        inactiveCount: 2, // Static (Not in API)
        imageUrl: e.images?.imagesList ?? [],
        id: e.id.toString(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Farm Management',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        // leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
            onPressed: () => showContactUsDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
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
              const Positioned(bottom: 120, right: 16, child: ChatbotWidget()),

            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'chatbotFab',
                    backgroundColor: _isChatbotOpen
                        ? Colors.white
                        : primaryBlue,
                    onPressed: _toggleChatbot,
                    child: Icon(
                      _isChatbotOpen ? Icons.close : Icons.smart_toy_outlined,
                      color: _isChatbotOpen ? primaryBlue : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'addFab',
                    backgroundColor: primaryBlue,
                    onPressed: () => Get.to(() => AddFarmerDetailsFormScreen()),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class FarmCard extends StatelessWidget {
  final FarmSection farm;
  const FarmCard({super.key, required this.farm});

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => AquacultureScreen()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        print(farm.imageUrl.isNotEmpty ? farm.imageUrl[0] : '');
                      },
                      child: Image.network(
                        farm.imageUrl.isNotEmpty ? farm.imageUrl[0] : '',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.asset(
                          "assets/images/farmer_fish.png",
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: InkWell(
                        onTap: () {
                          showFarmBottomSheet(
                            context: context,
                            farmName: farm.name,
                            onAddTankQty: () {
                              Navigator.pop(context);
                              // Navigate to tank quantity screen
                              print("Add tank quantity clicked");
                            },

                            onPartners: () {
                              Navigator.pop(context);
                              print("Partners clicked");
                            },

                            onManager: () {
                              Navigator.pop(context);
                              print("Manager clicked");
                            },

                            onEditFarm: () {
                              Navigator.pop(context);
                              Get.to(
                                () => AddFarmerDetailsFormScreen(
                                  farmData: FarmData(
                                    id: int.parse(farm.id),
                                    farmName: farm.name,
                                    farmerId: int.parse(farm.id),
                                    images: FarmImages(
                                      imagesList: farm.imageUrl,
                                    ),
                                    store: farm.store,
                                    noOfTanks: farm.noOfTanks,
                                    lowFeedLimit: farm.feedUsed,
                                  ),
                                ),
                              );
                            },

                            onDeleteFarm: () async {
                              Navigator.pop(context);
                              final farmerDetailController = Get.put(
                                FarmerDetailController(),
                              );
                              final farmListController =
                                  Get.find<FarmListController>();

                              if (await farmerDetailController.deleteFarm(
                                farmId: farm.id,
                              )) {
                                farmListController.fetchFarmList();
                              }
                            },
                          );
                        },
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(1, 3),
                                color: Colors.grey.withOpacity(.3),
                              ),
                            ],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.more_vert),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      farm.name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.roboto(fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Total Feed Used: ",
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: farm.feedUsed+' kgs',
                              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                       RichText(
                        text: TextSpan(
                          style: GoogleFonts.roboto(fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Store ",
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: farm.store+' kgs',
                              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Text(
                      //   "Total Feed Used: ${farm.feedUsed} ",
                      //   style: GoogleFonts.roboto(fontSize: 14),
                      // ),
                     
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const FarmOptionsBottomSheet(),
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

void showFarmBottomSheet({
  required BuildContext context,
  required String farmName,
  required VoidCallback onAddTankQty,
  required VoidCallback onPartners,
  required VoidCallback onManager,
  required VoidCallback onEditFarm,
  required VoidCallback onDeleteFarm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  farmName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _sheetItem(
              icon: Icons.layers,
              title: "Add today's tanks quantity",
              onTap: onAddTankQty,
            ),

            _sheetItem(icon: Icons.group, title: "Partners", onTap: onPartners),

            _sheetItem(icon: Icons.person, title: "Manager", onTap: onManager),

            _sheetItem(
              icon: Icons.edit,
              title: "Edit farm Details",
              onTap: onEditFarm,
            ),

            _sheetItem(
              icon: Icons.delete,
              title: "Delete farm",
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: onDeleteFarm,
            ),
          ],
        ),
      );
    },
  );
}

/// Single tile widget inside sheet
Widget _sheetItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
  Color? textColor,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.black, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: textColor ?? Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  );
}
