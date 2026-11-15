import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/provider_buyer_form/provider_buyer_form.dart';
import 'views/provider_client_detail/provider_client_detail.dart';
import 'views/provider_clients/provider_clients.dart';
import 'views/provider_tank_detail/provider_tank_detail.dart';
import 'views/provider_tank_form/provider_tank_form.dart';

/// Clientes del distribuidor: `/clients` (authGuard + providerGuard). El orden importa: `new` y `tank/:id` antes de `:buyerId`.
const List<Guard> _guards = [authGuard, providerGuard];

final List<AppRoute> providerClientRoutes = [
  AppRoute(
    '/clients',
    guards: _guards,
    shell: true,
    builder: (c, p) => const ProviderClients(),
  ),
  AppRoute(
    '/clients/new',
    guards: _guards,
    shell: true,
    builder: (c, p) => const ProviderBuyerForm(),
  ),
  AppRoute(
    '/clients/tank/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => ProviderTankDetail(rawId: p.path['id']),
  ),
  AppRoute(
    '/clients/:buyerId',
    guards: _guards,
    shell: true,
    builder: (c, p) => ProviderClientDetail(rawBuyerId: p.path['buyerId']),
  ),
  AppRoute(
    '/clients/:buyerId/tanks/new',
    guards: _guards,
    shell: true,
    builder: (c, p) => ProviderTankForm(rawBuyerId: p.path['buyerId']),
  ),
  AppRoute(
    '/clients/:buyerId/tanks/:tankId/edit',
    guards: _guards,
    shell: true,
    builder: (c, p) => ProviderTankForm(
      rawBuyerId: p.path['buyerId'],
      rawTankId: p.path['tankId'],
    ),
  ),
];
