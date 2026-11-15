import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/delivery_detail/delivery_detail.dart';
import 'views/delivery_list/delivery_list.dart';
import 'views/driver_form/driver_form.dart';
import 'views/driver_list/driver_list.dart';
import 'views/tanker_form/tanker_form.dart';
import 'views/tanker_list/tanker_list.dart';

/// Rutas de `/fulfillment` (authGuard + providerGuard).
const List<Guard> _guards = [authGuard, providerGuard];

final List<AppRoute> fulfillmentRoutes = [
  AppRoute(
    '/fulfillment/tanker-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const TankerList(),
  ),
  AppRoute(
    '/fulfillment/tanker-form',
    guards: _guards,
    shell: true,
    builder: (c, p) => const TankerForm(),
  ),
  AppRoute(
    '/fulfillment/tanker-form/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => TankerForm(rawId: p.path['id']),
  ),
  AppRoute.redirect('/fulfillment/vehicle-list', '/fulfillment/tanker-list'),
  AppRoute.redirect('/fulfillment/vehicle-form', '/fulfillment/tanker-form'),
  AppRoute.redirect(
    '/fulfillment/vehicle-form/:id',
    '/fulfillment/tanker-form/:id',
  ),
  AppRoute(
    '/fulfillment/driver-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const DriverList(),
  ),
  AppRoute(
    '/fulfillment/driver-form',
    guards: _guards,
    shell: true,
    builder: (c, p) => const DriverForm(),
  ),
  AppRoute(
    '/fulfillment/driver-form/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => DriverForm(rawId: p.path['id']),
  ),
  AppRoute(
    '/fulfillment/delivery-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const DeliveryList(),
  ),
  AppRoute(
    '/fulfillment/delivery-detail/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => DeliveryDetail(rawId: p.path['id']),
  ),
  AppRoute.redirect('/fulfillment', '/fulfillment/tanker-list'),
];
