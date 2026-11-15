import 'package:material_ui/material_ui.dart';

import 'admin/presentation/admin_routes.dart';
import 'analytics/presentation/analytics_routes.dart';
import 'dashboard/presentation/dashboard_routes.dart';
import 'equipment/presentation/equipment_routes.dart';
import 'equipment/presentation/provider_routes.dart';
import 'fulfillment/presentation/fulfillment_routes.dart';
import 'iam/application/iam_store.dart';
import 'iam/domain/model/session_entity.dart';
import 'iam/infrastructure/auth_guard.dart';
import 'iam/presentation/views/accept_invitation/accept_invitation.dart';
import 'iam/presentation/views/access_denied/access_denied.dart';
import 'iam/presentation/views/login/login.dart';
import 'iam/presentation/views/password_reset/password_reset.dart';
import 'iam/presentation/views/profile/profile.dart';
import 'iam/presentation/views/register/register.dart';
import 'inventory/presentation/inventory_routes.dart';
import 'notification/presentation/notification_routes.dart';
import 'ordering/presentation/ordering_routes.dart';
import 'ordering/presentation/provider_payments_routes.dart';
import 'shared/infrastructure/app_route.dart';
import 'shared/infrastructure/route_match.dart';
import 'shared/presentation/component/layout/layout.dart';
import 'shared/presentation/views/more/more.dart';
import 'shared/presentation/views/page_not_found/page_not_found.dart';

/// Clave del `Navigator` raíz (para navegar fuera del árbol de widgets, p. ej. en logout).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Entrada de la app: sin sesión `/login`; con sesión `/dashboard` (admin `/admin`).
String? _entryGuard(IamStore iam, String url) =>
    iam.isAuthenticated ? (iam.isAdmin ? '/admin' : '/dashboard') : '/login';

Widget _empty(BuildContext context, RouteParams params) =>
    const SizedBox.shrink();

/// Todas las rutas de la app (equivale a `app.routes.ts`). El primer patrón que coincide gana.
final List<AppRoute> appRoutes = [
  // Públicas (sin Layout)
  AppRoute('/login', builder: (c, p) => Login(returnUrl: p.query['returnUrl'])),
  AppRoute(
    '/register/buyer',
    data: const {'role': UserRole.buyer},
    builder: (c, p) =>
        Register(role: '${p.data['role']}', returnUrl: p.query['returnUrl']),
  ),
  AppRoute(
    '/register/distributor',
    data: const {'role': UserRole.provider},
    builder: (c, p) =>
        Register(role: '${p.data['role']}', returnUrl: p.query['returnUrl']),
  ),
  AppRoute(
    '/forgot-password',
    builder: (c, p) => PasswordReset(token: p.query['token']),
  ),
  AppRoute(
    '/reset-password',
    builder: (c, p) => PasswordReset(token: p.query['token']),
  ),
  AppRoute('/access-denied', builder: (c, p) => const AccessDenied()),
  AppRoute('/accept-invitation', builder: (c, p) => const AcceptInvitation()),
  AppRoute(
    '/accept-invitation/:token',
    builder: (c, p) => AcceptInvitation(routeToken: p.path['token']),
  ),
  // Más y perfil (con Layout)
  AppRoute(
    '/more',
    guards: const [authGuard],
    shell: true,
    builder: (c, p) => const More(),
  ),
  AppRoute(
    '/profile',
    guards: const [authGuard],
    shell: true,
    builder: (c, p) => Profile(initialTab: p.query['tab']),
  ),
  // Contextos
  ...fuelProductRoutes,
  ...fulfillmentRoutes,
  ...dashboardRoutes,
  ...orderingRoutes,
  ...analyticsRoutes,
  const AppRoute.redirect('/reporting', '/analytics'),
  const AppRoute.redirect('/reporting/report-main', '/analytics'),
  ...notificationRoutes,
  ...adminRoutes,
  ...equipmentRoutes,
  ...providerPaymentRoutes,
  ...providerClientRoutes,
  const AppRoute('/', guards: [_entryGuard], builder: _empty),
  const AppRoute('/home', guards: [_entryGuard], builder: _empty),
];

/// Resultado de resolver una URL: ruta (o `null` = 404), parámetros y URL final tras redirecciones/guards.
class ResolvedRoute {
  const ResolvedRoute(this.url, this.route, this.params);

  final String url;
  final AppRoute? route;
  final RouteParams params;

  String get path => Uri.parse(url).path;
}

/// Aplica coincidencia de patrón, redirecciones y guards hasta llegar a una ruta renderizable.
ResolvedRoute resolveUrl(String url, IamStore iam) {
  var current = url.isEmpty ? '/' : url;
  for (var i = 0; i < 10; i++) {
    final uri = Uri.parse(current);
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    AppRoute? route;
    Map<String, String>? pathParams;
    for (final candidate in appRoutes) {
      pathParams = matchPath(candidate.pattern, path);
      if (pathParams != null) {
        route = candidate;
        break;
      }
    }
    if (route == null) {
      return ResolvedRoute(current, null, RouteParams(url: current));
    }
    if (route.redirectTo != null) {
      current =
          fillPath(route.redirectTo!, pathParams!) +
          (uri.hasQuery ? '?${uri.query}' : '');
      continue;
    }
    String? redirect;
    for (final guard in route.guards) {
      redirect = guard(iam, current);
      if (redirect != null) break;
    }
    if (redirect != null) {
      current = redirect;
      continue;
    }
    return ResolvedRoute(
      current,
      route,
      RouteParams(
        path: pathParams!,
        query: uri.queryParameters,
        data: route.data,
        url: current,
      ),
    );
  }
  return ResolvedRoute('/login', null, const RouteParams());
}

/// `MaterialApp.onGenerateRoute`: las rutas con `shell` se envuelven en `Layout` (sin transición).
Route<dynamic> generateRoute(RouteSettings settings, IamStore iam) {
  final resolved = resolveUrl(settings.name ?? '/', iam);
  final route = resolved.route;
  final routeSettings = RouteSettings(
    name: resolved.url,
    arguments: settings.arguments,
  );
  Widget build(BuildContext context) {
    if (route == null) {
      return PageNotFound(
        invalidPath: resolved.path.replaceFirst(RegExp(r'^/'), ''),
      );
    }
    final page = route.builder!(context, resolved.params);
    return route.shell ? Layout(currentPath: resolved.path, child: page) : page;
  }

  if (route?.shell ?? false) {
    return PageRouteBuilder<void>(
      settings: routeSettings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => build(context),
    );
  }
  return MaterialPageRoute<void>(settings: routeSettings, builder: build);
}
