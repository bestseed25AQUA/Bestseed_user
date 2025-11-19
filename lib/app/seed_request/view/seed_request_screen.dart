import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/seed_request/controller/seed_request_controller.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';

import '../../home/model/brand_model.dart' show BrandModel;

class SeedRequestsFormScreen extends StatefulWidget {
  const SeedRequestsFormScreen({super.key});

  @override
  State<SeedRequestsFormScreen> createState() => _SeedRequestsFormScreenState();
}

class _SeedRequestsFormScreenState extends State<SeedRequestsFormScreen> {
  final SeedRequestController controller = Get.put(SeedRequestController());
  final HomeController homeController = Get.find();

  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();

  // Dropdown selections
  Category? _selectedCategory;
  BrandModel? _selectedBrand;

  String _packingDate = 'DD/MM/YYYY';

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

  // ----------------- Submit form ----------------
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        CustomToast.error("Please select category");
        return;
      }
      if (_selectedBrand == null) {
        CustomToast.error("Please select brand");
        return;
      }
      if (_packingDate == "DD/MM/YYYY") {
        CustomToast.error("Please select packing date");
        return;
      }

      controller.sendSeedRequest(
        categoryId: _selectedCategory!.id,
        brandId: _selectedBrand!.id,
        name: _nameController.text.trim(),
        mobile: _phoneController.text.trim(),
        pieces: int.parse(_piecesController.text.trim()),
        droppingLocation: _deliveryController.text.trim(),
        packingDate: _packingDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Seed requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NAME
              _buildTextFormField(
                label: "Name",
                hint: "Enter your name",
                controller: _nameController,
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 16),

              // PHONE
              _buildTextFormField(
                label: "Phone number",
                hint: "Enter your Phone number",
                controller: _phoneController,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) =>
                    v!.isEmpty ? "Please enter phone number" : null,
              ),
              const SizedBox(height: 16),

              // CATEGORY
              Text(
                "Categories",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              CustomDropdown<Category>(
                selectedValue: _selectedCategory,
                items: homeController.categories,
                hintText: "Select category",
                itemLabel: (c) => c.categoryName,
                onChanged: (v) {
                  setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),

              // BRANDS
              Text(
                "Brands",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              CustomDropdown<BrandModel>(
                selectedValue: _selectedBrand,
                items: homeController.brands,
                hintText: "Select brands",
                itemLabel: (b) => b.brandName,
                onChanged: (v) {
                  setState(() => _selectedBrand = v);
                },
              ),
              const SizedBox(height: 16),

              // PIECES
              _buildTextFormField(
                label: "No.of Pieces",
                hint: "Enter no. of pieces",
                controller: _piecesController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v!.isEmpty ? "Please enter number of pieces" : null,
              ),
              const SizedBox(height: 16),

              // DROPPING LOCATION (TEXTFIELD ONLY)
              _buildTextFormField(
                label: "Dropping location",
                hint: "Enter your Dropping location",
                controller: _deliveryController,
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v!.isEmpty ? "Please enter dropping location" : null,
              ),
              const SizedBox(height: 16),

              // PACKING DATE
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextFormField(
                    label: "Packing Date",
                    hint: _packingDate,
                    icon: Icons.calendar_today,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return SizedBox(
            height: 50,
            child: CustomButton(
              text: controller.isBooking.value
                  ? "Please wait..."
                  : "Send request",
              isLoading: controller.isBooking.value,
              onPressed: controller.isBooking.value
                  ? () {}
                  : () => _submitForm(),
            ),
          );
        }),
      ),
    );
  }

  // ---------------- TextField Builder ----------------
  Widget _buildTextFormField({
    required String label,
    required String hint,
    TextEditingController? controller,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          readOnly: readOnly,

          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              
            ),
            focusedBorder:OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(.4)),
              
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
