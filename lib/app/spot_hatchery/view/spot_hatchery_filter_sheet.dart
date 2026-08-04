import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:seedsuser/app/common/filter_bottom_sheet.dart';
import 'package:seedsuser/app/common/nearby.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';

// Re-exported so screens using this sheet get the radius without a second
// import — the chip label and the cut-off must always agree.
export 'package:seedsuser/app/common/nearby.dart' show kNearbyRadiusKm;

/// Filter group keys for the spot hatchery listing.
const String kSpotLocation = 'location';
const String kSpotCategory = 'category';
const String kSpotHatchery = 'hatchery';

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

/// Keeps only hatcheries within [kNearbyRadiusKm] of the user, nearest first.
///
/// Backs the "Nearby" chip above the list. A hatchery with no coordinates has
/// no measurable distance, so it can't be claimed to be nearby and is left
/// out — the "All" chip is how the user gets back to the full list. Returns
/// the list untouched if the user's location isn't known, so the caller can
/// keep showing everything rather than an empty screen.
List<SpotHatchery> applyNearbyFilter(
  List<SpotHatchery> list, {
  required double? userLat,
  required double? userLng,
}) {
  if (userLat == null || userLng == null) return list;

  final withDistance = <(SpotHatchery, double)>[];
  for (final spot in list) {
    final km = spotDistanceKm(spot, userLat, userLng);
    if (km != null && km <= kNearbyRadiusKm) withDistance.add((spot, km));
  }
  withDistance.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in withDistance) entry.$1];
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
      // Distance isn't offered here — it lives in the All / Nearby chips above
      // the list, where the client wanted it.
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
