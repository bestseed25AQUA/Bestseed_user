import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';

/// Pick people to give farm access to, by name or mobile number.
///
/// This is the only way access is granted. Anyone chosen here holds it as soon
/// as the form is saved and the farm appears in their app.
class FarmerPicker extends StatefulWidget {
  /// Currently selected people, as `{id, name, mobile}`.
  final List<Map<String, dynamic>> selected;

  /// Called whenever the selection changes.
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const FarmerPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<FarmerPicker> createState() => _FarmerPickerState();
}

class _FarmerPickerState extends State<FarmerPicker> {
  final TextEditingController _search = TextEditingController();
  final FarmAccessController _controller = Get.put(FarmAccessController());

  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Debounced so typing a phone number is one request, not ten.
  void _onQueryChanged(String value) {
    _debounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final found = await _controller.searchFarmers(value);
      if (!mounted) return;

      setState(() {
        _results = found;
        _searching = false;
      });
    });
  }

  bool _isSelected(Map<String, dynamic> person) =>
      widget.selected.any((p) => p['id'] == person['id']);

  void _toggle(Map<String, dynamic> person) {
    final next = [...widget.selected];

    if (_isSelected(person)) {
      next.removeWhere((p) => p['id'] == person['id']);
    } else {
      next.add(person);
    }

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Give access to people',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'They get access straight away.',
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _search,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search by name or mobile number',
            hintStyle: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Who is already chosen, so the list is visible without scrolling
        // back through search results.
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selected.map((person) {
              return Chip(
                label: Text(
                  person['name']?.toString().trim().isNotEmpty == true
                      ? person['name'].toString()
                      : person['mobile'].toString(),
                  style: GoogleFonts.roboto(fontSize: 13),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _toggle(person),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              );
            }).toList(),
          ),
        ],

        if (_results.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, i) {
                final person = _results[i];
                final selected = _isSelected(person);

                return ListTile(
                  dense: true,
                  onTap: () => _toggle(person),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (person['name']?.toString().trim().isNotEmpty == true
                              ? person['name'].toString()[0]
                              : '?')
                          .toUpperCase(),
                      style: GoogleFonts.roboto(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    person['name']?.toString().trim().isNotEmpty == true
                        ? person['name'].toString()
                        : 'Farmer #${person['id']}',
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                  subtitle: Text(
                    person['mobile']?.toString() ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(
                    selected ? Icons.check_circle : Icons.add_circle_outline,
                    color: selected ? AppColors.primary : Colors.grey.shade400,
                    size: 22,
                  ),
                );
              },
            ),
          ),
        ],

        if (_search.text.trim().length >= 3 &&
            !_searching &&
            _results.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'No one found for "${_search.text.trim()}"',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
