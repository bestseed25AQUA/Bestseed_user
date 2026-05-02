import 'package:flutter/material.dart';
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
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:shimmer/shimmer.dart';

class BroodStockScreen extends StatefulWidget {
  const BroodStockScreen({super.key});

  @override
  State<BroodStockScreen> createState() => _BroodStockScreenState();
}

class _BroodStockScreenState extends State<BroodStockScreen> {
  final BroodStockController controller = Get.put(BroodStockController());
  final ScrollController _scrollController = ScrollController();

  // Convenience getter — keeps all references short.
  RxString get selectedMonthYear => controller.userSelectedMonthYear;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeFilter();
  }

  void _initializeFilter() {
    // Only set default when the user hasn't made a selection yet.
    ever(controller.availableMonths, (months) {
      if (months.isNotEmpty && selectedMonthYear.value.isEmpty) {
        _setDefaultMonth();
      }
    });
    ever(controller.defaultMonthYear, (value) {
      // Sync from API default only if the user hasn't picked anything yet.
      if (selectedMonthYear.value.isEmpty) {
        _syncMonthYearFromController(value);
      }
    });
    if (selectedMonthYear.value.isEmpty) {
      if (controller.defaultMonthYear.value.isNotEmpty) {
        _syncMonthYearFromController(controller.defaultMonthYear.value);
      } else if (controller.availableMonths.isNotEmpty) {
        _setDefaultMonth();
      }
    }
  }

  void _setDefaultMonth() {
    final months = controller.availableMonths;
    if (months.isNotEmpty) {
      selectedMonthYear.value = months.first['display'] ?? '';
    }
  }

  void _syncMonthYearFromController(String value) {
    if (value.isNotEmpty) {
      final displayMonths =
          controller.availableMonths.map((m) => m['display'] ?? '').toList();
      if (displayMonths.contains(value)) {
        selectedMonthYear.value = value;
      } else if (displayMonths.isNotEmpty) {
        selectedMonthYear.value = displayMonths.first;
      }
    }
  }

  final dashboardCtrl = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) dashboardCtrl.changeIndex(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar:
            const CustomIconAppbar(title: "Brood Stock", showBackButton: false),
        body: Column(
          children: [
            const SizedBox(height: 8),

            // Pinned: Search + Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable: header + list
            Expanded(
              child: Obx(() {
                return CustomRefereshIndicator(
                  onRefresh: () => controller.getBroodStock(),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results header
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Hatchery & Suppliers',
                                  style: GoogleFonts.roboto(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (!controller.isLoading.value)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${controller.filteredBroodStocks.length} found',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // List
                          if (controller.isLoading.value)
                            _buildShimmerList()
                          else if (controller.filteredBroodStocks.isEmpty)
                            _buildEmptyState()
                          else
                            _buildBroodstockList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 44,
        child: TextField(
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
            hintText: 'Search hatcheries...',
            hintStyle: GoogleFonts.roboto(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (query) => controller.filterBroodStocks(query),
        ),
      ),
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => CustomDropdown<Category>(
              selectedValue: controller.selectedCategory.value,
              items: controller.categories
                  .where((cat) =>
                      cat.categoryName.toLowerCase() == 'vannamei' ||
                      cat.categoryName.toLowerCase() == 'tiger')
                  .toList(),
              itemLabel: (cat) => cat.categoryName,
              backgroundColor: const Color(0xffF3F4F6),
              hintText: "Category",
              onChanged: (cat) => controller.onCategoryChanged(cat),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() {
            final displayMonths = controller.availableMonths
                .map((m) => m['display'] ?? '')
                .where((d) => d.isNotEmpty)
                .toList();
            if (displayMonths.isNotEmpty &&
                !displayMonths.contains(selectedMonthYear.value)) {
              selectedMonthYear.value = displayMonths.first;
            }
            return CustomDropdown<String>(
              backgroundColor: const Color(0xffF3F4F6),
              selectedValue: selectedMonthYear.value,
              items: displayMonths.isEmpty
                  ? (selectedMonthYear.value.isNotEmpty
                      ? [selectedMonthYear.value]
                      : ['No data'])
                  : displayMonths,
              itemLabel: (month) => month,
              hintText: "Month/Year",
              onChanged: (monthYear) {
                // Persist user's choice in the controller so tab switches
                // don't reset it.
                controller.userSelectedMonthYear.value = monthYear;
                final matchingMonth = controller.availableMonths
                    .firstWhereOrNull((m) => m['display'] == monthYear);
                if (matchingMonth != null) {
                  controller.selectedMonth.value =
                      matchingMonth['month'] ?? '';
                  controller.selectedYear.value =
                      matchingMonth['year'] ?? '';
                  controller.getBroodStock();
                } else {
                  final parts = monthYear.split(' ');
                  if (parts.length == 2) {
                    controller.onMonthYearChanged(
                        parts[0].toLowerCase(), parts[1]);
                  }
                }
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Broodstock List ─────────────────────────────────────────────────
  Widget _buildBroodstockList() {
    return AnimatedAppearance(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredBroodStocks.length,
        itemBuilder: (context, index) {
          final data = controller.filteredBroodStocks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHatcheryCard(data),
          );
        },
      ),
    );
  }

  // ── Hatchery Card ───────────────────────────────────────────────────
  Widget _buildHatcheryCard(BroodstockData data) {
    return InkWell(
      onTap: () {
        Get.to(HatcheryCateogryScreen(
          hatcheryId: data.hatcheryId.toString(),
          hatcheryName: data.hatcheryName,
          useHatcheryId: true,
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row with image + name + category
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hatchery image
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFE8F4FD),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: data.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              data.image.startsWith('http')
                                  ? data.image
                                  : '${NetworkConfig.imageURL}/${data.image}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.water_drop_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.water_drop_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Location + Supplier
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.hatcheryName,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if (data.locationName.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  data.locationName,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (data.supplierName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            data.supplierName,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Category badge
                  if (data.categoryName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.categoryName,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info chips row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  _infoChip(
                    Icons.inventory_2_outlined,
                    data.availableQuantity.replaceAll("Pieces", "").trim(),
                    'Pieces',
                  ),
                  const SizedBox(width: 8),
                  if (data.importedDate.isNotEmpty)
                    _infoChip(
                      Icons.calendar_today_outlined,
                      data.importedDate,
                      'Imported',
                    ),
                ],
              ),
            ),

            // Description
            if (data.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: ExpandableDescription(text: data.description),
              ),

            // Status + Arrow
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  _buildStatusBadge(data),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BroodstockData data) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    // The API stores the date in `available_on` as a single string like
    // "Available on 05/04/2026" regardless of status. Extract just the date
    // portion so each status can render its own prefix + the date.
    final String dateOnly = data.availableOn
        .replaceAll('Shortly Available on ', '')
        .replaceAll('Shortly Available ', '')
        .replaceAll('Available on ', '')
        .replaceAll('Available ', '')
        .trim();

    switch (data.status) {
      case BroodstockStatus.available:
        label = dateOnly.isEmpty ? 'Available' : 'Available $dateOnly';
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        icon = Icons.check_circle_outline_rounded;
        break;
      case BroodstockStatus.comingSoon:
        label = dateOnly.isEmpty ? 'Coming Soon' : 'Coming Soon $dateOnly';
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.schedule_rounded;
        break;
      case BroodstockStatus.upcoming:
        label = dateOnly.isEmpty ? 'Upcoming' : 'Upcoming $dateOnly';
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF6B21A8);
        icon = Icons.upcoming_outlined;
        break;
      case BroodstockStatus.shortlyAvailable:
        label = dateOnly.isEmpty
            ? 'Shortly Available'
            : 'Shortly Available $dateOnly';
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFF9A3412);
        icon = Icons.timelapse_rounded;
        break;
      case BroodstockStatus.closed:
        label = 'Closed';
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.block_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label.replaceAll("Start", "").trim(),
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .15),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No brood stock available',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing the filters above',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer List ────────────────────────────────────────────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: hatcheryCardShimmer(),
      ),
    );
  }
}

// ── Shimmer Card ──────────────────────────────────────────────────────
Widget hatcheryCardShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 22,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 28,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Expandable Description ────────────────────────────────────────────
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
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : 2,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            if (widget.text.length > 80)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
