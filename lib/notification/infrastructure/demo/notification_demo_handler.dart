import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';

Map<String, dynamic> _n(
  int id,
  int userId,
  String type,
  String title,
  String message, {
  required bool read,
  required String at,
  int? ref,
}) => {
  'id': id,
  'userId': userId,
  'type': type,
  'title': title,
  'message': message,
  'read': read,
  'referenceId': ref,
  'createdAt': at,
};

/// Datos demo de notificaciones: diez por usuario (comprador y proveedor), con lectura mutable.
class NotificationDemoHandler implements DemoHandler {
  static final _buyer = DemoWorld.buyerUserId;
  static final _provider = DemoWorld.providerUserId;

  final List<Map<String, dynamic>> _items = [
    _n(
      900,
      _buyer,
      'ORDER_ACCEPTED',
      'Solicitud aceptada',
      'PetroSur Distribuciones aceptó tu solicitud #300 por 12 000 L de Diesel B5 S50.',
      read: true,
      ref: 300,
      at: '2026-11-03T13:10:00Z',
    ),
    _n(
      901,
      _buyer,
      'ORDER_CONFIRMED',
      'Pedido confirmado',
      'El pedido #400 fue confirmado y programado para el 12/11/2026.',
      read: true,
      ref: 400,
      at: '2026-11-03T16:02:00Z',
    ),
    _n(
      902,
      _buyer,
      'PAYMENT_COMPLETED',
      'Pago completado',
      'El pago #500 por S/ 201,600.00 del pedido #400 fue completado.',
      read: true,
      ref: 500,
      at: '2026-11-04T10:30:00Z',
    ),
    _n(
      903,
      _buyer,
      'DELIVERY_DISPATCHED',
      'Entrega en ruta',
      'La cisterna TTJ-812 salió de Arequipa con el pedido #400.',
      read: true,
      ref: 600,
      at: '2026-11-12T07:05:00Z',
    ),
    _n(
      904,
      _buyer,
      'ORDER_REJECTED',
      'Solicitud rechazada',
      'PetroSur no pudo atender la solicitud #305: capacidad de despacho insuficiente para esa fecha.',
      read: true,
      ref: 305,
      at: '2026-11-06T09:00:00Z',
    ),
    _n(
      905,
      _buyer,
      'DELIVERY_COMPLETED',
      'Entrega completada',
      'La entrega #601 fue registrada como completada en Av. Los Álamos 450.',
      read: false,
      ref: 601,
      at: '2026-11-13T18:20:00Z',
    ),
    _n(
      906,
      _buyer,
      'PAYMENT_REFUNDED',
      'Pago reembolsado',
      'Se reembolsó el pago #503 por S/ 18,200.00 tras cancelar el pedido #407.',
      read: false,
      ref: 503,
      at: '2026-11-14T11:00:00Z',
    ),
    _n(
      907,
      _buyer,
      'ORDER_CANCELLED',
      'Pedido cancelado',
      'El pedido #407 fue cancelado. Puedes crear una nueva solicitud desde el catálogo.',
      read: false,
      ref: 407,
      at: '2026-11-14T11:05:00Z',
    ),
    _n(
      908,
      _buyer,
      'GENERAL',
      'Stock bajo en Tanque Flota Volquetes',
      'El nivel del tanque 201 está en 18 %. Programa un reabastecimiento.',
      read: false,
      at: '2026-11-15T08:00:00Z',
    ),
    _n(
      909,
      _buyer,
      'REQUEST_PENDING',
      'Solicitud pendiente',
      'Tu solicitud #310 espera la respuesta de PetroSur Distribuciones.',
      read: false,
      ref: 310,
      at: '2026-11-15T09:15:00Z',
    ),
    _n(
      920,
      _provider,
      'NEW_REQUEST',
      'Nueva solicitud',
      'Minera Andina S.A.C. solicitó 12 000 L de Diesel B5 S50 para el 12/11/2026.',
      read: true,
      ref: 300,
      at: '2026-11-02T12:00:00Z',
    ),
    _n(
      921,
      _provider,
      'ORDER_CONFIRMED',
      'Pedido confirmado',
      'Confirmaste el pedido #400 de Minera Andina S.A.C.',
      read: true,
      ref: 400,
      at: '2026-11-03T16:00:00Z',
    ),
    _n(
      922,
      _provider,
      'PAYMENT_RECEIVED',
      'Pago recibido',
      'Minera Andina S.A.C. pagó S/ 201,600.00 del pedido #400.',
      read: true,
      ref: 500,
      at: '2026-11-04T10:31:00Z',
    ),
    _n(
      923,
      _provider,
      'DELIVERY_DISPATCHED',
      'Entrega despachada',
      'La cisterna TTJ-812 salió hacia Av. Los Álamos 450 con el pedido #400.',
      read: true,
      ref: 600,
      at: '2026-11-12T07:05:00Z',
    ),
    _n(
      924,
      _provider,
      'DELIVERY_COMPLETED',
      'Entrega completada',
      'La entrega #601 se completó con 9 800 L descargados.',
      read: false,
      ref: 601,
      at: '2026-11-13T18:21:00Z',
    ),
    _n(
      925,
      _provider,
      'DELIVERY_FAILED',
      'Entrega fallida',
      'La entrega #602 no pudo completarse: el cliente no tenía acceso al predio.',
      read: false,
      ref: 602,
      at: '2026-11-14T15:40:00Z',
    ),
    _n(
      926,
      _provider,
      'NEW_REQUEST',
      'Nueva solicitud',
      'Agroindustrial Costa Verde solicitó 8 000 L de Gasohol 95 para el 18/11/2026.',
      read: false,
      ref: 318,
      at: '2026-11-14T16:10:00Z',
    ),
    _n(
      927,
      _provider,
      'REQUEST_PENDING',
      'Solicitud pendiente',
      'Tienes 2 solicitudes pendientes en tu bandeja.',
      read: false,
      ref: 319,
      at: '2026-11-15T08:30:00Z',
    ),
    _n(
      928,
      _provider,
      'PAYMENT_RECEIVED',
      'Pago recibido',
      'Agroindustrial Costa Verde pagó S/ 61,920.00 del pedido #406.',
      read: true,
      ref: 504,
      at: '2026-11-09T17:00:00Z',
    ),
    _n(
      929,
      _provider,
      'GENERAL',
      'Catálogo actualizado',
      'El precio de Gasohol 95 se actualizó a S/ 17.10 por litro.',
      read: true,
      at: '2026-11-08T09:00:00Z',
    ),
  ];

  List<Map<String, dynamic>> _mine(int userId, {bool unreadOnly = false}) {
    final list = [
      for (final n in _items)
        if (n['userId'] == userId && (!unreadOnly || n['read'] == false)) n,
    ];
    list.sort(
      (a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String),
    );
    return list;
  }

  Map<String, dynamic>? _owned(int userId, String raw) {
    final id = int.tryParse(raw);
    for (final n in _items) {
      if (n['id'] == id && n['userId'] == userId) return n;
    }
    return null;
  }

  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    final isList = r.match('GET', '/me/notifications') != null;
    final isUnread = r.match('GET', '/me/notifications/unread') != null;
    final read = r.match('POST', '/me/notifications/:id/read');
    if (!isList && !isUnread && read == null) return null;

    final userId = r.userId;
    if (userId == null) return DemoResponse.error(401, 'Unauthorized');
    if (isList) return DemoResponse.json(_mine(userId));
    if (isUnread) return DemoResponse.json(_mine(userId, unreadOnly: true));

    final n = _owned(userId, read!['id']!);
    if (n == null) return DemoResponse.error(404, 'Notification not found');
    n['read'] = true;
    return DemoResponse.json(n);
  }
}
