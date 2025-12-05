import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/booking_review_widget.dart';

class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({
    super.key,
    required this.hatcheryId,
    required this.hatcheryName,
    this.isSpotHatchery,
    required this.categoryId,
  });
  final String hatcheryId;
  final String hatcheryName;
  final bool? isSpotHatchery;
  final String categoryId;

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

  String? _selectedUnit;
  String? _selectedPickupLocation;

  final List<String> _units = ["Unit 1", "Unit 2"];
  final List<String> _locations = ["Location A", "Location B"];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _piecesController.dispose();
    _dateController.dispose();
    _unitController.dispose();
    super.dispose();
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
                Text(
                  "Booking at Seven star\nHatcheries.",
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
              icon: Icons.person,
            ),
            _buildTextField(
              controller: _phoneController,
              label: "Phone number",
              hint: "Enter your Phone number",
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
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
            _buildTextField(
              controller: _piecesController,
              label: "No.of Pieces",
              hint: "Enter no.of pieces",
              icon: Icons.format_list_numbered,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              controller: _dropLocController,
              label: "Dropping location",
              hint: "Enter your Dropping location",
              icon: Icons.location_on,
            ),
            // _buildDropdownField(
            //   label: "Dropping location",
            //   hint: "Select your pickup location",
            //   value: _selectedPickupLocation,
            //   items: _locations,
            //   onChanged: (v) {
            //     setState(() => _selectedPickupLocation = v);
            //   },
            // ),
            _buildDateField(
              controller: _dateController,
              label: "Preferred date",
              hint: "DD/MM/YYYY",
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CustomButton(
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
                  );
                },
                text: "Confirm Booking",
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    CustomToast.show(message: message);
  }

  void _showBookingReviewSheet(BuildContext context, bool isSpotHatchery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.9,
          maxChildSize: 0.9,
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
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: BookingReviewContent(
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: Icon(icon, color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: InputBorder.none),
              hint: Text(hint),
              value: value,
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
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
              hintText: hint,
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
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
        ],
      ),
    );
  }
}
