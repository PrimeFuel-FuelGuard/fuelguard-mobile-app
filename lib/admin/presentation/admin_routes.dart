import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/admin_panel/admin_panel.dart';

/// Rutas de `/admin` (authGuard + adminGuard).
const List<Guard> _guards = [authGuard, adminGuard];

final List<AppRoute> adminRoutes = [
  AppRoute(
    '/admin',
    guards: _guards,
    shell: true,
    builder: (c, p) => const AdminPanel(),
  ),
];
