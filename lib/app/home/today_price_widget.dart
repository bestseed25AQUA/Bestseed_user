import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';

class TodayPricesWidget extends StatefulWidget {
  const TodayPricesWidget({super.key});

  @override
  State<TodayPricesWidget> createState() => _TodayPricesWidgetState();
}

class _TodayPricesWidgetState extends State<TodayPricesWidget> {
  // String selectedValue = "Vannamei";
  final dashboardCtrl = Get.find<DashboardController>();
  final SeedsPriceController controller = Get.put(SeedsPriceController());
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,

      // padding: const EdgeInsets.all(12.0),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(16),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.grey.withOpacity(.2),
      //       offset: Offset(2, 2)
      //     )
      //   ]
      // ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Prices",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // _buildDropdownButton(
                //   selectedValue,
                //   ["Vannamei", "Monodon", "Scampi"],
                //   (newValue) {
                //     setState(() {
                //       selectedValue = newValue!;
                //     });
                //   },
                // ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              return _buildPriceSection(
                title: controller.homePriceData.value?.location ?? '',
                prices: List.generate(
                  controller.homePriceData.value?.prices.length ?? 0,
                  (index) => PriceItem(
                    quantity:
                        "${controller.homePriceData.value?.prices[index].size}C",
                    price:
                        "₹${controller.homePriceData.value?.prices[index].todayPrice}",
                  ),
                ),
              );
            }),
            // const SizedBox(height: 20),
            // _buildPriceSection(
            //   title: "Krishna",
            //   prices: [
            //     PriceItem(quantity: "100C", price: "₹220"),
            //     PriceItem(quantity: "90C", price: "₹230"),
            //     PriceItem(
            //       quantity: "80C",
            //       price: "",
            //     ), // Example of an empty price
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true, // takes full width
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPriceSection({
    required String title,
    required List<PriceItem> prices,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () {
                dashboardCtrl.changeIndex(1);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "See all",
                  style: GoogleFonts.roboto(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: prices.length,
            itemBuilder: (context, index) {
              return _buildPriceChip(prices[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChip(PriceItem priceItem) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(priceItem.quantity),
          SizedBox(width: 16),
          Text(
            " ${priceItem.price}",
            style: GoogleFonts.roboto(
              color: AppColors.primary,
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
