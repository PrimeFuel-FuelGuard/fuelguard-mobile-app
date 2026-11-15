import '../../../shared/infrastructure/demo/demo_world.dart';

Map<String, dynamic> _user(
  int id,
  String username,
  List<String> roles, {
  int? companyId,
  int? providerId,
}) => {
  'id': id,
  'username': username,
  'roles': roles,
  'companyId': companyId,
  'providerId': providerId,
};

Map<String, dynamic> _metric(
  String version,
  String routeKey,
  String handler,
  int count,
  String lastSeen,
  int callers,
) => {
  'routeKey': routeKey,
  'version': version,
  'handler': handler,
  'count': count,
  'lastSeen': lastSeen,
  'distinctCallers': callers,
};

Map<String, dynamic> _payment(
  int id,
  int orderId,
  int companyId,
  double amount,
  String status,
  String method, {
  String? reference,
  String? paidAt,
}) => {
  'id': id,
  'orderId': orderId,
  'companyId': companyId,
  'amount': amount,
  'status': status,
  'paymentMethod': method,
  'transactionReference': reference,
  'paidAt': paidAt,
};

Map<String, dynamic> _sample(String at, double lat, double lng, double speed) =>
    {'timestamp': at, 'latitude': lat, 'longitude': lng, 'speedKmh': speed};

/// Usuarios demo: los tres usuarios del mundo demo y cinco más.
List<Map<String, dynamic>> seedUsers() => [
  _user(DemoWorld.buyerUserId, DemoWorld.buyerUsername, [
    'ROLE_BUYER',
  ], companyId: DemoWorld.buyerCompanyId),
  _user(DemoWorld.providerUserId, DemoWorld.providerUsername, [
    'ROLE_PROVIDER',
  ], providerId: DemoWorld.providerId),
  _user(DemoWorld.adminUserId, DemoWorld.adminUsername, ['ROLE_ADMIN']),
  _user(4, 'jefe.operaciones@mineraandina.pe', [
    'ROLE_BUYER',
  ], companyId: DemoWorld.buyerCompanyId),
  _user(5, 'contacto@costaverde.pe', [
    'ROLE_BUYER',
  ], companyId: DemoWorld.buyer2CompanyId),
  _user(6, 'despacho@andesfuel.pe', [
    'ROLE_PROVIDER',
  ], providerId: DemoWorld.provider21Id),
  _user(7, 'ventas@grifosdelpacifico.pe', [
    'ROLE_PROVIDER',
  ], providerId: DemoWorld.provider22Id),
  _user(8, 'supervisor@petrosur.pe', [
    'ROLE_PROVIDER',
  ], providerId: DemoWorld.providerId),
];

/// Métricas de API por versión (`v1`, `v2`).
Map<String, List<Map<String, dynamic>>> seedMetrics() => {
  'v1': [
    _metric(
      'v1',
      'GET /fuel-products',
      'ProductController#getAll',
      1842,
      '2026-11-15T13:58:12Z',
      14,
    ),
    _metric(
      'v1',
      'GET /fuel-orders/{scope}/{id}',
      'OrderController#list',
      1210,
      '2026-11-15T13:41:03Z',
      9,
    ),
    _metric(
      'v1',
      'POST /replenishment-requests',
      'RequestController#create',
      212,
      '2026-11-15T11:20:45Z',
      6,
    ),
    _metric(
      'v1',
      'GET /me/notifications',
      'NotificationController#mine',
      1566,
      '2026-11-15T13:59:30Z',
      11,
    ),
    _metric(
      'v1',
      'GET /analytics/providers/{id}',
      'AnalyticsController#provider',
      402,
      '2026-11-15T12:05:18Z',
      4,
    ),
    _metric(
      'v1',
      'GET /payments',
      'PaymentController#list',
      318,
      '2026-11-14T22:17:09Z',
      3,
    ),
  ],
  'v2': [
    _metric(
      'v2',
      'GET /fuel-products',
      'ProductControllerV2#getAll',
      264,
      '2026-11-15T13:12:40Z',
      5,
    ),
    _metric(
      'v2',
      'GET /fuel-orders/{scope}/{id}',
      'OrderControllerV2#list',
      133,
      '2026-11-15T12:48:21Z',
      4,
    ),
    _metric(
      'v2',
      'GET /analytics/platform',
      'AnalyticsControllerV2#platform',
      27,
      '2026-11-14T18:30:55Z',
      1,
    ),
  ],
};

/// Pagos de la plataforma (BANK_TRANSFER, CREDIT_CARD, DEBIT_CARD y CASH).
List<Map<String, dynamic>> seedPayments() => [
  _payment(
    500,
    400,
    10,
    201600.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000481',
    paidAt: '2026-11-04T10:30:00Z',
  ),
  _payment(
    501,
    401,
    10,
    98700.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000493',
    paidAt: '2026-11-06T16:12:00Z',
  ),
  _payment(
    502,
    402,
    10,
    214560.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000312',
    paidAt: '2026-10-21T09:45:00Z',
  ),
  _payment(
    503,
    407,
    10,
    18200.00,
    'REFUNDED',
    'CREDIT_CARD',
    reference: 'TRX-2026-000577',
    paidAt: '2026-11-14T10:58:00Z',
  ),
  _payment(
    504,
    406,
    11,
    61920.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000566',
    paidAt: '2026-11-09T16:55:00Z',
  ),
  _payment(505, 408, 10, 47300.00, 'PENDING', 'BANK_TRANSFER'),
  _payment(
    506,
    409,
    11,
    58400.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000210',
    paidAt: '2026-10-18T11:20:00Z',
  ),
  _payment(
    507,
    410,
    10,
    96800.00,
    'FAILED',
    'CREDIT_CARD',
    reference: 'TRX-2026-000599',
  ),
  _payment(508, 411, 11, 12500.00, 'PENDING', 'DEBIT_CARD'),
  _payment(
    509,
    412,
    10,
    88200.00,
    'COMPLETED',
    'BANK_TRANSFER',
    reference: 'TRX-2026-000620',
    paidAt: '2026-11-12T08:02:00Z',
  ),
  _payment(510, 413, 11, 9800.00, 'PENDING', 'CASH'),
];

/// Evidencias de transporte por id de entrega (trazas GPS Arequipa – Mina Andina).
Map<int, List<Map<String, dynamic>>> seedEvidence() => {
  600: [
    _sample('2026-11-12T07:12:00Z', -16.4040, -71.5410, 0),
    _sample('2026-11-12T07:21:00Z', -16.4212, -71.5523, 35),
    _sample('2026-11-12T07:33:00Z', -16.4398, -71.5610, 48),
    _sample('2026-11-12T07:45:00Z', -16.4467, -71.5702, 22),
    _sample('2026-11-12T07:58:00Z', -16.4481, -71.5739, 0),
  ],
  601: [
    _sample('2026-11-13T08:02:00Z', -16.4040, -71.5410, 0),
    _sample('2026-11-13T08:17:00Z', -16.4305, -71.5588, 41),
    _sample('2026-11-13T08:31:00Z', -16.4481, -71.5739, 0),
  ],
  603: [
    _sample('2026-11-14T14:05:00Z', -16.4040, -71.5410, 0),
    _sample('2026-11-14T14:26:00Z', -16.4390, -71.5600, 52),
    _sample('2026-11-14T14:49:00Z', -16.4481, -71.5739, 0),
  ],
};
