import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Partners / Manager pill switch used by the access list screens.
class RoleTabBar extends StatelessWidget {
  /// Either `partner` or `manager`.
  final String selected;
  final ValueChanged<String> onChanged;

  const RoleTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _pill(label: 'Partners', value: 'partner'),
          const SizedBox(width: 12),
          _pill(label: 'Manager', value: 'manager'),
        ],
      ),
    );
  }

  Widget _pill({required String label, required String value}) {
    final isSelected = selected == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F0FA) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
