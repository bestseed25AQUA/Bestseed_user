import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

import 'package:get/get.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // State variables for selected filters
  String? selectedBrandSeed;
  String? selectedCategory;

  final List<String> brandSeedOptions = ["Syqua", "SIS Hardline", "Kona Bay"];
  final List<String> categoryOptions = ["Size PL", "Tiger"];

  final HomeController _homeController = Get.put(HomeController());
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filters",
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Brand/Seed",
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children:
                List.generate(
                  _homeController.brands.length,
                  (index) => _homeController.brands[index],
                ).map((option) {
                  final isSelected = selectedBrandSeed == option;

                  return RawChip(
                    labelPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.brandName,
                          style: GoogleFonts.roboto(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    showCheckmark: false, // hide default checkmark
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    onSelected: (bool value) {
                      setState(() {
                        selectedBrandSeed = value ? option.id.toString() : null;
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            "Category",
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: _homeController.categories.map((option) {
              final isSelected = selectedCategory == option;
              return ChoiceChip(
                label: Text(option.categoryName),
                selected: isSelected,
                onSelected: (bool value) {
                  setState(() {
                    selectedCategory = value ? option.id.toString() : null;
                  });
                },
                checkmarkColor: Colors.white,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey[200],
                labelStyle: GoogleFonts.roboto(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Handle apply action with selected filters
              print("Selected Brand/Seed: $selectedBrandSeed");
              print("Selected Category: $selectedCategory");
              Navigator.pop(context); // Close the bottom sheet after applying
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              backgroundColor:
                  AppColors.primary, // Background color of the button
            ),
            child: Text(
              "APPLY",
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
