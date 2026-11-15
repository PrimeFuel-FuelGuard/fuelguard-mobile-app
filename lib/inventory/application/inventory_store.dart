import 'package:material_ui/material_ui.dart';

import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/fuel_product_entity.dart';
import '../infrastructure/inventory_api.dart';

/// Estado del catálogo de productos (equivale a `inventory.store.ts`); una instancia por vista.
class InventoryStore extends ChangeNotifier {
  InventoryStore(this._api);

  final InventoryApi _api;

  List<FuelProduct> _productList = [];
  FuelProduct? _selectedProduct;
  Map<int, String> _providerNames = {};
  bool _isLoading = false;
  String? _error;

  List<FuelProduct> get productList => _productList;
  FuelProduct? get selectedProduct => _selectedProduct;

  /// Nombres de proveedor por id (vacío si el directorio no está disponible).
  Map<int, String> get providerNames => _providerNames;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _start() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _fail(Object e) {
    _error = e is ApiException && e.message.isNotEmpty
        ? e.message
        : 'errors.generic';
    _isLoading = false;
    notifyListeners();
  }

  void _done() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProviders() async {
    try {
      final providers = await _api.getProviders();
      _providerNames = {for (final p in providers) p.id: p.name};
    } catch (_) {
      _providerNames = {};
    }
    notifyListeners();
  }

  Future<void> loadAllProducts([int? providerId]) async {
    _start();
    try {
      _productList = providerId == null
          ? await _api.getAllProducts()
          : await _api.getProductsByProvider(providerId);
      _done();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> loadProductById(int id) async {
    _start();
    try {
      _selectedProduct = await _api.getProductById(id);
      _done();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> createProduct(
    CreateProductPayload payload, [
    VoidCallback? done,
  ]) async {
    _start();
    try {
      final product = await _api.createProduct(payload);
      _productList = [..._productList, product];
      _done();
      done?.call();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> updateProduct(
    int id,
    UpdateProductPayload payload, [
    VoidCallback? done,
  ]) async {
    _start();
    try {
      final product = await _api.updateProduct(id, payload);
      _productList = [for (final p in _productList) p.id == id ? product : p];
      _selectedProduct = product;
      _done();
      done?.call();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> updateStock(int id, double stock) async {
    _start();
    try {
      final product = await _api.updateStock(id, stock);
      _productList = [for (final p in _productList) p.id == id ? product : p];
      _done();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    _start();
    try {
      await _api.deleteProduct(id);
      _productList = [
        for (final p in _productList)
          if (p.id != id) p,
      ];
      _done();
    } catch (e) {
      _fail(e);
    }
  }
}
