import '../../iam/infrastructure/auth_interceptor.dart';
import '../../environments/environment.dart';
import '../../shared/infrastructure/base_api_endpoint.dart';
import '../domain/model/request_entity.dart';
import 'request_assembler.dart';
import 'requests_response.dart';

/// CRUD genérico sobre `/replenishment-requests`. Hoy ninguna vista lo usa: las pantallas llaman a `OrderingApi`.
class RequestsApiEndpoint
    extends
        BaseApiEndpoint<
          Request,
          RequestResource,
          RequestsResponse,
          RequestAssembler
        > {
  RequestsApiEndpoint(AppHttpClient http)
    : super(
        http,
        Environment.serverBasePath + Environment.orderingRequestsEndpointPath,
        RequestAssembler(),
      );
}
