class ManagerResponse {
  final bool status;
  final String message;
  final List<Manager> data;

  ManagerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ManagerResponse.fromJson(Map<String, dynamic> json) {
    return ManagerResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<Manager>.from(json['data'].map((x) => Manager.fromJson(x)))
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


class Manager {
  final String name;
  final String phoneNumber;
  final bool canEdit;
  final bool canView;
  final bool canDelete;
  final bool canCreate;

  Manager({
    required this.name,
    required this.phoneNumber,
    required this.canEdit,
    required this.canView,
    required this.canDelete,
    required this.canCreate,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      canEdit: json['can_edit'] ?? false,
      canView: json['can_view'] ?? false,
      canDelete: json['can_delete'] ?? false,
      canCreate: json['can_create'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone_number": phoneNumber,
      "can_edit": canEdit,
      "can_view": canView,
      "can_delete": canDelete,
      "can_create": canCreate,
    };
  }
}
