import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/common/custom_icon_appbar.dart';
import 'package:seedsuser/app/common/custom_referesh_indicator.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:shimmer/shimmer.dart';

class BroodStockScreen extends StatefulWidget {
  const BroodStockScreen({super.key});

  @override
  State<BroodStockScreen> createState() => _BroodStockScreenState();
}

class _BroodStockScreenState extends State<BroodStockScreen> {
  final BroodStockController controller = Get.put(BroodStockController());
  RxString selectedMonthYear = "".obs;

  @override
  void initState() {
    super.initState();
    selectedMonthYear.value = getPastMonths(12).first;
    controller.getBroodStock();
  }

  // Generate list of past N months in "MMM yyyy" format
  List<String> getPastMonths(int count) {
    final now = DateTime.now();
    List<String> months = [];
    for (int i = 0; i < count; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add("${_monthName(date.month)} ${date.year}");
    }
    return months;
  }

  String _monthName(int month) {
    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomIconAppbar(title: "Brood Stock"),
      body: Obx(() {
        return CustomRefereshIndicator(
          onRefresh: () async {
            await controller.getBroodStock();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                  _buildFilterSection(),
                  const SizedBox(height: 12),
                  _buildHatcheryListHeader(),
                  const SizedBox(height: 8),
                  if (controller.isLoading.value)
                    ListView.builder(
                      itemCount: 3,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          child: AnimatedAppearance(
                            type: AnimationType.slideDown,
                            child: hatcheryCardShimmer(),
                          ),
                        );
                      },
                    )
                  else if (controller.filteredBroodStocks.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * .2,
                      ),
                      child: const Center(
                        child: Text('No brood stock available.'),
                      ),
                    )
                  else
                    AnimatedAppearance(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.filteredBroodStocks.length,
                        itemBuilder: (context, index) {
                          BroodstockData data =
                              controller.filteredBroodStocks[index];
                          return Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
                            child: InkWell(
                              onTap: () {
                                Get.to(
                                  HatcheryCateogryScreen(
                                    hatcheryId: controller
                                        .filteredBroodStocks[index]
                                        .id
                                        .toString(),
                                    hatcheryName: controller
                                        .filteredBroodStocks[index]
                                        .hatcheryName
                                        .toString(),
                                  ),
                                );
                              },
                              child: _buildHatcheryCard(data),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  CustomAppBar _buildAppBar() {
    return CustomAppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Brood Stock',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        InkWell(
          onTap: () => Get.to(() => LanguageSelectionScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/lan_image.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => NotificationsScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/notification.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => ProfileScreen()),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: Image.asset('assets/images/person.png', height: 28),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 38,
        child: TextField(
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: Colors.grey),
            hintText: 'Search for hatcheries...',
            border: InputBorder.none,
            suffixIcon: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(Icons.mic, color: Colors.blue),
            ),
          ),
          onChanged: (query) {
            controller.filterBroodStocks(query);
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        // ✅ Category Dropdown
        Expanded(
          child: Obx(
            () => CustomDropdown<Category>(
              selectedValue: controller.selectedCategory.value,
              items: controller.categories
                  .where(
                    (cat) =>
                        cat.categoryName.toLowerCase() == 'vannamei' ||
                        cat.categoryName.toLowerCase() == 'syaqua',
                  )
                  .toList(),
              itemLabel: (cat) => cat.categoryName,
              hintText: "Select Category",
              onChanged: (cat) {
                controller.onCategoryChanged(cat);
              },
            ),
          ),
        ),

        const SizedBox(width: 16),

        // ✅ Month Year Dropdown
        Expanded(
          child: Obx(
            () => CustomDropdown<String>(
              selectedValue: selectedMonthYear.value,
              items: getPastMonths(12),
              itemLabel: (month) => month,
              hintText: "Select Month/Year",
              onChanged: (monthYear) {
                selectedMonthYear.value = monthYear;

                // 🔹 Extract month & year
                final parts = monthYear.split(' ');
                if (parts.length == 2) {
                  controller.onMonthYearChanged(
                    parts[0].toLowerCase(),
                    parts[1],
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownButton(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEF8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
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

  Widget _buildHatcheryListHeader() {
    return Text(
      'Hatchery & Suppliers',
      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildHatcheryCard(BroodstockData data) {
    return Ink(
      // elevation: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(width: 1, color: Colors.grey.withOpacity(.1)),
        boxShadow: [BoxShadow(color: Colors.black)],
      ),

      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Material(
        elevation: 1,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 → Name + Count
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.hatcheryName,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    "Count",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Row 2 → Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      "Location",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    data.availableQuantity,
                    style: GoogleFonts.roboto(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Supplier + Imported Date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.supplierName,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    data.importedDate,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chips Row → Available + Packing (conditional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (data.availableOn.isNotEmpty)
                    _buildChip(
                      label: data.availableOn.replaceAll(" on", ''),
                      bgColor: Colors.green.withOpacity(0.15),
                      textColor: Colors.green[800]!,
                    ),

                  // if (data.availableOn.isNotEmpty && data.packingStart.isNotEmpty)
                  //   const SizedBox(width: 10),
                  if (data.packingStart.isNotEmpty)
                    _buildChip(
                      label: "${data.packingStart}",
                      bgColor: Colors.blue.withOpacity(0.15),
                      textColor: Colors.blue[700]!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .4 - 22,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

Widget hatcheryCardShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 14,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2
            Row(
              children: [
                Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 20,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 3
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 14,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Chips
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 28,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 28,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
