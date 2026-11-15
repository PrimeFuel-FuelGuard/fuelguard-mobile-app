import '../../../shared/domain/model/base_entity.dart';

/// Estado de la cisterna.
abstract final class TankerStatus {
  static const available = 'AVAILABLE';
  static const inRoute = 'IN_ROUTE';
  static const maintenance = 'MAINTENANCE';
  static const suspended = 'SUSPENDED';
  static const inactive = 'INACTIVE';
  static const values = [available, inRoute, maintenance, suspended, inactive];
}

/// `Pick<Tanker, 'licensePlate' | 'brand' | 'model' | 'capacity' | 'unit' | 'status'>`.
class TankerInput {
  const TankerInput({
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.unit,
    required this.status,
  });

  final String licensePlate;
  final String brand;
  final String model;
  final double capacity;
  final String unit;
  final String status;

  Map<String, dynamic> toJson() => {
    'licensePlate': licensePlate,
    'brand': brand,
    'model': model,
    'capacity': capacity,
    'unit': unit,
    'status': status,
  };
}

/// Entidad de dominio que representa una cisterna (camión) de transporte de combustible.
class Tanker implements BaseEntity {
  const Tanker({
    required this.id,
    required this.providerId,
    this.active = true,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.capacity,
    required this.unit,
    required this.status,
    required this.createdAt,
  });

  factory Tanker.fromJson(Map<String, dynamic> json) => Tanker(
    id: (json['id'] as num).toInt(),
    providerId: (json['providerId'] as num).toInt(),
    active: json['active'] as bool? ?? true,
    licensePlate: json['licensePlate'] as String,
    model: json['model'] as String,
    brand: json['brand'] as String,
    capacity: (json['capacity'] as num).toDouble(),
    unit: json['unit'] as String,
    status: json['status'] as String,
    createdAt: json['createdAt'] as String? ?? '',
  );

  @override
  final int id;
  final int providerId;
  final bool active;
  final String licensePlate;
  final String model;
  final String brand;

  /// Capacidad en litros.
  final double capacity;

  /// LITERS, GALLONS.
  final String unit;

  /// `TankerStatus`.
  final String status;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'active': active,
    'licensePlate': licensePlate,
    'model': model,
    'brand': brand,
    'capacity': capacity,
    'unit': unit,
    'status': status,
    'createdAt': createdAt,
  };

  Tanker copyWith({
    bool? active,
    String? licensePlate,
    String? model,
    String? brand,
    double? capacity,
    String? unit,
    String? status,
    String? createdAt,
  }) => Tanker(
    id: id,
    providerId: providerId,
    active: active ?? this.active,
    licensePlate: licensePlate ?? this.licensePlate,
    model: model ?? this.model,
    brand: brand ?? this.brand,
    capacity: capacity ?? this.capacity,
    unit: unit ?? this.unit,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
}
