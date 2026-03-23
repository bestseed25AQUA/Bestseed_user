import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/booking_review_widget.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/model/category_model.dart' as cat_model;
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({
    super.key,
    required this.hatcheryId,
    required this.hatcheryName,
    this.isSpotHatchery,
    this.isVehicleHatchery,
    required this.categoryId,
    required this.price,
  });
  final String hatcheryId;
  final String hatcheryName;
  final bool? isSpotHatchery;
  final bool? isVehicleHatchery;
  final String categoryId;
  final String price;

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _dropLocController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedSalinity;
  final List<String> _salinity = List.generate(41, (index) => '$index');

  Position? currentPosition;
  bool _isGettingLocation = false;
  double? _dropLat;
  double? _dropLng;

  Future<Position?> getCurrentLocation() async {
    currentPosition = await _getCurrentLocation();
    return currentPosition;
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CustomToast.show(message: 'location is not enabled');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomToast.show(message: 'Permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      CustomToast.show(message: 'Permission Permanently denied');
      return null;
    }

    // Try last known position first for speed
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && currentPosition == null) {
      currentPosition = lastKnown;
    }

    // Then get accurate position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    print('====current location get successfully=======');
    return position;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _piecesController.dispose();
    _dateController.dispose();
    _unitController.dispose();
    _dropLocController.dispose();
    super.dispose();
  }

  void _openMapScreen(NavigatorState navigator) {
    final double lat = currentPosition!.latitude;
    final double lng = currentPosition!.longitude;

    navigator.push<bool>(
      MaterialPageRoute(
        builder: (ctx) => GoogleMapSearchPlacesScreen(
          latitude: lat,
          longitude: lng,
          ontapSelectLocation: (location, fullAddress) {
            if (mounted) {
              setState(() {
                _dropLocController.text = fullAddress;
                _dropLat = location.latitude;
                _dropLng = location.longitude;
              });
            }
          },
        ),
      ),
    );
  }

  String calculatePrice(String noOfPices, String price) {
    try {
      return (double.parse(noOfPices) * double.parse(price)).toString();
    } catch (e) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _autoFillUserData();
  }

  /// Auto-fill name and phone from user profile
  void _autoFillUserData() {
    try {
      final profileController = Get.find<ProfileController>();
      final profile = profileController.profile.value;

      if (profile != null) {
        // Auto-fill name (combine first and last name)
        final firstName = profile.firstName ?? '';
        final lastName = profile.lastName ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          _nameController.text = fullName;
        }

        // Auto-fill phone number
        if (profile.mobile != null && profile.mobile!.isNotEmpty) {
          _phoneController.text = profile.mobile!;
        }
      }
    } catch (e) {
      // ProfileController not registered yet, ignore
      if (kDebugMode) {
        print('Profile not available for auto-fill: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * .7,
                  child: Text(
                    "Booking at ${widget.hatcheryName}",
                    style: GoogleFonts.roboto(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              label: "Name",
              hint: "Enter your name",
              isMendatory: true,
              icon: Icons.person,
            ),
            _buildTextField(
              isMendatory: true,
              controller: _phoneController,
              label: "Phone number",
              hint: "Enter your Phone number",
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            // Category (auto-filled, read-only)
            Builder(
              builder: (context) {
                String categoryName = '';
                try {
                  final homeCtrl = Get.find<HomeController>();
                  final catId = int.tryParse(widget.categoryId) ?? 0;
                  final cat = homeCtrl.categories.firstWhere(
                    (c) => c.id == catId,
                    orElse: () => cat_model.Category(id: -1, categoryName: ''),
                  );
                  if (cat.id != -1) categoryName = cat.categoryName;
                } catch (_) {}

                if (categoryName.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Category",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, size: 18, color: Colors.grey[500]),
                            const SizedBox(width: 10),
                            Text(
                              categoryName,
                              style: GoogleFonts.roboto(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // _buildDropdownField(
            //   label: "Unit",
            //   hint: "Select Unit",
            //   value: _selectedUnit,
            //   items: _units,
            //   onChanged: (v) {
            //     setState(() => _selectedUnit = v);
            //   },
            // ),
            _buildTextField(
              controller: _unitController,
              label: "Unit",
              hint: "Enter Unit",
              icon: Icons.format_list_numbered,
              keyboardType: TextInputType.name,
            ),
            _buildDropdownField(
              label: "Salinity",
              hint: "Select salinity",
              value: _selectedSalinity,
              items: _salinity,
              onChanged: (v) {
                setState(() {
                  _selectedSalinity = v;
                });
              },
            ),

            _buildTextField(
              controller: _piecesController,
              label: "No.of Pieces",
              hint: "Enter no.of pieces",
              icon: Icons.format_list_numbered,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {}); // Rebuild to update estimated price
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Price:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _piecesController.text.isNotEmpty && widget.price.isNotEmpty
                        ? '₹${calculatePrice(_piecesController.text, widget.price)}'
                        : '₹0',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _dropLocController,
              iconColor: Colors.blue,
              label: "Dropping location",
              hint: _isGettingLocation ? "Getting location..." : "Tap to select location from map",
              icon: Icons.location_on_outlined,
              readOnly: true,
              ontapSuffix: () async {
                // Prevent double tap
                if (_isGettingLocation) return;

                // Capture navigator before async gap
                final navigator = Navigator.of(context);

                // If location already available, open map immediately
                if (currentPosition != null) {
                  _openMapScreen(navigator);
                  return;
                }

                // Show loading while getting location
                setState(() => _isGettingLocation = true);
                currentPosition = await getCurrentLocation();
                if (!mounted) return;
                setState(() => _isGettingLocation = false);

                if (currentPosition == null) {
                  CustomToast.show(
                    message:
                        'Unable to get current location. Please enable location services.',
                  );
                  return;
                }

                _openMapScreen(navigator);
              },
            ),

            _buildDateField(
              controller: _dateController,
              label: "Preferred delivery date",
              hint: "DD/MM/YYYY",
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: CustomButton(
                verticalPadding: 0,
                textStyle: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () {
                  if (kDebugMode) {
                    print('validation here');
                  }

                  if (_nameController.text.trim().isEmpty) {
                    _showError("Please enter name");
                    return;
                  }

                  if (_phoneController.text.trim().isEmpty) {
                    _showError("Please enter phone number");
                    return;
                  }

                  final phone = _phoneController.text.trim();

                  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                    _showError("Enter a valid 10 digit phone number");
                    return;
                  }

                  // Reject all-same digits like 0000000000, 1111111111
                  if (RegExp(r'^(\d)\1{9}$').hasMatch(phone)) {
                    _showError("Enter a valid phone number");
                    return;
                  }

                  // Default pieces to 0 if not entered
                  String pieces = _piecesController.text.trim().isEmpty
                      ? "0"
                      : _piecesController.text.trim();

                  Navigator.pop(context);
                  _showBookingReviewSheet(
                    context,
                    widget.isSpotHatchery ?? false,
                    widget.isVehicleHatchery ?? false,
                    calculatePrice(pieces, widget.price),
                    pieces,
                    _selectedSalinity,
                  );
                },
                text: "Confirm Booking",
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    CustomToast.show(message: message);
  }

  void _showBookingReviewSheet(
    BuildContext context,
    bool isSpotHatchery,
    bool isVehicleHatchery,
    String? estimatePrice,
    String pieces,
    String? salinity,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.85,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Align(
                  //   alignment: Alignment.topRight,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.close),
                  //     onPressed: () => Navigator.pop(context),
                  //   ),
                  // ),
                  Expanded(
                    child: BookingReviewContent(
                        bottomSheetContext: context,
                        estimatedPrice: estimatePrice ?? "",
                        categoryId: widget.categoryId,
                        isSpotHatchery: isSpotHatchery,
                        isVehicleHatchery: isVehicleHatchery,
                        name: _nameController.text,
                        phone: _phoneController.text,
                        unit: _unitController.text,
                        salinity: salinity ?? '',
                        pieces: pieces,
                        location: _dropLocController.text,
                        dropLat: _dropLat,
                        dropLng: _dropLng,
                        date: _dateController.text,
                        hatcheryId: widget.hatcheryId,
                        hatcheryName: widget.hatcheryName,
                        locationId: '',
                      ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    VoidCallback? ontapSuffix,
    bool? isMendatory = false,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black,
              ),
              children: (isMendatory ?? false)
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ]
                  : [
                      TextSpan(
                        text: '',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: readOnly && ontapSuffix != null ? ontapSuffix : null,
            child: AbsorbPointer(
              absorbing: readOnly && ontapSuffix != null,
              child: TextField(
                maxLength: maxLength,
                controller: controller,
                keyboardType: keyboardType,
                readOnly: readOnly,
                onChanged: onChanged,
                maxLines: readOnly ? 2 : 1,
                minLines: 1,
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  counter: SizedBox(),
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 13),
                  suffixIcon: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            child: CustomDropdown<String>(
              selectedValue: _selectedSalinity,
              items: _salinity,
              hintText: hint,
              backgroundColor: Colors.grey[100],
              itemLabel: (item) => item,
              onChanged: (value) {
                setState(() {
                  _selectedSalinity = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            child: TextField(
              controller: controller,
              readOnly: true,
              style: TextStyle(fontSize: 13),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null)
                  controller.text =
                      "${picked.day}/${picked.month}/${picked.year}";
              },
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 13),
                hintText: hint,
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
