class PushNotificationModel {
  final int id;
  final String title;
  final String body;
  final String? image;
  final String type;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String createdAt;

  PushNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    required this.type,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  factory PushNotificationModel.fromJson(Map<String, dynamic> json) {
    return PushNotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      image: json['image'],
      type: json['type'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isRead => readAt != null;

  DateTime? get createdDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }
}
