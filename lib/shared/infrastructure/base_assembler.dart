import '../domain/model/base_entity.dart';
import 'base_response.dart';

/// Contrato para transformar recursos del API en entidades de dominio y viceversa.
abstract class BaseAssembler<
  TEntity extends BaseEntity,
  TResource extends BaseResource,
  TResponse
> {
  /// JSON del API → recurso.
  TResource resourceFromJson(Map<String, dynamic> json);

  /// Recurso → entidad.
  TEntity toEntityFromResource(TResource resource);

  /// Entidad → recurso (POST/PUT).
  TResource toResourceFromEntity(TEntity entity);

  /// Respuesta envuelta → lista de entidades.
  List<TEntity> toEntitiesFromResponse(TResponse response);
}
