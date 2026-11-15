import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/analytics/analytics.dart';

/// Rutas de `/analytics` (authGuard + analyticsGuard).
const List<Guard> _guards = [authGuard, analyticsGuard];

final List<AppRoute> analyticsRoutes = [
  AppRoute(
    '/analytics',
    guards: _guards,
    shell: true,
    builder: (c, p) => const Analytics(),
  ),
];
