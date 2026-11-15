import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/notification_list/notification_list.dart';

/// Rutas de `/notification`.
const List<Guard> _guards = [authGuard];

final List<AppRoute> notificationRoutes = [
  AppRoute(
    '/notification/notification-list',
    guards: _guards,
    shell: true,
    builder: (c, p) => const NotificationList(),
  ),
  AppRoute.redirect('/notification', '/notification/notification-list'),
];
