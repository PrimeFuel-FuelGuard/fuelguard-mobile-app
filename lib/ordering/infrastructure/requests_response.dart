import '../../shared/infrastructure/base_response.dart';
import '../domain/model/request_entity.dart';

/// Una solicitud tal como llega de la API (igual que la entidad): envuelve la entidad sin transformarla.
class RequestResource implements BaseResource {
  const RequestResource(this.request);

  factory RequestResource.fromJson(Map<String, dynamic> json) =>
      RequestResource(Request.fromJson(json));

  final Request request;

  @override
  int get id => request.id;

  @override
  Map<String, dynamic> toJson() => request.toJson();
}

/// Respuesta de listado de solicitudes: un arreglo sin envoltorio.
typedef RequestsResponse = List<RequestResource>;
