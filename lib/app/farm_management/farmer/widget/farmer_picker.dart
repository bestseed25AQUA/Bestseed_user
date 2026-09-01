import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/mobile_lookup.dart';

/// Pick people to give farm access to, by mobile number.
///
/// Only ever by the full 10-digit number, and only ever one person at a time.
/// Searching by name and showing a list of suggestions makes it far too easy
/// to tap the wrong "Ramesh" and hand a stranger the farm; a phone number is
/// something the owner already knows for the person standing in front of them.
///
/// A number nobody has registered is not a dead end: it can be added anyway,
/// and the farm is waiting for that person the first time they sign in.
class FarmerPicker extends StatefulWidget {
  /// Currently selected people.
  ///
  /// Registered people carry `{id, name, mobile}`. Someone added by a number
  /// with no account yet carries `{mobile, is_new: true}` and no id.
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
  final TextEditingController _mobile = TextEditingController();
  final FarmAccessController _controller = Get.put(FarmAccessController());

  MobileLookup _result = const MobileLookup.incomplete();
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _mobile.dispose();
    super.dispose();
  }

  /// Nothing is asked of the server until all ten digits are in.
  void _onChanged(String value) {
    _debounce?.cancel();

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10) {
      setState(() {
        _result = const MobileLookup.incomplete();
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    // Short, because this fires once — on the tenth digit — rather than on
    // every keystroke.
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await _controller.lookupByMobile(digits);
      if (!mounted) return;

      setState(() {
        _result = result;
        _searching = false;
      });
    });
  }

  bool _isSelected(String mobile) =>
      widget.selected.any((p) => '${p['mobile']}' == mobile);

  void _add(Map<String, dynamic> person) {
    if (_isSelected('${person['mobile']}')) return;

    widget.onChanged([...widget.selected, person]);

    // Clear for the next number, so adding several people in a row is just
    // type-tap, type-tap.
    _mobile.clear();
    setState(() => _result = const MobileLookup.incomplete());
  }

  void _remove(Map<String, dynamic> person) {
    widget.onChanged(
      widget.selected.where((p) => p['mobile'] != person['mobile']).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give access to people',
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter their 10-digit mobile number. They get access straight away.',
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _mobile,
          onChanged: _onChanged,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: 'Mobile number',
            counterText: '',
            hintStyle: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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

        if (!_searching) _resultBlock(),

        // Who is already chosen, so the list is visible without scrolling.
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selected.map(_chip).toList(),
          ),
        ],
      ],
    );
  }

  Widget _resultBlock() {
    switch (_result.status) {
      case MobileLookupStatus.incomplete:
        return const SizedBox.shrink();

      case MobileLookupStatus.found:
        return _foundCard(_result.person!);

      case MobileLookupStatus.notFound:
        return _notFoundCard(_result.mobile!);

      case MobileLookupStatus.error:
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            _result.message ?? 'Could not check that number.',
            style: GoogleFonts.roboto(fontSize: 13, color: Colors.red.shade700),
          ),
        );
    }
  }

  /// The one person who holds this number. Never a list.
  Widget _foundCard(Map<String, dynamic> person) {
    final name = '${person['name']}'.trim();
    final mobile = '${person['mobile']}';
    final already = _isSelected(mobile);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        onTap: already ? null : () => _add(person),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            (name.isNotEmpty ? name[0] : '?').toUpperCase(),
            style: GoogleFonts.roboto(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : 'Farmer $mobile',
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        subtitle: Text(
          mobile,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          already ? Icons.check_circle : Icons.add_circle_outline,
          color: already ? AppColors.primary : Colors.grey.shade400,
          size: 22,
        ),
      ),
    );
  }

  /// Nobody holds this number yet — offer to add them by it anyway.
  Widget _notFoundCard(String mobile) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 18,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No one is using $mobile yet',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You can still add them. They will find this farm waiting the '
            'first time they log in with this number.',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _add({'mobile': mobile, 'is_new': true}),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(
                'Add $mobile',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade900,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(Map<String, dynamic> person) {
    final isNew = person['is_new'] == true;
    final name = '${person['name'] ?? ''}'.trim();

    return Chip(
      avatar: isNew
          ? Icon(
              Icons.person_add_alt_1,
              size: 15,
              color: Colors.orange.shade800,
            )
          : null,
      label: Text(
        name.isNotEmpty ? '$name · ${person['mobile']}' : '${person['mobile']}',
        style: GoogleFonts.roboto(fontSize: 13),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _remove(person),
      backgroundColor: isNew
          ? Colors.orange.shade50
          : AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isNew
              ? Colors.orange.shade200
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
