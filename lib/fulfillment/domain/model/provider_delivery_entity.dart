/// Estado físico de la entrega.
abstract final class DeliveryPhysicalState {
  static const assigned = 'ASSIGNED';
  static const started = 'STARTED';
  static const arrived = 'ARRIVED';
  static const delivering = 'DELIVERING';
  static const completed = 'COMPLETED';
  static const failed = 'FAILED';
  static const cancelled = 'CANCELLED';
  static const values = [
    assigned,
    started,
    arrived,
    delivering,
    completed,
    failed,
    cancelled,
  ];
}

/// `{ id, firstName, lastName }` del conductor asignado.
class DeliveryDriver {
  const DeliveryDriver({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) => DeliveryDriver(
    id: (json['id'] as num).toInt(),
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
  );

  final int id;
  final String firstName;
  final String lastName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
  };
}

/// `{ id, licensePlate }` de la cisterna asignada.
class DeliveryTanker {
  const DeliveryTanker({required this.id, required this.licensePlate});

  factory DeliveryTanker.fromJson(Map<String, dynamic> json) => DeliveryTanker(
    id: (json['id'] as num).toInt(),
    licensePlate: json['licensePlate'] as String,
  );

  final int id;
  final String licensePlate;

  Map<String, dynamic> toJson() => {'id': id, 'licensePlate': licensePlate};
}

/// Entrega del distribuidor (GET /deliveries). `status` es el estado legado; la UI usa `physicalState`.
class ProviderDelivery {
  const ProviderDelivery({
    required this.id,
    required this.orderId,
    required this.status,
    required this.physicalState,
    required this.driver,
    required this.tanker,
    required this.scheduledDate,
    required this.windowStart,
    required this.windowEnd,
    required this.buyerCompanyId,
    required this.buyerCompanyName,
    required this.customerAccountId,
    required this.siteId,
    required this.deliveryAddress,
    required this.requestedVolume,
    required this.unit,
    required this.deliveredVolume,
  });

  factory ProviderDelivery.fromJson(Map<String, dynamic> json) =>
      ProviderDelivery(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num).toInt(),
        status: json['status'] as String,
        physicalState: json['physicalState'] as String,
        driver: json['driver'] == null
            ? null
            : DeliveryDriver.fromJson(json['driver'] as Map<String, dynamic>),
        tanker: json['tanker'] == null
            ? null
            : DeliveryTanker.fromJson(json['tanker'] as Map<String, dynamic>),
        scheduledDate: json['scheduledDate'] as String?,
        windowStart: json['windowStart'] as String?,
        windowEnd: json['windowEnd'] as String?,
        buyerCompanyId: (json['buyerCompanyId'] as num?)?.toInt(),
        buyerCompanyName: json['buyerCompanyName'] as String?,
        customerAccountId: (json['customerAccountId'] as num?)?.toInt(),
        siteId: (json['siteId'] as num?)?.toInt(),
        deliveryAddress: json['deliveryAddress'] as String?,
        requestedVolume: (json['requestedVolume'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        deliveredVolume: (json['deliveredVolume'] as num?)?.toDouble(),
      );

  final int id;
  final int orderId;
  final String status;

  /// `DeliveryPhysicalState`.
  final String physicalState;
  final DeliveryDriver? driver;
  final DeliveryTanker? tanker;
  final String? scheduledDate;
  final String? windowStart;
  final String? windowEnd;
  final int? buyerCompanyId;
  final String? buyerCompanyName;
  final int? customerAccountId;
  final int? siteId;
  final String? deliveryAddress;
  final double? requestedVolume;
  final String? unit;
  final double? deliveredVolume;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'status': status,
    'physicalState': physicalState,
    'driver': driver?.toJson(),
    'tanker': tanker?.toJson(),
    'scheduledDate': scheduledDate,
    'windowStart': windowStart,
    'windowEnd': windowEnd,
    'buyerCompanyId': buyerCompanyId,
    'buyerCompanyName': buyerCompanyName,
    'customerAccountId': customerAccountId,
    'siteId': siteId,
    'deliveryAddress': deliveryAddress,
    'requestedVolume': requestedVolume,
    'unit': unit,
    'deliveredVolume': deliveredVolume,
  };

  ProviderDelivery copyWith({
    String? status,
    String? physicalState,
    double? deliveredVolume,
  }) => ProviderDelivery(
    id: id,
    orderId: orderId,
    status: status ?? this.status,
    physicalState: physicalState ?? this.physicalState,
    driver: driver,
    tanker: tanker,
    scheduledDate: scheduledDate,
    windowStart: windowStart,
    windowEnd: windowEnd,
    buyerCompanyId: buyerCompanyId,
    buyerCompanyName: buyerCompanyName,
    customerAccountId: customerAccountId,
    siteId: siteId,
    deliveryAddress: deliveryAddress,
    requestedVolume: requestedVolume,
    unit: unit,
    deliveredVolume: deliveredVolume ?? this.deliveredVolume,
  );
}

class DeliveryRecommendation {
  const DeliveryRecommendation({
    required this.orderId,
    required this.recommended,
    required this.reason,
    required this.driverId,
    required this.driverName,
    required this.tankerId,
    required this.licensePlate,
    required this.tankerCapacityLitres,
    required this.requestedVolumeLitres,
    required this.windowStart,
    required this.windowEnd,
    required this.criterion,
  });

  factory DeliveryRecommendation.fromJson(
    Map<String, dynamic> json,
  ) => DeliveryRecommendation(
    orderId: (json['orderId'] as num).toInt(),
    recommended: json['recommended'] as bool,
    reason: json['reason'] as String?,
    driverId: (json['driverId'] as num?)?.toInt(),
    driverName: json['driverName'] as String?,
    tankerId: (json['tankerId'] as num?)?.toInt(),
    licensePlate: json['licensePlate'] as String?,
    tankerCapacityLitres: (json['tankerCapacityLitres'] as num?)?.toDouble(),
    requestedVolumeLitres: (json['requestedVolumeLitres'] as num).toDouble(),
    windowStart: json['windowStart'] as String,
    windowEnd: json['windowEnd'] as String,
    criterion: json['criterion'] as String,
  );

  final int orderId;
  final bool recommended;

  /// NO_ELIGIBLE_DRIVER | NO_SUFFICIENT_ELIGIBLE_TANKER | RESERVATION_CONFLICT
  final String? reason;
  final int? driverId;
  final String? driverName;
  final int? tankerId;
  final String? licensePlate;
  final double? tankerCapacityLitres;
  final double requestedVolumeLitres;
  final String windowStart;
  final String windowEnd;
  final String criterion;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'recommended': recommended,
    'reason': reason,
    'driverId': driverId,
    'driverName': driverName,
    'tankerId': tankerId,
    'licensePlate': licensePlate,
    'tankerCapacityLitres': tankerCapacityLitres,
    'requestedVolumeLitres': requestedVolumeLitres,
    'windowStart': windowStart,
    'windowEnd': windowEnd,
    'criterion': criterion,
  };
}

/// Estado de la válvula: abierta o cerrada.
abstract final class ValveState {
  static const open = 'OPEN';
  static const closed = 'CLOSED';
  static const values = [open, closed];
}

class ValveObservation {
  const ValveObservation({
    required this.id,
    required this.state,
    required this.unauthorized,
    required this.commandId,
    required this.recordedAt,
  });

  factory ValveObservation.fromJson(Map<String, dynamic> json) =>
      ValveObservation(
        id: (json['id'] as num).toInt(),
        state: json['state'] as String,
        unauthorized: json['unauthorized'] as bool,
        commandId: json['commandId'] as String?,
        recordedAt: json['recordedAt'] as String,
      );

  final int id;

  /// `ValveState`.
  final String state;
  final bool unauthorized;
  final String? commandId;
  final String recordedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'state': state,
    'unauthorized': unauthorized,
    'commandId': commandId,
    'recordedAt': recordedAt,
  };
}
