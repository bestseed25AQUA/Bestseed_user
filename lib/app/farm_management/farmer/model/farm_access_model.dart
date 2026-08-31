/// Permission flags carried by a membership.
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
  final DateTime? expiresAt;
  final AccessPermissions permissions;

  const FarmAccess({
    required this.role,
    required this.isOwner,
    required this.permissions,
    this.expiresAt,
  });

  /// Used when a response predates the access block. Full rights, because the
  /// server is the real gate — the app only decides what to *offer*, and
  /// hiding everything on an old payload would leave an owner unable to work.
  const FarmAccess.ownerFallback()
      : role = 'owner',
        isOwner = true,
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

  /// Anyone holding access may pass it on, capped at what they hold —
  /// `POST /farmer/farm/{id}/members` enforces the cap server-side.
  bool get canShareAccess => canView || canEdit || canCreate || canDelete;
}

/// A person who currently holds access to a farm.
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
      grantedBy: json['granted_by']?.toString(),
      status: json['status']?.toString() ?? 'active',
      expiresAt: DateTime.tryParse('${json['expires_at']}'),
      permissions: AccessPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// The role access is being set up for.
///
/// Chosen once, on the farm's options sheet, and carried through the guide,
/// the access list and the add form. Before this the farmer picked a role on
/// the sheet and was then asked for it AGAIN in a dropdown, which could
/// disagree with what they had just tapped.
enum FarmRole {
  manager,
  partner;

  /// What the API expects in `role`.
  String get apiValue => this == FarmRole.partner ? 'partner' : 'manager';

  /// Singular, for a title: "Set Up Access for Manager".
  String get label => this == FarmRole.partner ? 'Partner' : 'Manager';

  /// Plural, for a list heading: "No partners yet".
  String get pluralLabel => this == FarmRole.partner ? 'Partners' : 'Managers';

  bool get isPartner => this == FarmRole.partner;

  /// Matches a member row to this role.
  static FarmRole fromApi(String? value) =>
      value?.toLowerCase() == 'partner' ? FarmRole.partner : FarmRole.manager;
}
