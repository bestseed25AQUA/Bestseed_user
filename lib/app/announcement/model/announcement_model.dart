/// An admin announcement targeted at the farmer/user app.
///
/// Served by GET /api/farmer/announcements (list) and
/// GET /api/farmer/announcements/popup (the one to show as a dialog).
class AnnouncementModel {
  final int id;
  final String title;
  final String description;
  final String? image;
  final bool isRead;
  final String? createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.isRead = false,
    this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: (json['image']?.toString().isEmpty ?? true)
          ? null
          : json['image'].toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  AnnouncementModel copyWith({bool? isRead}) {
    return AnnouncementModel(
      id: id,
      title: title,
      description: description,
      image: image,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  DateTime? get createdDateTime {
    if (createdAt == null) return null;
    return DateTime.tryParse(createdAt!)?.toLocal();
  }
}
