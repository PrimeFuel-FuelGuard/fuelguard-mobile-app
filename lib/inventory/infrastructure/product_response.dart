import '../../shared/infrastructure/base_response.dart';

/// Producto tal como llega de la API.
class ProductResource implements BaseResource {
  const ProductResource({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.pricePerUnit,
    required this.unit,
    required this.availableStock,
    required this.capacity,
    required this.providerId,
    required this.active,
  });

  factory ProductResource.fromJson(Map<String, dynamic> json) =>
      ProductResource(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        fuelType: json['fuelType'] as String,
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
        unit: json['unit'] as String,
        availableStock: (json['availableStock'] as num).toDouble(),
        capacity: (json['capacity'] as num).toDouble(),
        providerId: (json['providerId'] as num).toInt(),
        active: json['active'] as bool,
      );

  @override
  final int id;
  final String name;

  /// `FuelType`.
  final String fuelType;
  final double pricePerUnit;
  final String unit;
  final double availableStock;
  final double capacity;
  final int providerId;
  final bool active;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fuelType': fuelType,
    'pricePerUnit': pricePerUnit,
    'unit': unit,
    'availableStock': availableStock,
    'capacity': capacity,
    'providerId': providerId,
    'active': active,
  };
}

/// Respuesta de listado: un arreglo sin envoltorio.
typedef ProductsResponse = List<ProductResource>;
