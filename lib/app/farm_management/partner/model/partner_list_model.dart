class PartnerResponse {
  final bool status;
  final String message;
  final List<Partner> data;

  PartnerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PartnerResponse.fromJson(Map<String, dynamic> json) {
    return PartnerResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<Partner>.from(json['data'].map((x) => Partner.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "data": data.map((e) => e.toJson()).toList(),
    };
  }
}

class Partner {
  final int id;
  final bool isPartner;
  final String name;
  final String phone;
  final bool readAccess;
  final bool viewAccess;
  final bool editAccess;
  final bool deleteAccess;
  final bool createAccess;  // ⭐ NEW (optional support)
  final String createdAt;
  final String updatedAt;

  Partner({
    required this.id,
    required this.isPartner,
    required this.name,
    required this.phone,
    required this.readAccess,
    required this.viewAccess,
    required this.editAccess,
    required this.deleteAccess,
    required this.createAccess,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value == "1" || value.toLowerCase() == "true";
      return false;
    }

    return Partner(
      id: json['id'] ?? 0,
      isPartner: toBool(json['is_partner']),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      readAccess: toBool(json['read_access']),
      viewAccess: toBool(json['view_access']),
      editAccess: toBool(json['edit_access']),
      deleteAccess: toBool(json['delete_access']),

      // ⭐ Future proof: handle missing create_access safely
      createAccess: toBool(json['create_access']),

      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "is_partner": isPartner ? 1 : 0,
      "name": name,
      "phone": phone,
      "read_access": readAccess ? 1 : 0,
      "view_access": viewAccess ? 1 : 0,
      "edit_access": editAccess ? 1 : 0,
      "delete_access": deleteAccess ? 1 : 0,
      "create_access": createAccess ? 1 : 0,  // ⭐ send to API
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }
}
