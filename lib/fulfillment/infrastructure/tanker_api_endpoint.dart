import '../../iam/infrastructure/auth_interceptor.dart';
import '../../environments/environment.dart';
import '../../shared/infrastructure/base_api_endpoint.dart';
import '../domain/model/tanker_entity.dart';
import 'driver_response.dart';
import 'tanker_assembler.dart';
import 'tanker_response.dart';

class TankerApiEndpoint
    extends
        BaseApiEndpoint<
          Tanker,
          TankerResource,
          List<TankerResource>,
          TankerAssembler
        > {
  TankerApiEndpoint(AppHttpClient http)
    : super(http, '${Environment.serverBasePath}/tankers', TankerAssembler());

  Tanker _one(dynamic json) => assembler.toEntityFromResource(
    TankerResource.fromJson(json as Map<String, dynamic>),
  );

  Future<List<Tanker>> list([bool eligible = false]) async {
    final json = await execute(
      () => http.getJson('$endpointUrl${eligible ? '/eligible' : ''}'),
      operation: 'Failed to load tankers',
    );
    return [for (final row in (json as List)) _one(row)];
  }

  Future<Tanker> get(int id) async => _one(
    await execute(
      () => http.getJson('$endpointUrl/$id'),
      operation: 'Failed to load tanker $id',
    ),
  );

  /// [body] equivale a `Partial<Tanker>`: solo se envían las claves presentes.
  Future<Tanker> save(Map<String, dynamic> body, [int? id]) async {
    const keys = [
      'licensePlate',
      'brand',
      'model',
      'capacity',
      'unit',
      'status',
    ];
    final request = <String, dynamic>{
      for (final k in keys)
        if (body[k] != null) k: body[k],
    };
    final json = await execute(
      () => id != null && id != 0
          ? http.putJson('$endpointUrl/$id', request)
          : http.postJson(endpointUrl, request),
      operation: 'Failed to save tanker',
    );
    return _one(json);
  }

  Future<EligibilityResult> eligibility(int id) async =>
      EligibilityResult.fromJson(
        await execute(
          () => http.getJson('$endpointUrl/$id/eligibility'),
          operation: 'Failed to check tanker eligibility $id',
          localized: true,
        ) as Map<String, dynamic>,
      );

  Future<Tanker> setActive(int id, bool active) async => _one(
    await execute(
      () => http.postJson(
        '$endpointUrl/$id/${active ? 'activate' : 'deactivate'}',
        {},
      ),
      operation: 'Failed to ${active ? 'activate' : 'deactivate'} tanker $id',
    ),
  );
}
