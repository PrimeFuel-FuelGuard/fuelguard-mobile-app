import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../iam/application/iam_store.dart';
import '../../inventory/domain/model/fuel_product_entity.dart';
import '../../inventory/infrastructure/inventory_api.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/equipment_entity.dart';
import '../domain/model/provider_equipment_entity.dart';
import '../infrastructure/provider_equipment_api.dart';

/// Sección de carga independiente de una vista (equivale a `Section<T>` de Angular).
class Section<T> {
  const Section({this.loading = false, this.error = false, required this.data});

  final bool loading;
  final bool error;
  final T data;
}

/// Estado de clientes, alta de comprador, detalle y formularios de tanques del distribuidor
/// (equivale a las llamadas directas de `ProviderEquipmentApi` en las vistas). Una instancia por vista.
class ProviderEquipmentStore extends ChangeNotifier {
  ProviderEquipmentStore(this._api, this._inventory, this._iam);

  final ProviderEquipmentApi _api;
  final InventoryApi _inventory;
  final IamStore _iam;

  static const _defaultRetryAfterSeconds = 60;
  static const _readingsWindow = Duration(hours: 48);

  Section<List<ProviderBuyerCompany>> _buyers = const Section(data: []);

  BuyerLookup? _found;
  String _lookupRuc = '';
  bool _searching = false;
  bool _createStep = false;
  String? _lookupError;
  int _waitSeconds = 0;
  Timer? _waitTimer;
  int _lookupSequence = 0;
  bool _saving = false;
  String? _buyerError;

  Section<ProviderBuyerCompany?> _client = const Section(data: null);
  Section<List<ProviderTank>> _clientTanks = const Section(data: []);

  bool _formLoading = true;
  bool _formLoadError = false;
  ProviderBuyerCompany? _formBuyer;
  List<FuelProduct> _formProducts = [];
  ProviderTank? _original;
  bool _formSaving = false;
  String? _tankFormError;

  Section<ProviderTank?> _tank = const Section(data: null);
  Section<List<ProviderTankReading>> _readings = const Section(data: []);
  Section<List<RefillEpisode>> _episodes = const Section(data: []);

  Section<List<ProviderBuyerCompany>> get buyers => _buyers;
  BuyerLookup? get found => _found;
  bool get searching => _searching;
  bool get createStep => _createStep;
  String? get lookupError => _lookupError;
  int get waitSeconds => _waitSeconds;
  bool get saving => _saving;
  String? get buyerError => _buyerError;
  Section<ProviderBuyerCompany?> get client => _client;
  Section<List<ProviderTank>> get clientTanks => _clientTanks;
  bool get formLoading => _formLoading;
  bool get formLoadError => _formLoadError;
  ProviderBuyerCompany? get formBuyer => _formBuyer;
  List<FuelProduct> get formProducts => _formProducts;
  ProviderTank? get original => _original;
  bool get formSaving => _formSaving;
  String? get tankFormError => _tankFormError;
  Section<ProviderTank?> get tank => _tank;
  Section<List<ProviderTankReading>> get readings => _readings;
  Section<List<RefillEpisode>> get episodes => _episodes;

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  // ── Clientes ──

  Future<void> loadBuyers() async {
    _buyers = Section(loading: true, data: _buyers.data);
    notifyListeners();
    try {
      _buyers = Section(data: await _api.buyerCompanies());
    } catch (_) {
      _buyers = const Section(error: true, data: []);
    }
    notifyListeners();
  }

  // ── Alta de comprador (RUC) ──

  /// Busca por RUC; si no existe pasa al paso de alta. 429 bloquea la búsqueda durante el Retry-After.
  Future<void> lookupBuyer(String ruc) async {
    if (_waitSeconds > 0 || _searching || _saving) return;
    final sequence = ++_lookupSequence;
    _lookupRuc = ruc;
    _searching = true;
    _lookupError = null;
    _found = null;
    notifyListeners();
    try {
      final buyer = await _api.lookupBuyer(ruc);
      if (sequence == _lookupSequence) _found = buyer;
    } catch (e) {
      if (sequence == _lookupSequence) {
        final code = e is ApiException ? e.code : '';
        if (code == 'BUYERCOMPANY_NOT_FOUND') {
          _createStep = true;
        } else {
          if (code == 'LOOKUP_RATE_LIMITED') _startWait();
          _lookupError = providerErrorKey(e);
        }
      }
    }
    if (sequence == _lookupSequence) _searching = false;
    notifyListeners();
  }

  /// Un cambio de RUC invalida la búsqueda en curso y su resultado.
  void resetLookup() {
    _lookupSequence++;
    _found = null;
    _searching = false;
    _lookupError = null;
    notifyListeners();
  }

  void backToLookup() {
    _createStep = false;
    _lookupError = null;
    notifyListeners();
  }

  /// Vincula el comprador encontrado; devuelve la empresa vinculada o `null` si falló.
  Future<ProviderBuyerCompany?> linkBuyer() async {
    final buyer = _found;
    if (buyer == null || _saving || buyer.ruc != _lookupRuc) return null;
    _saving = true;
    _buyerError = null;
    notifyListeners();
    try {
      return await _api.registerBuyerCompany({
        'buyerCompanyId': buyer.buyerCompanyId,
      });
    } catch (e) {
      final noOrg = e is ApiException && e.code == 'BUYERCOMPANY_NOT_FOUND';
      _buyerError = noOrg
          ? 'provider-equipment.err-buyer-no-org'
          : providerErrorKey(e);
      _saving = false;
      notifyListeners();
      return null;
    }
  }

  /// Alta de comprador con los campos no vacíos; devuelve la empresa creada o `null` si falló.
  Future<ProviderBuyerCompany?> createBuyer(Map<String, String> body) async {
    if (_saving) return null;
    _saving = true;
    _buyerError = null;
    notifyListeners();
    try {
      return await _api.registerBuyerCompany(body);
    } catch (e) {
      _buyerError = providerErrorKey(e);
      _saving = false;
      notifyListeners();
      return null;
    }
  }

  // ── Detalle de comprador ──

  Future<void> loadClient(int id) =>
      Future.wait([_loadClientBuyer(id), loadClientTanks(id)]);

  Future<void> loadClientTanks(int buyerId) async {
    _clientTanks = Section(loading: true, data: _clientTanks.data);
    notifyListeners();
    try {
      _clientTanks = Section(data: await _api.tanks(buyerId));
    } catch (_) {
      _clientTanks = const Section(error: true, data: []);
    }
    notifyListeners();
  }

  Future<void> _loadClientBuyer(int id) async {
    _client = const Section(loading: true, data: null);
    notifyListeners();
    try {
      final rows = await _api.buyerCompanies();
      _client = Section(data: rows.where((b) => b.id == id).firstOrNull);
    } catch (_) {
      _client = const Section(error: true, data: null);
    }
    notifyListeners();
  }

  // ── Formulario de tanque ──

  /// Carga comprador, productos activos del distribuidor y, al editar, el tanque actual.
  Future<void> loadTankForm(int buyerId, int? tankId) async {
    _formLoading = true;
    _formLoadError = false;
    notifyListeners();
    try {
      final buyers = await _api.buyerCompanies();
      final providerId = _iam.providerId;
      final products = providerId == null
          ? <FuelProduct>[]
          : await _inventory.getProductsByProvider(providerId);
      final tanks = tankId == null
          ? <ProviderTank>[]
          : await _api.tanks(buyerId);
      _formBuyer = buyers.where((b) => b.id == buyerId).firstOrNull;
      _formProducts = products.where((p) => p.active).toList();
      _original = tankId == null
          ? null
          : tanks.where((t) => t.id == tankId).firstOrNull;
      _formLoadError =
          _formBuyer == null || (tankId != null && _original == null);
    } catch (_) {
      _formLoadError = true;
    }
    _formLoading = false;
    notifyListeners();
  }

  Future<bool> createTank(NewProviderTank body) =>
      _saveTank(() => _api.registerTank(body));

  Future<bool> updateTank(int id, ProviderTankUpdate body) =>
      _saveTank(() => _api.updateTank(id, body));

  // ── Detalle de tanque ──

  Future<void> loadTankDetail(int id) =>
      Future.wait([loadTank(id), loadReadings(id), loadEpisodes(id)]);

  /// 404 `TANK_NOT_FOUND` (inexistente, inactivo o ajeno) no es error: la vista muestra "no encontrado".
  Future<void> loadTank(int id) async {
    _tank = Section(loading: true, data: _tank.data);
    notifyListeners();
    try {
      _tank = Section(data: await _api.tank(id));
    } catch (e) {
      final notFound = e is ApiException && e.code == 'TANK_NOT_FOUND';
      _tank = Section(error: !notFound, data: null);
    }
    notifyListeners();
  }

  Future<void> loadReadings(int id) async {
    _readings = Section(loading: true, data: _readings.data);
    notifyListeners();
    final from = DateTime.now()
        .subtract(_readingsWindow)
        .toUtc()
        .toIso8601String();
    try {
      _readings = Section(data: await _api.readings(id, from));
    } catch (_) {
      _readings = const Section(error: true, data: []);
    }
    notifyListeners();
  }

  Future<void> loadEpisodes(int id) async {
    _episodes = Section(loading: true, data: _episodes.data);
    notifyListeners();
    try {
      _episodes = Section(data: await _api.episodes(id));
    } catch (_) {
      _episodes = const Section(error: true, data: []);
    }
    notifyListeners();
  }

  // ── Helpers ──

  Future<bool> _saveTank(Future<ProviderTank> Function() request) async {
    if (_formSaving || _formLoading || _formLoadError) return false;
    _formSaving = true;
    _tankFormError = null;
    notifyListeners();
    try {
      await request();
      _formSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _tankFormError = providerErrorKey(e);
      _formSaving = false;
      notifyListeners();
      return false;
    }
  }

  void _startWait() {
    _waitTimer?.cancel();
    _waitSeconds = _defaultRetryAfterSeconds;
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _waitSeconds--;
      if (_waitSeconds <= 0) timer.cancel();
      notifyListeners();
    });
  }
}
