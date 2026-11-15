import '../../shared/infrastructure/base_response.dart';

class TankerResource implements BaseResource {
  const TankerResource({
    required this.id,
    required this.providerId,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.unit,
    required this.status,
    required this.active,
  });

  factory TankerResource.fromJson(Map<String, dynamic> json) => TankerResource(
    id: (json['id'] as num).toInt(),
    providerId: (json['providerId'] as num).toInt(),
    licensePlate: json['licensePlate'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    capacity: (json['capacity'] as num).toDouble(),
    unit: json['unit'] as String,
    status: json['status'] as String,
    active: json['active'] as bool,
  );

  @override
  final int id;
  final int providerId;
  final String licensePlate;
  final String brand;
  final String model;
  final double capacity;
  final String unit;

  /// `TankerStatus`.
  final String status;
  final bool active;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'licensePlate': licensePlate,
    'brand': brand,
    'model': model,
    'capacity': capacity,
    'unit': unit,
    'status': status,
    'active': active,
  };
}
