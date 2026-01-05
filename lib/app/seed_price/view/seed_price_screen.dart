import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/common/custom_icon_appbar.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/seed_price/widget/seed_price_banner_widget.dart';
import 'package:seedsuser/app/seed_price/widget/seed_wanted_banner_widget.dart';
import 'package:seedsuser/app/utils/app_size.dart';
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

  final dashboardCtrl = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomIconAppbar(
        title: "Seed Prices",
        ontapBack: () {
          dashboardCtrl.changeIndex(0);
        },
      ),
      body: Obx(() {
        // if (controller.isLoading.value) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        PriceModel? priceData = controller.priceData.value;

        if ((priceData == null || priceData.prices.isEmpty) && !_dialogShown) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.dialog(
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () {
                              _dialogShown = false;
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(Icons.clear, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Icon(
                        //   Icons.info_outline,
                        //   color: Colors.orange,
                        //   size: 48,
                        // ),
                        const SizedBox(height: 16),
                        Text(
                          'Prices \nComing Shortly',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Prices are not available right now. Well update them soon.',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // SizedBox(
                        //   width: double.infinity,
                        //   child: ElevatedButton(
                        //     onPressed: () => Get.back(),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: AppColors.primary,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       padding: const EdgeInsets.symmetric(vertical: 14),
                        //     ),
                        //     child: Text(
                        //       'OK',
                        //       style: GoogleFonts.roboto(
                        //         fontSize: 16,
                        //         fontWeight: FontWeight.bold,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
              barrierDismissible: true,
            );
          });
        }

        return CustomRefereshIndicator(
          onRefresh: () async {
            await controller.getPrices();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                //  SizedBox(height: 10),
                // // Container(color: Colors.black,height: 10,width: double.infinity,),
                // SizedBox(
                //   width: AppSize.width,
                //   child: Align(
                //     alignment: Alignment.center,
                //     child: WantedBannerWidget(
                //       ontapImage: () {
                //         Get.to(WantedCropBuyersScreen());
                //       },
                //     ),
                //   ),
                // ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.to(WantedCropBuyersScreen());
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/wanted_banner.png',
                      width: MediaQuery.of(context).size.width * .9,
                      height: 150,
                    ),
                  ),
                ),
                // const SizedBox(height: 10),
                // const SizedBox(height: 10),
                // SeedPriceBannerWidget(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                                selectedValue:
                                    controller.selectedLocation.value,
                                items: controller.locations,
                                itemLabel: (loc) => loc.title,
                                hintText: "Select Location",
                                backgroundColor: Color(0xffF3F4F6),
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
                                selectedValue:
                                    controller.selectedCategory.value,
                                items: controller.categories,
                                itemLabel: (cat) => cat.categoryName,
                                hintText: "Select Category",
                                backgroundColor: Color(0xffDCEEF8),
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          // color: Colors.blue[50],
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
                      const SizedBox(height: 5),
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
                                  height: 37,
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
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              height: MediaQuery.of(context).size.height * .4,
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(right: 10),
                                  itemCount: priceData.prices.length,
                                  shrinkWrap: true,
                                  // physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final item = priceData.prices[index];
                                    return AnimatedAppearance(
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xffF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            // BoxShadow(
                                            //   color: Colors.black.withOpacity(.3),
                                            //   blurRadius: 6,
                                            //   offset: const Offset(0, 3),
                                            // ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.size,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "₹${item.todayPrice}",
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
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
                              ),
                            ),
                            Text(
                              'The above prices may vary between above or below 5 rs per kilogram.',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
              ],
            ),
          ),
        );
      }),
    );
  }
}
