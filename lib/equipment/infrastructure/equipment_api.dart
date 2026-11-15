import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/equipment_entity.dart';

/// Cuerpo de `POST /tanks` (tipo inline en TS).
class CreateTankRequest {
  const CreateTankRequest({
    required this.customerAccountId,
    required this.siteId,
    required this.name,
    required this.fuelType,
    required this.capacity,
    required this.unit,
    required this.initialLevel,
  });

  final int customerAccountId;
  final int? siteId;
  final String name;
  final String fuelType;
  final double capacity;
  final String unit;
  final double initialLevel;

  Map<String, dynamic> toJson() => {
    'customerAccountId': customerAccountId,
    'siteId': siteId,
    'name': name,
    'fuelType': fuelType,
    'capacity': capacity,
    'unit': unit,
    'initialLevel': initialLevel,
  };
}

class EquipmentApi extends ErrorHandlingEnabledBaseType {
  EquipmentApi(this._http);

  final AppHttpClient _http;
  static const _base = Environment.serverBasePath;

  Future<List<T>> _list<T>(
    String url,
    T Function(Map<String, dynamic>) f,
  ) async => [
    for (final e in (await execute(() => _http.getJson(url)) as List))
      f(e as Map<String, dynamic>),
  ];

  Future<List<Customer>> customers() =>
      _list('$_base/customers', Customer.fromJson);

  /// [value] equivale a `Partial<Customer>`: solo se envían las claves presentes.
  Future<Customer> createCustomer(Map<String, dynamic> value) async =>
      Customer.fromJson(
        await execute(() => _http.postJson('$_base/customers', value))
            as Map<String, dynamic>,
      );

  Future<List<Site>> sites(int customerId) =>
      _list('$_base/customers/$customerId/sites', Site.fromJson);

  Future<Site> createSite(
    int customerId, {
    required String name,
    String? address,
  }) async => Site.fromJson(
    await execute(
      () => _http.postJson('$_base/customers/$customerId/sites', {
        'name': name,
        'address': ?address,
      }),
    ) as Map<String, dynamic>,
  );

  Future<List<Tank>> tanks() => _list('$_base/tanks', Tank.fromJson);

  Future<Tank> createTank(CreateTankRequest value) async => Tank.fromJson(
    await execute(() => _http.postJson('$_base/tanks', value.toJson()))
        as Map<String, dynamic>,
  );

  Future<Tank> tank(int id) async => Tank.fromJson(
    await execute(() => _http.getJson('$_base/tanks/$id'))
        as Map<String, dynamic>,
  );

  Future<RefillPolicy> policy(int id) async => RefillPolicy.fromJson(
    await execute(() => _http.getJson('$_base/tanks/$id/refill-policy'))
        as Map<String, dynamic>,
  );

  Future<RefillPolicy> savePolicy(int id, RefillPolicy value) async =>
      RefillPolicy.fromJson(
        await execute(
          () => _http.putJson('$_base/tanks/$id/refill-policy', value.toJson()),
        ) as Map<String, dynamic>,
      );

  Future<List<IdName>> providers() =>
      _list('$_base/provider-companies', IdName.fromJson);

  Future<List<ProductRef>> products(int providerId) =>
      _list('$_base/fuel-products/provider/$providerId', ProductRef.fromJson);

  Future<List<RefillEpisode>> episodes(int id) =>
      _list('$_base/tanks/$id/refill-episodes', RefillEpisode.fromJson);
}

/// Mensaje del backend (`{code, message}`) o clave i18n si el cuerpo viene vacío (403/404/401 manuales).
String apiError(Object? e) {
  final body = e is ApiException ? e.body : null;
  return (body?['message'] ?? body?['code'] ?? 'equipment.request-failed')
      .toString();
}
