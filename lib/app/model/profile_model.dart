class ProfileModel {
  final int? id;
  final String? mobile;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String? language;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    this.id,
    this.mobile,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.language,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      mobile: json['mobile'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'],
      language: json['language'],
      role: json['role'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobile,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'language': language,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
