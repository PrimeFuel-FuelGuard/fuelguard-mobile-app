import '../../iam/infrastructure/auth_interceptor.dart';
import '../../environments/environment.dart';
import '../../shared/infrastructure/base_api_endpoint.dart';
import '../domain/model/driver_entity.dart';
import 'driver_assembler.dart';
import 'driver_response.dart';

class DriverApiEndpoint
    extends
        BaseApiEndpoint<
          Driver,
          DriverResource,
          List<DriverResource>,
          DriverAssembler
        > {
  DriverApiEndpoint(AppHttpClient http)
    : super(http, '${Environment.serverBasePath}/drivers', DriverAssembler());

  Driver _one(dynamic json) => assembler.toEntityFromResource(
    DriverResource.fromJson(json as Map<String, dynamic>),
  );

  Future<List<Driver>> list([bool eligible = false]) async {
    final json = await execute(
      () => http.getJson('$endpointUrl${eligible ? '/eligible' : ''}'),
      operation: 'Failed to load drivers',
    );
    return [for (final row in (json as List)) _one(row)];
  }

  Future<Driver> get(int id) async => _one(
    await execute(
      () => http.getJson('$endpointUrl/$id'),
      operation: 'Failed to load driver $id',
    ),
  );

  /// [body] equivale a `Partial<Driver>`: solo se envían las claves presentes (salvo `userId`, siempre).
  Future<Driver> save(Map<String, dynamic> body, [int? id]) async {
    const keys = [
      'firstName',
      'lastName',
      'licenseNumber',
      'phoneNumber',
      'email',
      'status',
    ];
    final request = <String, dynamic>{
      'userId': body['userId'],
      for (final k in keys)
        if (body[k] != null) k: body[k],
    };
    final json = await execute(
      () => id != null && id != 0
          ? http.putJson('$endpointUrl/$id', request)
          : http.postJson(endpointUrl, request),
      operation: 'Failed to save driver',
    );
    return _one(json);
  }

  Future<Driver> setActive(int id, bool active) async => _one(
    await execute(
      () => http.postJson(
        '$endpointUrl/$id/${active ? 'activate' : 'deactivate'}',
        {},
      ),
      operation: 'Failed to update driver $id',
    ),
  );

  Future<EligibilityResult> eligibility(int id) async =>
      EligibilityResult.fromJson(
        await execute(
          () => http.getJson('$endpointUrl/$id/eligibility'),
          operation: 'Failed to check driver eligibility $id',
          localized: true,
        ) as Map<String, dynamic>,
      );
}
