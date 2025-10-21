import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';

class FeedUpdateScreen extends StatelessWidget {
  const FeedUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adding feed'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Today's Feed Update Header
            Center(
              child: Text(
                "Today's feed Update",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4.0),
            Center(
              child: Text(
                "16/09/2025",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Tank 1 - Editable Card (with Edit button)
            const FeedUpdateCard(
              tankName: 'Tank 1',
              dayInfo: '16 Day',
              initialMeals: '2',
              initialQuantity: '250',
              showEditButton: true,
              showAddButton: false,
            ),
            const SizedBox(height: 16.0),

            // Tank 1 - Addable Card (with Add button)
            const FeedUpdateCard(
              tankName:
                  'Tank 1', // Assuming this is another section for the same tank or a different time
              dayInfo: '16 Day',
              initialMeals: '2',
              initialQuantity: '250',
              showEditButton: false,
              showAddButton: true,
            ),
            const SizedBox(height: 16.0),

            // Tank 2 - Placeholder Card (partial view in image)
            const FeedUpdateCard(
              tankName: 'Tank 2',
              dayInfo: '16 Day',
              initialMeals: '2',
              initialQuantity: '250',
              showEditButton: false,
              showAddButton:
                  false, // Placeholder, actual button state is unknown
            ),

            // Add more tanks if needed
          ],
        ),
      ),
    );
  }
}

class FeedUpdateCard extends StatelessWidget {
  final String tankName;
  final String dayInfo;
  final String initialMeals;
  final String initialQuantity;
  final bool showEditButton;
  final bool showAddButton;

  const FeedUpdateCard({
    super.key,
    required this.tankName,
    required this.dayInfo,
    required this.initialMeals,
    required this.initialQuantity,
    this.showEditButton = false,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Tank Name and Day Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                tankName,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dayInfo,
                style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Meals Section
          Text(
            'Meals',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: initialMeals,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>['1', '2', '3', '4']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (String? newValue) {
                  // Handle meal selection change
                },
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Feed Quantity Section
          Text(
            'Feed Quantity',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: <Widget>[
              // Quantity Input Field
              Expanded(
                child: TextFormField(
                  initialValue: initialQuantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Unit Dropdown ('Kgs')
              SizedBox(
                width: 100, // Adjust width as needed
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Kgs',
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: <String>['Kgs', 'Grams', 'Lbs']
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? newValue) {
                        // Handle unit selection change
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Action Buttons (Edit or Add)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showEditButton)
                OutlinedButton(
                  onPressed: () {
                    // Handle Edit action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              if (showAddButton)
                ElevatedButton(
                  onPressed: () {
                    // Handle Add action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Add'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
