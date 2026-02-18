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
          body: Obx(() => pages[controller.currentIndex.value]),
          floatingActionButton: Obx(() {
            if (controller.currentIndex.value != 0) return const SizedBox();
            if (!_bookingController.hasInProgressBooking) return const SizedBox();
            final booking = _bookingController.inProgressBooking;
            if (booking == null) return const SizedBox();
            final inProgressCount = _bookingController.inProgressBookingCount;
            return GestureDetector(
              onTap: () {
                if (inProgressCount == 1) {
                  Get.to(() => VehicleTrackingMapScreen(
                        bookingId: booking.bookingId.toString(),
                      ));
                } else {
                  Get.to(() => const VehicleTrackingPage());
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup Started",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Vehicle Status",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Obx(
            () => ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              child: BottomNavigationBar(
                currentIndex: controller.currentIndex.value,
                selectedItemColor: Color(0xff0076BE),
                unselectedItemColor: Colors.black,
                backgroundColor: Colors.white, // AppColors.primary,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                onTap: (index) => controller.changeIndex(index),
                items: List.generate(
                  icons.length,
                  (index) => BottomNavigationBarItem(
                    icon: Image.asset(
                      index == controller.currentIndex.value
                          ? filledIcon[index]
                          : icons[index],

                      color: !(2 == controller.currentIndex.value)
                          ? Color(0xff0076BE)
                          : null,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox();
                      },  
                      height: index == controller.currentIndex.value? 30:25,
                      width:  index == controller.currentIndex.value? 30:25,
                    ),
                    label: labels[index],
                    backgroundColor: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
