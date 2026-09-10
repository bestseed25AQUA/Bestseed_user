import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';

// --- Harvest Bottom Sheet Widget ---
class HarvestBottomSheet extends StatefulWidget {
  final TankModel tank;
  final int statusToUpdate;

  /// Called with what the crop weighed, or null when the farmer left it blank.
  ///
  /// Null and 0 are different: null is "not weighed", 0 would claim the crop
  /// yielded nothing. The server only writes a figure it was actually given.
  final Future<void> Function(double? harvestQuantity) onSubmit;

  const HarvestBottomSheet({
    super.key,
    required this.tank,
    required this.statusToUpdate,
    required this.onSubmit,
  });

  @override
  State<HarvestBottomSheet> createState() => _HarvestBottomSheetState();
}

class _HarvestBottomSheetState extends State<HarvestBottomSheet> {
  final TextEditingController _harvest = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Recompute the ratio as the figure is typed.
    _harvest.addListener(_onHarvestChanged);
  }

  void _onHarvestChanged() => setState(() {});

  @override
  void dispose() {
    _harvest.removeListener(_onHarvestChanged);
    _harvest.dispose();
    super.dispose();
  }

  /// Digits only — the hint reads "2,500 kg", so a farmer typing it back with
  /// the comma and unit must not be read as nothing.
  double? get _harvestValue {
    final cleaned = _harvest.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Kilos of feed per kilo harvested.
  ///
  /// Mirrors TankBatch::fcr() on the server, which is what every other screen
  /// reads — so the number shown here is the number that gets stored. Null
  /// rather than 0 when it cannot be stated: dividing by a zero harvest is
  /// undefined, and an unweighed crop has no ratio.
  double? get _fcr {
    final harvest = _harvestValue;
    final feed = double.tryParse('${widget.tank.totalFeedUsed ?? 0}') ?? 0;

    if (harvest == null || harvest <= 0 || feed <= 0) return null;

    return feed / harvest;
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the content in a Padding and a Container to control the height
    // and shape of the bottom sheet.
    return SafeArea(
      child: Padding(
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
                ReadOnlyInput(text: '${widget.tank.totalFeedUsed ?? "0"} kgs'),
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
                ReadOnlyInput(text: '${widget.tank.day ?? "0"} Days'),

                const SizedBox(height: 24),

                // Count Label and Input
                // ReadOnlyInput(text: '${widget.tank.meals ?? 0}'),

                // const SizedBox(height: 8),
                // const EditableInput(hint: 'Enter count'),
                // const SizedBox(height: 24),

                // // Harvest Quantity Label and Input
                // const OptionalInputLabel(text: 'Harvest Quantity'),
                // const SizedBox(height: 8),
                // const EditableInput(hint: 'Enter Harvest Quantity'),
                // const SizedBox(height: 40),

                // Total harvest — optional, and the other half of FCR.
                //
                // Feed is already known for this crop; with the weight that
                // came out, FCR is simply one divided by the other. Optional
                // because a farmer may harvest without weighing, and a guess
                // would be worse than no figure at all.
                const OptionalInputLabel(text: 'Total harvest for FCR'),
                const SizedBox(height: 8),
                EditableInput(
                  controller: _harvest,
                  hint: 'e.g., 2,500 kg',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                // The ratio, as it is typed. Shown only once it can actually be
                // stated — an empty or zero harvest has no FCR, and printing
                // "0.00" would look like a real, very good result.
                if (_fcr != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        size: 16,
                        color: Color(0xFF137333),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FCR ${_fcr!.toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF137333),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.tank.totalFeedUsed ?? 0} kg feed '
                          '\u00F7 ${_harvestValue!.toStringAsFixed(0)} kg harvest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Inactive/Action Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => widget.onSubmit(_harvestValue),

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

  /// Optional, so the existing call sites that only wanted the look are
  /// unchanged; a caller that needs the value passes one in.
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const EditableInput({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
