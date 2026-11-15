import '../domain/model/base_entity.dart';
import 'base_assembler.dart';
import 'base_response.dart';
import 'error_handling_enabled_base_type.dart';
import '../../iam/infrastructure/auth_interceptor.dart';

/// Endpoint CRUD genérico. Cada contexto lo extiende pasando su assembler.
abstract class BaseApiEndpoint<
  TEntity extends BaseEntity,
  TResource extends BaseResource,
  TResponse,
  TAssembler extends BaseAssembler<TEntity, TResource, TResponse>
>
    extends ErrorHandlingEnabledBaseType {
  BaseApiEndpoint(this.http, this.endpointUrl, this.assembler);

  final AppHttpClient http;
  final String endpointUrl;
  final TAssembler assembler;

  TEntity _entity(dynamic json) => assembler.toEntityFromResource(
    assembler.resourceFromJson(json as Map<String, dynamic>),
  );

  Future<List<TEntity>> getAll() async {
    final json = await execute(
      () => http.getJson(endpointUrl),
      operation: 'Failed to fetch entities',
    );
    return [for (final item in (json as List)) _entity(item)];
  }

  Future<TEntity> getById(int id) async => _entity(
    await execute(
      () => http.getJson('$endpointUrl/$id'),
      operation: 'Failed to fetch entity with id $id',
    ),
  );

  Future<TEntity> create(TEntity entity) async {
    final resource = assembler.toResourceFromEntity(entity);
    return _entity(
      await execute(
        () => http.postJson(endpointUrl, resource.toJson()),
        operation: 'Failed to create entity',
      ),
    );
  }

  Future<TEntity> update(TEntity entity, int id) async {
    final resource = assembler.toResourceFromEntity(entity);
    return _entity(
      await execute(
        () => http.putJson('$endpointUrl/$id', resource.toJson()),
        operation: 'Failed to update entity with id $id',
      ),
    );
  }

  Future<void> delete(int id) async {
    await execute(
      () => http.deleteJson('$endpointUrl/$id'),
      operation: 'Failed to delete entity with id $id',
    );
  }
}
