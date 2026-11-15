import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';
import '../../domain/model/order_entity.dart';
import '../../domain/model/request_entity.dart';
import '../ordering_api.dart';
import 'ordering_demo_seed.dart';

part 'ordering_demo_payments.dart';

/// Datos demo del contexto ordering: solicitudes, órdenes y pagos en memoria, con estados mutables.
class OrderingDemoHandler implements DemoHandler {
  final List<Request> _requests = seedRequests();
  final List<Order> _orders = seedOrders();
  final List<Payment> _payments = seedPayments();
  final Map<int, String> _createdAt = Map.of(seedPaymentCreatedAt);

  @override
  Future<DemoResponse?> handle(DemoRequest r) async =>
      _requestRoutes(r) ??
      _orderRoutes(r) ??
      _paymentRoutes(r) ??
      _catalogRoutes(r);

  DemoResponse? _requestRoutes(DemoRequest r) {
    if (r.match('GET', '/replenishment-requests') != null) {
      return DemoResponse.json([
        for (final q in _requests)
          if (q.organizationId == DemoWorld.buyerOrganizationId) q.toJson(),
      ]);
    }
    if (r.match('GET', '/replenishment-requests/inbox') != null) {
      return DemoResponse.json([
        for (final q in _requests)
          if (q.providerId == DemoWorld.providerId) q.toJson(),
      ]);
    }
    if (r.match('POST', '/replenishment-requests') != null) {
      return _createRequest(r);
    }
    final detail = r.match('GET', '/replenishment-requests/:id');
    if (detail != null) {
      final request = _firstWhere(_requests, (q) => q.id == _idOf(detail));
      return request == null
          ? _notFound('Solicitud')
          : DemoResponse.json(request.toJson());
    }
    final accept = r.match('POST', '/replenishment-requests/:id/accept');
    if (accept != null) return _acceptRequest(_idOf(accept));
    final reject = r.match('POST', '/replenishment-requests/:id/reject');
    if (reject != null) return _rejectRequest(_idOf(reject), r.json['reason']);
    final cancel = r.match('POST', '/replenishment-requests/:id/cancel');
    if (cancel != null) return _cancelRequest(_idOf(cancel));
    return null;
  }

  DemoResponse _createRequest(DemoRequest r) {
    final body = r.json;
    final providerId = _intOf(body['providerId']);
    final productId = _intOf(body['fuelProductId']);
    final customerAccountId = _intOf(body['customerAccountId']);
    final quantity = (body['quantity'] as num?)?.toDouble() ?? 0;
    final product = _firstWhere(seedProducts(), (p) => p.id == productId);
    if (product == null ||
        customerAccountId == null ||
        product.providerId != providerId ||
        quantity <= 0) {
      return DemoResponse.error(400, 'Solicitud inválida (demo)');
    }
    final request = Request(
      id: _nextId(_requests.map((q) => q.id), DemoWorld.requestIdRange.$1),
      organizationId: DemoWorld.buyerOrganizationId,
      customerAccountId: customerAccountId,
      tankId: _intOf(body['tankId']),
      providerId: product.providerId,
      fuelProductId: product.id,
      quantity: quantity,
      unit: '${body['unit'] ?? 'LITERS'}',
      unitPrice: product.pricePerUnit,
      status: RequestStatus.pending,
      source: RequestSource.manual,
      rejectionReason: null,
      orderId: null,
      deliveryAddress: '${body['deliveryAddress'] ?? ''}',
      deliveryDate: '${body['deliveryDate'] ?? ''}',
      version: 1,
    );
    _requests.add(request);
    return DemoResponse.json(request.toJson());
  }

  DemoResponse _acceptRequest(int id) {
    final index = _indexOfRequest(id);
    if (index < 0) return _notFound('Solicitud');
    final request = _requests[index];
    if (request.status != RequestStatus.pending) return _conflict();
    final order = Order(
      id: _nextId(_orders.map((o) => o.id), DemoWorld.orderIdRange.$1),
      requestId: request.id,
      companyId: request.organizationId,
      providerId: request.providerId,
      fuelProductId: request.fuelProductId,
      equipmentId: request.tankId,
      requestedQuantity: request.quantity,
      totalPrice: _money(request.quantity * request.unitPrice),
      status: OrderStatus.pending,
      deliveryAddress: request.deliveryAddress,
      scheduledDate: request.deliveryDate,
    );
    _orders.add(order);
    final accepted = request.copyWith(
      status: RequestStatus.accepted,
      orderId: order.id,
    );
    _requests[index] = accepted;
    return DemoResponse.json(accepted.toJson());
  }

  DemoResponse _rejectRequest(int id, Object? reason) {
    final text = reason is String ? reason.trim() : '';
    if (text.isEmpty || text.length > 240) {
      return DemoResponse.error(
        400,
        'El motivo es obligatorio (máx. 240 caracteres)',
      );
    }
    final index = _indexOfRequest(id);
    if (index < 0) return _notFound('Solicitud');
    final request = _requests[index];
    if (request.status != RequestStatus.pending) return _conflict();
    final rejected = request.copyWith(
      status: RequestStatus.rejected,
      rejectionReason: text,
    );
    _requests[index] = rejected;
    return DemoResponse.json(rejected.toJson());
  }

  DemoResponse _cancelRequest(int id) {
    final index = _indexOfRequest(id);
    if (index < 0) return _notFound('Solicitud');
    final request = _requests[index];
    if (request.status != RequestStatus.pending) return _conflict();
    final cancelled = request.copyWith(status: RequestStatus.cancelled);
    _requests[index] = cancelled;
    return DemoResponse.json(cancelled.toJson());
  }

  DemoResponse? _orderRoutes(DemoRequest r) {
    final company = r.match('GET', '/fuel-orders/company/:id');
    if (company != null) {
      return DemoResponse.json([
        for (final o in _orders)
          if (o.companyId == _idOf(company)) o.toJson(),
      ]);
    }
    final provider = r.match('GET', '/fuel-orders/provider/:id');
    if (provider != null) {
      return DemoResponse.json([
        for (final o in _orders)
          if (o.providerId == _idOf(provider)) o.toJson(),
      ]);
    }
    final detail = r.match('GET', '/fuel-orders/:id');
    if (detail != null) {
      final order = _firstWhere(_orders, (o) => o.id == _idOf(detail));
      return order == null
          ? _notFound('Orden')
          : DemoResponse.json(order.toJson());
    }
    final confirm = r.match('POST', '/fuel-orders/:id/confirm');
    if (confirm != null) {
      return _moveOrder(_idOf(confirm), [
        OrderStatus.pending,
      ], OrderStatus.pendingPayment);
    }
    final cancel = r.match('POST', '/fuel-orders/:id/cancel');
    if (cancel != null) {
      return _moveOrder(_idOf(cancel), [
        OrderStatus.pending,
        OrderStatus.confirmed,
      ], OrderStatus.cancelled);
    }
    return null;
  }

  DemoResponse _moveOrder(int id, List<String> from, String to) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) return _notFound('Orden');
    if (!from.contains(_orders[index].status)) return _conflict();
    final moved = _orders[index].copyWith(status: to);
    _orders[index] = moved;
    return DemoResponse.json(moved.toJson());
  }

  /// Catálogo que consume el contexto (`/tanks`, `/provider-companies`, `/fuel-products`).
  DemoResponse? _catalogRoutes(DemoRequest r) {
    if (r.match('GET', '/tanks') != null) {
      return DemoResponse.json([for (final t in seedTanks()) t.toJson()]);
    }
    if (r.match('GET', '/provider-companies') != null) {
      return DemoResponse.json([for (final p in seedProviders()) p.toJson()]);
    }
    if (r.match('GET', '/fuel-products') != null) {
      return DemoResponse.json([for (final p in seedProducts()) p.toJson()]);
    }
    final byProvider = r.match('GET', '/fuel-products/provider/:id');
    if (byProvider != null) {
      return DemoResponse.json([
        for (final p in seedProducts())
          if (p.providerId == _idOf(byProvider)) p.toJson(),
      ]);
    }
    if (r.match('POST', '/fuel-products/provider/:id/empty-catalog-alert') !=
        null) {
      return DemoResponse.empty();
    }
    return null;
  }

  int _indexOfRequest(int id) => _requests.indexWhere((q) => q.id == id);

  DemoResponse _notFound(String what) =>
      DemoResponse.error(404, '$what no encontrado (demo)');

  DemoResponse _conflict() =>
      DemoResponse.error(409, 'Estado no válido para esta acción (demo)');
}

int _idOf(Map<String, String> params) => int.tryParse(params['id'] ?? '') ?? 0;

int? _intOf(Object? value) => (value as num?)?.toInt();

double _money(double value) => double.parse(value.toStringAsFixed(2));

int _nextId(Iterable<int> ids, int min) {
  var next = min;
  for (final id in ids) {
    if (id >= next) next = id + 1;
  }
  return next;
}

T? _firstWhere<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
