import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:seedsuser/app/common/app_color.dart';

/// One group of multi-select chips in the filter sheet (e.g. "Category").
class FilterGroup {
  /// Stable identifier used to look the group's selection up in
  /// [FilterSelection.of] — not shown to the user.
  final String key;

  /// Section heading.
  final String title;

  /// Values offered. Derive these from the data actually on screen so the
  /// sheet never offers a choice that matches nothing.
  final List<String> options;

  /// When true only one option can be active at a time, and tapping the
  /// selected one clears it. Used for choices that are mutually exclusive —
  /// a sort order can't be both Nearby and Farthest.
  final bool singleSelect;

  const FilterGroup({
    required this.key,
    required this.title,
    required this.options,
    this.singleSelect = false,
  });
}

/// What the user picked. An empty selection matches everything, so callers can
/// use `const FilterSelection()` as the "no filters" default.
class FilterSelection {
  final Map<String, Set<String>> values;
  final DateTimeRange? dateRange;

  const FilterSelection({this.values = const {}, this.dateRange});

  Set<String> of(String key) => values[key] ?? const {};

  /// The chosen value of a `singleSelect` group, or null when untouched.
  String? one(String key) {
    final selected = of(key);
    return selected.isEmpty ? null : selected.first;
  }

  bool get isEmpty =>
      dateRange == null && values.values.every((set) => set.isEmpty);

  /// Number of groups in use — drives the badge on the filter button.
  int get activeCount =>
      values.values.where((set) => set.isNotEmpty).length +
      (dateRange == null ? 0 : 1);

  /// True when [value] passes the group's filter. An untouched group imposes
  /// no restriction, which is what makes filters compose.
  bool allows(String key, String? value) {
    final selected = of(key);
    if (selected.isEmpty) return true;
    return selected.contains(value ?? '');
  }

  /// True when any of [candidates] is selected — for one-to-many fields such as
  /// a vehicle's route, where matching any stop should count.
  bool allowsAny(String key, Iterable<String> candidates) {
    final selected = of(key);
    if (selected.isEmpty) return true;
    return candidates.any(selected.contains);
  }
}

/// Shared filter bottom sheet used by the vehicle, spot hatchery and hatchery
/// listings. Returns the chosen filters, or null if dismissed without applying.
///
/// [matchCount] powers the live "Show N results" button and disables Apply when
/// nothing matches. Pass null when filtering happens server-side and the count
/// can't be known up front — the button then just reads "Apply filters".
/// [onReset] fires the moment Reset is tapped, with an empty selection, so the
/// caller can clear the list straight away instead of the user having to tap
/// Apply afterwards. The sheet stays open, and because the reset is already
/// applied, dismissing with X leaves the list cleared rather than reverting.
Future<FilterSelection?> showFilterSheet(
  BuildContext context, {
  required List<FilterGroup> groups,
  required FilterSelection initial,
  String? dateTitle,
  int Function(FilterSelection)? matchCount,
  String resultNoun = 'result',
  ValueChanged<FilterSelection>? onReset,
}) {
  return showModalBottomSheet<FilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _FilterBottomSheet(
      groups: groups,
      initial: initial,
      dateTitle: dateTitle,
      matchCount: matchCount,
      resultNoun: resultNoun,
      onReset: onReset,
    ),
  );
}

class _FilterBottomSheet extends StatefulWidget {
  final List<FilterGroup> groups;
  final FilterSelection initial;
  final String? dateTitle;
  final int Function(FilterSelection)? matchCount;
  final String resultNoun;
  final ValueChanged<FilterSelection>? onReset;

  const _FilterBottomSheet({
    required this.groups,
    required this.initial,
    required this.dateTitle,
    required this.matchCount,
    required this.resultNoun,
    this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Map<String, Set<String>> _values = {
    for (final g in widget.groups) g.key: {...widget.initial.of(g.key)},
  };
  late DateTimeRange? _dateRange = widget.initial.dateRange;

  FilterSelection get _current =>
      FilterSelection(values: _values, dateRange: _dateRange);

  /// Clears every group and the date range, and applies that to the list right
  /// away via [onReset] — waiting for Apply made Reset look like it had done
  /// nothing. The sheet stays open so the user can pick new filters, and since
  /// the clear is already committed, closing with X keeps the list reset.
  void _resetAll() {
    setState(() {
      _values = {for (final g in widget.groups) g.key: <String>{}};
      _dateRange = null;
    });
    widget.onReset?.call(_current);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _header(),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (widget.dateTitle != null) _dateSection(),
                    ...widget.groups.map(_chipSection),
                  ],
                ),
              ),
              _footer(),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Filters',
            style: GoogleFonts.roboto(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _dateSection() {
    final fmt = DateFormat('dd MMM, yyyy');
    final label = _dateRange == null
        ? 'Any dates'
        : '${fmt.format(_dateRange!.start)}  →  ${fmt.format(_dateRange!.end)}';
    final active = _dateRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(widget.dateTitle!),
        InkWell(
          onTap: _pickDateRange,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : Colors.grey.shade300,
              ),
              color: active
                  ? AppColors.primary.withOpacity(0.06)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: active ? AppColors.primary : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (active)
                  InkWell(
                    onTap: () => setState(() => _dateRange = null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipSection(FilterGroup group) {
    if (group.options.isEmpty) return const SizedBox.shrink();
    final selected = _values[group.key] ?? <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(group.title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.options.map((option) {
            final isOn = selected.contains(option);
            return InkWell(
              onTap: () => setState(() {
                if (group.singleSelect) {
                  // Tapping the active option clears it; anything else
                  // replaces the selection.
                  _values[group.key] = isOn ? <String>{} : {option};
                } else {
                  if (!selected.remove(option)) selected.add(option);
                  _values[group.key] = selected;
                }
              }),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOn
                      ? AppColors.primary.withOpacity(0.1)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOn) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      option,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
                        color: isOn ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _footer() {
    final count = widget.matchCount?.call(_current);
    // Applying with zero matches would leave the user staring at an empty
    // list, so the button is blocked when we know nothing matches.
    final blocked = count == 0;

    final String label;
    if (count == null) {
      label = 'Apply filters';
    } else if (count == 0) {
      label = 'No ${widget.resultNoun}s match';
    } else {
      label = 'Show $count ${widget.resultNoun}${count == 1 ? '' : 's'}';
    }

    final canReset = !_current.isEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            // Clears every group and the date range in one tap. Greyed out
            // when there is nothing to clear, so it never looks like a
            // control that did nothing.
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: canReset ? _resetAll : null,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Reset',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: canReset
                        ? const Color(0xFFEF4444)
                        : Colors.grey.shade400,
                    side: BorderSide(
                      color: canReset
                          ? const Color(0xFFEF4444)
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      blocked ? null : () => Navigator.pop(context, _current),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter button for a screen's search row. The badge showing how many groups
/// are active matters: without it a filtered list reads as missing data.
class FilterIconButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  /// Sized to sit level with the screen's search field, which is not the same
  /// height on every listing.
  final double height;
  final double width;

  const FilterIconButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.height = 48,
    this.width = 52,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 22,
              color: active ? Colors.white : Colors.grey.shade700,
            ),
            if (active)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
