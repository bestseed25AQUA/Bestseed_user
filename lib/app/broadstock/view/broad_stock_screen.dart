import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_dropdown.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';

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
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildFilterSection(),
                const SizedBox(height: 24),
                _buildHatcheryListHeader(),
                const SizedBox(height: 16),
                if (controller.filteredBroodStocks.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .2,
                    ),
                    child: const Center(
                      child: Text('No brood stock available.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.filteredBroodStocks.length,
                    itemBuilder: (context, index) {
                      BroodstockData data =
                          controller.filteredBroodStocks[index];
                      return _buildHatcheryCard(data);
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[800],
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
          child: Image.asset('assets/images/lan_image.png', height: 28),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => NotificationsScreen()),
          child: Image.asset('assets/images/notification.png', height: 28),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => Get.to(() => ProfileScreen()),
          child: Image.asset('assets/images/person.png', height: 28),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Search for hatcheries...',
          border: InputBorder.none,
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
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
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        // ✅ Category Dropdown
        Expanded(
          child: Obx(
            () => controller.categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CustomDropdown<Category>(
                    selectedValue: controller.selectedCategory.value,
                    items: controller.categories,
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
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  data.images.isNotEmpty ?? false ? data.images[0] : '',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.availableOn,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              data.packingStart,
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.hatcheryName,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Row(
                //   children: [
                //     const Icon(Icons.location_on, color: Colors.grey, size: 16),
                //     const SizedBox(width: 4),
                //     Text(
                //       data.location,
                //       style: GoogleFonts.roboto(color: Colors.grey),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 8),
                // Text(
                //   data.category.map((e) => e.capitalizeFirst ?? e).join(', '),
                //   style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                // ),
                const SizedBox(height: 4),
                Text('Imported Date: ${data.importedDate ?? ''}'),
                const SizedBox(height: 8),
                Text(
                  'Available Quantity',
                  style: GoogleFonts.roboto(color: Colors.grey[700]),
                ),
                Text(
                  data.availableQuantity,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
