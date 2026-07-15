import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';

class AddFarmerDetailsFormScreen extends StatefulWidget {
  const AddFarmerDetailsFormScreen({super.key, this.farmData});
  final FarmData? farmData;

  @override
  State<AddFarmerDetailsFormScreen> createState() =>
      _AddFarmerDetailsFormScreenState();
}

class _AddFarmerDetailsFormScreenState
    extends State<AddFarmerDetailsFormScreen> {
  final FarmListController controller = Get.put(FarmListController());

  final TextEditingController farmName = TextEditingController();
  final TextEditingController stockingDate = TextEditingController();
  final TextEditingController store = TextEditingController();
  final TextEditingController lowFeedLimit = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  List<Map<String, String>> images = [];
  int? selectedTanks;

  final List<int> tankOptions = List.generate(50, (i) => i + 1);

  Future<void> pickImages() async {
    final List<XFile>? files = await _picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      setState(() {
        for (var value in files) {
          images.add({'local': value.path});
        }
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? pick = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pick != null) {
      stockingDate.text =
          "${pick.year}-${pick.month.toString().padLeft(2, '0')}-${pick.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.farmData != null) {
      farmName.text = widget.farmData!.farmName ?? "";
      stockingDate.text = widget.farmData!.stockingDate ?? "";
      store.text = widget.farmData!.store ?? "";
      lowFeedLimit.text = widget.farmData!.lowFeedLimit ?? "";
      selectedTanks = widget.farmData!.noOfTanks;
      if (widget.farmData!.images?.imagesList != null) {
        for (var value in widget.farmData!.images!.imagesList!) {
          images.add({'network': value});
        }
      }
    }
  }

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.farmData != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => safeBack(),
        ),
        title: Text(
          "Fill form",
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Farm Images
                Text(
                  "Upload Farm Images",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildImageUploadArea(),
                const SizedBox(height: 24),

                // Farm Name
                _buildLabel("Farm Name"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: farmName,
                  hint: "Enter Farm Name",
                ),
                const SizedBox(height: 20),

                // Stocking Date
                _buildLabel("Stocking Date"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: stockingDate,
                  hint: "Select Date",
                  readOnly: true,
                  onTap: pickDate,
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // No. of Tanks (Dropdown)
                _buildLabel("No. of Tanks"),
                const SizedBox(height: 8),
                _buildTanksDropdown(),
                const SizedBox(height: 20),

                // Store
                _buildLabel("Store"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: store,
                  hint: "Enter Store",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Low Feed Limit with info tooltip
                Row(
                  children: [
                    _buildLabel("Low feed Limit"),
                    const SizedBox(width: 6),
                    Tooltip(
                      message:
                          "Once the feed limit is reached, all farm\npartners and managers will get a notification",
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: lowFeedLimit,
                  hint: "Enter Low Feed Limit",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 36),

                // Save Button
                Obx(() {
                  return CustomButton(
                    text: isEdit ? "Update" : "Save",
                    isLoading: controller.isOverlay.value,
                    borderRadius: 12,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      if (images.isEmpty) {
                        CustomToast.show(
                          message: "Please upload at least 1 image",
                        );
                        return;
                      }

                      if (selectedTanks == null) {
                        CustomToast.show(
                          message: "Please select number of tanks",
                        );
                        return;
                      }

                      bool success = false;

                      if (isEdit) {
                        success = await controller.updateFarmData(
                          farmId: widget.farmData!.id!,
                          farmName: farmName.text,
                          stockingDate: stockingDate.text,
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: selectedTanks.toString(),
                          imagePaths: images
                              .where((item) => item.containsKey('local'))
                              .map((item) => item['local'].toString())
                              .toList(),
                        );
                      } else {
                        success = await controller.uploadFarmData(
                          farmName: farmName.text,
                          stockingDate: stockingDate.text,
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: selectedTanks.toString(),
                          imagePaths: images
                              .where((item) => item.containsKey('local'))
                              .map((item) => item['local'].toString())
                              .toList(),
                        );
                      }
                      if (success) {
                        safeBack();
                        Get.find<FarmListController>().fetchFarmList();
                      }
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Image Upload Area ───
  Widget _buildImageUploadArea() {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: pickImages,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Upload Images",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "PNG, JPEG",
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CarouselSlider.builder(
            itemCount: images.length + 1,
            options: CarouselOptions(
              height: 180,
              enlargeCenterPage: true,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              if (index == images.length) {
                return GestureDetector(
                  onTap: pickImages,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add More",
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var map = images[index];
              bool isLocal = map.containsKey('local');
              bool isNetwork = map.containsKey('network');

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isLocal
                        ? Image.file(
                            File(map['local'].toString()),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(height: 180);
                            },
                          )
                        : isNetwork
                            ? CustomNetworkImage(
                                imageUrl: map['network'] ?? '',
                                width: double.infinity,
                                height: 180,
                              )
                            : const SizedBox(),
                  ),
                  // Delete Button
                  if (isLocal)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            images.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Image Counter
                  if (images.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${currentIndex + 1}/${images.length}",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Label Widget ───
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // ─── Text Field Widget ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$hint is required";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // ─── Tanks Dropdown Widget ───
  Widget _buildTanksDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTanks,
      hint: Text(
        "Select No. of Tanks",
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
      ),
      style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      items: tankOptions.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text("$value"),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedTanks = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return "Please select number of tanks";
        }
        return null;
      },
    );
  }
}
