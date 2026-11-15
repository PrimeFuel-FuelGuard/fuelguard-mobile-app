import '../../iam/infrastructure/auth_interceptor.dart';
import '../../environments/environment.dart';
import '../../shared/infrastructure/base_api_endpoint.dart';
import '../domain/model/order_entity.dart';
import 'order_assembler.dart';
import 'orders_response.dart';

/// CRUD genérico sobre `/fuel-orders`. Hoy ninguna vista lo usa: las pantallas llaman a `OrderingApi`.
class OrdersApiEndpoint
    extends
        BaseApiEndpoint<Order, OrderResource, OrdersResponse, OrderAssembler> {
  OrdersApiEndpoint(AppHttpClient http)
    : super(
        http,
        Environment.serverBasePath + Environment.orderingOrdersEndpointPath,
        OrderAssembler(),
      );
}
