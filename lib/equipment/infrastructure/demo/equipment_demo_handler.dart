import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';
import 'equipment_demo_state.dart';

const _fuelTypeByProduct = {
  100: 'DIESEL',
  101: 'GASOLINE_90',
  102: 'GASOLINE_95',
  103: 'GLP',
};

/// Datos demo de equipment: cuentas y sitios del comprador (`/customers`, `/tanks`) y la vista del
/// distribuidor (`/provider/...`). Los `/fuel-products*` y las empresas de iam los responden otros manejadores.
class EquipmentDemoHandler implements DemoHandler {
  final _state = EquipmentDemoState();

  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    final s = r.segments;
    if (s.isEmpty) return null;
    return switch (s.first) {
      'customers' => _customers(r),
      'tanks' => _buyerTanks(r),
      'provider-companies' => _providerCompanies(r),
      'provider' => _provider(r),
      _ => null,
    };
  }

  // ── Comprador ──

  DemoResponse? _customers(DemoRequest r) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 1) {
      return switch (method) {
        'GET' => DemoResponse.json([
          for (final c in _state.customers)
            if (c['legacyCompanyId'] == DemoWorld.buyerCompanyId) c,
        ]),
        'POST' => _createCustomer(r.json),
        _ => null,
      };
    }
    if (s.length == 3 && s[2] == 'sites') {
      final id = int.tryParse(s[1]);
      return switch (method) {
        'GET' => DemoResponse.json([
          for (final site in _state.sites)
            if (site['customerAccountId'] == id) site,
        ]),
        'POST' => _createSite(id, r.json),
        _ => null,
      };
    }
    return null;
  }

  DemoResponse _createCustomer(Map<String, dynamic> b) {
    final customer = <String, dynamic>{
      'id': _state.nextId(),
      'name': b['name'],
      'ruc': b['ruc'],
      'address': b['address'],
      'contactEmail': b['contactEmail'],
      'phone': b['phone'],
      'legacyCompanyId': b['legacyCompanyId'],
      'active': true,
    };
    _state.customers.add(customer);
    return DemoResponse.json(customer, 201);
  }

  DemoResponse _createSite(int? customerId, Map<String, dynamic> b) {
    if (_state.customerById(customerId ?? 0) == null) {
      return DemoResponse.error(404, 'Cuenta no encontrada (demo)');
    }
    final site = <String, dynamic>{
      'id': _state.nextId(),
      'customerAccountId': customerId,
      'name': b['name'],
      'address': b['address'],
      'active': true,
    };
    _state.sites.add(site);
    return DemoResponse.json(site, 201);
  }

  DemoResponse? _buyerTanks(DemoRequest r) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 1) {
      return switch (method) {
        'GET' => DemoResponse.json([
          for (final t in _state.tanks)
            if (t['customerAccountId'] == 1) _buyerView(t),
        ]),
        'POST' => _createBuyerTank(r.json),
        _ => null,
      };
    }
    final id = int.tryParse(s[1]);
    final tank = _state.tanks.where((t) => t['id'] == id).firstOrNull;
    if (id == null || tank == null) return _notFound('TANK_NOT_FOUND');
    final tail = s.skip(2).join('/');
    return switch ((method, tail)) {
      ('GET', '') => DemoResponse.json(_buyerView(tank)),
      ('GET', 'refill-policy') => _policyOf(tank),
      ('PUT', 'refill-policy') => _savePolicy(tank, r.json),
      ('GET', 'refill-episodes') => DemoResponse.json(
        _state.episodes[id] ?? const [],
      ),
      _ => null,
    };
  }

  Map<String, dynamic> _buyerView(Map<String, dynamic> t) => {
    'id': t['id'],
    'customerAccountId': t['customerAccountId'],
    'siteId': t['siteId'],
    'name': t['name'],
    'fuelType': t['fuelType'],
    'unit': t['unit'],
    'capacity': t['capacity'],
    'currentLevel': t['currentLevel'],
    'levelSource': t['levelSource'],
    'active': t['active'],
  };

  DemoResponse _createBuyerTank(Map<String, dynamic> b) {
    final id = _state.nextRowId(_state.tanks, DemoWorld.tankIdRange.$1);
    final capacity = (b['capacity'] as num).toDouble();
    final level = (b['initialLevel'] as num?)?.toDouble() ?? 0;
    if (level > capacity) {
      return DemoResponse.error(
        400,
        'El nivel inicial supera la capacidad (demo)',
      );
    }
    final tank = <String, dynamic>{
      'id': id,
      'customerAccountId': b['customerAccountId'],
      'siteId': b['siteId'],
      'name': b['name'],
      'fuelType': b['fuelType'],
      'fuelProductId': null,
      'unit': b['unit'] ?? 'LITERS',
      'capacity': capacity,
      'currentLevel': level,
      'levelSource': 'MANUAL',
      'lowLevelPercent': 20.0,
      'deviceId': null,
      'channel': null,
      'active': true,
      'policy': null,
    };
    _state.tanks.add(tank);
    _state.readings[id] = [_reading(id, 'MANUAL', 'manual', level, 0)];
    _state.episodes[id] = [];
    return DemoResponse.json(_buyerView(tank), 201);
  }

  DemoResponse _policyOf(Map<String, dynamic> tank) {
    final policy = tank['policy'];
    return policy == null
        ? DemoResponse(404, {
            'code': 'REFILL_POLICY_NOT_FOUND',
            'message': 'Sin política de reposición (demo)',
          })
        : DemoResponse.json(policy);
  }

  DemoResponse _savePolicy(Map<String, dynamic> tank, Map<String, dynamic> b) {
    final low = (b['lowLevelPercent'] as num?)?.toDouble();
    final hyst = (b['hysteresisPercent'] as num?)?.toDouble();
    final target = (b['targetLevelPercent'] as num?)?.toDouble();
    final auto = b['autoGenerateEnabled'] == true;
    final providerId = b['providerId'];
    final productId = b['fuelProductId'];
    if (low == null || low <= 0 || low >= 100) {
      return DemoResponse.error(400, 'Umbral bajo fuera de rango (demo)');
    }
    if (hyst == null || hyst <= 0 || low + hyst > 100) {
      return DemoResponse.error(400, 'Histéresis inválida (demo)');
    }
    if (target == null || target <= 0 || target > 100) {
      return DemoResponse.error(400, 'Objetivo fuera de rango (demo)');
    }
    if (auto && (providerId == null || productId == null)) {
      return DemoResponse.error(
        400,
        'La generación automática requiere proveedor y producto (demo)',
      );
    }
    final policy = <String, dynamic>{
      'lowLevelPercent': low,
      'hysteresisPercent': hyst,
      'targetLevelPercent': target,
      'providerId': providerId,
      'fuelProductId': productId,
      'autoGenerateEnabled': auto,
    };
    tank
      ..['policy'] = policy
      ..['lowLevelPercent'] = low
      ..['fuelProductId'] = productId;
    return DemoResponse.json(policy);
  }

  // ── Distribuidor ──

  DemoResponse? _providerCompanies(DemoRequest r) {
    if (r.segments.length != 1 || r.method.toUpperCase() != 'GET') return null;
    return DemoResponse.json([
      {'id': DemoWorld.providerId, 'name': DemoWorld.providerName},
      {'id': DemoWorld.provider21Id, 'name': DemoWorld.provider21Name},
      {'id': DemoWorld.provider22Id, 'name': DemoWorld.provider22Name},
    ]);
  }

  DemoResponse? _provider(DemoRequest r) {
    final s = r.segments;
    if (s.length < 2) return null;
    return switch (s[1]) {
      'buyer-companies' => _buyerCompanies(r),
      'tanks' => _providerTanks(r),
      _ => null,
    };
  }

  DemoResponse? _buyerCompanies(DemoRequest r) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 3 && s[2] == 'lookup' && method == 'GET') {
      return _lookup(r.query['ruc'] ?? '');
    }
    if (s.length != 2) return null;
    return switch (method) {
      'GET' => DemoResponse.json([
        for (final c in _state.companies)
          if (c['linked'] == true) _providerBuyerView(c),
      ]),
      'POST' => _registerBuyer(r.json),
      _ => null,
    };
  }

  DemoResponse _lookup(String ruc) {
    final company = _state.companies.where((c) => c['ruc'] == ruc).firstOrNull;
    if (company == null) return _notFound('BUYERCOMPANY_NOT_FOUND');
    return DemoResponse.json({
      'buyerCompanyId': company['id'],
      'name': company['name'],
      'ruc': company['ruc'],
    });
  }

  /// Vincula una empresa existente (`{buyerCompanyId}`) o crea una nueva con su cuenta y sitio.
  DemoResponse _registerBuyer(Map<String, dynamic> b) {
    final linkId = (b['buyerCompanyId'] as num?)?.toInt();
    if (linkId != null) {
      final company = _state.companyById(linkId);
      if (company == null) return _notFound('BUYERCOMPANY_NOT_FOUND');
      if (company['linked'] == true) {
        return DemoResponse(409, {
          'code': 'PROVIDERBUYERLINK_CONFLICT',
          'message': 'La empresa ya está vinculada (demo)',
        });
      }
      company['linked'] = true;
      return DemoResponse.json(_providerBuyerView(company), 201);
    }
    if (_state.companies.any((c) => c['ruc'] == b['ruc'])) {
      return DemoResponse(409, {
        'code': 'BUYERCOMPANY_CONFLICT',
        'message': 'Ya existe una empresa con ese RUC (demo)',
      });
    }
    final id = _state.nextRowId(_state.companies, 13);
    final customerId = _state.nextId();
    _state.customers.add({
      'id': customerId,
      'name': b['name'],
      'ruc': b['ruc'],
      'address': b['address'],
      'contactEmail': b['contactEmail'],
      'phone': b['phone'],
      'legacyCompanyId': id,
      'active': true,
    });
    _state.sites.add({
      'id': _state.nextId(),
      'customerAccountId': customerId,
      'name': b['siteName'] ?? b['name'],
      'address': b['address'] ?? '',
      'active': true,
    });
    final company = <String, dynamic>{
      'id': id,
      'name': b['name'],
      'ruc': b['ruc'],
      'sector': b['sector'] ?? '',
      'organizationId': id,
      'customerAccountId': customerId,
      'linked': true,
    };
    _state.companies.add(company);
    return DemoResponse.json(_providerBuyerView(company), 201);
  }

  Map<String, dynamic> _providerBuyerView(Map<String, dynamic> c) {
    final id = c['id'] as int;
    final owned = [
      for (final t in _state.tanks)
        if (_state.companyOf(t)?['id'] == id) t,
    ];
    final customerId = c['customerAccountId'];
    return {
      'id': id,
      'name': c['name'],
      'ruc': c['ruc'],
      'sector': c['sector'],
      'organizationId': c['organizationId'],
      'tankCount': owned.length,
      'criticalTankCount': owned.where(_isCritical).length,
      'activeOrderCount': id == DemoWorld.buyerCompanyId ? 1 : 0,
      'historicalOrderCount': id == DemoWorld.buyerCompanyId ? 6 : 2,
      'sites': [
        for (final site in _state.sites)
          if (site['customerAccountId'] == customerId)
            {
              'id': site['id'],
              'customerAccountId': customerId,
              'name': site['name'],
              'address': site['address'],
            },
      ],
    };
  }

  DemoResponse? _providerTanks(DemoRequest r) {
    final s = r.segments;
    final method = r.method.toUpperCase();
    if (s.length == 2) {
      return switch (method) {
        'GET' => _listProviderTanks(r.query['buyerCompanyId']),
        'POST' => _registerProviderTank(r.json),
        _ => null,
      };
    }
    final id = int.tryParse(s[2]);
    final tank = _state.tanks.where((t) => t['id'] == id).firstOrNull;
    if (id == null || tank == null || !_isLinked(tank)) {
      return _notFound('TANK_NOT_FOUND');
    }
    if (s.length == 3) {
      return switch (method) {
        'GET' => DemoResponse.json(_providerView(tank)),
        'PUT' => _updateProviderTank(tank, r.json),
        _ => null,
      };
    }
    if (s.length == 4 && method == 'GET') {
      return switch (s[3]) {
        'readings' => DemoResponse.json(_state.readings[id] ?? const []),
        'refill-episodes' => DemoResponse.json(_state.episodes[id] ?? const []),
        _ => null,
      };
    }
    return null;
  }

  bool _isLinked(Map<String, dynamic> tank) =>
      _state.companyOf(tank)?['linked'] == true;

  bool _isCritical(Map<String, dynamic> tank) =>
      _state.levelPercent(tank) <= (tank['lowLevelPercent'] as num);

  DemoResponse _listProviderTanks(String? buyerRaw) {
    final buyerId = int.tryParse(buyerRaw ?? '');
    return DemoResponse.json([
      for (final t in _state.tanks)
        if (_isLinked(t) &&
            (buyerId == null ||
                buyerId == 0 ||
                _state.companyOf(t)?['id'] == buyerId))
          _providerView(t),
    ]);
  }

  Map<String, dynamic> _providerView(Map<String, dynamic> t) {
    final company = _state.companyOf(t);
    final site = _state.siteById(t['siteId'] as int?);
    final latest = (_state.readings[t['id']] ?? const []).lastOrNull;
    final percent = _state.levelPercent(t);
    return {
      'id': t['id'],
      'buyerCompanyId': company?['id'],
      'organizationId': company?['organizationId'],
      'customerAccountId': t['customerAccountId'],
      'siteId': t['siteId'],
      'name': t['name'],
      'siteName': site?['name'],
      'deliveryAddress': site?['address'],
      'fuelType': t['fuelType'],
      'fuelProductId': t['fuelProductId'],
      'capacity': t['capacity'],
      'currentLevel': t['currentLevel'],
      'unit': t['unit'] == 'GALLONS' ? 'GALLON' : 'LITRE',
      'levelPercent': double.parse(percent.toStringAsFixed(2)),
      'lowLevelPercent': t['lowLevelPercent'],
      'critical': _isCritical(t),
      'levelObservedAt': latest?['capturedAt'],
      'levelSource': t['levelSource'],
      'devices': [
        if (t['deviceId'] != null)
          {
            'deviceId': t['deviceId'],
            'channel': t['channel'],
            'validFrom': _state.at(1, 8),
          },
      ],
    };
  }

  DemoResponse _registerProviderTank(Map<String, dynamic> b) {
    final company = _state.companyById((b['buyerCompanyId'] as num).toInt());
    if (company == null || company['linked'] != true) {
      return _notFound('BUYERCOMPANY_NOT_FOUND');
    }
    final productId = (b['fuelProductId'] as num).toInt();
    if (!EquipmentDemoState.providerProductIds.contains(productId)) {
      return _notFound('FUELPRODUCT_NOT_FOUND');
    }
    final device = b['deviceId'] as String;
    if (_state.isDeviceBound(device)) {
      return DemoResponse(409, {
        'code': 'DEVICEBINDING_CONFLICT',
        'message': 'El dispositivo ya está asociado a otro tanque (demo)',
      });
    }
    final id = _state.nextRowId(_state.tanks, DemoWorld.tankIdRange.$1);
    final capacity = (b['capacity'] as num).toDouble();
    final level = (b['initialLevel'] as num?)?.toDouble() ?? 0;
    if (level > capacity) {
      return DemoResponse.error(
        400,
        'El nivel inicial supera la capacidad (demo)',
      );
    }
    final tank = <String, dynamic>{
      'id': id,
      'customerAccountId': b['customerAccountId'],
      'siteId': b['siteId'],
      'name': b['name'],
      'fuelType': _fuelTypeByProduct[productId],
      'fuelProductId': productId,
      'unit': b['unit'] == 'GALLON' ? 'GALLONS' : 'LITERS',
      'capacity': capacity,
      'currentLevel': level,
      'levelSource': 'DEVICE',
      'lowLevelPercent': (b['lowLevelPercent'] as num).toDouble(),
      'deviceId': device,
      'channel': b['channel'],
      'active': true,
      'policy': null,
    };
    _state.tanks.add(tank);
    _state.readings[id] = [
      _reading(id, device, b['channel'] as String, level, 0),
    ];
    _state.episodes[id] = [];
    return DemoResponse.json(_providerView(tank), 201);
  }

  DemoResponse _updateProviderTank(
    Map<String, dynamic> tank,
    Map<String, dynamic> b,
  ) {
    final productId = (b['fuelProductId'] as num?)?.toInt();
    final device = b['deviceId'] as String?;
    if (productId != null &&
        !EquipmentDemoState.providerProductIds.contains(productId)) {
      return _notFound('FUELPRODUCT_NOT_FOUND');
    }
    if (device != null &&
        device != tank['deviceId'] &&
        _state.isDeviceBound(device)) {
      return DemoResponse(409, {
        'code': 'DEVICEBINDING_CONFLICT',
        'message': 'El dispositivo ya está asociado a otro tanque (demo)',
      });
    }
    if (productId != null) {
      tank['fuelProductId'] = productId;
      tank['fuelType'] = _fuelTypeByProduct[productId];
    }
    if (b['lowLevelPercent'] case final num low) {
      tank['lowLevelPercent'] = low.toDouble();
    }
    if (device != null) {
      tank
        ..['deviceId'] = device
        ..['channel'] = b['channel'];
    }
    final policy = tank['policy'] as Map<String, dynamic>?;
    if (policy != null) {
      policy
        ..['fuelProductId'] = tank['fuelProductId']
        ..['lowLevelPercent'] = tank['lowLevelPercent'];
      if (b['autoGenerateEnabled'] case final bool auto) {
        policy['autoGenerateEnabled'] = auto;
      }
    }
    return DemoResponse.json(_providerView(tank));
  }

  Map<String, dynamic> _reading(
    int tankId,
    String device,
    String channel,
    double level,
    int seq,
  ) => {
    'id': _state.nextId(),
    'tankId': tankId,
    'deviceId': device,
    'channel': channel,
    'sequence': seq,
    'level': level,
    'unit': 'LITRE',
    'capturedAt': DateTime.now().toUtc().toIso8601String(),
    'receivedAt': DateTime.now().toUtc().toIso8601String(),
    'quality': 'GOOD',
  };

  DemoResponse _notFound(String code) =>
      DemoResponse(404, {'code': code, 'message': 'No encontrado (demo)'});
}
