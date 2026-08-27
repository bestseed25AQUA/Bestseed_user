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
import 'package:seedsuser/app/farm_management/farmer/widget/request_sent_dialog.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class AddFarmerDetailsFormScreen extends StatefulWidget {
  const AddFarmerDetailsFormScreen({super.key, this.farmData});
  final FarmData? farmData;

  @override
  State<AddFarmerDetailsFormScreen> createState() =>
      _AddFarmerDetailsFormScreenState();
}

class _AddFarmerDetailsFormScreenState
    extends State<AddFarmerDetailsFormScreen> {
  final FarmListController controller = farmListController;

  final TextEditingController farmName = TextEditingController();
  final TextEditingController stockingDate = TextEditingController();
  final TextEditingController store = TextEditingController();
  final TextEditingController lowFeedLimit = TextEditingController();

  /// Only used when the farm was stocked before today — see [_daysSinceStocking].
  final TextEditingController feedUsedBefore = TextEditingController();

  /// Whether to offer the "feed already used" field.
  ///
  /// Shown for a past stocking date, on create AND on edit — a farmer often
  /// realises afterwards that the history is missing. It disappears once the
  /// farm has feed recorded against it, because backfilling then would
  /// double-count; the server enforces the same rule.
  /// Whether to offer the "feed already used" field: any farm stocked before
  /// today, on create or edit. Editing the figure REPLACES the generated
  /// history — feed entered by hand since is preserved.
  bool get _showFeedUsedField => _daysSinceStocking > 0;

  /// Days from the chosen stocking date to today, inclusive. 0 when the date is
  /// today, in the future, or not chosen yet.
  int get _daysSinceStocking {
    final picked = DateTime.tryParse(stockingDate.text.trim());
    if (picked == null) return 0;

    final start = DateTime(picked.year, picked.month, picked.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!start.isBefore(today)) return 0;
    return today.difference(start).inDays + 1;
  }
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  List<Map<String, String>> images = [];
  int? selectedTanks;

  final List<int> tankOptions = List.generate(50, (i) => i + 1);

  Future<void> pickImages() async {
    // Downscale and re-encode at pick time. A straight camera-roll photo is
    // ~4 MB, which silently exceeded the server's upload_max_filesize: PHP
    // discarded the file, hasFile() came back false, and the farm was created
    // with NO image while the API still reported success. These limits keep a
    // photo well under any sane server cap and cut upload time on mobile data.
    final List<XFile>? files = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (files != null && files.isNotEmpty) {
      // Capped to match the server's `farm_image|max:20`. Without this the
      // picker let a farmer select thirty photos, upload them all, and get back
      // a bare validation error after the wait.
      const maxImages = 20;
      final room = maxImages - images.length;

      if (room <= 0) {
        CustomToast.show(message: 'You can add up to $maxImages photos');
        return;
      }

      if (files.length > room) {
        CustomToast.show(message: 'Only the first $room photos were added');
      }

      setState(() {
        for (var value in files.take(room)) {
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
      // Refresh: a past date reveals the "feed already used" field below Store.
      setState(() {});
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

      // Prefill with the figure the farmer entered. Farms created before that
      // figure was recorded fall back to their running total, so the box shows
      // something meaningful instead of sitting empty next to weeks of history.
      final entered =
          widget.farmData!.feedUsedBefore ?? widget.farmData!.totalFeedUsed ?? 0;
      if (entered > 0) {
        feedUsedBefore.text = entered.toString();
      }
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
                _buildTextField(controller: farmName, hint: "Enter Farm Name"),
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
                // Optional: a farm can be set up before any feed has been
                // delivered, so there is no stock figure to give yet. Left
                // blank the server stores NULL, and it can be filled in later
                // from the farm's feed-store card.
                _buildTextField(
                  controller: store,
                  hint: "Enter Store",
                  keyboardType: TextInputType.number,
                  isRequired: false,
                ),
                const SizedBox(height: 20),

                // Feed already used — only for a farm stocked in the past.
                // A farm registered weeks after stocking has history the app
                // knows nothing about; this one figure fills it in.
                if (_showFeedUsedField) ...[
                  _buildLabel("Feed Already Used"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: feedUsedBefore,
                    hint: "Total feed used so far",
                    keyboardType: TextInputType.number,
                    // Optional: the farmer may prefer to enter feed tank by
                    // tank on the history screen instead of one lump figure.
                    isRequired: false,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final days = _daysSinceStocking;
                      final tanks = selectedTanks ?? 0;
                      final total =
                          double.tryParse(feedUsedBefore.text.trim()) ?? 0;

                      if (total <= 0 || tanks <= 0) {
                        return Text(
                          "$days days since stocking. Leave blank if none was used.",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }

                      final perTank = total / tanks;
                      final perDay = perTank / days;

                      return Text(
                        "$days days · $tanks tanks  →  "
                        "${perTank.toStringAsFixed(2)} kg per tank "
                        "(${perDay.toStringAsFixed(2)} kg/day)",
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

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
                        // `id!` threw here for a farm the API returned without
                        // one, losing everything the form had been filled with.
                        final farmId = widget.farmData?.id;
                        if (farmId == null) {
                          CustomToast.error('This farm is missing its id');
                          return;
                        }

                        success = await controller.updateFarmData(
                          farmId: farmId,
                          farmName: farmName.text,
                          stockingDate: stockingDate.text,
                          store: store.text,
                          lowFeedLimit: lowFeedLimit.text,
                          tanks: selectedTanks.toString(),
                          feedUsedBefore: feedUsedBefore.text.trim(),
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
                          // Backfill applies to a NEW farm only; editing must
                          // not re-create history that already exists.
                          feedUsedBefore: feedUsedBefore.text.trim(),
                          imagePaths: images
                              .where((item) => item.containsKey('local'))
                              .map((item) => item['local'].toString())
                              .toList(),
                        );
                      }
                      if (success) {
                        // Only a newly submitted farm is a "request"; an edit
                        // just saves, so it skips the confirmation popup.
                        if (!isEdit && context.mounted) {
                          await showRequestSentDialog(context);
                        }

                        // Refresh BEFORE popping. Popping first left the
                        // previous screen rebuilding against a stale, empty
                        // list, so a farm that had just been created still
                        // showed the "no farms yet" screen.
                        await farmListController.fetchFarmList();
                        safeBack();
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
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
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
                            // Stored urls may still name an old deployment host.
                            imageUrl: resolveMediaUrl(map['network']),
                            width: double.infinity,
                            height: 180,
                            // Without a fit the image drew at its natural size
                            // and sat letterboxed inside the grey box, unlike
                            // the locally picked images beside it.
                            fit: BoxFit.cover,
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
    ValueChanged<String>? onChanged,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      validator: (value) {
        // Every field here is mandatory except where a screen says otherwise.
        if (!isRequired) return null;

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
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade400),
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
        return DropdownMenuItem<int>(value: value, child: Text("$value"));
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
