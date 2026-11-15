import 'package:material_ui/material_ui.dart';

import 'app_config.dart';
import 'app_routes.dart';
import 'iam/application/iam_store.dart';
import 'shared/presentation/theme/app_theme.dart';

/// Raíz de la aplicación (equivale a `app.ts`): `MaterialApp` con navegación por nombre de ruta.
class App extends StatefulWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _InvitationTokenObserver _observer;

  @override
  void initState() {
    super.initState();
    final iam = widget.config.iamStore;
    _observer = _InvitationTokenObserver(iam);
    iam.navigate = (url) =>
        navigatorKey.currentState?.pushNamedAndRemoveUntil(url, (_) => false);
  }

  @override
  void dispose() {
    widget.config.iamStore.navigate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iam = widget.config.iamStore;
    final initial = iam.isAuthenticated
        ? (iam.isAdmin ? '/admin' : '/dashboard')
        : '/login';
    return AppScope(
      config: widget.config,
      child: MaterialApp(
        title: 'FuelGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: navigatorKey,
        navigatorObservers: [_observer],
        initialRoute: initial,
        onGenerateInitialRoutes: (name) => [
          generateRoute(RouteSettings(name: name), iam),
        ],
        onGenerateRoute: (settings) => generateRoute(settings, iam),
      ),
    );
  }
}

/// El token de invitación solo vive mientras se navega entre accept-invitation / login / register.
class _InvitationTokenObserver extends NavigatorObserver {
  _InvitationTokenObserver(this._iam);

  final IamStore _iam;
  static final _keep = RegExp(
    r'^/(accept-invitation([/#?]|$)|login([?#]|$)|register(/|$))',
  );

  void _check(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && !_keep.hasMatch(name)) _iam.pendingInvitationToken = '';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _check(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _check(newRoute);
}
