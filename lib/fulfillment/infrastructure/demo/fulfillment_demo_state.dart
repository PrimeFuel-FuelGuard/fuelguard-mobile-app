import 'dart:math' as math;

import '../../../shared/infrastructure/demo/demo_world.dart';

/// Datos en memoria de fulfillment para el modo demo: cisternas 700–705, conductores 800–805 y
/// entregas 600–607 (ligadas a los pedidos 400–407). Las mutaciones persisten hasta cerrar la app.
class FulfillmentDemoState {
  FulfillmentDemoState() {
    _seedTankers();
    _seedDrivers();
    _seedDeliveries();
  }

  final List<Map<String, dynamic>> tankers = [];
  final List<Map<String, dynamic>> drivers = [];
  final List<Map<String, dynamic>> deliveries = [];
  final Map<int, Map<String, dynamic>> tracking = {};
  final Map<int, List<Map<String, dynamic>>> samples = {};
  final Map<int, List<Map<String, dynamic>>> transitions = {};
  final Map<int, List<Map<String, dynamic>>> valves = {};
  final Map<int, Map<String, dynamic>> geofences = {};
  int _sequence = 5000;

  static const _open = ['ASSIGNED', 'STARTED', 'ARRIVED', 'DELIVERING'];
  static const _terminal = ['COMPLETED', 'FAILED', 'CANCELLED'];

  /// Id nuevo para registros sin rango propio (transiciones, muestras, geocercas…).
  int nextRecordId() => ++_sequence;

  /// Siguiente id libre dentro de un rango que empieza en [min].
  int nextRowId(List<Map<String, dynamic>> rows, int min) =>
      rows.fold(min - 1, (m, row) => math.max(m, row['id'] as int)) + 1;

  bool isOpen(Map<String, dynamic> delivery) =>
      _open.contains(delivery['physicalState']);

  /// Avanza la entrega a [to] registrando la transición y la marca de tiempo correspondiente.
  void move(
    Map<String, dynamic> delivery,
    String to,
    String at, {
    double? deliveredVolume,
    String? reason,
  }) {
    final from = delivery['physicalState'] as String;
    final id = delivery['id'] as int;
    delivery
      ..['physicalState'] = to
      ..['status'] = to;
    const timeKeys = {
      'STARTED': 'startedAt',
      'ARRIVED': 'arrivedAt',
      'DELIVERING': 'deliveringAt',
      'COMPLETED': 'deliveredAt',
    };
    if (timeKeys[to] case final key?) delivery[key] = at;
    if (to == 'COMPLETED') delivery['deliveredVolume'] = deliveredVolume;
    if (reason != null) delivery['notes'] = reason;
    final log = transitions.putIfAbsent(id, () => []);
    log.add({
      'id': nextRecordId(),
      'occurredAt': at,
      'fromState': from,
      'toState': to,
      'aggregateVersion': log.length + 1,
    });
    if (_terminal.contains(to)) _release(delivery);
  }

  /// Ocupa conductor y cisterna de una entrega abierta.
  void occupy(Map<String, dynamic> delivery) {
    _setStatus(driverOf(delivery), 'AVAILABLE', 'ASSIGNED');
    _setStatus(tankerOf(delivery), 'AVAILABLE', 'IN_ROUTE');
  }

  /// Libera conductor y cisterna salvo que otra entrega abierta los siga usando.
  void _release(Map<String, dynamic> delivery) {
    final driverBusy = deliveries.any(
      (d) => isOpen(d) && d['driverId'] == delivery['driverId'],
    );
    final tankerBusy = deliveries.any(
      (d) => isOpen(d) && d['vehicleId'] == delivery['vehicleId'],
    );
    if (!driverBusy) _setStatus(driverOf(delivery), 'ASSIGNED', 'AVAILABLE');
    if (!tankerBusy) _setStatus(tankerOf(delivery), 'IN_ROUTE', 'AVAILABLE');
  }

  void _setStatus(Map<String, dynamic>? row, String from, String to) {
    if (row != null && row['status'] == from) row['status'] = to;
  }

  Map<String, dynamic>? driverOf(Map<String, dynamic> delivery) =>
      drivers.where((x) => x['id'] == delivery['driverId']).firstOrNull;

  Map<String, dynamic>? tankerOf(Map<String, dynamic> delivery) =>
      tankers.where((x) => x['id'] == delivery['vehicleId']).firstOrNull;

  void _seedTankers() {
    const rows = [
      (700, 'ABC-123', 'Volvo', 'FM 440', 9000, 'AVAILABLE'),
      (701, 'ABC-124', 'Scania', 'P 380', 10000, 'IN_ROUTE'),
      (702, 'ABC-125', 'Mercedes-Benz', 'Actros 2645', 12000, 'MAINTENANCE'),
      (703, 'ABC-126', 'Volvo', 'FMX 460', 9500, 'AVAILABLE'),
      (704, 'ABC-127', 'Hino', '500 FG', 9000, 'AVAILABLE'),
      (705, 'ABC-128', 'Scania', 'G 410', 12000, 'AVAILABLE'),
    ];
    for (final (id, plate, brand, model, capacity, status) in rows) {
      tankers.add({
        'id': id,
        'providerId': DemoWorld.providerId,
        'licensePlate': plate,
        'brand': brand,
        'model': model,
        'capacity': capacity,
        'unit': 'GALLONS',
        'status': status,
        'active': true,
      });
    }
  }

  void _seedDrivers() {
    const rows = [
      (800, 'Luis Alberto', 'Quispe Mamani', 'Q12345678', 'AVAILABLE'),
      (801, 'Carlos Enrique', 'Huanca Ccama', 'Q23456789', 'ASSIGNED'),
      (802, 'Miguel Ángel', 'Flores Condori', 'Q34567890', 'AVAILABLE'),
      (803, 'Rosa Elena', 'Mamani Turpo', 'Q45678901', 'SUSPENDED'),
      (804, 'Jorge Luis', 'Apaza Vilca', 'Q56789012', 'AVAILABLE'),
      (805, 'Ricardo', 'Villanueva Chávez', 'Q67890123', 'INACTIVE'),
    ];
    for (final (id, first, last, license, status) in rows) {
      final seq = (id - 799).toString().padLeft(3, '0');
      drivers.add({
        'id': id,
        'providerId': DemoWorld.providerId,
        'userId': null,
        'firstName': first,
        'lastName': last,
        'licenseNumber': license,
        'phoneNumber': '+51 954 123 $seq',
        'email': 'conductor$seq@petrosur.pe',
        'status': status,
        'active': status != 'INACTIVE',
      });
    }
  }

  void _seedDeliveries() {
    // (id, orderId, driverId, tankerId, estado objetivo)
    const rows = [
      (600, 400, 801, 701, 'ASSIGNED'),
      (601, 401, 800, 703, 'STARTED'),
      (602, 402, 802, 704, 'ARRIVED'),
      (603, 403, 800, 705, 'DELIVERING'),
      (604, 404, 804, 700, 'COMPLETED'),
      (605, 405, 802, 703, 'FAILED'),
      (606, 406, 804, 704, 'CANCELLED'),
      (607, 407, 800, 705, 'ASSIGNED'),
    ];
    for (final (id, orderId, driverId, tankerId, target) in rows) {
      final nextDay = id == 607;
      final day = nextDay ? '2026-11-16' : '2026-11-15';
      final buyer2 = nextDay;
      final delivery = <String, dynamic>{
        'id': id,
        'orderId': orderId,
        'status': 'ASSIGNED',
        'physicalState': 'ASSIGNED',
        'driverId': driverId,
        'vehicleId': tankerId,
        'scheduledDate': day,
        'windowStart': '${day}T${nextDay ? '09' : '08'}:00:00-05:00',
        'windowEnd': '${day}T${nextDay ? '13' : '12'}:00:00-05:00',
        'buyerCompanyId': buyer2
            ? DemoWorld.buyer2CompanyId
            : DemoWorld.buyerCompanyId,
        'buyerCompanyName': buyer2
            ? DemoWorld.buyer2CompanyName
            : DemoWorld.buyerCompanyName,
        'customerAccountId': buyer2
            ? DemoWorld.buyer2CompanyId
            : DemoWorld.buyerCompanyId,
        'siteId': 1,
        'deliveryAddress': buyer2
            ? DemoWorld.buyer2CompanyAddress
            : 'Mina Cerro Verde, Uchumayo, Arequipa',
        'requestedVolume': 6000.0,
        'unit': 'GALLONS',
        'deliveredVolume': null,
        'notes': null,
        'dispatchedAt': nextDay
            ? '2026-11-15T18:00:00-05:00'
            : '2026-11-15T06:30:00-05:00',
        'startedAt': null,
        'arrivedAt': null,
        'deliveringAt': null,
        'deliveredAt': null,
      };
      deliveries.add(delivery);
      _seedHistory(delivery, target);
      _seedTracking(id);
      if (isOpen(delivery)) occupy(delivery);
    }
    geofences[604] = {
      'id': nextRecordId(),
      'deliveryId': 604,
      'centerLatitude': -16.39,
      'centerLongitude': -71.53,
      'radiusMeters': 300.0,
    };
  }

  void _seedHistory(Map<String, dynamic> delivery, String target) {
    final id = delivery['id'] as int;
    if (target == 'FAILED' || target == 'CANCELLED') {
      move(
        delivery,
        target,
        '2026-11-15T07:40:00-05:00',
        reason: target == 'FAILED'
            ? 'Acceso bloqueado por obra'
            : 'Pedido cancelado por el comprador',
      );
      return;
    }
    const chain = ['STARTED', 'ARRIVED', 'DELIVERING', 'COMPLETED'];
    for (var i = 0; i < chain.length; i++) {
      if (chain.indexOf(target) < i) break;
      final at = '2026-11-15T${(7 + i).toString().padLeft(2, '0')}:20:00-05:00';
      move(
        delivery,
        chain[i],
        at,
        deliveredVolume: chain[i] == 'COMPLETED' ? 5950 : null,
      );
      if (chain[i] == 'ARRIVED' || chain[i] == 'DELIVERING') {
        valves.putIfAbsent(id, () => []).add({
          'id': nextRecordId(),
          'state': 'OPEN',
          'unauthorized': id == 603,
          'commandId': 'cmd-$id-${i + 1}',
          'recordedAt': at,
        });
      }
    }
    samples[id] = [
      for (var i = 0; i < 2; i++)
        {
          'evidenceId': nextRecordId(),
          'recordedAt': '2026-11-15T0${7 + i}:10:00-05:00',
          'kind': 'POSITION',
          'latitude': -16.39 - 0.01 * (id % 5) - 0.002 * i,
          'longitude': -71.53 - 0.01 * (id % 3) - 0.002 * i,
          'milestone': delivery['physicalState'],
          'volume': null,
          'unit': null,
        },
    ];
  }

  void _seedTracking(int id) {
    final last = samples[id];
    tracking[id] = {
      'deliveryId': id,
      'lastLatitude': -16.39 - 0.01 * (id % 5),
      'lastLongitude': -71.53 - 0.01 * (id % 3),
      'lastAccuracyMeters': 8.5,
      'lastPositionAt': last == null
          ? '2026-11-15T07:30:00-05:00'
          : last.last['recordedAt'],
      'loaded': id >= 601 && id <= 604,
      'lastLoadMilestone': id >= 601 ? 'LOADED' : null,
      'lastLoadVolume': id >= 601 ? 6000 : null,
      'lastLoadUnit': id >= 601 ? 'GALLONS' : null,
    };
  }
}
