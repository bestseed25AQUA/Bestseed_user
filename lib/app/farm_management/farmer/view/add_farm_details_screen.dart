import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_list_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/farm_management_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/former_details_controller.dart' hide FarmListController;

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
  final TextEditingController tanks = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  List<Map<String, String>> images = [];

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
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Farm Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Builder(
      builder:  (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker preview
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: images.isEmpty
                        ? InkWell(
                            onTap: pickImages,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : CarouselSlider.builder(
                            itemCount: images.length + 1,
                            options: CarouselOptions(
                              height: 200,
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
                                return InkWell(
                                  onTap: pickImages,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
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
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return SizedBox(height: 200);
                                                },
                                          )
                                        : isNetwork
                                        ? CustomNetworkImage(
                                            imageUrl: map['network'] ?? '',
                                            width: double.infinity,
                                            height: 200,
                                          )
                                        : const SizedBox(),
                                  ),

                                  // ✅ Delete Button
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
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.red,
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: (images.isNotEmpty)
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: 4,
                                                  bottom: 4,
                                                  right: 8,
                                                  left: 8,
                                                ),
                                                child: Text(
                                                  "${currentIndex + 1}/${images.length}",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : SizedBox(),
                                  ),
                                ],
                              );
                            },
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

                  Obx(() {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: controller.isOverlay.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? "Update" : "Save",
                              style: const TextStyle(color: Colors.white),
                            ),

                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        bool success = false;

                        if (images.isEmpty) {
                          CustomToast.show(
                            message: "Please upload at least 1 image",
                          );
                          return;
                        }
                        if (isEdit) {
                          success = await controller.updateFarmData(
                            farmId: widget.farmData!.id!,
                            farmName: farmName.text,
                            stockingDate: stockingDate.text,
                            store: store.text,
                            lowFeedLimit: lowFeedLimit.text,
                            tanks: tanks.text,
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
                            tanks: tanks.text,
                            imagePaths:
                                images
                                        .where(
                                          (item) => item.containsKey('local'),
                                        )
                                        .map((item) => item['local'])
                                        .toList()
                                    as List<String>,
                          );
                        }
                        if (success) {
                          Get.back();
                          Get.find<FarmListController>().fetchFarmList();
                        }
                      },
                    );
                  }),
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
