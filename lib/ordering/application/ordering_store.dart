import 'package:material_ui/material_ui.dart';

import '../../iam/application/iam_store.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/order_entity.dart';
import '../domain/model/request_entity.dart';
import '../infrastructure/ordering_api.dart';

part 'ordering_store_payments.dart';

const _paymentOrderStatuses = [
  OrderStatus.pendingPayment,
  OrderStatus.paid,
  OrderStatus.inProgress,
  OrderStatus.delivered,
];

/// Solicitudes, órdenes y pagos (equivale a `OrderingStore`). Valida en cliente el rol y la
/// pertenencia antes de cada acción; cada vista crea su propia instancia.
class OrderingStore extends ChangeNotifier {
  OrderingStore(this._api, this._iam);

  final OrderingApi _api;
  final IamStore _iam;

  bool _disposed = false;
  int _activeRequests = 0;
  int _orderSequence = 0;
  bool _loading = false;
  String? _error;
  String _notice = '';
  List<Request> _requests = const [];
  List<Order> _orders = const [];
  List<Payment> _payments = const [];
  List<ProviderPayment> _providerPayments = const [];
  String _providerStatus = '';
  Map<int, String> _providerNames = const {};
  Map<int, String> _productNames = const {};
  int? _refundingId;
  String _refundError = '';
  String? _companyName;
  Payment? _payment;
  bool _paymentLoading = false;
  bool _paymentReadError = false;
  String _paymentError = '';
  bool _paying = false;
  int? _paymentOrderLoaded;
  int? _busyProviderPaymentId;
  String _providerActionError = '';

  bool get loading => _loading;
  String? get error => _error;
  String get notice => _notice;
  List<Request> get requests => _requests;
  List<Order> get orders => _orders;
  List<Payment> get payments => _payments;
  List<ProviderPayment> get providerPayments => _providerPayments;
  Map<int, String> get providerNames => _providerNames;
  Map<int, String> get productNames => _productNames;
  int? get refundingId => _refundingId;
  String get refundError => _refundError;
  String? get companyName => _companyName;
  Payment? get payment => _payment;
  bool get paymentLoading => _paymentLoading;
  bool get paymentReadError => _paymentReadError;
  String get paymentError => _paymentError;
  bool get paying => _paying;
  int? get busyProviderPaymentId => _busyProviderPaymentId;
  String get providerActionError => _providerActionError;
  bool get isProvider => _iam.isProvider;

  /// Orden del detalle abierto (la única cargada por [loadOrder]).
  Order? get order => _orders.isEmpty ? null : _orders.first;

  /// Nombres para mostrar en vez de ids; si una consulta falla se muestra el id (sin error visible).
  void loadNames() {
    if (_iam.isProvider) {
      final id = _iam.providerId;
      if (id == null) return;
      _quietly(
        () => _api.provider(id),
        (row) => _providerNames = {row.id: row.name},
      );
      _quietly(
        () => _api.products(id),
        (rows) => _productNames = {for (final row in rows) row.id: row.name},
      );
      return;
    }
    _quietly(
      () => _api.providers(),
      (rows) => _providerNames = {for (final row in rows) row.id: row.name},
    );
    _quietly(
      () => _api.allProducts(),
      (rows) => _productNames = {for (final row in rows) row.id: row.name},
    );
  }

  /// Carga la bandeja del distribuidor o las solicitudes del comprador, según el rol.
  void loadRequests() => _run(
    () => _iam.isProvider ? _api.requestInbox() : _api.requests(),
    (value) => _requests = value,
  );

  /// Carga una solicitud para el detalle (queda como única entrada de [requests]).
  void loadRequest(int id) {
    _update(() => _requests = const []);
    if (id < 1) {
      _update(() => _error = 'errors.http-404');
      return;
    }
    _run(() => _api.request(id), (value) => _requests = [value]);
  }

  void loadOrders() {
    final provider = _iam.isProvider;
    final id = provider ? _iam.providerId : _iam.companyId;
    if (id == null) {
      _update(() => _error = 'ordering.missing-organization');
      return;
    }
    _run(
      () => _api.orders(provider ? 'provider' : 'company', id),
      (value) => _orders = value,
    );
  }

  void loadOrder(int id) {
    final sequence = ++_orderSequence;
    _update(() => _orders = const []);
    if (id < 1) {
      _update(() => _error = 'errors.http-404');
      return;
    }
    _run(() => _api.order(id), (loaded) {
      if (sequence != _orderSequence) return;
      _orders = [loaded];
      _loadCompanyNameFor(loaded);
      _loadPaymentFor(loaded);
    });
  }

  void createRequest(CreateRequest value, void Function() done) =>
      _run(() => _api.createRequest(value), (_) {
        loadRequests();
        done();
      });

  /// Acepta una solicitud pendiente propia del distribuidor y recarga la lista y la orden generada.
  void acceptRequest(int id) {
    if (!_canDecideRequest(id)) return;
    _run(() => _api.acceptRequest(id), (request) {
      loadRequests();
      final orderId = request.orderId;
      if (orderId != null) {
        loadOrder(orderId);
      } else {
        loadOrders();
      }
      _notice = 'request-list.accepted';
    });
  }

  /// Rechaza una solicitud pendiente propia; el motivo es obligatorio y admite hasta 240 caracteres.
  void rejectRequest(int id, String reason) {
    final text = reason.trim();
    if (!_canDecideRequest(id) || text.isEmpty || text.length > 240) return;
    _run(() => _api.rejectRequest(id, text), (_) {
      loadRequests();
      _notice = 'request-list.rejected';
    });
  }

  void cancelRequest(int id) {
    if (!_iam.isBuyer ||
        _loading ||
        !_requests.any(
          (row) => row.id == id && row.status == RequestStatus.pending,
        )) {
      return;
    }
    _run(() => _api.cancelRequest(id), (_) {
      loadRequests();
      _notice = 'request-detail.cancel-success';
    });
  }

  void confirmOrder(int id) {
    final current = _find(_orders, (row) => row.id == id);
    if (_loading ||
        _paying ||
        !_iam.isBuyer ||
        current == null ||
        current.companyId != _iam.companyId ||
        current.status != OrderStatus.pending) {
      return;
    }
    _run(() => _api.confirmOrder(id), _replaceOrder);
  }

  void cancelOrder(int id) {
    final current = _find(_orders, (row) => row.id == id);
    final owns = _iam.isBuyer
        ? current?.companyId == _iam.companyId
        : _iam.isProvider && current?.providerId == _iam.providerId;
    if (_loading ||
        _paying ||
        current == null ||
        !owns ||
        ![
          OrderStatus.pending,
          OrderStatus.confirmed,
        ].contains(current.status)) {
      return;
    }
    _run(() => _api.cancelOrder(id), _replaceOrder);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool _canDecideRequest(int id) =>
      _iam.isProvider &&
      !_loading &&
      _requests.any(
        (row) =>
            row.id == id &&
            row.status == RequestStatus.pending &&
            row.providerId == _iam.providerId,
      );

  void _replaceOrder(Order updated) {
    _orders = [
      updated,
      for (final row in _orders)
        if (row.id != updated.id) row,
    ];
    _loadPaymentFor(updated);
  }

  Future<void> _quietly<T>(
    Future<T> Function() call,
    void Function(T value) save,
  ) async {
    try {
      final value = await call();
      _update(() => save(value));
    } catch (_) {
      /* Un nombre que no carga se muestra como id. */
    }
  }

  Future<void> _run<T>(
    Future<T> Function() call,
    void Function(T value) save, {
    bool keepNotice = false,
  }) async {
    _activeRequests++;
    _update(() {
      _loading = true;
      _error = null;
      if (!keepNotice) _notice = '';
    });
    try {
      save(await call());
    } catch (error) {
      _update(() => _error = _failure(error));
    } finally {
      _activeRequests--;
      _update(() => _loading = _activeRequests > 0);
    }
  }

  /// Clave i18n del fallo: mensaje del backend si lo hay; si no, según el estado HTTP.
  String _failure(Object error, [String fallback = 'ordering.request-failed']) {
    if (error is! ApiException) return fallback;
    final message = error.body?['message'];
    if (message is String && message.isNotEmpty) return message;
    return _statusKey(error, fallback);
  }

  String _statusKey(Object error, String fallback) {
    final status = error is ApiException ? error.status : null;
    if (status == null) return fallback;
    if (status == 0) return 'errors.network';
    if (status >= 500) return 'errors.server';
    return const [400, 401, 403, 404, 409, 422].contains(status)
        ? 'errors.http-$status'
        : 'errors.generic';
  }

  void _update(VoidCallback change) {
    change();
    if (!_disposed) notifyListeners();
  }

  T? _find<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
