import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

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
  const TankFeedScreen({super.key});

  @override
  State<TankFeedScreen> createState() => _TankFeedScreenState();
}

class _TankFeedScreenState extends State<TankFeedScreen> {
  // Mock data
  final List<DailyFeedRecord> _records = [
    DailyFeedRecord(
      date: '09 /08/2025',
      isExpandable: false,
      isExpanded: true,
      entries: [],
    ),
    DailyFeedRecord(
      date: '08 /08/2025',
      isExpanded: true,
      hasLink: true,
      entries: [MealEntry('02', '400 Kgs'), MealEntry('01', '400 Kgs')],
    ),
    DailyFeedRecord(
      date: '07 /08/2025',
      isExpanded: false,
      entries: [
        MealEntry('02', '400 Kgs'),
        MealEntry('01', '400 Kgs'),
        MealEntry('03', '400 Kgs'),
      ],
    ),
  ];

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

  void _toggleExpansion(int index) {
    if (_records[index].isExpandable) {
      setState(() {
        _records[index].isExpanded = !_records[index].isExpanded;
      });
    }
  }

  void _addEntry(int index) {
    final meal = _mealControllers[index]?.text ?? '';
    final quantity = _quantityControllers[index]?.text ?? '';

    if (meal.isNotEmpty && quantity.isNotEmpty) {
      setState(() {
        _records[index].entries.add(MealEntry(meal, quantity));
        _mealControllers[index]?.clear();
        _quantityControllers[index]?.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            'Sattamma Thalli - A section',
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
              child: Text(
                'Tank 1',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ..._records.asMap().entries.map((entry) {
              int index = entry.key;
              DailyFeedRecord record = entry.value;

              // Initialize controllers if not exist
              _mealControllers.putIfAbsent(
                index,
                () => TextEditingController(),
              );
              _quantityControllers.putIfAbsent(
                index,
                () => TextEditingController(),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DailyFeedCard(
                  record: record,
                  mealController: _mealControllers[index]!,
                  quantityController: _quantityControllers[index]!,
                  onTapHeader: () => _toggleExpansion(index),
                  onAdd: () => _addEntry(index),
                ),
              );
            }).toList(),
          ],
        ),
      ),
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

  const DailyFeedCard({
    super.key,
    required this.record,
    required this.mealController,
    required this.quantityController,
    required this.onTapHeader,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                        record.date,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                    decoration: InputDecoration(
                      hintText: 'Enter Meals',
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
                    decoration: InputDecoration(
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
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
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
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Feed Quantity',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  ...record.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.meal,
                            style: GoogleFonts.roboto(color: Colors.black87),
                          ),
                          Text(
                            entry.quantity,
                            style: GoogleFonts.roboto(color: Colors.black87),
                          ),
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
