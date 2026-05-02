import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/broadstock/view/broad_stock_screen.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/view/home_screen.dart';
import 'package:seedsuser/app/home/widget/location_permission_dialog.dart';
import 'package:seedsuser/app/news%20&%20ads/view/news_ads_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/seed_price/view/seed_price_screen.dart';
import 'package:seedsuser/app/updates/view/update_screen.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/vehicle_tracking/view/booking_vehicle_list_screen.dart';
import 'package:seedsuser/app/vehicle_tracking/view/vehicle_tracking_map_screen.dart';
import 'package:seedsuser/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final HomeController _homeController = Get.put(HomeController());
  final LocationController _locationController = Get.put(LocationController());
  final ProfileController _profileController = Get.put(ProfileController());
  final MyBookingController _bookingController = Get.put(MyBookingController());

  bool _isCheckingPermission = true;

  final List<Widget> pages = [
    HomeScreen(),
    SeedPricesScreen(),
    BroodStockScreen(),
    NewsAdsScreen(),
    UpdatesScreen(),
  ];

  final List<String> icons = [
    'assets/images/home.png',
    'assets/images/price.png',
    'assets/images/broodstock.png',
    'assets/images/news.png',
    'assets/images/updates.png',
  ];

  final List<String> filledIcon = [
    'assets/images/home_filled.png',
    'assets/images/price_filled.png',
    'assets/images/broodstock_filled.png',
    'assets/images/news_filled.png',
    'assets/images/updates_filled.png',
  ];

  late StreamSubscription subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  @override
  void initState() {
    super.initState();
    getConnectivity();
    _checkLocationPermission();
  }

  /// Check location permission on app start
  Future<void> _checkLocationPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    bool hasPermission =
        await LocationPermissionService.isLocationPermissionGranted();
    bool serviceEnabled =
        await LocationPermissionService.isLocationServiceEnabled();

    if (!hasPermission || !serviceEnabled) {
      setState(() {
        _isCheckingPermission = false;
      });
      // Show bottom sheet after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationBottomSheet();
      });
    } else {
      setState(() {
        _isCheckingPermission = false;
      });
      // Auto-detect current location
      _autoDetectLocation();
    }
  }

  /// Show location permission bottom sheet
  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              SystemNavigator.pop();
            }
          },
          child: LocationPermissionDialog(
            onEnable: () async {
              Navigator.pop(context);
              await _handleEnableLocation();
            },
          ),
        );
      },
    );
  }

  /// Handle enable location button press
  Future<void> _handleEnableLocation() async {
    final result = await LocationPermissionService.requestLocationPermission();

    switch (result) {
      case LocationPermissionResult.granted:
        // Permission granted, fetch location immediately
        _autoDetectLocation();
        break;

      case LocationPermissionResult.serviceDisabled:
        // GPS/Location service is disabled, show dialog to enable
        _showEnableGPSDialog();
        break;

      case LocationPermissionResult.deniedForever:
        // Permission permanently denied, show dialog to open app settings
        _showOpenSettingsDialog();
        break;

      case LocationPermissionResult.denied:
        // Permission denied, show bottom sheet again
        _showLocationBottomSheet();
        break;
    }
  }

  /// Show dialog when GPS/Location service is disabled
  void _showEnableGPSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 50,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Location Service Disabled',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable GPS/Location service on your device to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showLocationBottomSheet();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await LocationPermissionService.openLocationSettings();
                        // Check again after user returns from settings
                        await Future.delayed(const Duration(milliseconds: 500));
                        _checkAndRetryPermission();
                      },
                      child: Text(
                        'Open Settings',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog when permission is permanently denied
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                size: 50,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Location permission is required. Please enable it from app settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showLocationBottomSheet();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await LocationPermissionService.openAppSettings();
                        // Check again after user returns from settings
                        await Future.delayed(const Duration(milliseconds: 500));
                        _checkAndRetryPermission();
                      },
                      child: Text(
                        'Open Settings',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check permission again after returning from settings
  Future<void> _checkAndRetryPermission() async {
    bool hasPermission =
        await LocationPermissionService.isLocationPermissionGranted();
    bool serviceEnabled =
        await LocationPermissionService.isLocationServiceEnabled();

    if (hasPermission && serviceEnabled) {
      _autoDetectLocation();
    } else {
      _showLocationBottomSheet();
    }
  }

  /// Auto-detect current location
  Future<void> _autoDetectLocation() async {
    await _profileController.getProfile();
    final farmerId = _profileController.profile.value?.id.toString() ?? '';
    if (farmerId.isNotEmpty) {
      await _locationController.autoDetectCurrentLocation(farmerId: farmerId);
    }
  }

  void getConnectivity() {
    subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      bool currentStatus =
          await InternetConnectionChecker.createInstance().hasConnection;

      if (!currentStatus && !isAlertSet) {
        showDialogBox();
        setState(() => isAlertSet = true);
      } else if (currentStatus && isAlertSet) {
        if (mounted) {
          Navigator.pop(context);
        }
        setState(() => isAlertSet = false);
      }
    });
  }

  showDialogBox() => showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('No Connection'),
      content: const Text('Please check your internet connectivity'),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.pop(context, 'Cancel');
            setState(() => isAlertSet = false);
            isDeviceConnected =
                await InternetConnectionChecker.createInstance().hasConnection;
            if (!isDeviceConnected && isAlertSet == false) {
              showDialogBox();
              setState(() => isAlertSet = true);
            }
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<String> labels = [
      AppLocalizations.of(context).home,
      AppLocalizations.of(context).price,
      AppLocalizations.of(context).broadstock,
      AppLocalizations.of(context).news_ads,
      AppLocalizations.of(context).updates,
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () async { 
          print('++++++++++++++++++++++++');
          print(controller.currentIndex);
          // Show confirmation dialog 
          if (controller.currentIndex.value != 0) {
            controller.changeIndex(0);
            return false;
          } else {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false, // user must choose
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
                elevation: 4,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        size: 50,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exit App',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to close the app?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'No',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Yes',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            return result ?? false;
          }

          // Return true to exit, false to stay
        },
        child: Scaffold(
          body: Obx(() => IndexedStack(
                index: controller.currentIndex.value,
                children: pages,
              )),
          floatingActionButton: Obx(() {
            if (controller.currentIndex.value != 0) return const SizedBox();
            if (!_bookingController.hasInProgressBooking) return const SizedBox();
            final booking = _bookingController.inProgressBooking;
            if (booking == null) return const SizedBox();
            final inProgressCount = _bookingController.inProgressBookingCount;
            return _LiveTrackingFAB(
              count: inProgressCount,
              onTap: () {
                if (inProgressCount == 1) {
                  Get.to(() => VehicleTrackingMapScreen(
                        bookingId: booking.bookingId.toString(),
                      ));
                } else {
                  Get.to(() => const VehicleTrackingPage());
                }
              },
            );
          }),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Obx(() {
            final currentIdx = controller.currentIndex.value;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(icons.length, (index) {
                      final isSelected = index == currentIdx;
                      return Expanded(
                        child: InkWell(
                          onTap: () => controller.changeIndex(index),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Active indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                height: 3,
                                width: isSelected ? 24 : 0,
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Icon
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.all(isSelected ? 0 : 0),
                                child: Image.asset(
                                  isSelected
                                      ? filledIcon[index]
                                      : icons[index],
                                  height: isSelected ? 26 : 22,
                                  width: isSelected ? 26 : 22,
                                  color: isSelected
                                      ? (index == 2 ? null : AppColors.primary)
                                      : Colors.grey.shade500,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(height: 22, width: 22),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Label
                              Text(
                                labels[index],
                                style: GoogleFonts.roboto(
                                  fontSize: isSelected ? 11 : 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE TRACKING FAB — animated floating card with glow + pulse + slide-in
// ═══════════════════════════════════════════════════════════════════════════
class _LiveTrackingFAB extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _LiveTrackingFAB({required this.count, required this.onTap});

  @override
  State<_LiveTrackingFAB> createState() => _LiveTrackingFABState();
}

class _LiveTrackingFABState extends State<_LiveTrackingFAB>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Slide in from right
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _slideController.forward();

    // Breathing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Pulse for live dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0077C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077C8)
                        .withValues(alpha: _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Truck icon with white circle bg
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.local_shipping_rounded,
                            color: Colors.white, size: 22),
                        // Count badge
                        if (widget.count > 1)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.count}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing live dot
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80)
                                      .withValues(alpha: _pulseAnimation.value),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4ADE80)
                                          .withValues(
                                              alpha:
                                                  _pulseAnimation.value * 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Live Tracking",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.count > 1
                            ? "${widget.count} active deliveries"
                            : "Tap to track vehicle",
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: Colors.white70),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
