import '../../environments/environment.dart';
import '../../equipment/domain/model/equipment_entity.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../inventory/domain/model/fuel_product_entity.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/order_entity.dart';
import '../domain/model/request_entity.dart';

/// Método de pago.
abstract final class PaymentMethod {
  static const bankTransfer = 'BANK_TRANSFER';
  static const creditCard = 'CREDIT_CARD';
  static const debitCard = 'DEBIT_CARD';
  static const cash = 'CASH';
  static const values = [bankTransfer, creditCard, debitCard, cash];
}

/// Estado de un pago.
abstract final class PaymentStatus {
  static const pending = 'PENDING';
  static const completed = 'COMPLETED';
  static const failed = 'FAILED';
  static const refunded = 'REFUNDED';
  static const values = [pending, completed, failed, refunded];
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.companyId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.transactionReference,
    required this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: (json['id'] as num).toInt(),
    orderId: (json['orderId'] as num).toInt(),
    companyId: (json['companyId'] as num).toInt(),
    amount: (json['amount'] as num).toDouble(),
    status: json['status'] as String,
    paymentMethod: json['paymentMethod'] as String,
    transactionReference: json['transactionReference'] as String?,
    paidAt: json['paidAt'] as String?,
  );

  final int id;
  final int orderId;
  final int companyId;
  final double amount;
  final String status;

  /// `PaymentMethod`.
  final String paymentMethod;
  final String? transactionReference;
  final String? paidAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'companyId': companyId,
    'amount': amount,
    'status': status,
    'paymentMethod': paymentMethod,
    'transactionReference': transactionReference,
    'paidAt': paidAt,
  };

  Payment copyWith({
    String? status,
    String? paymentMethod,
    String? transactionReference,
    String? paidAt,
  }) => Payment(
    id: id,
    orderId: orderId,
    companyId: companyId,
    amount: amount,
    status: status ?? this.status,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    transactionReference: transactionReference ?? this.transactionReference,
    paidAt: paidAt ?? this.paidAt,
  );
}

/// Ítem de GET /payments/provider/{id}. `currency` llega siempre null; `paidAt` es LocalDateTime sin zona.
class ProviderPayment {
  const ProviderPayment({
    required this.id,
    required this.orderId,
    required this.buyerCompanyId,
    required this.buyerName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAt,
  });

  factory ProviderPayment.fromJson(Map<String, dynamic> json) =>
      ProviderPayment(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num).toInt(),
        buyerCompanyId: (json['buyerCompanyId'] as num).toInt(),
        buyerName: json['buyerName'] as String?,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String?,
        status: json['status'] as String,
        paymentMethod: json['paymentMethod'] as String,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        paidAt: json['paidAt'] as String?,
      );

  final int id;
  final int orderId;
  final int buyerCompanyId;
  final String? buyerName;
  final double amount;
  final String? currency;

  /// `PaymentStatus`.
  final String status;

  /// `PaymentMethod`.
  final String paymentMethod;
  final String createdAt;
  final String updatedAt;
  final String? paidAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'buyerCompanyId': buyerCompanyId,
    'buyerName': buyerName,
    'amount': amount,
    'currency': currency,
    'status': status,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'paidAt': paidAt,
  };
}

/// Cliente HTTP del contexto de pedidos: solicitudes, órdenes, pagos y consultas de catálogo.
class OrderingApi extends ErrorHandlingEnabledBaseType {
  OrderingApi(this._http);

  final AppHttpClient _http;
  static const _base = Environment.serverBasePath;

  Future<List<T>> _list<T>(
    String url,
    T Function(Map<String, dynamic>) f, {
    String? operation,
    bool localized = false,
  }) async => [
    for (final e in (await execute(
      () => _http.getJson(url),
      operation: operation,
      localized: localized,
    )) as List)
      f(e as Map<String, dynamic>),
  ];

  Future<Request> _request(Future<dynamic> call) async =>
      Request.fromJson(await call as Map<String, dynamic>);

  /// Solicitudes visibles para el usuario actual (vista del comprador).
  Future<List<Request>> requests() =>
      _list('$_base/replenishment-requests', Request.fromJson);

  /// Bandeja de solicitudes del distribuidor.
  Future<List<Request>> requestInbox() =>
      _list('$_base/replenishment-requests/inbox', Request.fromJson);

  Future<Request> request(int id) => _request(
    execute(() => _http.getJson('$_base/replenishment-requests/$id')),
  );

  Future<Request> createRequest(CreateRequest payload) => _request(
    execute(
      () => _http.postJson('$_base/replenishment-requests', {
        ...payload.toJson(),
        'source': 'MANUAL',
      }),
    ),
  );

  /// El distribuidor acepta una solicitud pendiente (POST sin cuerpo).
  Future<Request> acceptRequest(int id) => _request(
    execute(
      () => _http.postJson('$_base/replenishment-requests/$id/accept', {}),
    ),
  );

  /// El distribuidor rechaza una solicitud pendiente y envía el motivo en el cuerpo.
  Future<Request> rejectRequest(int id, String reason) => _request(
    execute(
      () => _http.postJson('$_base/replenishment-requests/$id/reject', {
        'reason': reason,
      }),
    ),
  );

  Future<Request> cancelRequest(int id) => _request(
    execute(
      () => _http.postJson('$_base/replenishment-requests/$id/cancel', {}),
    ),
  );

  Future<List<Order>> orders(String path, int id) =>
      _list('$_base/fuel-orders/$path/$id', Order.fromJson);

  Future<Order> order(int id) async => Order.fromJson(
    await execute(() => _http.getJson('$_base/fuel-orders/$id'))
        as Map<String, dynamic>,
  );

  Future<Order> confirmOrder(int id) async => Order.fromJson(
    await execute(() => _http.postJson('$_base/fuel-orders/$id/confirm', {}))
        as Map<String, dynamic>,
  );

  Future<Order> cancelOrder(int id) async => Order.fromJson(
    await execute(() => _http.postJson('$_base/fuel-orders/$id/cancel', {}))
        as Map<String, dynamic>,
  );

  Future<List<Payment>> paymentsForCompany(int companyId) => _list(
    '$_base/payments/company/$companyId',
    Payment.fromJson,
    operation: 'paymentsForCompany',
    localized: true,
  );

  Future<Payment> refundPayment(int id) async => Payment.fromJson(
    await execute(
      () => _http.postJson('$_base/payments/$id/refund', null),
      operation: 'refundPayment',
      localized: true,
    ) as Map<String, dynamic>,
  );

  Future<Payment> refundProviderPayment(int id) async => Payment.fromJson(
    await execute(() => _http.postJson('$_base/payments/$id/refund', null))
        as Map<String, dynamic>,
  );

  Future<List<ProviderPayment>> providerPayments(
    int providerId, {
    String? status,
    String? from,
    String? to,
  }) {
    final query = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final url = Uri.parse('$_base/payments/provider/$providerId')
        .replace(queryParameters: query.isEmpty ? null : query)
        .toString();
    return _list(url, ProviderPayment.fromJson);
  }

  Future<Payment> paymentForOrder(int orderId) async => Payment.fromJson(
    await execute(() => _http.getJson('$_base/payments/order/$orderId'))
        as Map<String, dynamic>,
  );

  Future<Payment> createPayment(
    int orderId,
    int companyId,
    double amount,
    String paymentMethod,
  ) async => Payment.fromJson(
    await execute(
      () => _http.postJson('$_base/payments', {
        'orderId': orderId,
        'companyId': companyId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      }),
    ) as Map<String, dynamic>,
  );

  Future<Payment> completePayment(int id, String transactionReference) async =>
      Payment.fromJson(
        await execute(
          () => _http.postJson('$_base/payments/$id/complete', {
            'transactionReference': transactionReference,
          }),
        ) as Map<String, dynamic>,
      );

  Future<List<Tank>> tanks() => _list('$_base/tanks', Tank.fromJson);

  Future<List<IdName>> providers() =>
      _list('$_base/provider-companies', IdName.fromJson);

  Future<IdName> provider(int id) async => IdName.fromJson(
    await execute(() => _http.getJson('$_base/provider-companies/$id'))
        as Map<String, dynamic>,
  );

  Future<IdName> buyerCompany(int id) async => IdName.fromJson(
    await execute(() => _http.getJson('$_base/buyer-companies/$id'))
        as Map<String, dynamic>,
  );

  Future<List<FuelProduct>> allProducts() =>
      _list('$_base/fuel-products', FuelProduct.fromJson);

  Future<List<FuelProduct>> products(int providerId) =>
      _list('$_base/fuel-products/provider/$providerId', FuelProduct.fromJson);

  Future<void> alertEmptyCatalog(int providerId) async {
    await execute(
      () => _http.postJson(
        '$_base/fuel-products/provider/$providerId/empty-catalog-alert',
        {},
      ),
    );
  }
}
