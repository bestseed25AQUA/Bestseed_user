/// Permission flags carried by an access grant.
class AccessPermissions {
  final bool view;
  final bool edit;
  final bool create;
  final bool delete;

  const AccessPermissions({
    this.view = false,
    this.edit = false,
    this.create = false,
    this.delete = false,
  });

  factory AccessPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AccessPermissions();
    return AccessPermissions(
      view: json['view'] == true,
      edit: json['edit'] == true,
      create: json['create'] == true,
      delete: json['delete'] == true,
    );
  }
}

/// A QR + PIN access code issued for a farm.
///
/// [pin] is only present on responses to the issuing farmer — the scanner side
/// never receives it.
class FarmAccessGrant {
  final int id;
  final int farmId;
  final String token;
  final String role;
  final String? pin;
  final int durationDays;
  final int daysRemaining;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final AccessPermissions permissions;

  const FarmAccessGrant({
    required this.id,
    required this.farmId,
    required this.token,
    required this.role,
    required this.durationDays,
    required this.daysRemaining,
    required this.status,
    required this.permissions,
    this.pin,
    this.expiresAt,
    this.createdAt,
  });

  bool get isPartner => role == 'partner';

  factory FarmAccessGrant.fromJson(Map<String, dynamic> json) {
    return FarmAccessGrant(
      id: json['id'] ?? 0,
      farmId: json['farm_id'] ?? 0,
      token: json['token']?.toString() ?? '',
      role: json['role']?.toString() ?? 'manager',
      pin: json['pin']?.toString(),
      durationDays: int.tryParse('${json['duration_days']}') ?? 0,
      daysRemaining: int.tryParse('${json['days_remaining']}') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse('${json['expires_at']}'),
      createdAt: DateTime.tryParse('${json['created_at']}'),
      permissions: AccessPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// A person who scanned a code and now holds access — the "Scanned Details" row.
class FarmGrantee {
  final int grantId;
  final int? managerId;
  final String? name;
  final String? phone;
  final String? farmName;
  final String role;
  final int daysRemaining;
  final String status;
  final DateTime? redeemedAt;
  final AccessPermissions permissions;

  const FarmGrantee({
    required this.grantId,
    required this.role,
    required this.daysRemaining,
    required this.status,
    required this.permissions,
    this.managerId,
    this.name,
    this.phone,
    this.farmName,
    this.redeemedAt,
  });

  bool get isPartner => role == 'partner';

  factory FarmGrantee.fromJson(Map<String, dynamic> json) {
    return FarmGrantee(
      grantId: json['grant_id'] ?? 0,
      managerId: json['manager_id'],
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      farmName: json['farm_name']?.toString(),
      role: json['role']?.toString() ?? 'manager',
      daysRemaining: int.tryParse('${json['days_remaining']}') ?? 0,
      status: json['status']?.toString() ?? 'active',
      redeemedAt: DateTime.tryParse('${json['redeemed_at']}'),
      permissions: AccessPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Result of scanning a QR, before the PIN step.
class ScannedGrantPreview {
  final String token;
  final int farmId;
  final String? farmName;
  final String role;

  const ScannedGrantPreview({
    required this.token,
    required this.farmId,
    required this.role,
    this.farmName,
  });

  factory ScannedGrantPreview.fromJson(Map<String, dynamic> json) {
    return ScannedGrantPreview(
      token: json['token']?.toString() ?? '',
      farmId: json['farm_id'] ?? 0,
      farmName: json['farm_name']?.toString(),
      role: json['role']?.toString() ?? 'manager',
    );
  }
}

/// What the logged-in farmer may do with one farm.
///
/// The farm list already returns this against every farm — role, whether they
/// own it, and the four ability flags. The app used to ignore it entirely and
/// offered Edit, Delete and Setup Access on every farm to everyone, so a
/// partner holding view access only discovered the limit as a 403 reported to
/// them as "Failed to update farm".
class FarmAccess {
  final String role;
  final bool isOwner;
  final int? grantId;
  final DateTime? expiresAt;
  final AccessPermissions permissions;

  const FarmAccess({
    required this.role,
    required this.isOwner,
    required this.permissions,
    this.grantId,
    this.expiresAt,
  });

  /// Used when a response predates the access block. Full rights, because the
  /// server is the real gate — the app only decides what to *offer*, and
  /// hiding everything on an old payload would leave an owner unable to work.
  const FarmAccess.ownerFallback()
      : role = 'owner',
        isOwner = true,
        grantId = null,
        expiresAt = null,
        permissions = const AccessPermissions(
          view: true,
          edit: true,
          create: true,
          delete: true,
        );

  factory FarmAccess.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FarmAccess.ownerFallback();

    return FarmAccess(
      role: json['role']?.toString() ?? 'owner',
      isOwner: json['is_owner'] == true,
      grantId: int.tryParse('${json['grant_id']}'),
      expiresAt: DateTime.tryParse('${json['expires_at']}'),
      permissions: AccessPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }

  bool get canView => isOwner || permissions.view;
  bool get canEdit => isOwner || permissions.edit;
  bool get canCreate => isOwner || permissions.create;
  bool get canDelete => isOwner || permissions.delete;

  /// Issuing QR codes, listing them and reading Scanned Details are the farm's
  /// keys — the API restricts all three to the owner, so the app must not
  /// offer them to a manager or partner.
  bool get canManageAccessCodes => isOwner;

  /// Anyone holding access may pass it on, capped at what they hold —
  /// `POST /farmer/farm/{id}/members` enforces the cap server-side.
  bool get canShareAccess => canView || canEdit || canCreate || canDelete;
}

/// A person who currently holds access to a farm, however they got it.
///
/// Backs the Setup Access list. Unlike the legacy `managers`/`partners`
/// endpoints — which are a per-farm address book of names and are readable
/// only by the owner — this is the table the server actually consults when it
/// decides who may open a farm, so it is the same for an owner and a member.
class FarmMember {
  final int id;
  final int? farmerId;
  final String name;
  final String? mobile;
  final String role;

  /// 'qr' when they scanned a code, 'direct' when someone picked them.
  final String via;

  /// Name of whoever admitted them.
  final String? grantedBy;

  /// 'active', 'revoked' or 'expired'.
  final String status;
  final DateTime? expiresAt;
  final AccessPermissions permissions;

  const FarmMember({
    required this.id,
    required this.name,
    required this.role,
    required this.via,
    required this.status,
    required this.permissions,
    this.farmerId,
    this.mobile,
    this.grantedBy,
    this.expiresAt,
  });

  bool get isPartner => role == 'partner';
  bool get isActive => status == 'active';

  factory FarmMember.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';

    return FarmMember(
      id: int.tryParse('${json['id']}') ?? 0,
      farmerId: int.tryParse('${json['farmer_id']}'),
      // A farmer who signed up by phone alone has no name on file; showing the
      // mobile beats showing an empty card.
      name: name.isEmpty ? (json['mobile']?.toString() ?? 'Unknown') : name,
      mobile: json['mobile']?.toString(),
      role: json['role']?.toString() ?? 'manager',
      via: json['via']?.toString() ?? 'direct',
      grantedBy: json['granted_by']?.toString(),
      status: json['status']?.toString() ?? 'active',
      expiresAt: DateTime.tryParse('${json['expires_at']}'),
      permissions: AccessPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }
}
