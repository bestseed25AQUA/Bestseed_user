/// One recorded change to a farm.
///
/// Every field the history row shows comes down preformatted where formatting
/// is involved, so the same change reads identically on every device whatever
/// its locale is set to.
class FarmActivity {
  final int id;

  /// farm | tank | feed | store | access.
  final String category;
  final String categoryLabel;

  /// created | updated | deleted | activated | harvested | granted | revoked.
  final String action;

  /// The whole change in one sentence, written server-side at the moment it
  /// happened — the only point at which both the old and the new value are
  /// known.
  final String description;

  final int? tankId;
  final String? tankName;

  final String? actorName;
  final String? actorMobile;

  /// What they were on this farm when they did it: owner, partner, manager or
  /// admin. Someone's role changes; what they were at the time does not.
  final String? actorRole;

  final String? happenedOn;
  final String? happenedAt;

  /// Parsed from the ISO timestamp, for grouping rows by day.
  final DateTime? createdAt;

  const FarmActivity({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.action,
    required this.description,
    this.tankId,
    this.tankName,
    this.actorName,
    this.actorMobile,
    this.actorRole,
    this.happenedOn,
    this.happenedAt,
    this.createdAt,
  });

  factory FarmActivity.fromJson(Map<String, dynamic> json) {
    return FarmActivity(
      id: int.tryParse('${json['id']}') ?? 0,
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tankId: int.tryParse('${json['tank_id']}'),
      tankName: json['tank_name']?.toString(),
      actorName: json['actor_name']?.toString(),
      actorMobile: json['actor_mobile']?.toString(),
      actorRole: json['actor_role']?.toString(),
      happenedOn: json['happened_on']?.toString(),
      happenedAt: json['happened_at']?.toString(),
      createdAt: DateTime.tryParse('${json['created_at']}'),
    );
  }

  /// Who did it, as one line. The mobile is part of the identity, not
  /// decoration: two people called Ramesh on one farm is the ordinary case,
  /// and the number is what tells them apart.
  String get actorLabel {
    final name = (actorName ?? '').trim();
    final who = name.isEmpty ? 'Unknown' : name;
    final mobile = (actorMobile ?? '').trim();

    return mobile.isEmpty ? who : '$who · $mobile';
  }

  /// The day this belongs under, as a heading.
  String get dayKey => happenedOn ?? '';
}

/// One filter chip.
class ActivityCategory {
  final String key;
  final String label;

  const ActivityCategory({required this.key, required this.label});

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

/// A farm's history as the server sends it.
class FarmActivityFeed {
  /// How far back this covers. Sent rather than hardcoded so the empty state
  /// can say "nothing in the last 15 days" instead of "no history", which
  /// reads as never.
  final int windowDays;

  final List<ActivityCategory> categories;
  final List<FarmActivity> entries;

  const FarmActivityFeed({
    required this.windowDays,
    required this.categories,
    required this.entries,
  });

  factory FarmActivityFeed.empty() =>
      const FarmActivityFeed(windowDays: 15, categories: [], entries: []);

  factory FarmActivityFeed.fromJson(Map<String, dynamic> json) {
    return FarmActivityFeed(
      windowDays: int.tryParse('${json['window_days']}') ?? 15,
      categories: (json['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ActivityCategory.fromJson)
          .toList(),
      entries: (json['entries'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FarmActivity.fromJson)
          .toList(),
    );
  }

  /// Entries grouped under their day, newest day first.
  ///
  /// The server already returns them newest-first, so walking in order and
  /// starting a new group whenever the date changes preserves that without a
  /// second sort.
  List<MapEntry<String, List<FarmActivity>>> get byDay {
    final groups = <String, List<FarmActivity>>{};

    for (final entry in entries) {
      groups.putIfAbsent(entry.dayKey, () => []).add(entry);
    }

    return groups.entries.toList();
  }
}
