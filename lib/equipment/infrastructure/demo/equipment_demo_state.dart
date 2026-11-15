import 'dart:math' as math;

import '../../../shared/infrastructure/demo/demo_world.dart';

/// Datos en memoria de equipment para el modo demo: cuentas, sitios, tanques 200–211 con sus
/// lecturas diarias (14 días de noviembre 2026), políticas y episodios de reposición.
class EquipmentDemoState {
  EquipmentDemoState() {
    _seedCompanies();
    _seedSitesAndTanks();
  }

  /// Cuentas internas de los compradores (`/customers`).
  final List<Map<String, dynamic>> customers = [];
  final List<Map<String, dynamic>> sites = [];

  /// Empresas compradoras de la plataforma; `linked` = vinculada al distribuidor demo.
  final List<Map<String, dynamic>> companies = [];
  final List<Map<String, dynamic>> tanks = [];
  final Map<int, List<Map<String, dynamic>>> episodes = {};
  final Map<int, List<Map<String, dynamic>>> readings = {};
  int _sequence = 900;

  static const providerProductIds = [100, 101, 102, 103];

  int nextId() => ++_sequence;

  /// Siguiente id libre dentro de un rango que empieza en [min] (tanques 200–219, etc.).
  int nextRowId(List<Map<String, dynamic>> rows, int min) =>
      rows.fold(min - 1, (m, row) => math.max(m, row['id'] as int)) + 1;

  bool isDeviceBound(String deviceId) =>
      tanks.any((t) => t['deviceId'] == deviceId);

  Map<String, dynamic>? companyById(int id) =>
      companies.where((c) => c['id'] == id).firstOrNull;

  Map<String, dynamic>? customerById(int id) =>
      customers.where((c) => c['id'] == id).firstOrNull;

  /// Empresa compradora dueña de una cuenta interna (legacyCompanyId).
  Map<String, dynamic>? companyOf(Map<String, dynamic> tank) {
    final customer = customerById(tank['customerAccountId'] as int);
    return companyById(customer?['legacyCompanyId'] as int? ?? 0);
  }

  Map<String, dynamic>? siteById(int? id) =>
      sites.where((s) => s['id'] == id).firstOrNull;

  /// Último nivel en porcentaje según la capacidad.
  double levelPercent(Map<String, dynamic> tank) {
    final capacity = (tank['capacity'] as num).toDouble();
    if (capacity <= 0) return 0;
    return (tank['currentLevel'] as num).toDouble() / capacity * 100;
  }

  /// Marca de tiempo de noviembre 2026 en hora de Lima.
  String at(int day, int hour, [int second = 0]) =>
      '2026-11-${day.toString().padLeft(2, '0')}T${hour.toString().padLeft(2, '0')}:00:${second.toString().padLeft(2, '0')}-05:00';

  void _seedCompanies() {
    customers.addAll([
      _customer(
        1,
        DemoWorld.buyerCompanyId,
        DemoWorld.buyerCompanyName,
        DemoWorld.buyerCompanyRuc,
        DemoWorld.buyerCompanyAddress,
      ),
      _customer(
        2,
        DemoWorld.buyer2CompanyId,
        DemoWorld.buyer2CompanyName,
        DemoWorld.buyer2CompanyRuc,
        DemoWorld.buyer2CompanyAddress,
      ),
      _customer(
        3,
        12,
        'Transportes Yura S.R.L.',
        '20444555666',
        'Av. Yura 900, Arequipa',
      ),
    ]);
    sites.addAll([
      _site(1, 1, 'Planta Cerro Verde', 'Mina Cerro Verde, Uchumayo, Arequipa'),
      _site(2, 1, 'Campamento Uchumayo', 'Km 4 carretera a Uchumayo, Arequipa'),
      _site(3, 2, 'Planta Ica', 'Km 12 Panamericana Sur, Ica'),
      _site(4, 3, 'Terminal Yura', 'Av. Yura 900, Arequipa'),
    ]);
    companies.addAll([
      _company(
        DemoWorld.buyerCompanyId,
        DemoWorld.buyerCompanyName,
        DemoWorld.buyerCompanyRuc,
        DemoWorld.buyerCompanySector,
        1,
        true,
      ),
      _company(
        DemoWorld.buyer2CompanyId,
        DemoWorld.buyer2CompanyName,
        DemoWorld.buyer2CompanyRuc,
        DemoWorld.buyer2CompanySector,
        2,
        true,
      ),
      _company(
        12,
        'Transportes Yura S.R.L.',
        '20444555666',
        'Transporte',
        3,
        false,
      ),
    ]);
  }

  void _seedSitesAndTanks() {
    _addTank(
      id: DemoWorld.tankMainId,
      customer: 1,
      site: 1,
      name: DemoWorld.tankMainName,
      capacity: DemoWorld.tankMainCapacity.toDouble(),
      percent: DemoWorld.tankMainLevelPercent.toDouble(),
      drift: 0.8,
      productId: DemoWorld.productDieselId,
      fuelType: 'DIESEL',
      low: 25,
      device: 'IOT-PLANTA-01',
      policy: {
        'hysteresisPercent': 10.0,
        'targetLevelPercent': 95.0,
        'auto': true,
      },
    );
    _addTank(
      id: DemoWorld.tankFleetId,
      customer: 1,
      site: 1,
      name: DemoWorld.tankFleetName,
      capacity: DemoWorld.tankFleetCapacity.toDouble(),
      percent: DemoWorld.tankFleetLevelPercent.toDouble(),
      drift: 2.5,
      productId: DemoWorld.productDieselId,
      fuelType: 'DIESEL',
      low: 20,
      device: 'IOT-FLOTA-02',
      policy: {
        'hysteresisPercent': 10.0,
        'targetLevelPercent': 100.0,
        'auto': true,
      },
    );
    _addTank(
      id: DemoWorld.tankCampId,
      customer: 1,
      site: 2,
      name: DemoWorld.tankCampName,
      capacity: DemoWorld.tankCampCapacity.toDouble(),
      percent: DemoWorld.tankCampLevelPercent.toDouble(),
      drift: -0.3,
      productId: DemoWorld.productDieselId,
      fuelType: 'DIESEL',
      low: 20,
      device: 'IOT-CAMP-03',
      policy: null,
    );
    _addTank(
      id: DemoWorld.tank2aId,
      customer: 2,
      site: 3,
      name: 'Tanque Almacén Ica',
      capacity: 15000,
      percent: 40,
      drift: 0.6,
      productId: DemoWorld.productGasohol90Id,
      fuelType: 'GASOLINE_90',
      low: 30,
      device: 'IOT-ICA-04',
      policy: {
        'hysteresisPercent': 5.0,
        'targetLevelPercent': 90.0,
        'auto': false,
      },
    );
    _addTank(
      id: DemoWorld.tank2bId,
      customer: 2,
      site: 3,
      name: 'Generador Ica',
      capacity: 8000,
      percent: 70,
      drift: 0.4,
      productId: DemoWorld.productDieselId,
      fuelType: 'DIESEL',
      low: 20,
      device: 'IOT-ICA-05',
      policy: null,
    );
    _seedEpisodes();
  }

  void _addTank({
    required int id,
    required int customer,
    required int site,
    required String name,
    required double capacity,
    required double percent,
    required double drift,
    required int productId,
    required String fuelType,
    required double low,
    required String device,
    required Map<String, Object>? policy,
  }) {
    final tank = <String, dynamic>{
      'id': id,
      'customerAccountId': customer,
      'siteId': site,
      'name': name,
      'fuelType': fuelType,
      'fuelProductId': productId,
      'unit': 'LITERS',
      'capacity': capacity,
      'currentLevel': capacity * percent / 100,
      'levelSource': 'DEVICE',
      'lowLevelPercent': low,
      'deviceId': device,
      'channel': 'level',
      'active': true,
      'policy': policy == null
          ? null
          : {
              'lowLevelPercent': low,
              'hysteresisPercent': policy['hysteresisPercent'],
              'targetLevelPercent': policy['targetLevelPercent'],
              'providerId': DemoWorld.providerId,
              'fuelProductId': productId,
              'autoGenerateEnabled': policy['auto'],
            },
    };
    tanks.add(tank);
    readings[id] = _history(id, capacity, percent, drift, device);
  }

  /// Catorce lecturas diarias (08:00 de Lima) del 1 al 14 de noviembre, terminando en el nivel actual.
  List<Map<String, dynamic>> _history(
    int tankId,
    double capacity,
    double percent,
    double drift,
    String device,
  ) => [
    for (var i = 0; i < 14; i++)
      {
        'id': tankId * 100 + i,
        'tankId': tankId,
        'deviceId': device,
        'channel': 'level',
        'sequence': i + 1,
        'level': capacity * _clamp(_pct(percent, drift, i)) / 100,
        'unit': 'LITRE',
        'capturedAt': at(i + 1, 8),
        'receivedAt': at(i + 1, 8, 5),
        'quality': 'GOOD',
      },
  ];

  double _pct(double end, double drift, int i) {
    if (i == 13) return end;
    return end + (13 - i) * drift + ((i * 5) % 7 - 3) * 0.6;
  }

  double _clamp(double v) => v < 0 ? 0 : (v > 100 ? 100 : v);

  void _seedEpisodes() {
    episodes[DemoWorld.tankMainId] = [
      {
        'id': 1,
        'status': 'CLOSED',
        'openedAt': at(10, 14),
        'openedLevelPercent': 24.0,
        'openedLevel': 4800.0,
        'targetLevel': 19000.0,
        'requestedVolume': 14200.0,
        'unit': 'LITRE',
        'requestEmitted': true,
        'requestId': 301,
        'closedAt': at(10, 18),
        'episodeKey': 'ep-200-1',
        'tankId': DemoWorld.tankMainId,
        'organizationId': DemoWorld.buyerOrganizationId,
        'policyVersion': 1,
        'closedLevelPercent': 95.0,
        'version': 2,
      },
    ];
    episodes[DemoWorld.tankFleetId] = [
      {
        'id': 2,
        'status': 'OPEN',
        'openedAt': at(14, 9),
        'openedLevelPercent': 18.0,
        'openedLevel': 1800.0,
        'targetLevel': 10000.0,
        'requestedVolume': 8200.0,
        'unit': 'LITRE',
        'requestEmitted': true,
        'requestId': 340,
        'closedAt': null,
        'episodeKey': 'ep-201-1',
        'tankId': DemoWorld.tankFleetId,
        'organizationId': DemoWorld.buyerOrganizationId,
        'policyVersion': 1,
        'closedLevelPercent': null,
        'version': 1,
      },
    ];
  }

  Map<String, dynamic> _customer(
    int id,
    int legacy,
    String name,
    String ruc,
    String address,
  ) => {
    'id': id,
    'name': name,
    'ruc': ruc,
    'address': address,
    'contactEmail': 'compras$id@demo.pe',
    'phone': '+51 54 200 0$id',
    'legacyCompanyId': legacy,
    'active': true,
  };

  Map<String, dynamic> _site(
    int id,
    int customer,
    String name,
    String address,
  ) => {
    'id': id,
    'customerAccountId': customer,
    'name': name,
    'address': address,
    'active': true,
  };

  Map<String, dynamic> _company(
    int id,
    String name,
    String ruc,
    String sector,
    int customer,
    bool linked,
  ) => {
    'id': id,
    'name': name,
    'ruc': ruc,
    'sector': sector,
    'organizationId': id,
    'customerAccountId': customer,
    'linked': linked,
  };
}
