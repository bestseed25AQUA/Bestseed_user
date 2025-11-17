import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';

// Data model for a single meal entry
class MealEntry {
  final String meal;
  final String quantity;

  MealEntry(this.meal, this.quantity);
}

// Data model for a daily feed record
class DailyFeedRecord {
  final String date;
  final bool isExpandable;
  bool isExpanded;
  final List<MealEntry> entries;
  final bool hasLink;

  DailyFeedRecord({
    required this.date,
    this.isExpandable = true,
    this.isExpanded = true,
    required this.entries,
    this.hasLink = false,
  });
}

class TankFeedScreen extends StatefulWidget {
  const TankFeedScreen({
    super.key,
    required this.tankId,
    required this.tankName,
    required this.farmName,
  });
  final String tankId;
  final String tankName;
  final String farmName;
  @override
  State<TankFeedScreen> createState() => _TankFeedScreenState();
}

class _TankFeedScreenState extends State<TankFeedScreen> {
  final TankController _tankController = Get.find<TankController>();
  // Mock data

  // Controllers for text fields per card
  final Map<int, TextEditingController> _mealControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    for (var controller in _mealControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEntry(int index, String date) async {
    final meal = _mealControllers[index]?.text.trim() ?? '';
    final quantity = _quantityControllers[index]?.text.trim() ?? '';

    if (meal.isEmpty || quantity.isEmpty) {
      CustomToast.show(message: 'Please enter meal and quantity');
      return;
    }

    // 🔥 Call API to add feed to server
    final success = await _tankController.addTodayTankQuntity(
      feedQty: quantity,
      mealQty: meal,
      tankId: widget.tankId,
      date: date,
    );

    if (success) {
      _mealControllers[index]?.clear();
      _quantityControllers[index]?.clear();

      _tankController.getTankHistory(widget.tankId);
    }
  }

  @override
  void initState() {
    _tankController.getTankHistory(widget.tankId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.farmName,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: Obx(() {
        final tankHistory = _tankController.tankHistoryData.value;
        if (_tankController.isTankHistoryLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 26.0, 16.0, 26.0),
                    child: Text(
                      widget.tankName,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Column(
                    children: List.generate(tankHistory?.dates.length ?? 0, (
                      index,
                    ) {
                      final tankDate = tankHistory!.dates[index];

                      if (!_mealControllers.containsKey(index)) {
                        _mealControllers[index] = TextEditingController();
                      }
                      if (!_quantityControllers.containsKey(index)) {
                        _quantityControllers[index] = TextEditingController();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DailyFeedCard(
                          isLoading:
                              _tankController.isAddingTodayTankQuntity.value,
                          record: DailyFeedRecord(
                            date: tankDate.date,
                            entries: tankDate.tankDateHistory.map((item) {
                              return MealEntry(
                                item.meals.toString(),
                                item.feedQuantity.toString(),
                              );
                            }).toList(),
                          ),
                          mealController:
                              _mealControllers[index] ??
                              TextEditingController(),
                          quantityController:
                              _quantityControllers[index] ??
                              TextEditingController(),
                          onTapHeader: () {},
                          onAdd: () => _addEntry(index, tankDate.date),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (_tankController.isAddingTodayTankQuntity.value)
              Positioned(
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(.3)),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// --- Daily Feed Card ---
class DailyFeedCard extends StatelessWidget {
  final DailyFeedRecord record;
  final TextEditingController mealController;
  final TextEditingController quantityController;
  final VoidCallback onTapHeader;
  final VoidCallback onAdd;
  final bool isLoading;

  const DailyFeedCard({
    super.key,
    required this.record,
    required this.mealController,
    required this.quantityController,
    required this.onTapHeader,
    required this.onAdd,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            spreadRadius: 0,
            blurRadius: 22,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: record.isExpandable ? onTapHeader : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        formatDate(record.date),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (record.hasLink)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.link,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  if (record.isExpandable)
                    Icon(
                      record.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black,
                    ),
                ],
              ),
            ),
          ),
          // Input Fields & Add Button
          // Input Fields & Add Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mealController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter Meals',
                      hintStyle: GoogleFonts.roboto(
                        color: Color(0xff908A8A),
                        fontSize: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200, // light grey fill
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none, // remove border
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(
                        color: Color(0xff908A8A),
                        fontSize: 10,
                      ),
                      hintText: 'Enter Feed Quantity',
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextButton.icon(
                    onPressed: !isLoading ? onAdd : null,
                    icon: Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text(
                      'Add',
                      style: GoogleFonts.roboto(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meal Entries
          if (record.isExpanded && record.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meals',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xff908A8A),
                        ),
                      ),
                      Text(
                        'Feed Quantity',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xff908A8A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ...record.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.meal,
                                style: GoogleFonts.roboto(
                                  color: Color(0xff908A8A),
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                entry.quantity,
                                style: GoogleFonts.roboto(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xffE4E4E4)),
                          SizedBox(height: 10),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String formatDate(String? date) {
  try {
    if (date == null || date.isEmpty) return "-";

    // Parse the input date (2025-08-09)
    DateTime parsed = DateTime.tryParse(date) ?? DateTime(0000);

    if (parsed.year == 0000) return "-";

    // Format to dd/MM/yyyy
    final String day = parsed.day.toString().padLeft(2, '0');
    final String month = parsed.month.toString().padLeft(2, '0');
    final String year = parsed.year.toString();

    return "$day/$month/$year";
  } catch (e) {
    return "-"; // safe fallback
  }
}
