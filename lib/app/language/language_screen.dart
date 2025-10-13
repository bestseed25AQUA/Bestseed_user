import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/language/controller/language_controller.dart';
import 'package:seedsuser/l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatelessWidget {
  LanguageSelectionScreen({super.key});

  final LanguageController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final languages = controller.langMap.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).selectLanguage,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'preferred_language'.tr,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                ),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = controller.isSelected(lang);

                  return GestureDetector(
                    onTap: () => controller.setLanguage(lang),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              lang,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Radio<String>(
                            value: lang,
                            groupValue: controller.currentLanguageName.value,
                            onChanged: (value) =>
                                controller.setLanguage(value!),
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // CustomButton(
            //   text: 'save'.tr,
            //   onPressed: () {

            //     Get.back();
            //     Get.snackbar(
            //       'language_saved'.tr,
            //       '${'selected'.tr}: ${controller.currentLanguageName.value}',
            //       backgroundColor: AppColors.primary,
            //       colorText: Colors.white,
            //       snackPosition: SnackPosition.BOTTOM,
            //       duration: const Duration(seconds: 2),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
