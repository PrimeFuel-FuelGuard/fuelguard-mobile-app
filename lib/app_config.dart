import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'environments/environment.dart';
import 'iam/application/iam_store.dart';
import 'iam/infrastructure/auth_interceptor.dart';
import 'iam/infrastructure/iam_api.dart';
import 'notification/application/notification_store.dart';
import 'shared/infrastructure/i18n/translate_service.dart';

/// Contenedor de dependencias (equivale a `app.config.ts`): se crea una vez antes de `runApp`.
///
/// Para registrar un store nuevo: añadir el campo `final`, crearlo en [create] y usarlo desde los
/// widgets con `AppScope.of(context).xStore`.
class AppConfig {
  AppConfig._({
    required this.prefs,
    required this.translateService,
    required this.httpClient,
    required this.iamStore,
    required this.notificationStore,
  });

  final SharedPreferences prefs;
  final TranslateService translateService;
  final AppHttpClient httpClient;
  final IamStore iamStore;
  final NotificationStore notificationStore;

  /// Carga prefs, idioma y sesión (restauración asíncrona antes de `runApp`).
  static Future<AppConfig> create() async {
    final prefs = await SharedPreferences.getInstance();
    final translate = TranslateService(prefs);
    await translate.init();
    final http = AppHttpClient(translate);
    final iam = IamStore(IamApi(http), prefs);
    http.iam = iam;
    // El modo demo solo tiene sentido con sesión activa.
    Environment.demoMode =
        (prefs.getBool('fuelguard.demo') ?? false) && iam.isAuthenticated;
    return AppConfig._(
      prefs: prefs,
      translateService: translate,
      httpClient: http,
      iamStore: iam,
      notificationStore: NotificationStore(http),
    );
  }
}

/// Expone [AppConfig] a los widgets: `AppScope.of(context).iamStore`.
///
/// Notifica al cambiar de idioma, por lo que `context.tr` reconstruye los widgets.
class AppScope extends InheritedNotifier<TranslateService> {
  AppScope({super.key, required this.config, required super.child})
    : super(notifier: config.translateService);

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol');
    return scope!.config;
  }
}
