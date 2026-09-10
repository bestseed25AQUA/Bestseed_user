import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/refresh_button.dart';
import 'package:seedsuser/app/help/contact_labels.dart';
import 'package:seedsuser/app/help/help_contact_service.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/contact_us_dialog.dart';
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
import 'package:seedsuser/app/farm_management/farmer/widget/farm_options.dart';
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

  /// True only while the app-bar refresh is running.
  ///
  /// Separate from the controller's isLoading so the shimmer can be shown for
  /// a button press without also firing during a pull-to-refresh, where
  /// swapping the body out would tear the gesture away mid-pull.
  bool _refreshing = false;

  /// Shared by the farm list and its Scrollbar, so the thumb tracks the list.
  /// A Scrollbar and its scroll view must be given the SAME controller, or the
  /// bar has no position to draw and throws.
  final ScrollController _listScrollController = ScrollController();

  /// The Manager tab's list. A SEPARATE controller, because a Scrollbar and its
  /// scroll view must be one-to-one — pointing both tabs at one controller
  /// gives it two positions to draw and throws the moment the bar paints.
  final ScrollController _managedScrollController = ScrollController();
  final tankController = Get.put(TankController());
  bool _isChatbotOpen = false;

  @override
  void dispose() {
    _listScrollController.dispose();
    _managedScrollController.dispose();
    super.dispose();
  }

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  /// Re-read the farm list.
  ///
  /// Held open for a minimum spell: against a local server the request comes
  /// back in single-digit milliseconds, so the button's spin would be over
  /// before it rendered and the tap would look like it did nothing.
  Future<void> _refreshList() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    final startedAt = DateTime.now();

    try {
      await controller.fetchFarmList();
    } finally {
      // Held open long enough to be seen. Against a local server the request
      // returns in single-digit milliseconds, so the shimmer would never get a
      // frame and the tap would look like it did nothing.
      const minimumSpin = Duration(milliseconds: 700);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minimumSpin) {
        await Future.delayed(minimumSpin - elapsed);
      }

      // finally, so a failed request cannot strand the screen in shimmer.
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Open a screen and re-read the farm list once it closes.
  ///
  /// Nearly everything reachable from here changes what the cards show:
  /// recording feed moves Total Feed Used, editing a farm rewrites the
  /// generated history behind it, adding a tank changes the count. None of
  /// those returns were refreshing the list, so a farmer came back to their own
  /// change missing and had to pull-to-refresh to see it.
  ///
  /// Cheap enough to do unconditionally — one request on the way back beats
  /// trying to guess which screens changed something.
  Future<void> _openThenRefresh(Widget screen) async {
    await Get.to(() => screen);
    if (mounted) await controller.fetchFarmList();
  }

  List<FarmSection> get farmSections {
    // `?? [] as List<FarmData>?` cast an empty List<dynamic>, which throws a
    // TypeError the moment it is reached — and it IS reached whenever the farm
    // list request fails, because this getter runs from build() as soon as
    // isLoading drops. A typed empty list cannot throw.
    final data = controller.farmList.value?.data ?? <FarmData>[];

    // The API returns farms oldest-first. Sort newest-first here so the most
    // recently added farm is at the TOP of the list.
    final ordered = [...data]..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    return ordered.map((e) {
      return FarmSection(
        lowFeedLimit: e.lowFeedLimit ?? '',
        noOfTanks: e.noOfTanks ?? 0,
        name: e.farmName ?? "Unknown Farm",
        // Empty, not "0 kgs": the card appends " kgs" itself, so that fallback
        // rendered "0 kgs kgs" — and store being unset is not a store of zero.
        store: e.store ?? '',
        remainingStore: e.remainingStore,
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

  /// Farms belonging in the "Farm" tab: the ones this farmer created, plus any
  /// they were made a PARTNER on. A partner stands beside the owner rather than
  /// working for them, so both sit in one list.
  List<FarmSection> _ownAndPartnered(List<FarmSection> all) =>
      all.where((f) => !f.access.isManagerGrant).toList();

  /// Farms belonging in the "Manager" tab — the ones somebody else made this
  /// farmer a manager of.
  List<FarmSection> _managed(List<FarmSection> all) =>
      all.where((f) => f.access.isManagerGrant).toList();

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
        actions: [
          // The shared button, as on the farm detail and tank screens.
          RefreshButton(onTap: _refreshList),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        final farms = farmSections;
        final own = _ownAndPartnered(farms);
        final managed = _managed(farms);

        // Shimmer on the FIRST load, and on an app-bar refresh.
        //
        // NOT during a pull-to-refresh: RefreshIndicator draws its own spinner
        // and swapping the body out would tear the gesture away mid-pull —
        // which is why this reads _refreshing rather than isLoading alone.
        final showShimmer =
            (controller.isLoading.value && farms.isEmpty) || _refreshing;

        // Cross-faded, so the list arrives rather than snapping in.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: showShimmer
              ? const FarmListShimmer(key: ValueKey('farm-shimmer'))
              : _farmListBody(context, primaryBlue, own, managed),
        );
      }),
    );
  }

  /// One scrolling list of farm cards.
  ///
  /// Lifted out of [_farmListBody] so the two tabs can each have one. Every
  /// list needs its OWN [scrollController]: a Scrollbar draws from the
  /// controller's position, and a controller attached to two lists at once has
  /// two, which throws as soon as the bar paints.
  Widget _farmScrollList(
    List<FarmSection> farms,
    ScrollController scrollController,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => controller.fetchFarmList(),
      // Same treatment as the tank list: a visible thumb, so a
      // farmer with more farms than fit on screen can see there
      // is more below and where they are in it.
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(8),
        thickness: 4,
        child: ListView.builder(
          controller: scrollController,
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
                onTap: () => _openThenRefresh(
                  FarmTankListScreen(
                    farmId: farms[index].id,
                    farmName: farms[index].name,
                    access: farms[index].access,
                  ),
                ),
                child: FarmCard(
                  farm: farms[index],
                  tankController: tankController,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The Farm / Manager tabs.
  ///
  /// Only reached when BOTH lists have something in them — see [_farmListBody].
  /// DefaultTabController rather than one built in initState, because whether
  /// there are tabs at all depends on data that arrives after this screen does,
  /// and can change under a refresh when a grant is given or revoked.
  Widget _tabbedLists(List<FarmSection> own, List<FarmSection> managed) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          ColoredBox(
            color: Colors.white,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 4,
              labelStyle: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Farm'),
                Tab(text: 'Manager'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE6E8EB)),
          Expanded(
            child: TabBarView(
              children: [
                _farmScrollList(own, _listScrollController),
                _farmScrollList(managed, _managedScrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The list itself, split out so the shimmer and it can be cross-faded.
  ///
  /// [own] is what the farmer created plus anything they partner on; [managed]
  /// is what someone else made them a manager of. The tabs appear only when
  /// there is something in both — with one bucket empty a tab bar would just be
  /// a header over the only list there is, and an empty tab beside it.
  Widget _farmListBody(
    BuildContext context,
    Color primaryBlue,
    List<FarmSection> own,
    List<FarmSection> managed,
  ) {
    final showTabs = own.isNotEmpty && managed.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (showTabs)
                _tabbedLists(own, managed)
              else
                _farmScrollList(
                  own.isNotEmpty ? own : managed,
                  _listScrollController,
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
                        _isChatbotOpen ? Icons.close : Icons.smart_toy_outlined,
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
              // Popup, not the bottom sheet: this matches the Contact Us
              // design. It reads the numbers the admin panel stores,
              // preferring the farm-management slot and falling back to
              // the first active contact when that slot is unset.
              showDialog(
                context: context,
                builder: (_) => const ContactUsDialog(
                  preferredLabel: ContactLabels.farmManagementHelp,
                ),
              );
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
  }
}

class FarmCard extends StatelessWidget {
  final FarmSection farm;
  const FarmCard({super.key, required this.farm, required this.tankController});
  final TankController tankController;

  /// Open a screen from the farm's options sheet and re-read the list after.
  ///
  /// Same reason as the screen's own version: recording feed and editing a farm
  /// both change what this card shows, and nothing was re-reading the list on
  /// the way back. Uses the shared controller directly — this card is
  /// stateless, and the list it feeds is a singleton.
  Future<void> _openThenRefresh(Widget screen) async {
    await Get.to(() => screen);
    await farmListController.fetchFarmList();
  }

  /// One "label: value" figure on a farm card.
  ///
  /// No maxLines and no ellipsis on purpose — see the Wrap that lays these
  /// out. A long figure wraps within itself rather than being cut short.
  Widget _farmFigure(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.roboto(fontSize: 14),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

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
                            _openThenRefresh(
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
                            _openThenRefresh(
                              AddFarmerDetailsFormScreen(
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
                // Wrap, not Row.
                //
                // A Row had to trim one of these to fit, and what it trimmed
                // was the end of the line — the FIGURE. "Total Feed Used:
                // 300…" is worse than useless: it reads as a number. A Wrap
                // never truncates; the two sit side by side while they fit and
                // the second drops to its own line when they do not, so the
                // full count is always readable.
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _farmFigure(
                      "Total Feed Used: ",
                      '${farm.totalFeedUsedLabel} kgs',
                    ),
                    // Named as the farm's own header names it, since it is now
                    // the same number — "Store" beside a remainder invited the
                    // reading that nothing had been used.
                    _farmFigure("Store: ", farm.storeLabel),
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
          // Full width, so the Wrap has room to centre within.
          //
          // The parent Column is crossAxisAlignment.start — which the heading
          // and body text want — so without this the Wrap shrank to the width
          // of its one button and sat against the left edge, and its own
          // `center` had nothing to centre inside.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              // center, not spaceAround: with Voice assist hidden there is only
              // one button, and spaceAround's intent (spread several evenly) no
              // longer describes what this row is doing.
              alignment: WrapAlignment.center,
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
                  onPressed: () => _openWhatsAppChat(context),
                ),
                // Voice Assist Button — hidden for now, wanted later.
                // _showVoiceAssistanceModal below is kept for the same reason.
                // OutlinedButton.icon(
                //   icon: const Icon(Icons.mic_none),
                //   label: const Text('Voice assist'),
                //   style: OutlinedButton.styleFrom(
                //     foregroundColor: primaryBlue,
                //     side: const BorderSide(color: primaryBlue),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 18,
                //       vertical: 10,
                //     ),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   onPressed: () {
                //     _showVoiceAssistanceModal(context);
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Open WhatsApp on the support number the admin panel stores.
  ///
  /// Same contact the farm's Contact Us popup uses — the farm-management slot,
  /// falling back to the first active contact when that slot is unset.
  Future<void> _openWhatsAppChat(BuildContext context) async {
    final contacts = await fetchActiveHelpContacts();

    final picked = contacts.isEmpty
        ? null
        : contacts.firstWhere(
            (c) =>
                contactLabelMatches(c.label, ContactLabels.farmManagementHelp),
            orElse: () => contacts.first,
          );

    final number = picked?.whatsapp?.trim();

    // Said out loud rather than silently doing nothing: launchHelpWhatsApp
    // would build "wa.me/" with no number and the tap would look broken.
    if (number == null || number.isEmpty) {
      CustomToast.error('No WhatsApp number configured yet');
      return;
    }

    await launchHelpWhatsApp(number);
  }

  /// Kept for the Voice assist button, which is commented out above until
  /// that feature is wanted again.
  // ignore: unused_element
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
/// Every option is always listed. [access] decides which are LIVE and which
/// are masked — greyed out, padlocked, and answering a tap with the reason
/// rather than opening. Every action is gated server-side too; leaving them all
/// live meant a partner with view access could tap Delete farm and be told
/// "Failed to delete", a 403 dressed up as a fault. Removing them instead hid
/// the fact that the feature exists at all, so a manager could not tell a
/// missing permission from a missing feature. The rules mirror the API exactly:
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
              _sheetItem(
                icon: Icons.layers,
                title: "Add today's tanks quantity",
                onTap: onAddTankQty,
                enabled: access.canCreate,
                deniedMessage:
                    "You don't have create access to this farm, so you can't record feed.",
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
              _sheetItem(
                icon: Icons.person,
                title: "Set Up Access for Manager",
                onTap: onManagerAccess,
                enabled: access.canShareAccess,
                deniedMessage: "You hold no access on this farm to pass on.",
              ),

              _sheetItem(
                icon: Icons.group,
                title: "Set Up Access for Partner",
                onTap: onPartnerAccess,
                enabled: access.canShareAccess,
                deniedMessage: "You hold no access on this farm to pass on.",
              ),

              _sheetItem(
                icon: Icons.edit,
                title: "Edit farm Details",
                onTap: onEditFarm,
                enabled: access.canEdit,
                deniedMessage: "You don't have edit access to this farm.",
              ),

              _sheetItem(
                icon: Icons.delete,
                title: "Delete farm",
                iconColor: Colors.red,
                textColor: Colors.red,
                enabled: access.canDelete,
                deniedMessage: "You don't have delete access to this farm.",
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

              // Says why the rows above are greyed out. Without it a manager
              // sees four padlocks and no explanation.
              if (!access.canCreate &&
                  !access.canEdit &&
                  !access.canDelete &&
                  !access.canShareAccess)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
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
/// One row of the farm options sheet.
///
/// [enabled] false renders the row MASKED rather than removing it: greyed out,
/// with a padlock where the chevron would be, and a tap that explains itself
/// instead of opening anything. Hiding a row left a manager wondering whether
/// the app had lost the feature or the farm had never had it; showing it
/// greyed says plainly that the action exists and they were not given it.
///
/// [deniedMessage] names the missing permission, so the answer is specific
/// rather than a blanket "not allowed".
Widget _sheetItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
  Color? textColor,
  bool enabled = true,
  String? deniedMessage,
}) {
  // One grey for the icon, the text and the padlock, so the whole row reads as
  // a single unavailable thing rather than three faded pieces.
  final disabledGrey = Colors.grey.shade400;

  return InkWell(
    onTap: enabled
        ? onTap
        : () => CustomToast.info(
            deniedMessage ?? "You don't have access to do this.",
          ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? (iconColor ?? Colors.black) : disabledGrey,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: enabled ? (textColor ?? Colors.black) : disabledGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // The padlock is the mask: an arrow on a row that goes nowhere reads
          // as a bug.
          Icon(
            enabled ? Icons.arrow_forward_ios : Icons.lock_outline,
            size: enabled ? 16 : 18,
            color: enabled ? null : disabledGrey,
          ),
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

  /// What is LEFT of the stock, as the farm detail screen shows it.
  final num? remainingStore;

  /// The remaining stock, or an em dash when the farmer has not entered one.
  ///
  /// What is LEFT, not what was put in: the raw store figure never moves as
  /// feed is recorded, so the card read as though nothing had been used while
  /// the farm's own header showed the remainder correctly.
  ///
  /// Store is optional, so this can genuinely be unset — which is not the same
  /// as a remainder of zero and should not be shown as one. Falls back to the
  /// raw figure only if the server sent no remainder at all.
  String get storeLabel {
    final left = remainingStore;
    if (left != null) {
      return '${left % 1 == 0 ? left.toStringAsFixed(0) : left.toStringAsFixed(2)} kgs';
    }

    return store.trim().isEmpty ? '—' : '$store kgs';
  }

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
    this.remainingStore,
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

  /// Shown only while an image is genuinely in flight.
  Widget _loading() => const AppShimmer(
    child: ShimmerBlock(height: 150, width: double.infinity, radius: 0),
  );

  /// Shown when there is no image, or the one on file will not load.
  ///
  /// Still deliberately NOT a stock photo: falling back to farmer_fish.png
  /// made a farm look like it had an image that was not the one the farmer
  /// uploaded. But a shimmer was wrong here too — it never resolves, so an
  /// imageless farm looked permanently stuck mid-load. Farm photos are
  /// optional, so "no photo" is a normal resting state and should look
  /// settled rather than pending.
  Widget _placeholder(String label) => Container(
    height: 150,
    width: double.infinity,
    color: Colors.grey.shade100,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.photo_outlined, size: 30, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    if (urls.isEmpty) {
      return _placeholder('No photos added');
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
              errorBuilder: (c, e, st) => _placeholder('Image unavailable'),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _loading(),
            ),
          ),

          // Only worth showing when there is somewhere to swipe to.
          if (urls.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
