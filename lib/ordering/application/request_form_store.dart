import 'package:material_ui/material_ui.dart';

import '../../equipment/domain/model/equipment_entity.dart';
import '../../equipment/infrastructure/equipment_api.dart';
import '../../iam/application/iam_store.dart';
import '../../inventory/domain/model/fuel_product_entity.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/request_entity.dart';
import '../infrastructure/ordering_api.dart';

/// Estado del formulario de nueva solicitud: cuenta del cliente, sedes, tanques, distribuidores y catálogo.
class RequestFormStore extends ChangeNotifier {
  RequestFormStore(this._api, this._equipmentApi, this._iam);

  final OrderingApi _api;
  final EquipmentApi _equipmentApi;
  final IamStore _iam;

  int? _customerAccountId;
  List<Site> _sites = [];
  List<Tank> _tanks = [];
  List<IdName> _providers = [];
  List<FuelProduct> _products = [];
  bool _productsLoading = false;
  bool _sending = false;
  int? _selectedProvider;
  String _loadError = '';
  String _productError = '';
  String _catalogAlert = '';
  String? _error;

  int? get customerAccountId => _customerAccountId;
  List<Site> get sites => _sites;
  List<Tank> get tanks => _tanks;
  List<IdName> get providers => _providers;
  List<FuelProduct> get products => _products;
  bool get productsLoading => _productsLoading;
  bool get sending => _sending;
  String get loadError => _loadError;
  String get productError => _productError;
  String get catalogAlert => _catalogAlert;
  String? get error => _error;

  bool get canSubmit =>
      _customerAccountId != null &&
      !_sending &&
      !_productsLoading &&
      _productError.isEmpty &&
      _products.isNotEmpty;

  Future<void> load() async {
    try {
      _providers = await _api.providers();
    } catch (_) {
      _loadError = 'request-form.providers-error';
    }
    try {
      final customer = await _resolveCustomer();
      _customerAccountId = customer.id;
      final tanks = await _api.tanks();
      _tanks = tanks.where((t) => t.customerAccountId == customer.id).toList();
      _sites = await _equipmentApi.sites(customer.id);
    } catch (e) {
      _loadError = apiError(e);
    }
    notifyListeners();
  }

  /// La cuenta interna sale de la organización activa; el comprador no la elige.
  Future<Customer> _resolveCustomer() async {
    final companyId = _iam.companyId;
    final rows = await _equipmentApi.customers();
    for (final row in rows) {
      if (companyId != null && row.legacyCompanyId == companyId) return row;
    }
    if (rows.length == 1 && rows.first.legacyCompanyId == null) {
      return rows.first;
    }
    throw StateError('equipment.customer-unresolved');
  }

  String? addressOfSite(int? siteId) {
    final address = _sites.where((s) => s.id == siteId).firstOrNull?.address;
    if (address == null) return null;
    return address.length > 255 ? address.substring(0, 255) : address;
  }

  /// Carga el catálogo activo del distribuidor; si está vacío, le avisa.
  Future<void> selectProvider(int? providerId) async {
    _selectedProvider = providerId;
    _products = [];
    _productError = '';
    _catalogAlert = '';
    _productsLoading = providerId != null;
    notifyListeners();
    if (providerId == null) return;
    try {
      final rows = await _api.products(providerId);
      if (_selectedProvider != providerId) return;
      _products = rows.where((p) => p.active).toList();
      if (_products.isEmpty) {
        _productError = 'request-form.no-products';
        _notifyEmptyCatalog(providerId);
      }
    } catch (_) {
      if (_selectedProvider == providerId) {
        _productError = 'request-form.products-error';
      }
    }
    _productsLoading = false;
    notifyListeners();
  }

  Future<void> _notifyEmptyCatalog(int providerId) async {
    try {
      await _api.alertEmptyCatalog(providerId);
      if (_selectedProvider == providerId) {
        _catalogAlert = 'request-form.provider-notified';
      }
    } catch (_) {
      if (_selectedProvider == providerId) {
        _catalogAlert = 'request-form.notification-error';
      }
    }
    notifyListeners();
  }

  /// Envía solo si el producto pertenece al catálogo cargado.
  Future<bool> submit(CreateRequest value) async {
    if (!canSubmit || !_products.any((p) => p.id == value.fuelProductId)) {
      return false;
    }
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      await _api.createRequest(value);
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'ordering.request-failed';
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
