import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/admin_panel/admin_panel.dart';

/// Rutas de `/admin` (authGuard + adminGuard).
/// Access guards required for administration routes.
///
/// Ensures the user is authenticated ([authGuard]) and has
/// administrator privileges ([adminGuard]).
const List<Guard> _guards = [authGuard, adminGuard];

/// Route configuration for the administration module (`/admin`).
///
/// Wraps the view in the main layout (`shell: true`) and restricts access
/// using [_guards] before rendering [AdminPanel].
final List<AppRoute> adminRoutes = [
  AppRoute(
    '/admin',
    guards: _guards,
    shell: true,
    builder: (c, p) => const AdminPanel(),
  ),
];
