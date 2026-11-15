double? _d(Object? v) => (v as num?)?.toDouble();
int? _i(Object? v) => (v as num?)?.toInt();

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.ruc,
    this.address,
    this.contactEmail,
    this.phone,
    this.legacyCompanyId,
    required this.active,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    ruc: json['ruc'] as String?,
    address: json['address'] as String?,
    contactEmail: json['contactEmail'] as String?,
    phone: json['phone'] as String?,
    legacyCompanyId: _i(json['legacyCompanyId']),
    active: json['active'] as bool,
  );

  final int id;
  final String name;
  final String? ruc;
  final String? address;
  final String? contactEmail;
  final String? phone;
  final int? legacyCompanyId;
  final bool active;

  /// Omite los campos opcionales nulos (equivale a `undefined` en JSON de TS).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (ruc != null) 'ruc': ruc,
    if (address != null) 'address': address,
    if (contactEmail != null) 'contactEmail': contactEmail,
    if (phone != null) 'phone': phone,
    if (legacyCompanyId != null) 'legacyCompanyId': legacyCompanyId,
    'active': active,
  };

  Customer copyWith({
    String? name,
    String? ruc,
    String? address,
    String? contactEmail,
    String? phone,
    int? legacyCompanyId,
    bool? active,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    ruc: ruc ?? this.ruc,
    address: address ?? this.address,
    contactEmail: contactEmail ?? this.contactEmail,
    phone: phone ?? this.phone,
    legacyCompanyId: legacyCompanyId ?? this.legacyCompanyId,
    active: active ?? this.active,
  );
}

class Site {
  const Site({
    required this.id,
    required this.customerAccountId,
    required this.name,
    this.address,
    required this.active,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: (json['id'] as num).toInt(),
    customerAccountId: (json['customerAccountId'] as num).toInt(),
    name: json['name'] as String,
    address: json['address'] as String?,
    active: json['active'] as bool,
  );

  final int id;
  final int customerAccountId;
  final String name;
  final String? address;
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerAccountId': customerAccountId,
    'name': name,
    if (address != null) 'address': address,
    'active': active,
  };
}

class Tank {
  const Tank({
    required this.id,
    required this.customerAccountId,
    required this.siteId,
    required this.name,
    this.fuelType,
    this.unit,
    required this.capacity,
    required this.currentLevel,
    required this.levelSource,
    required this.active,
  });

  factory Tank.fromJson(Map<String, dynamic> json) => Tank(
    id: (json['id'] as num).toInt(),
    customerAccountId: (json['customerAccountId'] as num).toInt(),
    siteId: _i(json['siteId']),
    name: json['name'] as String,
    fuelType: json['fuelType'] as String?,
    unit: json['unit'] as String?,
    capacity: (json['capacity'] as num).toDouble(),
    currentLevel: (json['currentLevel'] as num).toDouble(),
    levelSource: json['levelSource'] as String,
    active: json['active'] as bool,
  );

  final int id;
  final int customerAccountId;
  final int? siteId;
  final String name;
  final String? fuelType;
  final String? unit;
  final double capacity;
  final double currentLevel;
  final String levelSource;
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerAccountId': customerAccountId,
    'siteId': siteId,
    'name': name,
    if (fuelType != null) 'fuelType': fuelType,
    if (unit != null) 'unit': unit,
    'capacity': capacity,
    'currentLevel': currentLevel,
    'levelSource': levelSource,
    'active': active,
  };

  Tank copyWith({
    String? name,
    String? fuelType,
    String? unit,
    double? capacity,
    double? currentLevel,
    String? levelSource,
    bool? active,
  }) => Tank(
    id: id,
    customerAccountId: customerAccountId,
    siteId: siteId,
    name: name ?? this.name,
    fuelType: fuelType ?? this.fuelType,
    unit: unit ?? this.unit,
    capacity: capacity ?? this.capacity,
    currentLevel: currentLevel ?? this.currentLevel,
    levelSource: levelSource ?? this.levelSource,
    active: active ?? this.active,
  );
}

class RefillPolicy {
  const RefillPolicy({
    required this.lowLevelPercent,
    required this.hysteresisPercent,
    required this.targetLevelPercent,
    required this.providerId,
    required this.fuelProductId,
    required this.autoGenerateEnabled,
  });

  factory RefillPolicy.fromJson(Map<String, dynamic> json) => RefillPolicy(
    lowLevelPercent: (json['lowLevelPercent'] as num).toDouble(),
    hysteresisPercent: (json['hysteresisPercent'] as num).toDouble(),
    targetLevelPercent: (json['targetLevelPercent'] as num).toDouble(),
    providerId: _i(json['providerId']),
    fuelProductId: _i(json['fuelProductId']),
    autoGenerateEnabled: json['autoGenerateEnabled'] as bool,
  );

  final double lowLevelPercent;
  final double hysteresisPercent;
  final double targetLevelPercent;
  final int? providerId;
  final int? fuelProductId;
  final bool autoGenerateEnabled;

  Map<String, dynamic> toJson() => {
    'lowLevelPercent': lowLevelPercent,
    'hysteresisPercent': hysteresisPercent,
    'targetLevelPercent': targetLevelPercent,
    'providerId': providerId,
    'fuelProductId': fuelProductId,
    'autoGenerateEnabled': autoGenerateEnabled,
  };

  /// Los campos nulables no se pueden poner en `null` vía copyWith.
  RefillPolicy copyWith({
    double? lowLevelPercent,
    double? hysteresisPercent,
    double? targetLevelPercent,
    int? providerId,
    int? fuelProductId,
    bool? autoGenerateEnabled,
  }) => RefillPolicy(
    lowLevelPercent: lowLevelPercent ?? this.lowLevelPercent,
    hysteresisPercent: hysteresisPercent ?? this.hysteresisPercent,
    targetLevelPercent: targetLevelPercent ?? this.targetLevelPercent,
    providerId: providerId ?? this.providerId,
    fuelProductId: fuelProductId ?? this.fuelProductId,
    autoGenerateEnabled: autoGenerateEnabled ?? this.autoGenerateEnabled,
  );
}

class RefillEpisode {
  const RefillEpisode({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.openedLevelPercent,
    required this.openedLevel,
    required this.targetLevel,
    required this.requestedVolume,
    required this.unit,
    required this.requestEmitted,
    required this.requestId,
    required this.closedAt,
    this.episodeKey,
    this.tankId,
    this.organizationId,
    this.policyVersion,
    this.closedLevelPercent,
    this.version,
  });

  factory RefillEpisode.fromJson(Map<String, dynamic> json) => RefillEpisode(
    id: (json['id'] as num).toInt(),
    status: json['status'] as String,
    openedAt: json['openedAt'] as String,
    openedLevelPercent: (json['openedLevelPercent'] as num).toDouble(),
    openedLevel: (json['openedLevel'] as num).toDouble(),
    targetLevel: (json['targetLevel'] as num).toDouble(),
    requestedVolume: (json['requestedVolume'] as num).toDouble(),
    unit: json['unit'] as String,
    requestEmitted: json['requestEmitted'] as bool,
    requestId: _i(json['requestId']),
    closedAt: json['closedAt'] as String?,
    episodeKey: json['episodeKey'] as String?,
    tankId: _i(json['tankId']),
    organizationId: _i(json['organizationId']),
    policyVersion: _i(json['policyVersion']),
    closedLevelPercent: _d(json['closedLevelPercent']),
    version: _i(json['version']),
  );

  final int id;
  final String status;
  final String openedAt;
  final double openedLevelPercent;
  final double openedLevel;
  final double targetLevel;
  final double requestedVolume;
  final String unit;
  final bool requestEmitted;
  final int? requestId;
  final String? closedAt;
  final String? episodeKey;
  final int? tankId;
  final int? organizationId;
  final int? policyVersion;
  final double? closedLevelPercent;
  final int? version;

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'openedAt': openedAt,
    'openedLevelPercent': openedLevelPercent,
    'openedLevel': openedLevel,
    'targetLevel': targetLevel,
    'requestedVolume': requestedVolume,
    'unit': unit,
    'requestEmitted': requestEmitted,
    'requestId': requestId,
    'closedAt': closedAt,
    if (episodeKey != null) 'episodeKey': episodeKey,
    if (tankId != null) 'tankId': tankId,
    if (organizationId != null) 'organizationId': organizationId,
    if (policyVersion != null) 'policyVersion': policyVersion,
    if (closedLevelPercent != null) 'closedLevelPercent': closedLevelPercent,
    if (version != null) 'version': version,
  };
}

/// `{ id: number; name: string }` usado por varios endpoints de catálogo (proveedores, empresas).
class IdName {
  const IdName({required this.id, required this.name});

  factory IdName.fromJson(Map<String, dynamic> json) =>
      IdName(id: (json['id'] as num).toInt(), name: json['name'] as String);

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// `{ id: number; name: string; fuelType: string }` de `/fuel-products/provider/{id}` (vista de equipment).
class ProductRef {
  const ProductRef({
    required this.id,
    required this.name,
    required this.fuelType,
  });

  factory ProductRef.fromJson(Map<String, dynamic> json) => ProductRef(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    fuelType: json['fuelType'] as String,
  );

  final int id;
  final String name;
  final String fuelType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fuelType': fuelType,
  };
}
