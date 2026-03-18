import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/home/model/hatchery_filter_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
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
  final FilterHatcheryController filterHatcheryController = Get.find();

  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  final TextEditingController _hatcheryNameController = TextEditingController();

  // Dropdown selections
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _autoFillUserData();
  }

  void _autoFillUserData() {
    try {
      final profileController = Get.find<ProfileController>();
      final profile = profileController.profile.value;

      if (profile != null) {
        final firstName = profile.firstName ?? '';
        final lastName = profile.lastName ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          _nameController.text = fullName;
        }

        if (profile.mobile != null && profile.mobile!.isNotEmpty) {
          _phoneController.text = profile.mobile!;
        }
      }
    } catch (e) {
      debugPrint('Profile not available for auto-fill: $e');
    }
  }

  String _packingDate = 'DD/MM/YYYY';
  String _packingDateForApi = ''; // Store date in YYYY-MM-DD format for API

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        // Display format for user
        _packingDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        // API format (YYYY-MM-DD)
        _packingDateForApi =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
      if (_packingDateForApi.isEmpty) {
        CustomToast.error("Please select packing date");
        return;
      }

      controller.sendSeedRequest(
        categoryId: _selectedCategory!.id,
        hatcheryName: _hatcheryNameController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _phoneController.text.trim(),
        pieces: int.parse(_piecesController.text.trim()),
        droppingLocation: _deliveryController.text.trim(),
        packingDate: _packingDateForApi,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget gap = const SizedBox(height: 0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: const Text('Seed requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NAME
              _buildTextFormField(
                label: "Name",
                hint: "Enter your name",
                controller: _nameController,
                // icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? "Please enter your name" : null,
              ),
              gap,

              // PHONE
              _buildTextFormField(
                label: "Phone number",
                hint: "Enter your Phone number",
                controller: _phoneController,
                // icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) =>
                    v!.isEmpty ? "Please enter phone number" : null,
              ),
              gap,

              // CATEGORY
              Text(
                "Categories",
                style: GoogleFonts.roboto(
                  fontSize: 14,
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
              gap,

              const SizedBox(height: 8),
              // BRANDS
              _buildTextFormField(
                label: "Hatchery Name",
                hint: "Enter hatchery name (optional)",
                controller: _hatcheryNameController,
              ),
              gap,

              const SizedBox(height: 8),
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
              gap,

              const SizedBox(height: 8),
              // DROPPING LOCATION (TEXTFIELD ONLY)
              _buildTextFormField(
                label: "Dropping location",
                hint: "Enter your Dropping location",
                controller: _deliveryController,
                // icon: Icons.location_on_outlined,
                validator: (v) =>
                    v!.isEmpty ? "Please enter dropping location" : null,
              ),
              gap,
              // PACKING DATE
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextFormField(
                    label: "Packing Date",
                    hint: _packingDate,
                    icon: Icons.calendar_today,
                    vericalPadding: 0,
                    readOnly: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: 30,
                ),
                child: Obx(() {
                  return SizedBox(
                    height: 40,
                    child: CustomButton(
                      verticalPadding: 0,
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
            ],
          ),
        ),
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
    double? vericalPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,

          decoration: InputDecoration(
            // IMPORTANT FOR HEIGHT + ERROR
            isDense: true,
            helperText: ' ', // reserves space for error
            hintText: hint,
            suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: vericalPadding ?? 8, //  controls field height
            ),

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
              borderSide: BorderSide(color: Colors.grey.withOpacity(.6)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
