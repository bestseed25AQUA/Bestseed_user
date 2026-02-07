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
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
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
    _initializeFilter();
  }

  void _initializeFilter() {
    // Set initial fallback value
    selectedMonthYear.value = getPastMonths(24).first;

    // Listen for future changes to defaultMonthYear
    ever(controller.defaultMonthYear, (value) {
      _syncMonthYearFromController(value);
    });

    // Also check if value is already set (in case API call already completed)
    if (controller.defaultMonthYear.value.isNotEmpty) {
      _syncMonthYearFromController(controller.defaultMonthYear.value);
    }
  }

  void _syncMonthYearFromController(String value) {
    if (value.isNotEmpty) {
      // Check if the value exists in our list (24 months to include past months)
      final months = getPastMonths(24);
      if (months.contains(value)) {
        selectedMonthYear.value = value;
        print('Synced month/year to: $value');
      } else {
        // If not found, try to find a matching month
        // The API returns "Dec 2025" format, our list also uses "Dec 2025"
        print('Default month "$value" not found in list: $months');
        selectedMonthYear.value = months.first;
      }
    }
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

  final dashboardCtrl = Get.find<DashboardController>();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          dashboardCtrl.changeIndex(0); // Navigate to home screen
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomIconAppbar(title: "Brood Stock", showBackButton: false),
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
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Get.to(
                                    HatcheryCateogryScreen(
                                      hatcheryId: controller
                                          .filteredBroodStocks[index]
                                          .hatcheryId
                                          .toString(),
                                      // hatcheryId: '139',
                                      hatcheryName: controller
                                          .filteredBroodStocks[index]
                                          .hatcheryName
                                          .toString(),
                                      useHatcheryId:
                                          true, // Use database id endpoint for broodstock flow
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
      ),
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
            fillColor: Color(0xffF3F4F6),
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
        Expanded(
          child: Obx(
            () => CustomDropdown<Category>(
              selectedValue: controller.selectedCategory.value,
              items: controller.categories
                  .where(
                    (cat) =>
                        cat.categoryName.toLowerCase() == 'vannamei' ||
                        cat.categoryName.toLowerCase() == 'tiger',
                  )
                  .toList(),
              itemLabel: (cat) => cat.categoryName,
              backgroundColor: Color(0xffF3F4F6),
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
              backgroundColor: Color(0xffF3F4F6),
              selectedValue: selectedMonthYear.value,
              items: getPastMonths(24),
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
        color: Color(0xffF9FAFB),
        border: Border.all(width: 1, color: Colors.grey.withOpacity(.1)),
        boxShadow: [BoxShadow(color: Colors.black)],
      ),

      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Material(
        elevation: 1,
        color: Color(0xffF9FAFB),
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
                        fontSize: 14,
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
                    size: 14,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      data.locationName,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    data.availableQuantity.replaceAll("Pieces", ""),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
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

              const SizedBox(height: 8),

              if ((data.description ?? '').isNotEmpty)
                ExpandableDescription(text: data.description!),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [buildStatusChip(data)],
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
        width: MediaQuery.of(context).size.width * .6 - 22,
        child: Center(
          child: Text(
            label.replaceAll("Start", ""),
            style: GoogleFonts.roboto(
              fontSize: 14,
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

  Widget buildStatusChip(BroodstockData data) {
    switch (data.status) {
      case BroodstockStatus.available:
        // Show "Available" with date if available
        String availableLabel = 'Available';
        if (data.availableOn.isNotEmpty) {
          // Extract just the date part from availableOn
          String dateStr = data.availableOn
              .replaceAll('Available on ', '')
              .replaceAll('Available ', '')
              .trim();
          availableLabel = 'Available $dateStr';
        }
        return _buildChip(
          label: availableLabel,
          bgColor: Colors.green.withOpacity(0.15),
          textColor: Colors.green[800]!,
        );

      case BroodstockStatus.upcoming:
        return _buildChip(
          label: 'Upcoming',
          bgColor: Colors.blue.withOpacity(0.15),
          textColor: Colors.blue[700]!,
        );

      case BroodstockStatus.shortlyAvailable:
        // Show "Shortly Available" with date if available
        String shortlyLabel = 'Shortly Available';
        if (data.availableOn.isNotEmpty) {
          String dateStr = data.availableOn
              .replaceAll('Shortly Available on ', '')
              .replaceAll('Shortly Available ', '')
              .replaceAll('Available on ', '')
              .replaceAll('Available ', '')
              .trim();
          shortlyLabel = 'Shortly Available $dateStr';
        }
        return _buildChip(
          label: shortlyLabel,
          bgColor: Colors.orange.withOpacity(0.15),
          textColor: Colors.orange[800]!,
        );

      case BroodstockStatus.closed:
        return _buildChip(
          label: 'Closed',
          bgColor: Colors.grey.withOpacity(0.2),
          textColor: Colors.grey[800]!,
        );

      default:
        return const SizedBox.shrink();
    }
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

class ExpandableDescription extends StatefulWidget {
  final String text;

  const ExpandableDescription({Key? key, required this.text}) : super(key: key);

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription>
    with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Text(
          widget.text,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
