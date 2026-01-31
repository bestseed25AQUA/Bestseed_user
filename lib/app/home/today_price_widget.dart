import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/home/controller/home_controller.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';

class TodayPricesWidget extends StatelessWidget {
  TodayPricesWidget({super.key});

  final dashboardCtrl = Get.find<DashboardController>();

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Container(
       margin:  const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
      padding: EdgeInsets.symmetric(horizontal: 14,vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            spreadRadius: 0,
            color: Color(0xff00000029).withOpacity(.16),
          ),
        ],
      ),
      child: Padding(
           padding: EdgeInsets.only(left:  12,right:  12,top:  12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Prices",
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // CustomDropdown(
                //   selectedValue: null,
                //   items: [],
                //   itemLabel: (v) {
                //     return '';
                //   },
                //   onChanged: (v) {},
                //   hintText: 'Vennamai',
                // ),
                InkWell(
                  onTap: () {
                    dashboardCtrl.changeIndex(1);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xffDCEEF8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          controller.homePriceData.value.category,
                          style: GoogleFonts.roboto(
                            color: Colors.black,fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Prices Section
            Obx(() {
              if (controller.homePriceData.value.data.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No prices are available for today',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: controller.homePriceData.value.data
                    .map((loc) {
                      return _buildPriceSection(
                        title: loc.location,
                        prices: loc.prices
                            .map(
                              (p) => PriceItem(
                                quantity: "${p.size}C",
                                price: "₹${p.todayPrice}",
                              ),
                            )
                            .toList(),
                      );
                    })
                    .toList()
                    .reversed
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection({
    required String title,
    required List<PriceItem> prices,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Title with See all button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () {
                  dashboardCtrl.changeIndex(1);
                },
                child: Text(
                  "See all",
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Price Chips List
          SizedBox(
            height: 40,
            child: prices.isEmpty
                ? Text(
                    "Prices coming shortly",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prices.length,
                    itemBuilder: (context, index) {
                      return _buildPriceChip(prices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(PriceItem priceItem) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(priceItem.quantity, style: GoogleFonts.roboto(fontSize: 14)),
          SizedBox(width: 12),
          Text(
            priceItem.price,
            style: GoogleFonts.roboto(
              color: AppColors.primary,fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PriceItem {
  final String quantity;
  final String price;

  PriceItem({required this.quantity, required this.price});
}
