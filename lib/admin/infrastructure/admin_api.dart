import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../ordering/infrastructure/ordering_api.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.roles,
    this.companyId,
    this.providerId,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: (json['id'] as num).toInt(),
    username: json['username'] as String,
    roles: [for (final r in (json['roles'] as List? ?? const [])) '$r'],
    companyId: (json['companyId'] as num?)?.toInt(),
    providerId: (json['providerId'] as num?)?.toInt(),
  );

  final int id;
  final String username;
  final List<String> roles;
  final int? companyId;
  final int? providerId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'roles': roles,
    'companyId': companyId,
    'providerId': providerId,
  };
}

class ApiMetric {
  const ApiMetric({
    required this.routeKey,
    required this.version,
    required this.handler,
    required this.count,
    required this.lastSeen,
    required this.distinctCallers,
  });

  factory ApiMetric.fromJson(Map<String, dynamic> json) => ApiMetric(
    routeKey: json['routeKey'] as String,
    version: json['version'] as String,
    handler: json['handler'] as String,
    count: (json['count'] as num).toInt(),
    lastSeen: json['lastSeen'] as String?,
    distinctCallers: (json['distinctCallers'] as num).toInt(),
  );

  final String routeKey;
  final String version;
  final String handler;
  final int count;
  final String? lastSeen;
  final int distinctCallers;

  Map<String, dynamic> toJson() => {
    'routeKey': routeKey,
    'version': version,
    'handler': handler,
    'count': count,
    'lastSeen': lastSeen,
    'distinctCallers': distinctCallers,
  };
}

class TransportEvidence {
  const TransportEvidence({required this.deliveryId, required this.samples});

  factory TransportEvidence.fromJson(Map<String, dynamic> json) =>
      TransportEvidence(
        deliveryId: (json['deliveryId'] as num).toInt(),
        samples: List<dynamic>.from(json['samples'] as List? ?? const []),
      );

  final int deliveryId;
  final List<dynamic> samples;

  Map<String, dynamic> toJson() => {
    'deliveryId': deliveryId,
    'samples': samples,
  };
}

/// Resultado de promover un usuario: `{ userId, username, roles }`.
class PromoteResult {
  const PromoteResult({
    required this.userId,
    required this.username,
    required this.roles,
  });

  factory PromoteResult.fromJson(Map<String, dynamic> json) => PromoteResult(
    userId: (json['userId'] as num).toInt(),
    username: json['username'] as String,
    roles: [for (final r in (json['roles'] as List? ?? const [])) '$r'],
  );

  final int userId;
  final String username;
  final List<String> roles;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'roles': roles,
  };
}

/// Servicio de administración para métricas de API, usuarios y evidencias de transporte.
class AdminApi extends ErrorHandlingEnabledBaseType {
  AdminApi(this._http);

  final AppHttpClient _http;
  static const _base = Environment.serverBasePath;

  Future<List<AdminUser>> users() async => [
    for (final e
        in (await execute(() => _http.getJson('$_base/users')) as List))
      AdminUser.fromJson(e as Map<String, dynamic>),
  ];

  Future<PromoteResult> promote(int userId) async => PromoteResult.fromJson(
    await execute(
      () => _http.postJson('$_base/admin/users/$userId/promote', {}),
    ) as Map<String, dynamic>,
  );

  Future<List<ApiMetric>> metrics(String version) async {
    final url =
        '$_base/admin/api-metrics?version=${Uri.encodeQueryComponent(version)}';
    return [
      for (final e in (await execute(() => _http.getJson(url)) as List))
        ApiMetric.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<List<Payment>> payments() async => [
    for (final e
        in (await execute(() => _http.getJson('$_base/payments')) as List))
      Payment.fromJson(e as Map<String, dynamic>),
  ];

  Future<TransportEvidence> exportEvidence(int deliveryId) async =>
      TransportEvidence.fromJson(
        await execute(
          () => _http.getJson(
            '$_base/admin/deliveries/$deliveryId/transport-evidence/export',
          ),
        ) as Map<String, dynamic>,
      );

  Future<void> deleteEvidence(int deliveryId) async {
    await execute(
      () => _http.deleteJson(
        '$_base/admin/deliveries/$deliveryId/transport-evidence',
      ),
    );
  }
}
