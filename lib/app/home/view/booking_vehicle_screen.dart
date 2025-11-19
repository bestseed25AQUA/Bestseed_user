import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/home/controller/vehicle_availability_controller.dart';
import 'package:seedsuser/app/home/map_screen.dart';
import 'package:seedsuser/app/model/vehicle_availability_model.dart';
import 'package:seedsuser/l10n/app_localizations.dart';

class BookingVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;
  const BookingVehicleScreen({super.key, required this.vehicle});

  @override
  State<BookingVehicleScreen> createState() => _BookingVehicleScreenState();
}

class _BookingVehicleScreenState extends State<BookingVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();

  final VehicleController _vehicleController = Get.find();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      _vehicleController
          .bookVehicle(
            vehicleNumber: widget.vehicle.vehicleNumber,
            hatcheryName: widget.vehicle.hatcheryName,
            name: _nameController.text.trim(),
            mobile: _phoneController.text.trim(),
            date: _dateController.text.trim(),
            deliveryAddress: _deliveryController.text.trim(),
            seedQuantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          )
          .then((_) {
            // _showConfirmationDialog();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Booking vehicle at ${widget.vehicle.hatcheryName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildVehicleInfoCard(),
              const SizedBox(height: 24),
              _buildTextField("Name", _nameController, Icons.person),
              _buildTextField(
                "Phone number",
                _phoneController,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildDateField(),
              _buildTextField(
                "Delivery Address",
                _deliveryController,
                Icons.location_on,
              ),
              _buildTextField(
                "Seed Quantity",
                _quantityController,
                Icons.grain,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          height: 86,
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            text: AppLocalizations.of(context).send_request,
            onPressed: _submitBooking,
            isLoading: _vehicleController.isBooking.value,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.vehicle.hatcheryName,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(widget.vehicle.hatcheryLocation ?? ''),
          // const SizedBox(height: 16),
          // Text(
          //   'Vehicle Driver Details',
          //   style: GoogleFonts.roboto(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   children: [
          //     const Icon(Icons.person),
          //     const SizedBox(width: 8),
          //     Text(widget.vehicle.driverName),
          //     const Spacer(),
          //     const Icon(Icons.phone),
          //     const SizedBox(width: 8),
          //     Text('+91${widget.vehicle.driverMobile}'),
          //   ],
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   children: [
          //     const Icon(Icons.directions_car),
          //     const SizedBox(width: 8),
          //     Text(widget.vehicle.vehicleNumber),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
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
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,

            decoration: InputDecoration(
              hintText: "Enter $label",

              // NEW DESIGN
              filled: true,
              fillColor: Colors.white,

              suffixIcon: Icon(icon, color: Colors.grey),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),

            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return _buildTextField(
      "Date",
      _dateController,
      Icons.calendar_today,
      readOnly: true,
      onTap: _pickDate,
    );
  }
}
