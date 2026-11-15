import 'package:material_ui/material_ui.dart';

import '../../iam/application/iam_store.dart';
import '../../iam/infrastructure/iam_api.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/equipment_entity.dart';
import '../infrastructure/equipment_api.dart';

const _defaultPolicy = RefillPolicy(
  lowLevelPercent: 20,
  hysteresisPercent: 10,
  targetLevelPercent: 100,
  providerId: null,
  fuelProductId: null,
  autoGenerateEnabled: false,
);

/// Equipo del comprador (equivale a `equipment.store.ts`): cuenta interna, sitios y tanques,
/// más el detalle de tanque (política de reposición y episodios). Una instancia por vista.
class EquipmentStore extends ChangeNotifier {
  EquipmentStore(this._api, this._iam, this._iamApi);

  final EquipmentApi _api;
  final IamStore _iam;
  final IamApi _iamApi;

  Customer? _customer;
  List<Site> _sites = [];
  List<Tank> _tanks = [];
  String? _error;
  bool _loading = false;
  bool _creatingSite = false;
  bool _creatingTank = false;
  int _sitesSequence = 0;

  Tank? _tank;
  List<IdName> _providers = [];
  RefillPolicy? _policy;
  bool _policyReady = false;
  bool _savingPolicy = false;
  bool _policySaved = false;
  List<ProductRef> _products = [];
  int _productsSequence = 0;
  List<RefillEpisode> _episodes = [];

  /// Cuenta interna de la organización activa; el comprador nunca la registra ni ve su id.
  Customer? get customer => _customer;
  List<Site> get sites => _sites;
  List<Tank> get tanks => _tanks;
  String? get error => _error;
  bool get loading => _loading;
  bool get creatingSite => _creatingSite;
  bool get creatingTank => _creatingTank;
  Tank? get tank => _tank;
  List<IdName> get providers => _providers;
  RefillPolicy? get policy => _policy;
  bool get policyReady => _policyReady;
  bool get savingPolicy => _savingPolicy;
  bool get policySaved => _policySaved;
  List<ProductRef> get products => _products;
  List<RefillEpisode> get episodes => _episodes;

  static const _unresolved = ApiException('equipment.customer-unresolved');

  /// Resuelve la cuenta de la organización activa: la enlazada a la empresa del usuario, la única
  /// sin enlace, o la crea desde su BuyerCompany. Un 409 en la creación relee la cuenta ganadora.
  Future<Customer> resolveCustomer() async {
    final companyId = _iam.companyId;
    final rows = await _api.customers();
    final customer =
        _matchCustomer(rows, companyId) ??
        (rows.isNotEmpty || companyId == null
            ? null
            : await _createCustomer(companyId));
    if (customer == null) throw _unresolved;
    _customer = customer;
    notifyListeners();
    return customer;
  }

  Future<void> load() async {
    _error = null;
    _customer = null;
    _sites = [];
    _loading = true;
    notifyListeners();
    await Future.wait([_loadTanks(), _resolveAndLoadSites()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadSites(int customerId) async {
    final sequence = ++_sitesSequence;
    _sites = [];
    notifyListeners();
    try {
      final rows = await _api.sites(customerId);
      if (sequence == _sitesSequence) _sites = rows;
    } catch (e) {
      if (sequence == _sitesSequence) _error = _messageOf(e);
    }
    notifyListeners();
  }

  Future<void> createSite({
    required String name,
    required String address,
    VoidCallback? done,
  }) async {
    final customer = _customer;
    if (_creatingSite || customer == null) return;
    _error = null;
    _creatingSite = true;
    notifyListeners();
    try {
      await _api.createSite(customer.id, name: name, address: address);
      await loadSites(customer.id);
      done?.call();
    } catch (e) {
      _error = _messageOf(e);
    }
    _creatingSite = false;
    notifyListeners();
  }

  Future<void> createTank(CreateTankRequest value, [VoidCallback? done]) async {
    if (_creatingTank || _customer == null) return;
    _error = null;
    _creatingTank = true;
    notifyListeners();
    try {
      await _api.createTank(value);
      _tanks = await _api.tanks();
      done?.call();
    } catch (e) {
      _error = _messageOf(e);
    }
    _creatingTank = false;
    notifyListeners();
  }

  /// Carga el tanque, sus proveedores, su política (404 = sin política aún) y episodios (404 = ninguno).
  Future<void> loadTankDetail(int id) async {
    _error = null;
    _tank = null;
    _policy = null;
    _policyReady = false;
    _policySaved = false;
    _products = [];
    _episodes = [];
    notifyListeners();
    await Future.wait([
      _run(_api.providers, (rows) => _providers = rows),
      _run(() => _api.tank(id), (row) => _tank = row),
      _loadPolicy(id),
      _run(
        () => _api.episodes(id),
        (rows) => _episodes = rows,
        ignoreNotFound: true,
      ),
    ]);
  }

  /// Carga los productos del proveedor; descarta la respuesta si ya se eligió otro.
  Future<void> loadProducts(int providerId) async {
    final sequence = ++_productsSequence;
    try {
      final rows = await _api.products(providerId);
      if (sequence == _productsSequence) _products = rows;
    } catch (e) {
      if (sequence == _productsSequence) _error = _messageOf(e);
    }
    notifyListeners();
  }

  /// Cambia el proveedor del borrador: limpia productos y carga los del nuevo proveedor.
  Future<void> selectProvider(int? providerId) async {
    if (!_policyReady || _savingPolicy) return;
    _productsSequence++;
    _products = [];
    _policySaved = false;
    notifyListeners();
    if (providerId != null) await loadProducts(providerId);
  }

  /// Cualquier cambio del borrador invalida el aviso de guardado.
  void editPolicy() {
    _policySaved = false;
    notifyListeners();
  }

  Future<void> savePolicy(RefillPolicy value) async {
    final id = _tank?.id;
    if (!_policyReady || id == null || _savingPolicy) return;
    _savingPolicy = true;
    _policySaved = false;
    _error = null;
    notifyListeners();
    try {
      _policy = await _api.savePolicy(id, value);
      _policySaved = true;
    } catch (e) {
      _error = _messageOf(e);
    }
    _savingPolicy = false;
    notifyListeners();
  }

  Future<void> _loadTanks() async {
    try {
      _tanks = await _api.tanks();
    } catch (e) {
      _error = _messageOf(e);
    }
    notifyListeners();
  }

  Future<void> _resolveAndLoadSites() async {
    try {
      final customer = await resolveCustomer();
      await loadSites(customer.id);
    } catch (e) {
      _error = _messageOf(e);
    }
    notifyListeners();
  }

  Future<Customer> _createCustomer(int companyId) async {
    try {
      final profile = await _iamApi.getBuyerCompany(companyId);
      return await _api.createCustomer({
        'name': profile.name,
        'ruc': profile.ruc,
        'address': profile.address,
        'contactEmail': profile.contactEmail,
        'phone': profile.phone,
        'legacyCompanyId': companyId,
      });
    } on ApiException catch (e) {
      if (e.status != 409) rethrow;
      final winner = _matchCustomer(await _api.customers(), companyId);
      if (winner == null) throw _unresolved;
      return winner;
    }
  }

  Customer? _matchCustomer(List<Customer> rows, int? companyId) {
    final linked = rows
        .where((c) => companyId != null && c.legacyCompanyId == companyId)
        .firstOrNull;
    if (linked != null) return linked;
    return rows.length == 1 && rows.first.legacyCompanyId == null
        ? rows.first
        : null;
  }

  Future<void> _loadPolicy(int id) async {
    try {
      final policy = await _api.policy(id);
      _policy = policy;
      _policyReady = true;
      notifyListeners();
      final providerId = policy.providerId;
      if (providerId != null) await loadProducts(providerId);
    } catch (e) {
      if (e is ApiException && e.status == 404) {
        _policy = _defaultPolicy;
        _policyReady = true;
      } else {
        _error = _messageOf(e);
      }
      notifyListeners();
    }
  }

  Future<void> _run<T>(
    Future<T> Function() request,
    void Function(T) done, {
    bool ignoreNotFound = false,
  }) async {
    try {
      done(await request());
    } catch (e) {
      final notFound = e is ApiException && e.status == 404;
      if (!(ignoreNotFound && notFound)) _error = _messageOf(e);
    }
    notifyListeners();
  }

  String _messageOf(Object e) => e is ApiException && e.message.isNotEmpty
      ? e.message
      : 'equipment.request-failed';
}
