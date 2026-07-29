import 'dart:io';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileController profileController = Get.find<ProfileController>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  File? _profileImageFile; // Selected image file

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current profile data
    _firstNameController = TextEditingController(
      text: profileController.profile.value?.firstName ?? "",
    );
    _lastNameController = TextEditingController(
      text: profileController.profile.value?.lastName ?? "",
    );
  }

  Future<void> _pickImageFromGallery() async {
    // The API caps profile_image at 2048 KB and only accepts jpeg/png/jpg/gif.
    // Resizing + re-encoding here keeps full-resolution camera photos (often
    // 3-8 MB) under that limit, and converts iOS HEIC shots to JPEG, both of
    // which the server would otherwise reject with a 422.
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (profileController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileController.profile.value;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageFile != null
                            ? FileImage(_profileImageFile!)
                            : (profile?.profileImage != null
                                  ? NetworkImage(profile!.profileImage!)
                                        as ImageProvider
                                  : const AssetImage("assets/images/logo.png")),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImageFromGallery,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration("First Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter first name" : null,
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration("Last Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter last name" : null,
                ),
                const SizedBox(height: 16),

                // Phone (read-only)
                TextFormField(
                  controller: TextEditingController(
                    text: profile?.mobile ?? "N/A",
                  ),
                  readOnly: true,
                  decoration: _inputDecoration(
                    "Phone Number",
                  ).copyWith(suffixIcon: const Icon(Icons.lock)),
                ),
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: profileController.isUpdating.value
                ? null
                : () {
                    profileController.updateProfile(
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      profileImage: _profileImageFile,
                    );
                  },
            child: profileController.isUpdating.value
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    "Save",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          );
        }),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
