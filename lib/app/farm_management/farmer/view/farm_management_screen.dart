import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farm_home/form_details_screen.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
// import 'package:seedsuser/app/farm_management/farmer/controller/former_details_controller.dart'  hide FarmListController;
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_detail_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/add_farm_details_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/feed_update_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/setup_access_guide_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/view/tank_history_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/chat_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_options.dart';
import 'package:seedsuser/app/farm_management/farm_home/notify_us_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';
import 'package:seedsuser/app/farm_management/farmer/view/initial_farmer_screen.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  final FarmListController controller = farmListController;

  /// Guards the one-way handover to the empty-state screen.
  bool _handedOver = false;
  final tankController = Get.put(TankController());
  bool _isChatbotOpen = false;

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  List<FarmSection> get farmSections {
    // `?? [] as List<FarmData>?` cast an empty List<dynamic>, which throws a
    // TypeError the moment it is reached — and it IS reached whenever the farm
    // list request fails, because this getter runs from build() as soon as
    // isLoading drops. A typed empty list cannot throw.
    final data = controller.farmList.value?.data ?? <FarmData>[];

    // The API returns farms oldest-first. Sort newest-first here so the most
    // recently added farm is at the TOP of the list.
    final ordered = [...data]
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    return ordered.map((e) {
      return FarmSection(
        lowFeedLimit: e.lowFeedLimit ?? '',
        noOfTanks: e.noOfTanks ?? 0,
        name: e.farmName ?? "Unknown Farm",
        // Empty, not "0 kgs": the card appends " kgs" itself, so that fallback
        // rendered "0 kgs kgs" — and store being unset is not a store of zero.
        store: e.store ?? '',
        activeCount: e.activeCount.toString(),
        inactiveCount: e.inactiveCount.toString(), // Static (Not in API)
        imageUrls: e.images?.imagesList ?? [],
        id: e.id.toString(),
        stockingDate: e.stockingDate.toString(),
        totalFeedUsed: e.totalFeedUsed ?? 0,
        feedUsedBefore: e.feedUsedBefore,
        access: e.access,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    // Deleting the last farm leaves this screen with nothing to show, so hand
    // back to the empty-state screen.
    //
    // This REPLACES the route in a post-frame callback. Returning
    // InitialFarmScreen from here instead made the two screens render each
    // other: its initState refetched, that flipped isLoading, this Obx rebuilt,
    // and round it went — an endless stream of /farm-lists calls and a
    // "!_dirty is not true" crash every frame. Navigating leaves exactly one
    // screen mounted, and the guard makes it fire once.
    return Obx(() {
      // `!hasLoadError`: an empty list after a FAILED request is not the same
      // as a farmer with no farms, and handing over on it showed the
      // add-your-first-farm screen to someone who simply had no signal.
      if (!controller.isLoading.value &&
          !controller.hasLoadError.value &&
          farmSections.isEmpty &&
          !_handedOver) {
        _handedOver = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InitialFarmScreen()),
          );
        });
      }

      return _buildFarmList(context, primaryBlue);
    });
  }

  Widget _buildFarmList(BuildContext context, Color primaryBlue) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => safeBack(),
        ),
        title: Text(
          'Farm Management',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        // leading: const Icon(Icons.menu),
        //
        // The Scan action is gone with the rest of the QR flow: access is
        // given by picking people directly in Setup Access, so there is no
        // code to scan.
      ),
      body: Obx(() {
        final farms = farmSections;

        // Full-screen spinner only on the FIRST load. During a pull-to-refresh
        // the list stays put and RefreshIndicator draws its own spinner —
        // swapping the body out would tear the gesture away mid-pull.
        if (controller.isLoading.value && farms.isEmpty) {
          return const FarmListShimmer();
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => controller.fetchFarmList(),
                    child: ListView.builder(
                      // Not reversed: a reversed list anchors its items to the
                      // BOTTOM of the viewport, which left a single farm
                      // floating at the bottom of an empty screen. Newest-first
                      // ordering is done in `farmSections` instead, so the list
                      // fills from the top like every other list in the app.
                      //
                      // AlwaysScrollable so the pull gesture still works when
                      // there are too few farms to fill the screen.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 12,
                        right: 12,
                        bottom: 12,
                        left: 12,
                      ),
                      itemCount: farms.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () {
                              Get.to(
                                FarmTankListScreen(
                                  farmId: farms[index].id,
                                  farmName: farms[index].name,
                                  access: farms[index].access,
                                ),
                              );
                            },
                            child: FarmCard(
                              farm: farms[index],
                              tankController: tankController,
                            ),
                          ),
                        );
                      },
                    ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
                  _FarmImageCarousel(imageUrls: farm.imageUrls),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: InkWell(
                      onTap: () {
                        // Every option below needs the farm id as a number.
                        // It arrives here as a string built with `toString()`,
                        // so a farm the API returned without an id becomes the
                        // literal "null" and `int.parse` threw inside the tap
                        // callback — an unhandled exception, and the sheet
                        // simply did nothing. Resolve it once, up front.
                        final farmIdNum = int.tryParse(farm.id);
                        if (farmIdNum == null) {
                          CustomToast.error('This farm is missing its id');
                          return;
                        }

                        showFarmBottomSheet(
                          context: context,
                          farmName: farm.name,
                          access: farm.access,
                          onAddTankQty: () {
                            Navigator.pop(context);
                            tankController.getTankList(farm.id);
                            Get.to(
                              FeedUpdateScreen(
                                farmId: farm.id,
                                access: farm.access,
                              ),
                            );
                          },

                          // One entry point per role. The role is chosen HERE
                          // and carried through the guide, the access list and
                          // the add form, so it is never asked for twice.
                          onManagerAccess: () {
                            final rootNav = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            Navigator.pop(context);
                            rootNav.push(
                              MaterialPageRoute(
                                builder: (_) => SetupAccessGuideScreen(
                                  farmId: farmIdNum,
                                  access: farm.access,
                                  role: FarmRole.manager,
                                ),
                              ),
                            );
                          },

                          onPartnerAccess: () {
                            final rootNav = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            Navigator.pop(context);
                            rootNav.push(
                              MaterialPageRoute(
                                builder: (_) => SetupAccessGuideScreen(
                                  farmId: farmIdNum,
                                  access: farm.access,
                                  role: FarmRole.partner,
                                ),
                              ),
                            );
                          },

                          onEditFarm: () {
                            Navigator.pop(context);
                            Get.to(
                              () => AddFarmerDetailsFormScreen(
                                farmData: FarmData(
                                  id: farmIdNum,
                                  farmName: farm.name,
                                  farmerId: farmIdNum,
                                  images: FarmImages(
                                    imagesList: farm.imageUrls,
                                  ),
                                  stockingDate: farm.stockingDate,
                                  store: farm.store,
                                  noOfTanks: farm.noOfTanks,
                                  // The real field. It used to read
                                  // `farm.feedUsed`, which happened to hold the
                                  // low-feed limit too — right value, wrong
                                  // name, and it would have started filling the
                                  // edit form with the feed total the moment
                                  // that field was corrected.
                                  lowFeedLimit: farm.lowFeedLimit,
                                  // Without this the edit form showed an empty
                                  // "Feed Already Used" box on a farm that has
                                  // weeks of history.
                                  totalFeedUsed: farm.totalFeedUsed,
                                  feedUsedBefore: farm.feedUsedBefore,
                                ),
                              ),
                            );
                          },

                          onDeleteFarm: () async {
                            Navigator.pop(context);

                            // The shared instance — the same object the list
                            // above is watching, so the refresh is visible.
                            if (await farmListController.deleteFarm(
                              farmId: farm.id,
                            )) {
                              await farmListController.fetchFarmList();
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
                    Flexible(
                      child: _buildStatusChip(
                        'Active - ${farm.activeCount}',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildStatusChip(
                        'Inactive - ${farm.inactiveCount}',
                        Colors.red,
                      ),
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
                // Both figures are Flexible: "Total Feed Used: 12500 kgs" and
                // "Store 8000 kgs" side by side are wider than a narrow phone,
                // and a fixed pair of RichTexts overflowed instead of trimming.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: GoogleFonts.roboto(fontSize: 14),
                          children: [
                            const TextSpan(
                              text: "Total Feed Used: ",
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: '${farm.totalFeedUsedLabel} kgs',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Flexible(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: GoogleFonts.roboto(fontSize: 14),
                          children: [
                            const TextSpan(
                              text: "Store ",
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: farm.storeLabel,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Text(
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
      // A hard 320 is wider than the usable width of a small phone once the
      // surrounding padding is taken off, so the card overflowed there. Cap it
      // instead, and let it shrink on anything narrower.
      constraints: const BoxConstraints(maxWidth: 320),
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
              Expanded(
                child: Text(
                  'Hi ! I\'m Bestseed Bot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
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
          //
          // Wrap rather than Row: at a larger system font size the two buttons
          // are wider than the card and a Row overflowed. This drops "Voice
          // assist" onto its own line instead.
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8,
            runSpacing: 8,
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

/// The per-farm options sheet.
///
/// [access] decides which options appear. Every one of these actions is gated
/// server-side; offering all of them to everybody meant a partner with view
/// access could tap Delete farm and be told "Failed to delete" — a 403 dressed
/// up as a fault. The rules mirror the API exactly:
///
///   * Add today's quantity → create access
///   * Edit farm details    → edit access
///   * Delete farm          → delete access
///   * Set Up Access (either role) → anyone holding access may pass on what
///     they hold, capped server-side at their own permissions.
void showFarmBottomSheet({
  required BuildContext context,
  required String farmName,
  required FarmAccess access,
  required VoidCallback onAddTankQty,
  required VoidCallback onManagerAccess,
  required VoidCallback onPartnerAccess,
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
                  // Expanded: a farm name long enough to reach the close
                  // button pushed it off the sheet and overflowed the row.
                  Expanded(
                    child: Text(
                      farmName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Recording feed is a create, not an edit — matches
              // `farm.access:create` on /tanks/add-todays-tanks-quantity.
              if (access.canCreate)
                _sheetItem(
                  icon: Icons.layers,
                  title: "Add today's tanks quantity",
                  onTap: onAddTankQty,
                ),

              // One row per role, each carrying the role all the way through
              // to the access list and the add form.
              //
              // This was three rows: a combined "Manager or Partner" setup,
              // plus separate Partners and Manager entries that opened the old
              // address-book screens. The farmer had to pick the role twice —
              // once here and again in a dropdown — and the two list screens
              // showed people who did not necessarily hold any access.
              //
              // Not owner-only: the members endpoint lets anyone with access
              // pass on what they hold, so a manager can appoint someone too.
              if (access.canShareAccess) ...[
                _sheetItem(
                  icon: Icons.person,
                  title: "Set Up Access for Manager",
                  onTap: onManagerAccess,
                ),

                _sheetItem(
                  icon: Icons.group,
                  title: "Set Up Access for Partner",
                  onTap: onPartnerAccess,
                ),
              ],

              if (access.canEdit)
                _sheetItem(
                  icon: Icons.edit,
                  title: "Edit farm Details",
                  onTap: onEditFarm,
                ),

              if (access.canDelete)
                _sheetItem(
                  icon: Icons.delete,
                  title: "Delete farm",
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // User must tap a button to close
                      builder: (BuildContext context) {
                        return CustomConfirmationDialog(ontapYes: onDeleteFarm);
                      },
                    );
                  },
                ),

              // A partner given view access only would otherwise be shown an
              // empty sheet with no explanation.
              if (!access.canCreate &&
                  !access.canEdit &&
                  !access.canDelete &&
                  !access.canShareAccess)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'You have view-only access to this farm.',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
  final String store;
  final String activeCount;
  final String inactiveCount;
  final List<String> imageUrls;
  final String id;
  final int noOfTanks;
  final String stockingDate;
  final String lowFeedLimit;

  /// Feed recorded against the farm so far — the sum of every feed entry.
  ///
  /// The same figure the farm detail screen shows in its header, because both
  /// come from the same `Feed::sum('feed_quantity')` server-side.
  final num totalFeedUsed;

  /// [totalFeedUsed] without a pointless ".0" on a whole number.
  String get totalFeedUsedLabel => totalFeedUsed % 1 == 0
      ? totalFeedUsed.toStringAsFixed(0)
      : totalFeedUsed.toStringAsFixed(2);

  /// The stock figure, or an em dash when the farmer has not entered one.
  ///
  /// Store is optional, so this can genuinely be unset — which is not the same
  /// as a store of zero and should not be shown as one.
  String get storeLabel => store.trim().isEmpty ? '—' : '$store kgs';

  /// The figure entered as "feed already used", if any.
  final num? feedUsedBefore;

  /// What the logged-in farmer may do with this farm — owner, or a manager or
  /// partner with whatever the grant gave them.
  final FarmAccess access;

  FarmSection({
    this.access = const FarmAccess.ownerFallback(),
    required this.lowFeedLimit,
    required this.noOfTanks,
    this.totalFeedUsed = 0,
    this.feedUsedBefore,
    required this.name,
    required this.store,
    required this.activeCount,
    required this.inactiveCount,
    required this.imageUrls,
    required this.stockingDate,
    required this.id,
  });
}

/// The farm photo on a farm card.
///
/// A farm can have several images; the card used to render only `imageUrls[0]`
/// with no way to reach the rest. This pages through them and shows a counter
/// when there is more than one, matching the edit form's carousel.
class _FarmImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _FarmImageCarousel({required this.imageUrls});

  @override
  State<_FarmImageCarousel> createState() => _FarmImageCarouselState();
}

class _FarmImageCarouselState extends State<_FarmImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shown while an image loads and when it fails.
  ///
  /// Deliberately NOT a stock photo: falling back to farmer_fish.png made a
  /// farm look like it had an image that was not the one the farmer uploaded.
  /// A shimmer says "nothing to show here" without lying about the content.
  Widget _fallback() => const AppShimmer(
        child: ShimmerBlock(height: 150, width: double.infinity, radius: 0),
      );

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    if (urls.isEmpty) {
      return SizedBox(height: 150, width: double.infinity, child: _fallback());
    }

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Image.network(
              // Stored urls may name an old host — re-pointed at this server.
              resolveMediaUrl(urls[i]),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, st) => _fallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _fallback(),
            ),
          ),

          // Only worth showing when there is somewhere to swipe to.
          if (urls.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_index + 1}/${urls.length}",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _index ? 16 : 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
