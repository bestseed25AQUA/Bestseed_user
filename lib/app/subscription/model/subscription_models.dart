/// One package on offer, exactly as the server describes it.
///
/// Prices are NOT hardcoded in the app. They come down with the status call so
/// a change is a backend deploy rather than a store release, and so an old
/// install can never quote a price the helpline no longer honours.
class SubscriptionPlan {
  final String key;
  final String label;
  final int months;
  final double amount;

  /// Preformatted by the server, e.g. "₹1,899". Used as-is so every surface
  /// renders the price identically.
  final String priceLabel;

  /// What one month of this plan costs, for the "best value" badge. Null when
  /// the server could not work it out.
  final double? perMonth;

  const SubscriptionPlan({
    required this.key,
    required this.label,
    required this.months,
    required this.amount,
    required this.priceLabel,
    this.perMonth,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      months: int.tryParse('${json['months']}') ?? 1,
      amount: double.tryParse('${json['amount']}') ?? 0,
      priceLabel: json['price_label']?.toString() ?? '',
      perMonth: json['per_month'] == null
          ? null
          : double.tryParse('${json['per_month']}'),
    );
  }
}

/// The farmer's current or most recent subscription.
class SubscriptionDetails {
  final int id;
  final String planLabel;
  final String? expiresOn;
  final int daysRemaining;

  /// One of: active, expiring, expired, cancelled.
  final String state;

  final bool isActive;
  final bool isExpired;
  final bool isExpiringSoon;

  const SubscriptionDetails({
    required this.id,
    required this.planLabel,
    required this.expiresOn,
    required this.daysRemaining,
    required this.state,
    required this.isActive,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      id: int.tryParse('${json['id']}') ?? 0,
      planLabel: json['plan_label']?.toString() ?? '',
      expiresOn: json['expires_on']?.toString(),
      daysRemaining: int.tryParse('${json['days_remaining']}') ?? 0,
      state: json['state']?.toString() ?? 'active',
      isActive: json['is_active'] == true,
      isExpired: json['is_expired'] == true,
      isExpiringSoon: json['is_expiring_soon'] == true,
    );
  }

  /// How the expiry banner should read. Null when there is nothing to say.
  ///
  /// Only warns while the plan is actually close to running out, or has run
  /// out. A plan with four months left is not news.
  String? get warning {
    if (isExpired) {
      return expiresOn == null
          ? 'Your subscription has ended. Renew it to add more farms.'
          : 'Your subscription ended on $expiresOn. Renew it to add more farms.';
    }

    if (!isActive || !isExpiringSoon) return null;

    if (daysRemaining <= 0) {
      return 'Your $planLabel subscription ends today. Renew it to keep adding farms.';
    }

    if (daysRemaining == 1) {
      return 'Your $planLabel subscription ends tomorrow. Renew it to keep adding farms.';
    }

    return 'Your $planLabel subscription ends in $daysRemaining days'
        '${expiresOn == null ? '' : ' on $expiresOn'}. '
        'Renew it to keep adding farms.';
  }
}

/// The helpline to ring. There is no payment in the app.
class SubscriptionContact {
  final String? phone;
  final String? whatsapp;
  final String? label;

  const SubscriptionContact({this.phone, this.whatsapp, this.label});

  factory SubscriptionContact.fromJson(Map<String, dynamic> json) {
    return SubscriptionContact(
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      label: json['label']?.toString(),
    );
  }

  bool get hasPhone => (phone?.trim().isNotEmpty ?? false);
  bool get hasWhatsapp => (whatsapp?.trim().isNotEmpty ?? false);
}

/// Everything the app needs to decide what the add-farm button does.
class SubscriptionStatus {
  final int ownedFarms;
  final int freeLimit;
  final int freeRemaining;

  /// May the farmer create another farm right now?
  final bool canCreateFarm;

  /// True only when a PLAN is the thing standing in the way, so the app shows
  /// the packages sheet rather than a generic error.
  final bool needsSubscription;

  final String? message;
  final SubscriptionDetails? subscription;
  final List<SubscriptionPlan> plans;
  final SubscriptionContact? contact;

  const SubscriptionStatus({
    required this.ownedFarms,
    required this.freeLimit,
    required this.freeRemaining,
    required this.canCreateFarm,
    required this.needsSubscription,
    required this.message,
    required this.subscription,
    required this.plans,
    required this.contact,
  });

  /// What to assume when the status could not be fetched.
  ///
  /// Permissive on purpose: the server checks again on create and answers 402
  /// if the farmer really is over the limit, so a failed status call costs one
  /// extra screen rather than locking a paying farmer out of a feature they
  /// are entitled to.
  factory SubscriptionStatus.unknown() {
    return const SubscriptionStatus(
      ownedFarms: 0,
      freeLimit: 0,
      freeRemaining: 0,
      canCreateFarm: true,
      needsSubscription: false,
      message: null,
      subscription: null,
      plans: [],
      contact: null,
    );
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      ownedFarms: int.tryParse('${json['owned_farms']}') ?? 0,
      freeLimit: int.tryParse('${json['free_limit']}') ?? 0,
      freeRemaining: int.tryParse('${json['free_remaining']}') ?? 0,
      // Absent means yes. An older server that does not know about
      // subscriptions must not lock everybody out of adding farms.
      canCreateFarm: json['can_create_farm'] != false,
      needsSubscription: json['needs_subscription'] == true,
      message: json['message']?.toString(),
      subscription: json['subscription'] is Map<String, dynamic>
          ? SubscriptionDetails.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
      plans: (json['plans'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList(),
      contact: json['contact'] is Map<String, dynamic>
          ? SubscriptionContact.fromJson(
              json['contact'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
