import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farm_home/form_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
// import 'package:seedsuser/app/farm_management/farmer/controller/former_details_controller.dart'  hide FarmListController;
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_detail_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/feed_update_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/setup_access_guide_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_history_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/chat_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_options.dart';
import 'package:seedsuser/app/farm_management/manager/view/manager_screen.dart';
import 'package:seedsuser/app/farm_management/farm_home/notify_us_screen.dart';
import 'package:seedsuser/app/farm_management/partner/view/partner_screen.dart';

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  final FarmListController controller = Get.put(FarmListController());
  final tankController = Get.put(TankController());
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
        activeCount: e.activeCount.toString(),
        inactiveCount: e.inactiveCount.toString(), // Static (Not in API)
        imageUrls: e.images?.imagesList ?? [],
        id: e.id.toString(),
        stockingDate: e.stockingDate.toString(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Farm Management',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        // leading: const Icon(Icons.menu),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(
                      top: 12,
                      right: 12,
                      bottom: 12,
                      left: 12,
                    ),
                    itemCount: farmSections.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () {
                            Get.to(
                              FarmTankListScreen(
                                farmId: farmSections[index].id,
                                farmName: farmSections[index].name,
                              ),
                            );
                          },
                          child: FarmCard(
                            farm: farmSections[index],
                            tankController: tankController,
                          ),
                        ),
                      );
                    },
                  ),

                  if (_isChatbotOpen)
                    const Positioned(
                      bottom: 120,
                      right: 16,
                      child: ChatbotWidget(),
                    ),
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
                            _isChatbotOpen
                                ? Icons.close
                                : Icons.smart_toy_outlined,
                            color: _isChatbotOpen ? primaryBlue : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FloatingActionButton(
                          heroTag: 'addFab',
                          backgroundColor: primaryBlue,
                          onPressed: () =>
                              Get.to(() => AddFarmerDetailsFormScreen()),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Fixed Contact Us button at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: TextButton(
                onPressed: () {
                  Get.to(() => const NotifyUsScreen());
                },
                child: Text(
                  'Contact Us',
                  style: GoogleFonts.roboto(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  const FarmCard({super.key, required this.farm, required this.tankController});
  final TankController tankController;

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
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
            BoxShadow(
              offset: const Offset(1, 3),
              color: Colors.grey.withOpacity(.3),
              blurRadius: 5,
            ),
          ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    farm.imageUrls.isNotEmpty ? farm.imageUrls[0] : '',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Image.asset(
                      "assets/images/farmer_fish.png",
                      height: 150,
                      fit: BoxFit.cover,
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
                            tankController.getTankList(farm.id);
                            Get.to(FeedUpdateScreen(farmId: farm.id));
                          },

                          onTapAccessSetup: () {
                            final rootNav = Navigator.of(context, rootNavigator: true);
                            Navigator.pop(context);
                            rootNav.push(
                              MaterialPageRoute(
                                builder: (_) => const SetupAccessGuideScreen(),
                              ),
                            );
                          },

                          onPartners: () {
                            Navigator.pop(context);
                            Get.to(PartnerScreen());
                            print("Partners clicked");
                          },

                          onManager: () {
                            Navigator.pop(context);
                            Get.to(ManagerScreen());
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
                                    imagesList: farm.imageUrls,
                                  ),
                                  stockingDate: farm.stockingDate,
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
                              FarmListController(),
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
                            text: '${farm.feedUsed} kgs',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
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
                            text: farm.store + ' kgs',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
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
                'Hi ! I\'m Bestseed Bot',
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
  required VoidCallback onTapAccessSetup,
  required VoidCallback onPartners,
  required VoidCallback onManager,
  required VoidCallback onEditFarm,
  required VoidCallback onDeleteFarm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Container(
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

              _sheetItem(
                icon: Icons.person_2,
                title: "Set Up Access for Manager or Partner",
                onTap: onTapAccessSetup,
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
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false, // User must tap a button to close
                    builder: (BuildContext context) {
                      return CustomConfirmationDialog(ontapYes: onDeleteFarm);
                    },
                  );
                },
              ),
            ],
          ),
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

// --- Custom Confirmation Dialog Widget ---
class CustomConfirmationDialog extends StatelessWidget {
  const CustomConfirmationDialog({super.key, required this.ontapYes});
  final VoidCallback ontapYes;
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
                        Navigator.of(context).pop(true);
                        ontapYes();
                        // Pop with 'true'
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

class FarmSection {
  final String name;
  final String feedUsed;
  final String store;
  final String activeCount;
  final String inactiveCount;
  final List<String> imageUrls;
  final String id;
  final int noOfTanks;
  final String stockingDate;
  final String lowFeedLimit;

  FarmSection({
    required this.lowFeedLimit,
    required this.noOfTanks,
    required this.name,
    required this.feedUsed,
    required this.store,
    required this.activeCount,
    required this.inactiveCount,
    required this.imageUrls,
    required this.stockingDate,
    required this.id,
  });
}
