import '../../shared/infrastructure/base_assembler.dart';
import '../domain/model/order_entity.dart';
import 'orders_response.dart';

/// Ensamblador identidad: el recurso de la API ya tiene la forma de la entidad `Order`, así que no transforma nada.
class OrderAssembler
    implements BaseAssembler<Order, OrderResource, OrdersResponse> {
  @override
  OrderResource resourceFromJson(Map<String, dynamic> json) =>
      OrderResource.fromJson(json);

  @override
  Order toEntityFromResource(OrderResource resource) => resource.order;

  @override
  OrderResource toResourceFromEntity(Order entity) => OrderResource(entity);

  @override
  List<Order> toEntitiesFromResponse(OrdersResponse response) => [
    for (final r in response) r.order,
  ];
}
