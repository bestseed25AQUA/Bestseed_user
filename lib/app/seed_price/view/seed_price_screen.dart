import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/common/custom_icon_appbar.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/seed_price/widget/seed_price_banner_widget.dart';
import 'package:seedsuser/app/seed_price/widget/seed_wanted_banner_widget.dart';
import 'package:seedsuser/app/wanted/view/wanted_screen.dart';
import 'package:seedsuser/app/model/price_model.dart';

class SeedPricesScreen extends StatefulWidget {
  const SeedPricesScreen({super.key});
  @override
  State<SeedPricesScreen> createState() => _SeedPricesScreenState();
}

class _SeedPricesScreenState extends State<SeedPricesScreen> {
  final SeedsPriceController controller = Get.put(SeedsPriceController());
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    // If needed, you can log or validate the selected value
    if (controller.locations.isNotEmpty) {
      try {
        bool isFound = false;
        for (var location in controller.locations) {
          if (location.title == "East Godavari" ||
              location.title == "East Godawari") {
            controller.selectedLocation.value = location;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          controller.selectedLocation.value = controller.locations.first;
        }
      } catch (e) {
        controller.selectedLocation.value = controller.locations.first;
      }
    }

    /// for default category
    if (controller.categories.isNotEmpty) {
      try {
        bool isFound = false;
        for (var category in controller.categories) {
          if (category.categoryName == "Vannamei") {
            controller.selectedCategory.value = category;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          controller.selectedCategory.value = controller.categories.first;
        }
      } catch (e) {
        controller.selectedCategory.value = controller.categories.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomIconAppbar(title: "Seed Prices"),
      body: Obx(() {
        // if (controller.isLoading.value) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        PriceModel? priceData = controller.priceData.value;

        // if ((priceData == null || priceData.prices.isEmpty) && !_dialogShown) {
        //   _dialogShown = true;
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     Get.dialog(
        //       Center(
        //         child: Container(
        //           padding: const EdgeInsets.all(24),
        //           margin: const EdgeInsets.symmetric(horizontal: 32),
        //           decoration: BoxDecoration(
        //             color: Colors.white,
        //             borderRadius: BorderRadius.circular(16),
        //             boxShadow: [
        //               BoxShadow(
        //                 color: Colors.black26,
        //                 blurRadius: 10,
        //                 offset: const Offset(0, 4),
        //               ),
        //             ],
        //           ),
        //           child: Material(
        //             color: Colors.white,
        //             child: Column(
        //               mainAxisSize: MainAxisSize.min,
        //               children: [
        //                 Icon(
        //                   Icons.info_outline,
        //                   color: Colors.orange,
        //                   size: 48,
        //                 ),
        //                 const SizedBox(height: 16),
        //                 Text(
        //                   'No Prices Found',
        //                   style: GoogleFonts.roboto(
        //                     fontSize: 20,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.black87,
        //                   ),
        //                   textAlign: TextAlign.center,
        //                 ),
        //                 const SizedBox(height: 12),
        //                 Text(
        //                   priceData?.msg ??
        //                       'No price data is available for the selected filters.',
        //                   style: GoogleFonts.roboto(
        //                     fontSize: 16,
        //                     color: Colors.grey[700],
        //                   ),
        //                   textAlign: TextAlign.center,
        //                 ),
        //                 const SizedBox(height: 24),
        //                 SizedBox(
        //                   width: double.infinity,
        //                   child: ElevatedButton(
        //                     onPressed: () => Get.back(),
        //                     style: ElevatedButton.styleFrom(
        //                       backgroundColor: AppColors.primary,
        //                       shape: RoundedRectangleBorder(
        //                         borderRadius: BorderRadius.circular(12),
        //                       ),
        //                       padding: const EdgeInsets.symmetric(vertical: 14),
        //                     ),
        //                     child: Text(
        //                       'OK',
        //                       style: GoogleFonts.roboto(
        //                         fontSize: 16,
        //                         fontWeight: FontWeight.bold,
        //                         color: Colors.white,
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //       barrierDismissible: true,
        //     );
        //   });
        // }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              SeedPriceBannerWidget(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Filters: Location & Category ---
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            if (controller.locations.isEmpty) {
                              return const SizedBox();
                            }
                            return CustomDropdown<Location>(
                              selectedValue: controller.selectedLocation.value,
                              items: controller.locations,
                              itemLabel: (loc) => loc.title,
                              hintText: "Select Location",
                              onChanged: (loc) {
                                controller.selectedLocation.value = loc;
                                _dialogShown = false;
                                controller.getPrices();
                              },
                            );
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() {
                            if (controller.categories.isEmpty) {
                              return const SizedBox();
                            }

                            return CustomDropdown<Category>(
                              selectedValue: controller.selectedCategory.value,
                              items: controller.categories,
                              itemLabel: (cat) => cat.categoryName,
                              hintText: "Select Category",
                              onChanged: (cat) {
                                controller.selectedCategory.value = cat;
                                _dialogShown = false;
                                controller.getPrices();
                              },
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Count',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                          Text(
                            "Today's Prices",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.isLoading.value)
                      AnimatedAppearance(
                        child: ListView.builder(
                          itemCount: 3,
                          shrinkWrap: true,
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(top: 5, bottom: 5),
                              child: CustomShimmer(
                                width: MediaQuery.of(context).size.width * .9,
                                height: 40,
                              ),
                            );
                          },
                        ),
                      )
                    else if (priceData == null || priceData.prices.isEmpty)
                      SizedBox(
                        height: 80,
                        child: const Center(
                          child: Text("No prices available."),
                        ),
                      )
                    else if (priceData.prices.isNotEmpty)
                      ListView.builder(
                        itemCount: priceData.prices.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = priceData.prices[index];
                          return AnimatedAppearance(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.size,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "₹${item.todayPrice}",
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // const SizedBox(height: 20),
                    // if (priceData != null)
                    //   Text(
                    //     priceData.description,
                    //     textAlign: TextAlign.center,
                    //     style: GoogleFonts.roboto(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.w500,
                    //       color: Colors.grey[800],
                    //     ),
                    //   ),
                    // InkWell(
                    //   onTap: () {
                    //   Get.to(WantedCropBuyersScreen());
                    //  },
                    //   child: Text('wanted')),
                  ],
                ),
              ),
              SizedBox(height: 30),
              // Container(color: Colors.black,height: 10,width: double.infinity,),
              WantedBannerWidget(
                ontapImage: () {
                  Get.to(WantedCropBuyersScreen());
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }
}
