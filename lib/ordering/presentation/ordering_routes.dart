import 'views/request_form/request_form.dart';
import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/order_detail/order_detail.dart';
import 'views/order_list/order_list.dart';
import 'views/payment_history/payment_history.dart';
import 'views/request_detail/request_detail.dart';
import 'views/request_list/request_list.dart';

/// Rutas de `/ordering`; crear solicitudes y el historial de pagos exigen buyerGuard.
const List<Guard> _guards = [authGuard, supportedRoleGuard];

final List<AppRoute> orderingRoutes = [
  AppRoute(
    '/ordering/request-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const RequestList(),
  ),
  AppRoute(
    '/ordering/request-detail/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => RequestDetail(id: int.tryParse(p.path['id'] ?? '') ?? 0),
  ),
  AppRoute(
    '/ordering/request-form',
    guards: [..._guards, buyerGuard],
    shell: true,
    builder: (c, p) => const RequestForm(),
  ),
  AppRoute(
    '/ordering/request-form/:id',
    guards: [..._guards, buyerGuard],
    shell: true,
    builder: (c, p) => const RequestForm(),
  ),
  AppRoute(
    '/ordering/payment-history',
    guards: [..._guards, buyerGuard],
    shell: true,
    builder: (c, p) => const PaymentHistory(),
  ),
  AppRoute(
    '/ordering/order-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const OrderList(),
  ),
  AppRoute(
    '/ordering/order-detail/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => OrderDetail(id: int.tryParse(p.path['id'] ?? '') ?? 0),
  ),
  AppRoute.redirect('/ordering', '/ordering/request-list'),
];
