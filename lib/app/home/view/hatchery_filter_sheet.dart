import 'package:flutter/material.dart';

import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';

/// Filter group keys for the hatchery listing.
const String kHatcheryLocation = 'location';
const String kHatcheryCategory = 'category';
const String kHatcheryBrand = 'brand';

/// Opens the filter sheet for the hatchery listing and applies the result.
///
/// Unlike the vehicle and spot-hatchery sheets, this one does NOT filter a
/// local list: [FilterHatcheryController] already filters server-side by
/// category / brand / location ids, and until now nothing in the UI let the
/// user reach it — the ids were only ever set by the home screen's category
/// tabs. So the sheet writes the controller's id sets and re-runs applyFilter().
///
/// Because the matching happens on the server there is no way to preview a
/// result count, hence no `matchCount` — the sheet's button reads
/// "Apply filters" instead of "Show N results".
Future<bool> showHatcheryFilterSheet(
  BuildContext context,
  FilterHatcheryController controller,
) async {
  // The controller stores ids; the sheet works in display names. Build both
  // directions up front so the mapping is unambiguous even when two rows share
  // a name.
  final categoryNameById = {
    for (final c in controller.categories) '${c.id}': c.categoryName,
  };
  final brandNameById = {
    for (final b in controller.brands) '${b.id}': b.brandName,
  };
  final locationNameById = {
    for (final l in controller.locations) '${l.id}': l.locationName,
  };

  Set<String> namesFor(Map<String, String> nameById, Iterable<String> ids) =>
      ids.map((id) => nameById[id]).whereType<String>().toSet();

  Set<String> idsFor(Map<String, String> nameById, Set<String> names) =>
      nameById.entries
          .where((e) => names.contains(e.value))
          .map((e) => e.key)
          .toSet();

  // Reset re-queries with no filters straight away. This one goes through the
  // server, so it clears the controller's ids and refetches rather than just
  // clearing local state.
  Future<void> applySelection(FilterSelection selection) async {
    controller.selectedCategoryIds
      ..clear()
      ..addAll(idsFor(categoryNameById, selection.of(kHatcheryCategory)));
    controller.selectedBrandIds
      ..clear()
      ..addAll(idsFor(brandNameById, selection.of(kHatcheryBrand)));
    controller.selectedLocationIds
      ..clear()
      ..addAll(idsFor(locationNameById, selection.of(kHatcheryLocation)));

    // Re-query from page 1 — keeping the old page number would ask the server
    // for e.g. page 3 of a much shorter filtered result and show nothing.
    controller.page = 1;
    await controller.applyFilter();
  }

  final result = await showFilterSheet(
    context,
    onReset: applySelection,
    initial: FilterSelection(
      values: {
        kHatcheryCategory: namesFor(
          categoryNameById,
          controller.selectedCategoryIds,
        ),
        kHatcheryBrand: namesFor(brandNameById, controller.selectedBrandIds),
        kHatcheryLocation: namesFor(
          locationNameById,
          controller.selectedLocationIds,
        ),
      },
    ),
    groups: [
      FilterGroup(
        key: kHatcheryLocation,
        title: 'Location',
        options: _sorted(locationNameById.values),
      ),
      FilterGroup(
        key: kHatcheryCategory,
        title: 'Category',
        options: _sorted(categoryNameById.values),
      ),
      FilterGroup(
        key: kHatcheryBrand,
        title: 'Brand',
        options: _sorted(brandNameById.values),
      ),
    ],
  );

  // Dismissed. A Reset tapped before closing has already been applied, so the
  // list correctly stays cleared rather than reverting.
  if (result == null) return false;

  await applySelection(result);
  return true;
}

List<String> _sorted(Iterable<String> values) {
  final list = values.where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
  return list;
}
