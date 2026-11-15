import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';

Map<String, dynamic> _product({
  required int id,
  required String name,
  required String fuelType,
  required double price,
  required double stock,
  required double capacity,
  required int providerId,
}) => {
  'id': id,
  'name': name,
  'fuelType': fuelType,
  'pricePerUnit': price,
  'unit': 'LITERS',
  'availableStock': stock,
  'capacity': capacity,
  'providerId': providerId,
  'active': true,
};

/// Datos demo de inventory: catálogo de productos de PetroSur y Andes Fuel, y directorio de proveedores.
class InventoryDemoHandler implements DemoHandler {
  final Map<int, Map<String, dynamic>> _products = {
    DemoWorld.productDieselId: _product(
      id: DemoWorld.productDieselId,
      name: DemoWorld.productDieselName,
      fuelType: 'DIESEL',
      price: 16.80,
      stock: 28500,
      capacity: 40000,
      providerId: DemoWorld.providerId,
    ),
    DemoWorld.productGasohol90Id: _product(
      id: DemoWorld.productGasohol90Id,
      name: DemoWorld.productGasohol90Name,
      fuelType: 'GASOLINE_90',
      price: 15.20,
      stock: 19200,
      capacity: 30000,
      providerId: DemoWorld.providerId,
    ),
    DemoWorld.productGasohol95Id: _product(
      id: DemoWorld.productGasohol95Id,
      name: DemoWorld.productGasohol95Name,
      fuelType: 'GASOLINE_95',
      price: 17.10,
      stock: 14800,
      capacity: 25000,
      providerId: DemoWorld.providerId,
    ),
    DemoWorld.productGlpId: _product(
      id: DemoWorld.productGlpId,
      name: DemoWorld.productGlpName,
      fuelType: 'GLP',
      price: 7.40,
      stock: 3200,
      capacity: 12000,
      providerId: DemoWorld.providerId,
    ),
    DemoWorld.product21DieselId: _product(
      id: DemoWorld.product21DieselId,
      name: DemoWorld.product21DieselName,
      fuelType: 'DIESEL',
      price: 16.55,
      stock: 22000,
      capacity: 35000,
      providerId: DemoWorld.provider21Id,
    ),
    DemoWorld.product21Gasohol97Id: _product(
      id: DemoWorld.product21Gasohol97Id,
      name: DemoWorld.product21Gasohol97Name,
      fuelType: 'GASOLINE_97',
      price: 18.30,
      stock: 9100,
      capacity: 20000,
      providerId: DemoWorld.provider21Id,
    ),
  };

  int _nextId = 112;

  Map<String, dynamic>? _find(String raw) {
    final id = int.tryParse(raw);
    return id == null ? null : _products[id];
  }

  static final _notFound = DemoResponse.error(404, 'Product not found');

  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    if (r.match('GET', '/provider-companies') != null) {
      return DemoResponse.json([
        {'id': DemoWorld.providerId, 'name': DemoWorld.providerName},
        {'id': DemoWorld.provider21Id, 'name': DemoWorld.provider21Name},
        {'id': DemoWorld.provider22Id, 'name': DemoWorld.provider22Name},
      ]);
    }

    if (r.match('GET', '/fuel-products') != null) {
      return DemoResponse.json(_products.values.toList());
    }
    var m = r.match('GET', '/fuel-products/provider/:id');
    if (m != null) {
      final providerId = int.tryParse(m['id']!);
      return DemoResponse.json([
        for (final p in _products.values)
          if (p['providerId'] == providerId) p,
      ]);
    }
    m = r.match('POST', '/fuel-products/provider/:id/empty-catalog-alert');
    if (m != null) return DemoResponse.empty();

    if (r.match('POST', '/fuel-products') != null) {
      final b = r.json;
      final id = _nextId++;
      _products[id] = {
        'id': id,
        'name': b['name'],
        'fuelType': b['fuelType'],
        'pricePerUnit': b['pricePerUnit'],
        'unit': b['unit'],
        'availableStock': b['availableStock'],
        'capacity': b['capacity'],
        'providerId': b['providerId'],
        'active': b['active'] ?? true,
      };
      return DemoResponse.json(_products[id], 201);
    }

    m = r.match('POST', '/fuel-products/:id/update-stock');
    if (m != null) {
      final p = _find(m['id']!);
      if (p == null) return _notFound;
      final stock = r.json['newStock'];
      if (stock is! num || stock < 0) {
        return DemoResponse.error(400, 'newStock must be >= 0');
      }
      p['availableStock'] = stock.toDouble();
      return DemoResponse.json(p);
    }

    m = r.match('GET', '/fuel-products/:id');
    if (m != null) {
      final p = _find(m['id']!);
      return p == null ? _notFound : DemoResponse.json(p);
    }

    m = r.match('PUT', '/fuel-products/:id');
    if (m != null) {
      final p = _find(m['id']!);
      if (p == null) return _notFound;
      for (final k in const [
        'name',
        'fuelType',
        'pricePerUnit',
        'unit',
        'availableStock',
        'capacity',
        'active',
      ]) {
        if (r.json.containsKey(k)) p[k] = r.json[k];
      }
      return DemoResponse.json(p);
    }

    m = r.match('DELETE', '/fuel-products/:id');
    if (m != null) {
      final id = int.tryParse(m['id']!);
      if (id == null || _products.remove(id) == null) return _notFound;
      return DemoResponse.empty();
    }
    return null;
  }
}
