class ContactModel {
  bool status;
  List<ContactItem> contacts;

  ContactModel({required this.status, required this.contacts});

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      status: json['status'] ?? false,
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => ContactItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ContactItem {
  dynamic id;
  String phone;
  String whatsapp;
  String label;

  ContactItem({
    this.id,
    required this.phone,
    required this.whatsapp,
    required this.label,
  });

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      id: json['id'],
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      label: json['label'] ?? '',
    );
  }
}
