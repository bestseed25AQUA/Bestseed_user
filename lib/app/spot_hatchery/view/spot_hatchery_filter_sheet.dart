import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';

/// Filter group keys for the spot hatchery listing.
const String kSpotLocation = 'location';
const String kSpotCategory = 'category';
const String kSpotHatchery = 'hatchery';
const String kSpotSort = 'sort';

/// Hatcheries closer than this count as "nearby". Sorting ascending by
/// distance already puts them ahead of everything else, so this drives the
/// label rather than a separate cut — nothing is ever hidden by the sort.
const int kNearbyRadiusKm = 150;

const String kSortNearby = 'Nearby (within $kNearbyRadiusKm km first)';
const String kSortFarthest = 'Farthest first';

/// Great-circle distance in km between two coordinates (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double toRad(double deg) => deg * math.pi / 180.0;

  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Distance from the user to [spot], or null when either end has no
/// coordinates (the admin hasn't geocoded the location, or GPS is unavailable).
double? spotDistanceKm(SpotHatchery spot, double? userLat, double? userLng) {
  if (userLat == null || userLng == null) return null;
  final lat = spot.latitude;
  final lng = spot.longitude;
  if (lat == null || lng == null) return null;
  return distanceKm(userLat, userLng, lat, lng);
}

/// Applies the chosen sort. Hatcheries with no usable distance always sink to
/// the bottom rather than being dropped, and the list is returned untouched
/// when no sort is picked or the user's location is unknown.
List<SpotHatchery> applySpotSort(
  List<SpotHatchery> list,
  FilterSelection filters, {
  required double? userLat,
  required double? userLng,
}) {
  final sort = filters.one(kSpotSort);
  if (sort == null || userLat == null || userLng == null) return list;

  final sorted = [...list];
  sorted.sort((a, b) {
    final da = spotDistanceKm(a, userLat, userLng);
    final db = spotDistanceKm(b, userLat, userLng);
    if (da == null && db == null) return 0;
    if (da == null) return 1; // unknown distance goes last in both modes
    if (db == null) return -1;
    return sort == kSortFarthest ? db.compareTo(da) : da.compareTo(db);
  });
  return sorted;
}

/// Does [spot] pass every active filter?
bool spotHatcheryMatchesFilters(SpotHatchery spot, FilterSelection f) {
  if (!f.allows(kSpotCategory, spot.categoryName)) return false;
  if (!f.allows(kSpotLocation, spot.locationName)) return false;
  if (!f.allows(kSpotHatchery, spot.selectedHatchery?.hatcheryName)) {
    return false;
  }

  final range = f.dateRange;
  if (range != null) {
    // A spot hatchery has a single availability day rather than a window, so
    // it matches when that day falls inside the chosen range.
    final availableOn = DateTime.tryParse(spot.availableOn ?? '');
    if (availableOn == null) return false;
    final day = DateUtils.dateOnly(availableOn);
    if (day.isBefore(DateUtils.dateOnly(range.start))) return false;
    if (day.isAfter(DateUtils.dateOnly(range.end))) return false;
  }

  return true;
}

List<String> _sortedUnique(Iterable<String> values) {
  final list = values.where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
  return list;
}

/// Filter sheet for the spot hatchery listing. Options are derived from the
/// loaded hatcheries so it never offers a choice that matches nothing.
Future<FilterSelection?> showSpotHatcheryFilterSheet(
  BuildContext context, {
  required List<SpotHatchery> hatcheries,
  required FilterSelection initial,
  bool canSortByDistance = true,
  ValueChanged<FilterSelection>? onReset,
}) {
  return showFilterSheet(
    context,
    initial: initial,
    dateTitle: 'Available between',
    resultNoun: 'hatchery',
    onReset: onReset,
    matchCount: (selection) =>
        hatcheries.where((h) => spotHatcheryMatchesFilters(h, selection)).length,
    groups: [
      // Offered only when at least one hatchery has coordinates — a sort that
      // cannot reorder anything is worse than no sort at all.
      if (canSortByDistance &&
          hatcheries.any((h) => h.latitude != null && h.longitude != null))
        const FilterGroup(
          key: kSpotSort,
          title: 'Sort by',
          singleSelect: true,
          options: [kSortNearby, kSortFarthest],
        ),
      FilterGroup(
        key: kSpotLocation,
        title: 'Location',
        options: _sortedUnique(hatcheries.map((h) => h.locationName ?? '')),
      ),
      FilterGroup(
        key: kSpotCategory,
        title: 'Category',
        options: _sortedUnique(hatcheries.map((h) => h.categoryName)),
      ),
      FilterGroup(
        key: kSpotHatchery,
        title: 'Hatchery',
        options: _sortedUnique(
          hatcheries.map((h) => h.selectedHatchery?.hatcheryName ?? ''),
        ),
      ),
    ],
  );
}
