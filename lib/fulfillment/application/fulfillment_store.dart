import 'package:material_ui/material_ui.dart';

import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/driver_entity.dart';
import '../domain/model/provider_delivery_entity.dart';
import '../domain/model/tanker_entity.dart';
import '../infrastructure/driver_response.dart';
import '../infrastructure/fulfillment_api.dart';

/// Secciones del detalle de entrega que cargan y fallan por separado.
enum DeliverySection { detail, tracking, samples, transitions, timeline, valve }

/// Estado del BC Fulfillment (equivale a `fulfillment.store.ts`): cisternas, conductores y entregas.
///
/// Una instancia por vista. Los errores y avisos son claves de traducción.
class FulfillmentStore extends ChangeNotifier {
  FulfillmentStore(this._api);

  final FulfillmentApi _api;

  List<Tanker> _tankerList = [];
  Tanker? _selectedTanker;
  List<Driver> _driverList = [];
  Driver? _selectedDriver;
  List<ProviderDelivery> _deliveries = [];
  bool _isLoading = false;
  String? _error;
  String? _successMsg;
  final Map<int, EligibilityResult> _tankerEligibility = {};
  final Map<int, bool> _tankerEligibilityLoading = {};
  final Map<int, String> _tankerEligibilityError = {};
  final Map<int, EligibilityResult> _driverEligibility = {};
  final Map<int, bool> _driverEligibilityLoading = {};
  final Map<int, String> _driverEligibilityError = {};
  int _deliveryRequest = 0;

  Map<String, dynamic>? _delivery;
  Map<String, dynamic>? _tracking;
  List<Map<String, dynamic>> _samples = [];
  List<Map<String, dynamic>> _transitions = [];
  List<Map<String, dynamic>> _timeline = [];
  List<ValveObservation>? _valve;
  final Set<DeliverySection> _failedSections = {};
  String _driverName = '';
  String _tankerName = '';
  bool _commandBusy = false;
  bool _geofenceBusy = false;
  bool _recommendationLoading = false;
  String? _recommendationError;
  DeliveryRecommendation? _recommendation;

  List<Tanker> get tankerList => _tankerList;
  Tanker? get selectedTanker => _selectedTanker;
  List<Driver> get driverList => _driverList;
  Driver? get selectedDriver => _selectedDriver;
  List<ProviderDelivery> get deliveries => _deliveries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMsg => _successMsg;
  Map<int, EligibilityResult> get tankerEligibility => _tankerEligibility;
  Map<int, bool> get tankerEligibilityLoading => _tankerEligibilityLoading;
  Map<int, String> get tankerEligibilityError => _tankerEligibilityError;
  Map<int, EligibilityResult> get driverEligibility => _driverEligibility;
  Map<int, bool> get driverEligibilityLoading => _driverEligibilityLoading;
  Map<int, String> get driverEligibilityError => _driverEligibilityError;

  Map<String, dynamic>? get delivery => _delivery;
  Map<String, dynamic>? get tracking => _tracking;
  List<Map<String, dynamic>> get samples => _samples;
  List<Map<String, dynamic>> get transitions => _transitions;
  List<Map<String, dynamic>> get timeline => _timeline;
  List<ValveObservation>? get valve => _valve;
  String get driverName => _driverName;
  String get tankerName => _tankerName;
  bool get commandBusy => _commandBusy;
  bool get geofenceBusy => _geofenceBusy;
  bool sectionFailed(DeliverySection section) =>
      _failedSections.contains(section);
  bool get recommendationLoading => _recommendationLoading;
  String? get recommendationError => _recommendationError;
  DeliveryRecommendation? get recommendation => _recommendation;

  void clearMessages() {
    _error = null;
    _successMsg = null;
    notifyListeners();
  }

  // ── Deliveries ──

  /// Entregas del distribuidor; la petición anterior se descarta si llega otra.
  Future<void> loadDeliveries([String? date]) async {
    final request = ++_deliveryRequest;
    _deliveries = [];
    _error = null;
    _isLoading = true;
    notifyListeners();
    List<ProviderDelivery> rows = const [];
    String? failure;
    try {
      rows = await _api.deliveries(date);
    } catch (e) {
      failure = _messageOf(e);
    }
    if (request != _deliveryRequest) return;
    _deliveries = rows;
    _error = failure;
    _isLoading = false;
    notifyListeners();
  }

  /// Recarga todas las secciones del detalle de una entrega.
  Future<void> reloadDelivery(int id) async {
    _delivery = null;
    _tracking = null;
    _samples = [];
    _transitions = [];
    _timeline = [];
    _valve = null;
    _driverName = '';
    _tankerName = '';
    _failedSections.clear();
    notifyListeners();
    await Future.wait([
      _load(
        DeliverySection.detail,
        () => _api.delivery(id),
        (v) => _delivery = v as Map<String, dynamic>,
      ).then((_) => _loadParties()),
      _load(
        DeliverySection.tracking,
        () => _api.tracking(id),
        (v) => _tracking = v as Map<String, dynamic>?,
      ),
      _load(
        DeliverySection.samples,
        () => _api.trackingSamples(id),
        (v) => _samples = _maps(v),
      ),
      _load(
        DeliverySection.transitions,
        () => _api.deliveryTransitions(id),
        (v) => _transitions = _maps(v),
      ),
      _load(
        DeliverySection.timeline,
        () => _api.deliveryTimeline(id),
        (v) => _timeline = _maps(v),
      ),
      loadValve(id),
    ]);
  }

  /// Observaciones de válvula; `null` = sin cargar, `[]` = sin observaciones.
  Future<void> loadValve(int id) async {
    _valve = null;
    _failedSections.remove(DeliverySection.valve);
    notifyListeners();
    await _load(
      DeliverySection.valve,
      () => _api.valveObservations(id),
      (v) => _valve = v,
    );
  }

  bool canCommand(String action) {
    final state = _delivery?['physicalState'];
    return switch (action) {
      'start' => state == DeliveryPhysicalState.assigned,
      'arrive' => state == DeliveryPhysicalState.started,
      'complete' =>
        state == DeliveryPhysicalState.arrived ||
            state == DeliveryPhysicalState.delivering,
      'fail' || 'cancel' => const [
        DeliveryPhysicalState.assigned,
        DeliveryPhysicalState.started,
        DeliveryPhysicalState.arrived,
        DeliveryPhysicalState.delivering,
      ].contains(state),
      _ => false,
    };
  }

  /// Ejecuta una transición de la entrega y recarga el detalle.
  Future<void> deliveryCommand(
    int id,
    String action, {
    double? deliveredVolume,
    String reason = '',
  }) async {
    if (_commandBusy || !canCommand(action)) return;
    if (action == 'complete' &&
        (deliveredVolume == null ||
            !deliveredVolume.isFinite ||
            deliveredVolume <= 0)) {
      return;
    }
    if ((action == 'fail' || action == 'cancel') && reason.trim().isEmpty) {
      return;
    }
    final body = switch (action) {
      'complete' => <String, dynamic>{'deliveredVolume': deliveredVolume},
      'fail' || 'cancel' => <String, dynamic>{'reason': reason},
      _ => <String, dynamic>{},
    };
    _commandBusy = true;
    _error = null;
    notifyListeners();
    try {
      await _api.deliveryCommand(id, action, body);
    } catch (_) {
      _commandBusy = false;
      _error = 'fulfillment.command-failed';
      notifyListeners();
      return;
    }
    _commandBusy = false;
    await reloadDelivery(id);
  }

  /// Geocerca de la entrega (una sola, no editable).
  Future<void> saveGeofence(
    int id, {
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    if (_geofenceBusy) return;
    _geofenceBusy = true;
    _error = null;
    _successMsg = null;
    notifyListeners();
    try {
      await _api.createGeofence(id, {
        'centerLatitude': latitude,
        'centerLongitude': longitude,
        'radiusMeters': radiusMeters,
      });
      _successMsg = 'fulfillment.geofence-saved';
    } catch (e) {
      _error = e is ApiException && e.status == 409
          ? 'fulfillment.geofence-exists'
          : 'fulfillment.geofence-failed';
    }
    _geofenceBusy = false;
    notifyListeners();
  }

  /// Sugerencia de cisterna y conductor para un pedido; la ventana es opcional.
  Future<void> loadRecommendation(
    int orderId, [
    String? windowStart,
    String? windowEnd,
  ]) async {
    _recommendation = null;
    _recommendationError = null;
    _recommendationLoading = true;
    notifyListeners();
    try {
      _recommendation = await _api.recommendation(
        orderId,
        windowStart,
        windowEnd,
      );
    } catch (e) {
      _recommendationError = e is ApiException && e.status == 409
          ? 'fulfillment.recommendation.conflict'
          : _messageOf(e);
    }
    _recommendationLoading = false;
    notifyListeners();
  }

  /// Crea la entrega; devuelve su id, o `null` si falló (con `error` puesto).
  /// Un 409 recarga conductores y cisternas porque su disponibilidad cambió.
  Future<int?> assignDelivery(Map<String, dynamic> body) async {
    _error = null;
    notifyListeners();
    try {
      final result = await _api.assignDelivery(body) as Map<String, dynamic>;
      return (result['deliveryId'] as num).toInt();
    } catch (e) {
      final conflict = e is ApiException && e.status == 409;
      if (conflict) {
        await Future.wait([loadAvailableDrivers(), loadAvailableTankers()]);
      }
      _error = conflict
          ? 'fulfillment.assignment.conflict'
          : 'fulfillment.assignment-failed';
      notifyListeners();
      return null;
    }
  }

  // ── Tankers ──

  Future<void> loadTankers() async {
    _clearTankerEligibility();
    await _run(_api.getTankers, (rows) => _tankerList = rows);
  }

  Future<void> loadAvailableTankers() async {
    _clearTankerEligibility();
    await _run(_api.getEligibleTankers, (rows) => _tankerList = rows);
  }

  Future<void> loadTankerById(int id) =>
      _run(() => _api.getTankerById(id), (row) => _selectedTanker = row);

  Future<void> registerTanker(
    TankerInput request, [
    VoidCallback? onSuccess,
  ]) async {
    _successMsg = null;
    final ok = await _run(() => _api.registerTanker(request), (row) {
      _tankerList = [..._tankerList, row];
      _successMsg = 'tanker-form.saved-created';
    });
    if (ok) onSuccess?.call();
  }

  Future<void> updateTanker(
    int id,
    Map<String, dynamic> request, [
    VoidCallback? onSuccess,
  ]) async {
    _successMsg = null;
    final ok = await _run(() => _api.updateTanker(id, request), (row) {
      _tankerList = [for (final t in _tankerList) t.id == id ? row : t];
      _selectedTanker = row;
      _successMsg = 'tanker-form.saved';
    });
    if (ok) onSuccess?.call();
  }

  Future<void> updateTankerStatus(int id, String status) async {
    _successMsg = null;
    await _run(() => _api.updateTankerStatus(id, status), (row) {
      _tankerList = [for (final t in _tankerList) t.id == id ? row : t];
      _clearTankerEligibility(id);
      _successMsg = 'tanker-form.saved';
    });
  }

  Future<void> checkTankerEligibility(int id) => _checkEligibility(
    id,
    _api.checkTankerEligibility,
    _tankerEligibility,
    _tankerEligibilityLoading,
    _tankerEligibilityError,
  );

  // ── Drivers ──

  Future<void> loadDrivers() async {
    _clearDriverEligibility();
    await _run(_api.getDrivers, (rows) => _driverList = rows);
  }

  Future<void> loadAvailableDrivers() async {
    _clearDriverEligibility();
    await _run(_api.getEligibleDrivers, (rows) => _driverList = rows);
  }

  Future<void> loadDriverById(int id) =>
      _run(() => _api.getDriverById(id), (row) => _selectedDriver = row);

  Future<void> registerDriver(
    DriverInput request, [
    VoidCallback? onSuccess,
  ]) async {
    _successMsg = null;
    final ok = await _run(() => _api.registerDriver(request), (row) {
      _driverList = [..._driverList, row];
      _successMsg = 'driver-form.saved-created';
    });
    if (ok) onSuccess?.call();
  }

  Future<void> updateDriver(
    int id,
    Map<String, dynamic> request, [
    VoidCallback? onSuccess,
  ]) async {
    _successMsg = null;
    final ok = await _run(() => _api.updateDriver(id, request), (row) {
      _driverList = [for (final d in _driverList) d.id == id ? row : d];
      _selectedDriver = row;
      _successMsg = 'driver-form.saved';
    });
    if (ok) onSuccess?.call();
  }

  Future<void> updateDriverStatus(int id, String status) async {
    _successMsg = null;
    await _run(() => _api.updateDriverStatus(id, status), (row) {
      _driverList = [for (final d in _driverList) d.id == id ? row : d];
      _clearDriverEligibility(id);
      _successMsg = 'driver-form.saved';
    });
  }

  Future<void> checkDriverEligibility(int id) => _checkEligibility(
    id,
    _api.checkDriverEligibility,
    _driverEligibility,
    _driverEligibilityLoading,
    _driverEligibilityError,
  );

  // ── Helpers ──

  Future<void> _loadParties() async {
    final d = _delivery;
    if (d == null) return;
    await Future.wait([
      _api
          .getDriverById((d['driverId'] as num).toInt())
          .then<void>(
            (x) => _driverName = '${x.firstName} ${x.lastName}',
            onError: (_) => _driverName = '',
          ),
      _api
          .getTankerById((d['vehicleId'] as num).toInt())
          .then<void>(
            (x) => _tankerName = '${x.brand} ${x.model} · ${x.licensePlate}',
            onError: (_) => _tankerName = '',
          ),
    ]);
    notifyListeners();
  }

  Future<void> _load<T>(
    DeliverySection section,
    Future<T> Function() request,
    void Function(T) done,
  ) async {
    try {
      done(await request());
      _failedSections.remove(section);
    } catch (_) {
      _failedSections.add(section);
    }
    notifyListeners();
  }

  /// Ejecuta [request] con el indicador de carga; devuelve `true` si tuvo éxito.
  Future<bool> _run<T>(
    Future<T> Function() request,
    void Function(T) done,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    var ok = false;
    try {
      done(await request());
      ok = true;
    } catch (e) {
      _error = _messageOf(e);
    }
    _isLoading = false;
    notifyListeners();
    return ok;
  }

  Future<void> _checkEligibility(
    int id,
    Future<EligibilityResult> Function(int) check,
    Map<int, EligibilityResult> results,
    Map<int, bool> loading,
    Map<int, String> errors,
  ) async {
    if (loading[id] == true) return;
    loading[id] = true;
    errors[id] = '';
    results.remove(id);
    notifyListeners();
    try {
      results[id] = await check(id);
    } catch (e) {
      errors[id] = _messageOf(e);
    }
    loading[id] = false;
    notifyListeners();
  }

  /// Un resultado de elegibilidad deja de ser válido al recargar o cambiar la fila.
  void _clearTankerEligibility([int? id]) {
    _drop(_tankerEligibility, id);
    _drop(_tankerEligibilityError, id);
  }

  void _clearDriverEligibility([int? id]) {
    _drop(_driverEligibility, id);
    _drop(_driverEligibilityError, id);
  }

  void _drop<T>(Map<int, T> entries, int? id) {
    if (id == null) {
      entries.clear();
    } else {
      entries.remove(id);
    }
  }

  List<Map<String, dynamic>> _maps(List<dynamic> rows) => [
    for (final e in rows) e as Map<String, dynamic>,
  ];

  String _messageOf(Object e) =>
      e is ApiException && e.message.isNotEmpty ? e.message : 'errors.generic';
}
