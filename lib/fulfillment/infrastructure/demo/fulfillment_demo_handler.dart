import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';
import 'fulfillment_demo_state.dart';

typedef _Creator = Map<String, dynamic> Function(
  Map<String, dynamic> body,
  int id,
);

const _tankerFields = [
  'licensePlate',
  'brand',
  'model',
  'capacity',
  'unit',
  'status',
];
const _driverFields = [
  'userId',
  'firstName',
  'lastName',
  'licenseNumber',
  'phoneNumber',
  'email',
  'status',
];

/// Datos demo del contexto fulfillment: cisternas, conductores y entregas (`/tankers`, `/drivers`, `/deliveries`).
class FulfillmentDemoHandler implements DemoHandler {
  final _state = FulfillmentDemoState();

  @override
  Future<DemoResponse?> handle(DemoRequest r) async =>
      switch (r.segments.firstOrNull) {
        'tankers' => _resource(
          r,
          _state.tankers,
          DemoWorld.tankerIdRange.$1,
          _tankerFields,
          _newTanker,
        ),
        'drivers' => _resource(
          r,
          _state.drivers,
          DemoWorld.driverIdRange.$1,
          _driverFields,
          _newDriver,
        ),
        'deliveries' => _deliveries(r),
        _ => null,
      };

  /// CRUD + elegibilidad + activar/desactivar de cisternas y conductores.
  DemoResponse? _resource(
    DemoRequest r,
    List<Map<String, dynamic>> rows,
    int idMin,
    List<String> fields,
    _Creator create,
  ) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 1) {
      return switch (method) {
        'GET' => DemoResponse.json(rows),
        'POST' => _create(rows, idMin, r.json, create),
        _ => null,
      };
    }
    if (method == 'GET' && s[1] == 'eligible') {
      return DemoResponse.json(rows.where(_isEligible).toList());
    }
    final id = int.tryParse(s[1]);
    final row = rows.where((x) => x['id'] == id).firstOrNull;
    if (row == null) return DemoResponse.error(404, 'Not found (demo)');
    return switch ((method, s.length > 2 ? s[2] : '')) {
      ('GET', '') => DemoResponse.json(row),
      ('PUT', '') => DemoResponse.json(_update(row, r.json, fields)),
      ('GET', 'eligibility') => DemoResponse.json(_eligibility(row)),
      ('POST', 'activate') => DemoResponse.json(_setActive(row, true)),
      ('POST', 'deactivate') => DemoResponse.json(_setActive(row, false)),
      _ => null,
    };
  }

  DemoResponse _create(
    List<Map<String, dynamic>> rows,
    int idMin,
    Map<String, dynamic> body,
    _Creator create,
  ) {
    final row = create(body, _state.nextRowId(rows, idMin));
    rows.add(row);
    return DemoResponse.json(row, 201);
  }

  Map<String, dynamic> _update(
    Map<String, dynamic> row,
    Map<String, dynamic> body,
    List<String> fields,
  ) {
    for (final field in fields) {
      if (body.containsKey(field)) row[field] = body[field];
    }
    return row;
  }

  Map<String, dynamic> _setActive(Map<String, dynamic> row, bool active) {
    row['active'] = active;
    if (!active) {
      row['status'] = 'INACTIVE';
    } else if (row['status'] == 'INACTIVE') {
      row['status'] = 'AVAILABLE';
    }
    return row;
  }

  Map<String, dynamic> _eligibility(Map<String, dynamic> row) {
    final status = row['status'];
    final (outcome, reason) = switch (status) {
      _ when row['active'] != true => ('INELIGIBLE', 'Registro inactivo'),
      'AVAILABLE' => ('ELIGIBLE', 'Disponible para asignar'),
      'ASSIGNED' || 'IN_ROUTE' => ('BUSY', 'Ocupado en una entrega en curso'),
      _ => ('INELIGIBLE', 'Estado $status: no disponible'),
    };
    return {'outcome': outcome, 'reason': reason};
  }

  bool _isEligible(Map<String, dynamic> row) =>
      row['active'] == true && row['status'] == 'AVAILABLE';

  Map<String, dynamic> _newTanker(Map<String, dynamic> b, int id) => {
    'id': id,
    'providerId': DemoWorld.providerId,
    'licensePlate': b['licensePlate'],
    'brand': b['brand'],
    'model': b['model'],
    'capacity': b['capacity'],
    'unit': b['unit'],
    'status': b['status'],
    'active': true,
  };

  Map<String, dynamic> _newDriver(Map<String, dynamic> b, int id) => {
    'id': id,
    'providerId': DemoWorld.providerId,
    'userId': b['userId'],
    'firstName': b['firstName'],
    'lastName': b['lastName'],
    'licenseNumber': b['licenseNumber'],
    'phoneNumber': b['phoneNumber'],
    'email': b['email'],
    'status': b['status'],
    'active': true,
  };

  DemoResponse? _deliveries(DemoRequest r) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 1) {
      return switch (method) {
        'GET' => _list(r.query['date']),
        'POST' => _assign(r.json),
        _ => null,
      };
    }
    if (method == 'GET' && s[1] == 'recommendation') {
      return _recommendation(r.query);
    }
    final id = int.tryParse(s[1]);
    final delivery = _state.deliveries.where((x) => x['id'] == id).firstOrNull;
    if (id == null || delivery == null) {
      return DemoResponse.error(404, 'Not found (demo)');
    }
    final tail = s.skip(2).join('/');
    return switch ((method, tail)) {
      ('GET', '') => DemoResponse.json(_view(delivery)),
      ('GET', 'tracking') => DemoResponse.json(
        _state.tracking[id] ?? _emptyTracking(id),
      ),
      ('GET', 'tracking/samples') => DemoResponse.json(
        _state.samples[id] ?? const [],
      ),
      ('GET', 'transitions') => DemoResponse.json(
        _state.transitions[id] ?? const [],
      ),
      ('GET', 'timeline') => DemoResponse.json(_timeline(id)),
      ('GET', 'valve-observations') => DemoResponse.json(
        _state.valves[id] ?? const [],
      ),
      ('POST', 'geofence-policies') => _geofence(id, r.json),
      ('POST', 'start' || 'arrive' || 'complete' || 'fail' || 'cancel') =>
        _command(delivery, tail, r.json),
      _ => null,
    };
  }

  DemoResponse _list(String? date) => DemoResponse.json([
    for (final d in _state.deliveries)
      if (date == null || date.isEmpty || d['scheduledDate'] == date) _view(d),
  ]);

  /// Fila de entrega con `driver` y `tanker` anidados, como devuelve el backend.
  Map<String, dynamic> _view(Map<String, dynamic> d) {
    final driver = _state.driverOf(d);
    final tanker = _state.tankerOf(d);
    return {
      ...d,
      'driver': driver == null
          ? null
          : {
              'id': driver['id'],
              'firstName': driver['firstName'],
              'lastName': driver['lastName'],
            },
      'tanker': tanker == null
          ? null
          : {'id': tanker['id'], 'licensePlate': tanker['licensePlate']},
    };
  }

  Map<String, dynamic> _emptyTracking(int id) => {
    'deliveryId': id,
    'lastLatitude': null,
    'lastLongitude': null,
    'lastAccuracyMeters': null,
    'lastPositionAt': null,
    'loaded': false,
    'lastLoadMilestone': null,
    'lastLoadVolume': null,
    'lastLoadUnit': null,
  };

  List<Map<String, dynamic>> _timeline(int id) {
    final rows = [
      for (final t in _state.transitions[id] ?? const <Map<String, dynamic>>[])
        {
          'refId': 't-${t['id']}',
          'type': 'DELIVERY_STATE_CHANGED',
          'occurredAt': t['occurredAt'],
          'summary': 'Estado: ${t['toState']}',
        },
      for (final v in _state.valves[id] ?? const <Map<String, dynamic>>[])
        {
          'refId': 'v-${v['id']}',
          'type': 'VALVE_OBSERVATION',
          'occurredAt': v['recordedAt'],
          'summary': 'Válvula ${v['state']}',
        },
      for (final p in _state.samples[id] ?? const <Map<String, dynamic>>[])
        {
          'refId': 's-${p['evidenceId']}',
          'type': 'TRACKING_SAMPLE',
          'occurredAt': p['recordedAt'],
          'summary': 'Posición registrada',
        },
    ];
    return rows
      ..sort((a, b) => '${a['occurredAt']}'.compareTo('${b['occurredAt']}'));
  }

  DemoResponse _command(
    Map<String, dynamic> delivery,
    String action,
    Map<String, dynamic> body,
  ) {
    const moves = {
      'start': (['ASSIGNED'], 'STARTED'),
      'arrive': (['STARTED'], 'ARRIVED'),
      'complete': (['ARRIVED', 'DELIVERING'], 'COMPLETED'),
      'fail': (['ASSIGNED', 'STARTED', 'ARRIVED', 'DELIVERING'], 'FAILED'),
      'cancel': (['ASSIGNED', 'STARTED', 'ARRIVED', 'DELIVERING'], 'CANCELLED'),
    };
    final (from, to) = moves[action]!;
    final state = delivery['physicalState'];
    if (!from.contains(state)) {
      return DemoResponse.error(
        409,
        'Transición no permitida desde $state (demo)',
      );
    }
    final volume = (body['deliveredVolume'] as num?)?.toDouble();
    final reason = body['reason'] as String?;
    if (action == 'complete' && (volume == null || volume <= 0)) {
      return DemoResponse.error(
        400,
        'deliveredVolume debe ser mayor que 0 (demo)',
      );
    }
    if ((action == 'fail' || action == 'cancel') &&
        (reason == null || reason.trim().isEmpty)) {
      return DemoResponse.error(400, 'reason es obligatorio (demo)');
    }
    _state.move(
      delivery,
      to,
      DateTime.now().toUtc().toIso8601String(),
      deliveredVolume: volume,
      reason: reason,
    );
    return DemoResponse.json(_view(delivery));
  }

  DemoResponse _geofence(int id, Map<String, dynamic> body) {
    if (_state.geofences.containsKey(id)) {
      return DemoResponse.error(
        409,
        'Ya existe una política de geocerca (demo)',
      );
    }
    final policy = <String, dynamic>{
      'id': _state.nextRecordId(),
      'deliveryId': id,
      'centerLatitude': body['centerLatitude'],
      'centerLongitude': body['centerLongitude'],
      'radiusMeters': body['radiusMeters'],
    };
    _state.geofences[id] = policy;
    return DemoResponse.json(policy, 201);
  }

  /// Crea una entrega con el conductor y la cisterna elegidos (ambos deben estar disponibles).
  DemoResponse _assign(Map<String, dynamic> body) {
    final driver = _state.drivers
        .where((x) => x['id'] == body['driverId'])
        .firstOrNull;
    final tanker = _state.tankers
        .where((x) => x['id'] == body['tankerId'])
        .firstOrNull;
    if (driver == null || !_isEligible(driver)) {
      return DemoResponse.error(409, 'El conductor no está disponible (demo)');
    }
    if (tanker == null || !_isEligible(tanker)) {
      return DemoResponse.error(409, 'La cisterna no está disponible (demo)');
    }
    final id = _state.nextRowId(
      _state.deliveries,
      DemoWorld.deliveryIdRange.$1,
    );
    final delivery = <String, dynamic>{
      'id': id,
      'orderId': body['orderId'],
      'status': 'ASSIGNED',
      'physicalState': 'ASSIGNED',
      'driverId': driver['id'],
      'vehicleId': tanker['id'],
      'scheduledDate': body['scheduledDate'],
      'windowStart': body['windowStart'],
      'windowEnd': body['windowEnd'],
      'buyerCompanyId': DemoWorld.buyerCompanyId,
      'buyerCompanyName': DemoWorld.buyerCompanyName,
      'customerAccountId': DemoWorld.buyerCompanyId,
      'siteId': 1,
      'deliveryAddress': 'Mina Cerro Verde, Uchumayo, Arequipa',
      'requestedVolume': 6000.0,
      'unit': 'GALLONS',
      'deliveredVolume': null,
      'notes': null,
      'dispatchedAt': DateTime.now().toUtc().toIso8601String(),
      'startedAt': null,
      'arrivedAt': null,
      'deliveringAt': null,
      'deliveredAt': null,
    };
    _state.deliveries.add(delivery);
    _state.occupy(delivery);
    return DemoResponse.json({'deliveryId': id}, 201);
  }

  /// Cisterna más pequeña que cubre el volumen pedido (22 712 L) con conductor disponible.
  DemoResponse _recommendation(Map<String, String> q) {
    final orderId = int.tryParse(q['orderId'] ?? '');
    if (orderId == null) {
      return DemoResponse.error(400, 'orderId es obligatorio (demo)');
    }
    const requiredLitres = 22712.0;
    final driver = _state.drivers.where(_isEligible).firstOrNull;
    final tankers =
        _state.tankers
            .where((t) => _isEligible(t) && _litres(t) >= requiredLitres)
            .toList()
          ..sort((a, b) => _litres(a).compareTo(_litres(b)));
    final tanker = tankers.firstOrNull;
    final reason = driver == null
        ? 'NO_ELIGIBLE_DRIVER'
        : tanker == null
        ? 'NO_SUFFICIENT_ELIGIBLE_TANKER'
        : null;
    return DemoResponse.json({
      'orderId': orderId,
      'recommended': reason == null,
      'reason': reason,
      'driverId': driver?['id'],
      'driverName': driver == null
          ? null
          : '${driver['firstName']} ${driver['lastName']}',
      'tankerId': tanker?['id'],
      'licensePlate': tanker?['licensePlate'],
      'tankerCapacityLitres': tanker == null ? null : _litres(tanker),
      'requestedVolumeLitres': requiredLitres,
      'windowStart': q['windowStart'] ?? '2026-11-15T08:00:00-05:00',
      'windowEnd': q['windowEnd'] ?? '2026-11-15T12:00:00-05:00',
      'criterion': 'MIN_SUFFICIENT_CAPACITY',
    });
  }

  double _litres(Map<String, dynamic> tanker) {
    final capacity = (tanker['capacity'] as num).toDouble();
    return tanker['unit'] == 'GALLONS' ? capacity * 3.78541 : capacity;
  }
}
