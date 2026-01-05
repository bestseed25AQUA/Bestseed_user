import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/booking_review_widget.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/controller/location_controller.dart';
import 'package:seedsuser/app/home/map_search_screen.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({
    super.key,
    required this.hatcheryId,
    required this.hatcheryName,
    this.isSpotHatchery,
    required this.categoryId,
    required this.price,
  });
  final String hatcheryId;
  final String hatcheryName;
  final bool? isSpotHatchery;
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

  // String? _selectedUnit;
  // String? _selectedPickupLocation;
  String? _selectedSalinity;

  // final List<String> _units = ["Unit 1", "Unit 2"];
  // final List<String> _locations = ["Location A", "Location B"];
  final List<String> _salinity = List.generate(41, (index) => '$index');

  Position? currentPosition;
  getCurrentLocation() async {
    currentPosition = await _getCurrentLocation();
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

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
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
    super.dispose();
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
    // TODO: implement initState
    getCurrentLocation();
    super.initState();
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
                  width: MediaQuery.of(context).size.width*.7,
                  child: Text(
                    "Booking at \n${widget.hatcheryName}",
                    style: GoogleFonts.roboto(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            ),
            Row(
              children: [
                Text(
                  'Estimated Price',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Builder(
                  builder: (context) {
                    return Text(
                      calculatePrice(_phoneController.text, widget.price),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildTextField(
              controller: _dropLocController,
              iconColor: Colors.blue,
              label: "Dropping location",
              hint: "Enter your Dropping location",
              icon: Icons.location_on_outlined,
              ontapSuffix: () async {
                print(currentPosition?.latitude);
                print(currentPosition?.longitude);
                // return;
                if (currentPosition == null ||
                    currentPosition?.latitude == null ||
                    currentPosition?.longitude == null) {
                  currentPosition = await getCurrentLocation();
                }
                if (currentPosition?.latitude != null &&
                    currentPosition?.longitude != null) {
                  await Get.to(
                    () => GoogleMapSearchPlacesScreen(
                      latitude: currentPosition!.latitude,
                      longitude: currentPosition!.longitude,
                      ontapSelectLocation: (location) async {
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                              location.latitude,
                              location.longitude,
                            );
                        Placemark place = placemarks.first;
                        String fullAddress =
                            "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
                        fullAddress = fullAddress
                            .replaceAll(RegExp(r', ,'), ',')
                            .replaceAll(RegExp(r',,'), ',')
                            .trim();
                        if (fullAddress.endsWith(',')) {
                          fullAddress = fullAddress.substring(
                            0,
                            fullAddress.length - 1,
                          );
                        }
                        setState(() {
                          _dropLocController.text = fullAddress;
                        });
                      },
                    ),
                  );
                }
              },
            ),

            _buildDateField(
              controller: _dateController,
              label: "Preferred date",
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

                  if (_phoneController.text.trim().length != 10) {
                    _showError("Enter valid 10 digit phone number");
                    return;
                  }
                  if (_unitController.text.isEmpty) {
                    _showError("Please select unit");
                    return;
                  }

                  if (_piecesController.text.trim().isEmpty) {
                    _showError("Please enter number of pieces");
                    return;
                  }

                  if (int.tryParse(_piecesController.text.trim()) == null ||
                      int.parse(_piecesController.text.trim()) <= 0) {
                    _showError("Enter valid number of pieces");
                    return;
                  }
                  if (_dateController.text.trim().isEmpty) {
                    _showError("Please select date");
                    return;
                  }
                  Navigator.pop(context);
                  _showBookingReviewSheet(
                    context,
                    widget.isSpotHatchery ?? false,
                    calculatePrice(_piecesController.text, widget.price),
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
    String? estimatePrice,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.8,
          maxChildSize: 0.8,
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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: BookingReviewContent(
                        bottomSheetContext: context,
                        estimatedPrice: estimatePrice ?? "",
                        categoryId: widget.categoryId,
                        isSpotHatchery: isSpotHatchery,
                        name: _nameController.text,
                        phone: _phoneController.text,
                        unit: _unitController.text,
                        pieces: _piecesController.text,
                        location: _dropLocController.text,
                        date: _dateController.text,
                        hatcheryId: widget.hatcheryId,
                        hatcheryName: widget.hatcheryName,
                        locationId: '',
                      ),
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
          // Text(
          //   label,
          //   style: GoogleFonts.roboto(
          //     fontWeight: FontWeight.w500,
          //     fontSize: 14,
          //   ),
          // ),
          const SizedBox(height: 4),
          SizedBox(
            height: 35,
            child: TextField(
              maxLength: maxLength,
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                counter: SizedBox(),
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14),
                suffixIcon: InkWell(
                  onTap: ontapSuffix,
                  child: Icon(icon, color: iconColor ?? Colors.grey),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
  
  return  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Salinity",
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38, // 👈 exact height control
                        child: CustomDropdown<String>(
                          selectedValue: _selectedSalinity,
                          items: _salinity,
                          hintText: "Select salinity",
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
                  );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(height: 8),
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
             Center(
              child: DropdownButtonFormField<String>(
                isDense: true, isExpanded: true,
                padding: EdgeInsets.all(0),
                initialValue: items.contains(value) ? value : null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                 contentPadding: EdgeInsets.only(bottom: 13),
                ),
                hint: Text(hint),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: TextField(
              controller: controller,
              readOnly: true,
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
                hintStyle: TextStyle(fontSize: 14),
                hintText: hint,
                suffixIcon: const Icon(
                  Icons.calendar_today,
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
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
