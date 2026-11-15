import '../../../shared/domain/model/base_entity.dart';

/// Tipos de notificación (unión de strings del backend).
abstract final class NotificationType {
  static const newRequest = 'NEW_REQUEST';
  static const requestPending = 'REQUEST_PENDING';
  static const orderAccepted = 'ORDER_ACCEPTED';
  static const orderRejected = 'ORDER_REJECTED';
  static const orderDispatched = 'ORDER_DISPATCHED';
  static const orderDelivered = 'ORDER_DELIVERED';
  static const orderConfirmed = 'ORDER_CONFIRMED';
  static const orderCancelled = 'ORDER_CANCELLED';
  static const deliveryDispatched = 'DELIVERY_DISPATCHED';
  static const deliveryCompleted = 'DELIVERY_COMPLETED';
  static const deliveryFailed = 'DELIVERY_FAILED';
  static const paymentReceived = 'PAYMENT_RECEIVED';
  static const paymentCompleted = 'PAYMENT_COMPLETED';
  static const paymentRefunded = 'PAYMENT_REFUNDED';
  static const general = 'GENERAL';

  static const values = [
    newRequest,
    requestPending,
    orderAccepted,
    orderRejected,
    orderDispatched,
    orderDelivered,
    orderConfirmed,
    orderCancelled,
    deliveryDispatched,
    deliveryCompleted,
    deliveryFailed,
    paymentReceived,
    paymentCompleted,
    paymentRefunded,
    general,
  ];
}

/// Notificación del usuario. `read` es mutable en el store, por eso se usa [copyWith].
class Notification implements BaseEntity {
  const Notification(
    this.id,
    this.userId,
    this.type,
    this.title,
    this.message,
    this.read,
    this.referenceId,
    this.createdAt,
  );

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    (json['id'] as num).toInt(),
    (json['userId'] as num).toInt(),
    json['type'] as String,
    json['title'] as String,
    json['message'] as String,
    json['read'] as bool,
    (json['referenceId'] as num?)?.toInt(),
    json['createdAt'] as String,
  );

  @override
  final int id;
  final int userId;

  /// `NotificationType`.
  final String type;
  final String title;
  final String message;
  final bool read;
  final int? referenceId;
  final String createdAt;

  bool isOrderEvent() => type.startsWith('ORDER_');
  bool isDeliveryEvent() => type.startsWith('DELIVERY_');
  bool isPaymentEvent() => type.startsWith('PAYMENT_');
  bool isRequestEvent() =>
      type.endsWith('_REQUEST') || type == 'REQUEST_PENDING';

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

  Notification copyWith({
    String? type,
    String? title,
    String? message,
    bool? read,
    int? referenceId,
    String? createdAt,
  }) => Notification(
    id,
    userId,
    type ?? this.type,
    title ?? this.title,
    message ?? this.message,
    read ?? this.read,
    referenceId ?? this.referenceId,
    createdAt ?? this.createdAt,
  );
}
