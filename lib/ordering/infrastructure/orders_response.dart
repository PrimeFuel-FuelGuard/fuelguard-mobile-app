import '../../shared/infrastructure/base_response.dart';
import '../domain/model/order_entity.dart';

/// Una orden tal como llega de la API (igual que la entidad): envuelve la entidad sin transformarla.
class OrderResource implements BaseResource {
  const OrderResource(this.order);

  factory OrderResource.fromJson(Map<String, dynamic> json) =>
      OrderResource(Order.fromJson(json));

  final Order order;

  @override
  int get id => order.id;

  @override
  Map<String, dynamic> toJson() => order.toJson();
}

/// Respuesta de listado de órdenes: un arreglo sin envoltorio.
typedef OrdersResponse = List<OrderResource>;
