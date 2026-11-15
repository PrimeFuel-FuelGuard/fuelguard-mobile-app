class NotificationResource {
  const NotificationResource({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.referenceId,
    required this.createdAt,
  });

  factory NotificationResource.fromJson(Map<String, dynamic> json) =>
      NotificationResource(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        read: json['read'] as bool,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        createdAt: json['createdAt'] as String,
      );

  final int id;
  final int userId;

  /// `NotificationType`.
  final String type;
  final String title;
  final String message;
  final bool read;
  final int? referenceId;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type,
    'title': title,
    'message': message,
    'read': read,
    'referenceId': referenceId,
    'createdAt': createdAt,
  };
}
