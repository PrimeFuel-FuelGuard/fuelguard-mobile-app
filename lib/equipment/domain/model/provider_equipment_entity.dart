int? _i(Object? v) => (v as num?)?.toInt();

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final e in (v as List? ?? const [])) f(e as Map<String, dynamic>),
];

/// Unidad de capacidad del tanque del distribuidor.
abstract final class ProviderUnit {
  static const litre = 'LITRE';
  static const gallon = 'GALLON';
  static const values = [litre, gallon];
}

class ProviderSite {
  const ProviderSite({
    required this.id,
    required this.customerAccountId,
    required this.name,
    required this.address,
  });

  factory ProviderSite.fromJson(Map<String, dynamic> json) => ProviderSite(
    id: (json['id'] as num).toInt(),
    customerAccountId: (json['customerAccountId'] as num).toInt(),
    name: json['name'] as String,
    address: json['address'] as String?,
  );

  final int id;
  final int customerAccountId;
  final String name;
  final String? address;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerAccountId': customerAccountId,
    'name': name,
    'address': address,
  };
}

class ProviderBuyerCompany {
  const ProviderBuyerCompany({
    required this.id,
    required this.name,
    required this.ruc,
    required this.sector,
    required this.organizationId,
    required this.tankCount,
    required this.criticalTankCount,
    required this.activeOrderCount,
    required this.historicalOrderCount,
    required this.sites,
  });

  factory ProviderBuyerCompany.fromJson(Map<String, dynamic> json) =>
      ProviderBuyerCompany(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        ruc: json['ruc'] as String?,
        sector: json['sector'] as String?,
        organizationId: _i(json['organizationId']),
        tankCount: (json['tankCount'] as num).toInt(),
        criticalTankCount: (json['criticalTankCount'] as num).toInt(),
        activeOrderCount: (json['activeOrderCount'] as num).toInt(),
        historicalOrderCount: (json['historicalOrderCount'] as num).toInt(),
        sites: _list(json['sites'], ProviderSite.fromJson),
      );

  final int id;
  final String name;
  final String? ruc;
  final String? sector;
  final int? organizationId;
  final int tankCount;
  final int criticalTankCount;
  final int activeOrderCount;
  final int historicalOrderCount;
  final List<ProviderSite> sites;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ruc': ruc,
    'sector': sector,
    'organizationId': organizationId,
    'tankCount': tankCount,
    'criticalTankCount': criticalTankCount,
    'activeOrderCount': activeOrderCount,
    'historicalOrderCount': historicalOrderCount,
    'sites': [for (final s in sites) s.toJson()],
  };
}

class ProviderTankDevice {
  const ProviderTankDevice({
    required this.deviceId,
    required this.channel,
    required this.validFrom,
  });

  factory ProviderTankDevice.fromJson(Map<String, dynamic> json) =>
      ProviderTankDevice(
        deviceId: json['deviceId'] as String,
        channel: json['channel'] as String,
        validFrom: json['validFrom'] as String,
      );

  final String deviceId;
  final String channel;
  final String validFrom;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'channel': channel,
    'validFrom': validFrom,
  };
}

class ProviderTank {
  const ProviderTank({
    required this.id,
    required this.buyerCompanyId,
    required this.organizationId,
    required this.customerAccountId,
    required this.siteId,
    required this.name,
    required this.siteName,
    required this.deliveryAddress,
    required this.fuelType,
    required this.fuelProductId,
    required this.capacity,
    required this.currentLevel,
    required this.unit,
    required this.levelPercent,
    required this.lowLevelPercent,
    required this.critical,
    required this.levelObservedAt,
    required this.levelSource,
    required this.devices,
  });

  factory ProviderTank.fromJson(Map<String, dynamic> json) => ProviderTank(
    id: (json['id'] as num).toInt(),
    buyerCompanyId: (json['buyerCompanyId'] as num).toInt(),
    organizationId: (json['organizationId'] as num).toInt(),
    customerAccountId: (json['customerAccountId'] as num).toInt(),
    siteId: (json['siteId'] as num).toInt(),
    name: json['name'] as String,
    siteName: json['siteName'] as String?,
    deliveryAddress: json['deliveryAddress'] as String?,
    fuelType: json['fuelType'] as String,
    fuelProductId: _i(json['fuelProductId']),
    capacity: (json['capacity'] as num).toDouble(),
    currentLevel: (json['currentLevel'] as num).toDouble(),
    unit: json['unit'] as String,
    levelPercent: (json['levelPercent'] as num).toDouble(),
    lowLevelPercent: (json['lowLevelPercent'] as num).toDouble(),
    critical: json['critical'] as bool,
    levelObservedAt: json['levelObservedAt'] as String?,
    levelSource: json['levelSource'] as String,
    devices: _list(json['devices'], ProviderTankDevice.fromJson),
  );

  final int id;
  final int buyerCompanyId;
  final int organizationId;
  final int customerAccountId;
  final int siteId;
  final String name;
  final String? siteName;
  final String? deliveryAddress;
  final String fuelType;
  final int? fuelProductId;
  final double capacity;
  final double currentLevel;

  /// `ProviderUnit`.
  final String unit;
  final double levelPercent;
  final double lowLevelPercent;
  final bool critical;
  final String? levelObservedAt;
  final String levelSource;
  final List<ProviderTankDevice> devices;

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyerCompanyId': buyerCompanyId,
    'organizationId': organizationId,
    'customerAccountId': customerAccountId,
    'siteId': siteId,
    'name': name,
    'siteName': siteName,
    'deliveryAddress': deliveryAddress,
    'fuelType': fuelType,
    'fuelProductId': fuelProductId,
    'capacity': capacity,
    'currentLevel': currentLevel,
    'unit': unit,
    'levelPercent': levelPercent,
    'lowLevelPercent': lowLevelPercent,
    'critical': critical,
    'levelObservedAt': levelObservedAt,
    'levelSource': levelSource,
    'devices': [for (final d in devices) d.toJson()],
  };
}

class ProviderTankReading {
  const ProviderTankReading({
    required this.id,
    required this.tankId,
    required this.deviceId,
    required this.channel,
    required this.sequence,
    required this.level,
    required this.unit,
    required this.capturedAt,
    required this.receivedAt,
    required this.quality,
  });

  factory ProviderTankReading.fromJson(Map<String, dynamic> json) =>
      ProviderTankReading(
        id: (json['id'] as num).toInt(),
        tankId: (json['tankId'] as num).toInt(),
        deviceId: json['deviceId'] as String,
        channel: json['channel'] as String,
        sequence: (json['sequence'] as num).toInt(),
        level: (json['level'] as num).toDouble(),
        unit: json['unit'] as String,
        capturedAt: json['capturedAt'] as String,
        receivedAt: json['receivedAt'] as String,
        quality: json['quality'] as String,
      );

  final int id;
  final int tankId;
  final String deviceId;
  final String channel;
  final int sequence;
  final double level;
  final String unit;
  final String capturedAt;
  final String receivedAt;
  final String quality;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tankId': tankId,
    'deviceId': deviceId,
    'channel': channel,
    'sequence': sequence,
    'level': level,
    'unit': unit,
    'capturedAt': capturedAt,
    'receivedAt': receivedAt,
    'quality': quality,
  };
}

class BuyerLookup {
  const BuyerLookup({
    required this.buyerCompanyId,
    required this.name,
    required this.ruc,
  });

  factory BuyerLookup.fromJson(Map<String, dynamic> json) => BuyerLookup(
    buyerCompanyId: (json['buyerCompanyId'] as num).toInt(),
    name: json['name'] as String,
    ruc: json['ruc'] as String,
  );

  final int buyerCompanyId;
  final String name;
  final String ruc;

  Map<String, dynamic> toJson() => {
    'buyerCompanyId': buyerCompanyId,
    'name': name,
    'ruc': ruc,
  };
}

class NewBuyerCompany {
  const NewBuyerCompany({
    required this.name,
    required this.ruc,
    this.sector,
    this.address,
    this.contactEmail,
    this.phone,
    this.siteName,
  });

  factory NewBuyerCompany.fromJson(Map<String, dynamic> json) =>
      NewBuyerCompany(
        name: json['name'] as String,
        ruc: json['ruc'] as String,
        sector: json['sector'] as String?,
        address: json['address'] as String?,
        contactEmail: json['contactEmail'] as String?,
        phone: json['phone'] as String?,
        siteName: json['siteName'] as String?,
      );

  final String name;
  final String ruc;
  final String? sector;
  final String? address;
  final String? contactEmail;
  final String? phone;
  final String? siteName;

  /// Omite los opcionales nulos (como `undefined` en JSON).
  Map<String, dynamic> toJson() => {
    'name': name,
    'ruc': ruc,
    if (sector != null) 'sector': sector,
    if (address != null) 'address': address,
    if (contactEmail != null) 'contactEmail': contactEmail,
    if (phone != null) 'phone': phone,
    if (siteName != null) 'siteName': siteName,
  };
}

class NewProviderTank {
  const NewProviderTank({
    required this.buyerCompanyId,
    required this.customerAccountId,
    required this.siteId,
    required this.name,
    required this.fuelProductId,
    required this.capacity,
    required this.unit,
    this.initialLevel,
    required this.lowLevelPercent,
    required this.deviceId,
    required this.channel,
    this.autoGenerateEnabled,
  });

  factory NewProviderTank.fromJson(Map<String, dynamic> json) =>
      NewProviderTank(
        buyerCompanyId: (json['buyerCompanyId'] as num).toInt(),
        customerAccountId: (json['customerAccountId'] as num).toInt(),
        siteId: (json['siteId'] as num).toInt(),
        name: json['name'] as String,
        fuelProductId: (json['fuelProductId'] as num).toInt(),
        capacity: (json['capacity'] as num).toDouble(),
        unit: json['unit'] as String,
        initialLevel: (json['initialLevel'] as num?)?.toDouble(),
        lowLevelPercent: (json['lowLevelPercent'] as num).toDouble(),
        deviceId: json['deviceId'] as String,
        channel: json['channel'] as String,
        autoGenerateEnabled: json['autoGenerateEnabled'] as bool?,
      );

  final int buyerCompanyId;
  final int customerAccountId;
  final int siteId;
  final String name;
  final int fuelProductId;
  final double capacity;

  /// `ProviderUnit`.
  final String unit;
  final double? initialLevel;
  final double lowLevelPercent;
  final String deviceId;
  final String channel;
  final bool? autoGenerateEnabled;

  Map<String, dynamic> toJson() => {
    'buyerCompanyId': buyerCompanyId,
    'customerAccountId': customerAccountId,
    'siteId': siteId,
    'name': name,
    'fuelProductId': fuelProductId,
    'capacity': capacity,
    'unit': unit,
    if (initialLevel != null) 'initialLevel': initialLevel,
    'lowLevelPercent': lowLevelPercent,
    'deviceId': deviceId,
    'channel': channel,
    if (autoGenerateEnabled != null) 'autoGenerateEnabled': autoGenerateEnabled,
  };
}

/// `Partial<Pick<NewProviderTank, 'fuelProductId' | 'lowLevelPercent' | 'deviceId' | 'channel' | 'autoGenerateEnabled'>>`.
class ProviderTankUpdate {
  const ProviderTankUpdate({
    this.fuelProductId,
    this.lowLevelPercent,
    this.deviceId,
    this.channel,
    this.autoGenerateEnabled,
  });

  factory ProviderTankUpdate.fromJson(Map<String, dynamic> json) =>
      ProviderTankUpdate(
        fuelProductId: _i(json['fuelProductId']),
        lowLevelPercent: (json['lowLevelPercent'] as num?)?.toDouble(),
        deviceId: json['deviceId'] as String?,
        channel: json['channel'] as String?,
        autoGenerateEnabled: json['autoGenerateEnabled'] as bool?,
      );

  final int? fuelProductId;
  final double? lowLevelPercent;
  final String? deviceId;
  final String? channel;
  final bool? autoGenerateEnabled;

  Map<String, dynamic> toJson() => {
    if (fuelProductId != null) 'fuelProductId': fuelProductId,
    if (lowLevelPercent != null) 'lowLevelPercent': lowLevelPercent,
    if (deviceId != null) 'deviceId': deviceId,
    if (channel != null) 'channel': channel,
    if (autoGenerateEnabled != null) 'autoGenerateEnabled': autoGenerateEnabled,
  };
}
