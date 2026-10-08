/// What is paying for one farm, and whether it is closed to new data.
///
/// A farm is licensed INDIVIDUALLY: it sits inside a free period or under one
/// package. When neither holds it is LOCKED — still visible, still carrying
/// every record ever written to it, but closed to new entries until somebody
/// renews THAT farm. A farmer with three farms and one package has one working
/// farm and two locked ones, which is what was sold.
///
/// Mirrors `FarmLicenceService::statusFor()` on the server.
class FarmLicence {
  final bool isLocked;

  /// Why, in words meant for the farmer. Written server-side so the wording
  /// can change without a store release. Null when the farm is open.
  final String? lockReason;

  /// On the free plan, as opposed to under a paid package.
  final bool isFree;

  /// The day cover runs out, as the server formatted it. Null when there is
  /// no end date.
  final String? coverEndsOn;

  /// Whole days left. Negative once past, null when nothing expires.
  final int? daysRemaining;

  final bool neverExpires;

  const FarmLicence({
    this.isLocked = false,
    this.lockReason,
    this.isFree = true,
    this.coverEndsOn,
    this.daysRemaining,
    this.neverExpires = true,
  });

  /// What to assume when the server said nothing about this farm.
  ///
  /// Open, deliberately. An older build, or a farm fetched from an endpoint
  /// that does not carry licence state, must not read as locked — that would
  /// stop a paying farmer working over what is only missing data. The server
  /// refuses the write regardless, so being permissive here costs nothing.
  static const FarmLicence unknown = FarmLicence();

  factory FarmLicence.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unknown;

    return FarmLicence(
      isLocked: json['is_locked'] == true,
      lockReason: json['lock_reason']?.toString(),
      isFree: json['is_free'] != false,
      coverEndsOn: json['cover_ends_on']?.toString(),
      daysRemaining: json['days_remaining'] == null
          ? null
          : int.tryParse('${json['days_remaining']}'),
      neverExpires: json['never_expires'] == true,
    );
  }

  /// Close enough to expiry to be worth saying so on the card.
  ///
  /// Fifteen days, the same window the admin panel highlights a renewal in,
  /// so the farmer and the person who will take their call start worrying on
  /// the same day.
  bool get isExpiringSoon =>
      !isLocked &&
      !neverExpires &&
      daysRemaining != null &&
      daysRemaining! >= 0 &&
      daysRemaining! <= 15;

  /// What is running out, in the farmer's words rather than ours.
  String get coverLabel => isFree ? 'Free period' : 'Subscription';

  /// The line for the card when cover is running out. Null when there is
  /// nothing to say.
  String? get expiryNote {
    if (!isExpiringSoon) return null;

    final days = daysRemaining!;

    if (days == 0) return 'Your ${coverLabel.toLowerCase()} ends today';
    if (days == 1) return 'Your ${coverLabel.toLowerCase()} ends tomorrow';

    return 'Your ${coverLabel.toLowerCase()} ends in $days days';
  }

  /// The line for the strip above the farm photo, locked or expiring.
  ///
  /// Named, because a farmer with several farms reads this strip on one card
  /// and needs to know it is about THAT farm and not the account.
  String? noticeTextFor(String farmName) {
    final name = farmName.trim().isEmpty ? 'This farm' : farmName.trim();

    if (isLocked) {
      return lockReason == null
          ? '$name is read-only. Take a package to record data again.'
          : '$name — $lockReason';
    }

    if (!isExpiringSoon) return null;

    final days = daysRemaining!;
    final what = coverLabel.toLowerCase();

    final when = days == 0
        ? 'ends today'
        : days == 1
        ? 'ends tomorrow'
        : 'ends in $days days';

    return 'Your $what for $name $when. Renew to keep recording.';
  }
}
