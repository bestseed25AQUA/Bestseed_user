import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/home/map_screen.dart';

class BookingVehicleScreen extends StatefulWidget {
  const BookingVehicleScreen({super.key});

  @override
  State<BookingVehicleScreen> createState() => _BookingVehicleScreenState();
}

class _BookingVehicleScreenState extends State<BookingVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  'assets/images/SealCheck.png',
                  height: 109,
                  width: 109,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your request was recorded',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _pickDeliveryAddress() async {
    final selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    if (selectedAddress != null && selectedAddress is String) {
      setState(() {
        _deliveryController.text = selectedAddress;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking vehicle at Seven sta...'),
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
                "Pickup Address",
                _pickupController,
                Icons.location_on,
              ),
              _buildTextField(
                "Delivery Address",
                _deliveryController,
                Icons.location_on,
                readOnly: true,
                onTap: _pickDeliveryAddress, // <-- open map picker
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
      bottomNavigationBar: Container(
        height: 86,
        padding: const EdgeInsets.all(16.0),
        child: CustomButton(
          text: 'Send request',
          onPressed: () {
            // if (_formKey.currentState!.validate()) {
            _showConfirmationDialog();
            // }
          },
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
            'Seven Star Hatchery seeds',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('Prakasam, Andhra Pradesh'),
          const SizedBox(height: 16),
          Text(
            'Vehicle Driver Details',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.person),
              SizedBox(width: 8),
              Text('Ramesh'),
              Spacer(),
              Icon(Icons.phone),
              SizedBox(width: 8),
              Text('+91xxxxxxxxx'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.directions_car),
              SizedBox(width: 8),
              Text('TSN05656'),
            ],
          ),
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
              fontWeight: FontWeight.w400,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFFC1BFBF)),
              ),
              prefixIcon: Icon(icon),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
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
