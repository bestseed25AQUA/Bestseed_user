import 'package:flutter/material.dart';

import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';

/// Filter group keys for the vehicle listing.
const String kVehicleLocation = 'location';
const String kVehicleCategory = 'category';
const String kVehicleHatchery = 'hatchery';

/// Every place name a vehicle can be found under — its own location plus each
/// stop on the route. The card advertises the whole route, so someone
/// filtering for "Nellore" should match a Srikakulam → Nellore → Chennai
/// vehicle rather than only ones based in Nellore.
Set<String> _vehiclePlaces(VehicleAvailability v) => {
  if ((v.locationName ?? '').isNotEmpty) v.locationName!,
  ...v.locations.map((l) => l.name).where((n) => n.isNotEmpty),
};

/// Does [vehicle] pass every active filter?
bool vehicleMatchesFilters(VehicleAvailability vehicle, FilterSelection f) {
  if (!f.allows(kVehicleCategory, vehicle.categoryName)) return false;
  if (!f.allowsAny(kVehicleLocation, _vehiclePlaces(vehicle))) return false;
  if (!f.allows(kVehicleHatchery, vehicle.selectedHatchery?.hatcheryName)) {
    return false;
  }

  final range = f.dateRange;
  if (range != null) {
    // Keep vehicles whose availability window OVERLAPS the chosen range, not
    // just those fully inside it — a vehicle running 28 Jul–05 Aug is
    // genuinely available to someone searching 01–02 Aug.
    final start = DateTime.tryParse(vehicle.startDate ?? '');
    final end = DateTime.tryParse(vehicle.endDate ?? '') ?? start;
    if (start == null || end == null) return false;
    if (DateUtils.dateOnly(end).isBefore(DateUtils.dateOnly(range.start))) {
      return false;
    }
    if (DateUtils.dateOnly(start).isAfter(DateUtils.dateOnly(range.end))) {
      return false;
    }
  }

  return true;
}

List<String> _sortedUnique(Iterable<String> values) {
  final list = values.where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
  return list;
}

/// Filter sheet for the vehicle availability listing. Options are derived from
/// the loaded vehicles so it never offers a choice that matches nothing.
Future<FilterSelection?> showVehicleFilterSheet(
  BuildContext context, {
  required List<VehicleAvailability> vehicles,
  required FilterSelection initial,
  ValueChanged<FilterSelection>? onReset,
}) {
  return showFilterSheet(
    context,
    initial: initial,
    dateTitle: 'Available between',
    resultNoun: 'vehicle',
    onReset: onReset,
    matchCount: (selection) =>
        vehicles.where((v) => vehicleMatchesFilters(v, selection)).length,
    groups: [
      FilterGroup(
        key: kVehicleLocation,
        title: 'Location / Route',
        options: _sortedUnique(vehicles.expand(_vehiclePlaces)),
      ),
      FilterGroup(
        key: kVehicleCategory,
        title: 'Category',
        options: _sortedUnique(vehicles.map((v) => v.categoryName ?? '')),
      ),
      FilterGroup(
        key: kVehicleHatchery,
        title: 'Hatchery',
        options: _sortedUnique(
          vehicles.map((v) => v.selectedHatchery?.hatcheryName ?? ''),
        ),
      ),
    ],
  );
}
