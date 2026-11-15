import '../../../shared/domain/model/base_entity.dart';

/// Estados posibles de una orden de combustible, desde su creación hasta la entrega o cancelación.
abstract final class OrderStatus {
  static const pending = 'PENDING';
  static const confirmed = 'CONFIRMED';
  static const dispatched = 'DISPATCHED';
  static const pendingPayment = 'PENDING_PAYMENT';
  static const paid = 'PAID';
  static const inProgress = 'IN_PROGRESS';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';

  static const values = [
    pending,
    confirmed,
    dispatched,
    pendingPayment,
    paid,
    inProgress,
    delivered,
    cancelled,
  ];
}

/// Orden de combustible de la API `/fuel-orders`; `requestId` es la solicitud de origen, si la hay.
class Order implements BaseEntity {
  const Order({
    required this.id,
    required this.requestId,
    required this.companyId,
    required this.providerId,
    required this.fuelProductId,
    required this.equipmentId,
    required this.requestedQuantity,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    required this.scheduledDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json['id'] as num).toInt(),
    requestId: (json['requestId'] as num?)?.toInt(),
    companyId: (json['companyId'] as num).toInt(),
    providerId: (json['providerId'] as num).toInt(),
    fuelProductId: (json['fuelProductId'] as num).toInt(),
    equipmentId: (json['equipmentId'] as num?)?.toInt(),
    requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'] as String,
    deliveryAddress: json['deliveryAddress'] as String,
    scheduledDate: json['scheduledDate'] as String?,
  );

  @override
  final int id;
  final int? requestId;
  final int companyId;
  final int providerId;
  final int fuelProductId;
  final int? equipmentId;
  final double requestedQuantity;
  final double totalPrice;

  /// `OrderStatus`.
  final String status;
  final String deliveryAddress;
  final String? scheduledDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'companyId': companyId,
    'providerId': providerId,
    'fuelProductId': fuelProductId,
    'equipmentId': equipmentId,
    'requestedQuantity': requestedQuantity,
    'totalPrice': totalPrice,
    'status': status,
    'deliveryAddress': deliveryAddress,
    'scheduledDate': scheduledDate,
  };

  /// Los campos nulables no se pueden poner en `null` vía copyWith.
  Order copyWith({
    int? requestId,
    int? companyId,
    int? providerId,
    int? fuelProductId,
    int? equipmentId,
    double? requestedQuantity,
    double? totalPrice,
    String? status,
    String? deliveryAddress,
    String? scheduledDate,
  }) => Order(
    id: id,
    requestId: requestId ?? this.requestId,
    companyId: companyId ?? this.companyId,
    providerId: providerId ?? this.providerId,
    fuelProductId: fuelProductId ?? this.fuelProductId,
    equipmentId: equipmentId ?? this.equipmentId,
    requestedQuantity: requestedQuantity ?? this.requestedQuantity,
    totalPrice: totalPrice ?? this.totalPrice,
    status: status ?? this.status,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    scheduledDate: scheduledDate ?? this.scheduledDate,
  );
}
