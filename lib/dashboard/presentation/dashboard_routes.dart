import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/dashboard/dashboard.dart';

/// Rutas de `/dashboard`.
const List<Guard> _guards = [authGuard, supportedRoleGuard];

final List<AppRoute> dashboardRoutes = [
  AppRoute(
    '/dashboard',
    guards: _guards,
    shell: true,
    builder: (c, p) => const Dashboard(),
  ),
];
