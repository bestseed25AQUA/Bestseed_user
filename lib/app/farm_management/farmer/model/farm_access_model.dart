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
