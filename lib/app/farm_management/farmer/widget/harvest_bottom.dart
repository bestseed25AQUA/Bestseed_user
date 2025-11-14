import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';

// --- Harvest Bottom Sheet Widget ---
class HarvestBottomSheet extends StatelessWidget {
  final TankModel tank;
  final int statusToUpdate;
  final VoidCallback onSubmit;

  HarvestBottomSheet({
    super.key,
    required this.tank,
    required this.statusToUpdate,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    // We wrap the content in a Padding and a Container to control the height
    // and shape of the bottom sheet.
    return Padding(
      // This is crucial for handling the keyboard pushing the content up
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        // Set the height to be dynamic, based on content
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.9, // Max 90% of screen height
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total Fields Label
              Text(
                'Total Fields',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Total Fields Display (Read-only/Fixed Value)
              const ReadOnlyInput(text: '3200 kgs'),
              const SizedBox(height: 24),

              // Days Label
              Text(
                'Days',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Days Display (Read-only/Fixed Value)
              ReadOnlyInput(text: '${tank.totalFeedUsed ?? "0"} kgs'),

              const SizedBox(height: 24),

              // Count Label and Input
              ReadOnlyInput(text: '${tank.meals ?? 0}'),

              const SizedBox(height: 8),
              const EditableInput(hint: 'Enter count'),
              const SizedBox(height: 24),

              // Harvest Quantity Label and Input
              const OptionalInputLabel(text: 'Harvest Quantity'),
              const SizedBox(height: 8),
              const EditableInput(hint: 'Enter Harvest Quantity'),
              const SizedBox(height: 40),

              // Inactive/Action Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: onSubmit,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935), // Bright Red
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Inactive',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Padding below the button
            ],
          ),
        ),
      ),
    );
  }
}

// --- Reusable Widget for Read-Only Inputs (Total Fields, Days) ---
class ReadOnlyInput extends StatelessWidget {
  final String text;
  const ReadOnlyInput({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light grey background
        borderRadius: BorderRadius.circular(8),
        // Add a subtle border to match the input look
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// --- Reusable Widget for Editable Inputs (Count, Harvest Quantity) ---
class EditableInput extends StatelessWidget {
  final String hint;
  const EditableInput({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500),

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
    );
  }
}

// --- Reusable Widget for Optional Labels ---
class OptionalInputLabel extends StatelessWidget {
  final String text;
  const OptionalInputLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *optional',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
