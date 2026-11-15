import '../../shared/infrastructure/base_assembler.dart';
import '../domain/model/request_entity.dart';
import 'requests_response.dart';

/// Ensamblador identidad: el recurso de la API ya tiene la forma de la entidad `Request`, así que no transforma nada.
class RequestAssembler
    implements BaseAssembler<Request, RequestResource, RequestsResponse> {
  @override
  RequestResource resourceFromJson(Map<String, dynamic> json) =>
      RequestResource.fromJson(json);

  @override
  Request toEntityFromResource(RequestResource resource) => resource.request;

  @override
  RequestResource toResourceFromEntity(Request entity) =>
      RequestResource(entity);

  @override
  List<Request> toEntitiesFromResponse(RequestsResponse response) => [
    for (final r in response) r.request,
  ];
}
