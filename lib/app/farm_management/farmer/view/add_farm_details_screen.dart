import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_list_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/former_details_controller.dart';

class AddFarmerDetailsFormScreen extends StatefulWidget {
  const AddFarmerDetailsFormScreen({super.key, this.farmData});
  final FarmData? farmData;

  @override
  State<AddFarmerDetailsFormScreen> createState() =>
      _AddFarmerDetailsFormScreenState();
}

class _AddFarmerDetailsFormScreenState
    extends State<AddFarmerDetailsFormScreen> {
  final FarmerDetailController controller = Get.put(FarmerDetailController());

  final TextEditingController farmName = TextEditingController();
  final TextEditingController stockingDate = TextEditingController();
  final TextEditingController store = TextEditingController();
  final TextEditingController lowFeedLimit = TextEditingController();
  final TextEditingController tanks = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  final List<File> selectedImages = [];

  Future<void> pickImages() async {
    final List<XFile>? files = await _picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      setState(() {
        selectedImages.addAll(files.map((e) => File(e.path)).toList());
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? pick = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );
    if (pick != null) {
      stockingDate.text = "${pick.year}-${pick.month}-${pick.day}";
    }
  }

  @override
  void initState() {
    super.initState();

    /// ✅ Assign incoming farm values (Edit Mode)
    if (widget.farmData != null) {
      farmName.text = widget.farmData!.farmName ?? "";
      stockingDate.text = widget.farmData!.stockingDate ?? "";
      store.text = widget.farmData!.store ?? "";
      lowFeedLimit.text = widget.farmData!.lowFeedLimit ?? "";
      tanks.text = widget.farmData!.noOfTanks?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.farmData != null;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Farm Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker preview
                  GestureDetector(
                    onTap: pickImages,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImages.isEmpty
                          ? const Center(child: Text("Tap to upload images"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) => Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    child: Image.file(
                                      selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImages.removeAt(index);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        child: Icon(Icons.close, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  textField("Farm Name", farmName),
                  textField(
                    "Stocking Date",
                    stockingDate,
                    readOnly: true,
                    onTap: pickDate,
                  ),
                  textField("Store", store),
                  textField(
                    "Low Feed Limit",
                    lowFeedLimit,
                    keyboardType: TextInputType.number,
                  ),
                  textField(
                    "No. of Tanks",
                    tanks,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEdit ? "Update" : "Save",
                            style: const TextStyle(color: Colors.white),
                          ),

                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      if (selectedImages.isEmpty) {
                        CustomToast.show(
                          message: "Please upload at least 1 image",
                        );
                        return;
                      }
                      if (isEdit) {
                        await controller.updateFarmData(
                          farmId: widget.farmData!.id!,
                          farmName: farmName.text,
                          stockingDate: stockingDate.text,
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: tanks.text,
                          imagePaths: selectedImages
                              .map((e) => e.path)
                              .toList(),
                        );
                      } else {
                        await controller.uploadFarmData(
                          farmName: farmName.text,
                          stockingDate: stockingDate.text,
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: tanks.text,
                          imagePaths: selectedImages
                              .map((e) => e.path)
                              .toList(),
                        );
                      }

                      Get.back(); // close
                      Get.find<FarmListController>()
                          .fetchFarmList(); // refresh list screen
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onTap: onTap,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required!";
            }

            if (label == "Low Feed Limit" || label == "No. of Tanks") {
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return "$label must be a valid number!";
              }
              if (int.parse(value) <= 0) {
                return "$label must be greater than 0!";
              }
            }

            return null;
          },

          decoration: InputDecoration(
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
