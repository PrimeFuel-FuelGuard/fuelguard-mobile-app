import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/tank_detail/tank_detail.dart';
import 'views/tank_list/tank_list.dart';

/// Rutas de `/tanks` (authGuard + buyerGuard).
const List<Guard> _guards = [authGuard, buyerGuard];

final List<AppRoute> equipmentRoutes = [
  AppRoute(
    '/tanks',
    guards: _guards,
    shell: true,
    builder: (c, p) => const TankList(),
  ),
  AppRoute(
    '/tanks/:id',
    guards: _guards,
    shell: true,
    builder: (c, p) => TankDetail(rawId: p.path['id']),
  ),
];
