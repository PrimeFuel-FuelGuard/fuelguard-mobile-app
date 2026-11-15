import '../../../shared/domain/model/base_entity.dart';

/// Tipos de combustible (unión de strings del backend).
abstract final class FuelType {
  static const diesel = 'DIESEL';
  static const gasoline = 'GASOLINE';
  static const gasoline84 = 'GASOLINE_84';
  static const gasoline90 = 'GASOLINE_90';
  static const gasoline95 = 'GASOLINE_95';
  static const gasoline97 = 'GASOLINE_97';
  static const glp = 'GLP';
  static const gnv = 'GNV';
}

/// Valores del enum del backend (inventory.FuelType); lista fija para selects y chips (`FUEL_TYPES`).
const List<String> fuelTypes = [
  FuelType.diesel,
  FuelType.gasoline,
  FuelType.gasoline84,
  FuelType.gasoline90,
  FuelType.gasoline95,
  FuelType.gasoline97,
  FuelType.glp,
  FuelType.gnv,
];

/// Producto de combustible de un distribuidor.
class FuelProduct implements BaseEntity {
  const FuelProduct({
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

  factory FuelProduct.fromJson(Map<String, dynamic> json) => FuelProduct(
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

  FuelProduct copyWith({
    String? name,
    String? fuelType,
    double? pricePerUnit,
    String? unit,
    double? availableStock,
    double? capacity,
    int? providerId,
    bool? active,
  }) => FuelProduct(
    id: id,
    name: name ?? this.name,
    fuelType: fuelType ?? this.fuelType,
    pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    unit: unit ?? this.unit,
    availableStock: availableStock ?? this.availableStock,
    capacity: capacity ?? this.capacity,
    providerId: providerId ?? this.providerId,
    active: active ?? this.active,
  );
}

/// Cuerpo de `POST /fuel-products`.
class CreateProductPayload {
  const CreateProductPayload({
    required this.name,
    required this.fuelType,
    required this.pricePerUnit,
    required this.unit,
    required this.availableStock,
    required this.capacity,
    required this.providerId,
    required this.active,
  });

  final String name;
  final String fuelType;
  final double pricePerUnit;
  final String unit;
  final double availableStock;
  final double capacity;
  final int providerId;
  final bool active;

  Map<String, dynamic> toJson() => {
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

/// `Omit<CreateProductPayload, 'providerId'>`: cuerpo de `PUT /fuel-products/{id}`.
class UpdateProductPayload {
  const UpdateProductPayload({
    required this.name,
    required this.fuelType,
    required this.pricePerUnit,
    required this.unit,
    required this.availableStock,
    required this.capacity,
    required this.active,
  });

  final String name;
  final String fuelType;
  final double pricePerUnit;
  final String unit;
  final double availableStock;
  final double capacity;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name,
    'fuelType': fuelType,
    'pricePerUnit': pricePerUnit,
    'unit': unit,
    'availableStock': availableStock,
    'capacity': capacity,
    'active': active,
  };
}
