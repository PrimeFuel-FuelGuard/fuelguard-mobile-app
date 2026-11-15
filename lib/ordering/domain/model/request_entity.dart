import '../../../shared/domain/model/base_entity.dart';

/// Estado de una solicitud de reabastecimiento; solo las `PENDING` admiten aceptar, rechazar o cancelar.
abstract final class RequestStatus {
  static const pending = 'PENDING';
  static const accepted = 'ACCEPTED';
  static const rejected = 'REJECTED';
  static const cancelled = 'CANCELLED';

  static const values = [pending, accepted, rejected, cancelled];
}

/// Origen de la solicitud: creada por el comprador (`MANUAL`) o generada por el sistema (`AUTOMATIC`).
abstract final class RequestSource {
  static const manual = 'MANUAL';
  static const automatic = 'AUTOMATIC';

  static const values = [manual, automatic];
}

/// Solicitud de reabastecimiento tal como la devuelve la API `/replenishment-requests`.
class Request implements BaseEntity {
  const Request({
    required this.id,
    required this.organizationId,
    required this.customerAccountId,
    required this.tankId,
    required this.providerId,
    required this.fuelProductId,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.status,
    required this.source,
    required this.rejectionReason,
    required this.orderId,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.version,
  });

  factory Request.fromJson(Map<String, dynamic> json) => Request(
    id: (json['id'] as num).toInt(),
    organizationId: (json['organizationId'] as num).toInt(),
    customerAccountId: (json['customerAccountId'] as num).toInt(),
    tankId: (json['tankId'] as num?)?.toInt(),
    providerId: (json['providerId'] as num).toInt(),
    fuelProductId: (json['fuelProductId'] as num).toInt(),
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    status: json['status'] as String,
    source: json['source'] as String,
    rejectionReason: json['rejectionReason'] as String?,
    orderId: (json['orderId'] as num?)?.toInt(),
    deliveryAddress: json['deliveryAddress'] as String,
    deliveryDate: json['deliveryDate'] as String,
    version: (json['version'] as num).toInt(),
  );

  @override
  final int id;
  final int organizationId;
  final int customerAccountId;
  final int? tankId;
  final int providerId;
  final int fuelProductId;
  final double quantity;
  final String unit;
  final double unitPrice;

  /// `RequestStatus`.
  final String status;

  /// `RequestSource`.
  final String source;
  final String? rejectionReason;
  final int? orderId;
  final String deliveryAddress;
  final String deliveryDate;
  final int version;

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'customerAccountId': customerAccountId,
    'tankId': tankId,
    'providerId': providerId,
    'fuelProductId': fuelProductId,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'status': status,
    'source': source,
    'rejectionReason': rejectionReason,
    'orderId': orderId,
    'deliveryAddress': deliveryAddress,
    'deliveryDate': deliveryDate,
    'version': version,
  };

  /// Los campos nulables no se pueden poner en `null` vía copyWith.
  Request copyWith({
    int? organizationId,
    int? customerAccountId,
    int? tankId,
    int? providerId,
    int? fuelProductId,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? status,
    String? source,
    String? rejectionReason,
    int? orderId,
    String? deliveryAddress,
    String? deliveryDate,
    int? version,
  }) => Request(
    id: id,
    organizationId: organizationId ?? this.organizationId,
    customerAccountId: customerAccountId ?? this.customerAccountId,
    tankId: tankId ?? this.tankId,
    providerId: providerId ?? this.providerId,
    fuelProductId: fuelProductId ?? this.fuelProductId,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    status: status ?? this.status,
    source: source ?? this.source,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    orderId: orderId ?? this.orderId,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    deliveryDate: deliveryDate ?? this.deliveryDate,
    version: version ?? this.version,
  );
}

/// Campos que el comprador envía al crear una solicitud; el origen (`MANUAL`) lo agrega `OrderingApi`.
class CreateRequest {
  const CreateRequest({
    required this.customerAccountId,
    required this.tankId,
    required this.providerId,
    required this.fuelProductId,
    required this.quantity,
    required this.unit,
    required this.deliveryAddress,
    required this.deliveryDate,
  });

  final int customerAccountId;
  final int? tankId;
  final int providerId;
  final int fuelProductId;
  final double quantity;
  final String unit;
  final String deliveryAddress;
  final String deliveryDate;

  Map<String, dynamic> toJson() => {
    'customerAccountId': customerAccountId,
    'tankId': tankId,
    'providerId': providerId,
    'fuelProductId': fuelProductId,
    'quantity': quantity,
    'unit': unit,
    'deliveryAddress': deliveryAddress,
    'deliveryDate': deliveryDate,
  };
}
