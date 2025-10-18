import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/home/map_screen.dart';

class SeedRequestsFormScreen extends StatefulWidget {
  const SeedRequestsFormScreen({super.key});

  @override
  State<SeedRequestsFormScreen> createState() => _SeedRequestsFormScreenState();
}

class _SeedRequestsFormScreenState extends State<SeedRequestsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _packingDate = 'DD/MM/YYYY';
  final _deliveryController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _packingDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Get.back();
      Get.to(() => ConfirmationScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Name Field
              _buildTextFormField(
                label: 'Name',
                hint: 'Enter your name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16.0),

              // Phone Number Field
              _buildTextFormField(
                label: 'Phone number',
                hint: 'Enter your Phone number',
                icon: Icons.phone_android,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 16.0),

              // No of Pieces Field
              _buildTextFormField(
                label: 'No of Pieces',
                hint: 'Enter no. of pieces',
                // icon: Icons.upload_file,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the number of pieces' : null,
              ),
              const SizedBox(height: 16.0),

              // Dropping location Field
              _buildTextFormField(
                label: 'Dropping location',
                hint: 'Select your Dropping location',
                controller: _deliveryController,

                icon: Icons.location_on_outlined,
                readOnly: true,
                onTap: () {
                  _pickDeliveryAddress();
                },
                validator: (value) =>
                    value!.isEmpty ? 'Please select a location' : null,
              ),
              const SizedBox(height: 16.0),

              // Packing Date Field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextFormField(
                    label: 'Packing Date',
                    hint: _packingDate,
                    icon: Icons.calendar_today,
                    readOnly: true,
                    // Note: Validation on _packingDate for actual value if needed
                  ),
                ),
              ),
              const SizedBox(height: 32.0),

              // Send request Button
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          child: CustomButton(text: 'Send request', onPressed: _submitForm),
        ),
      ),
    );
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

  Widget _buildTextFormField({
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,

            suffixIcon: icon != null
                ? Icon(icon, color: Colors.grey)
                : Padding(
                    padding: const EdgeInsets.only(right: 12.0),

                    child: SizedBox(
                      height: 12,
                      width: 12,
                      child: Image.asset(
                        'assets/images/pieces_icon.png',
                        height: 12,
                        fit: BoxFit.cover,
                        width: 12,
                      ),
                    ),
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
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }
}

// ---------------------------------------------
// 2. Request Sent Confirmation Screen
// ---------------------------------------------

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Blue checkmark icon
              Image.asset(
                'assets/images/SealCheck.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 24),
              // Main confirmation text
              Text(
                'Your \nrequest was sent',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Sub-text for notification
              Text(
                'We will notify you within 24 Hours',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
