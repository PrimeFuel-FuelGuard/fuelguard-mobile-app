import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/analytics/analytics.dart';

/// Rutas de `/analytics` (authGuard + analyticsGuard).
/// Access guards required for analytics routes.
///
/// Ensures the user is authenticated ([authGuard]) and has
/// permissions to view analytics ([analyticsGuard]).
const List<Guard> _guards = [authGuard, analyticsGuard];

/// Route configuration for the analytics module (`/analytics`).
///
/// Wraps the view in the main layout (`shell: true`) and restricts access
/// using [_guards] before rendering [Analytics].
final List<AppRoute> analyticsRoutes = [
  AppRoute(
    '/analytics',
    guards: _guards,
    shell: true,
    builder: (c, p) => const Analytics(),
  ),
];
