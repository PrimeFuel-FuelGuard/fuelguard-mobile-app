import 'package:material_ui/material_ui.dart';

import '../../iam/application/iam_store.dart';

/// Guard: devuelve la URL de redirección o `null` si se permite el acceso.
typedef Guard = String? Function(IamStore iam, String url);

/// Parámetros de la ruta resuelta.
class RouteParams {
  const RouteParams({
    this.path = const {},
    this.query = const {},
    this.data = const {},
    this.url = '',
  });

  /// Parámetros de segmento (`:id`).
  final Map<String, String> path;

  /// Query string.
  final Map<String, String> query;

  /// Datos estáticos de la ruta (equivale a `data` en Angular).
  final Map<String, Object?> data;

  /// URL completa solicitada.
  final String url;
}

typedef AppRouteBuilder = Widget Function(
  BuildContext context,
  RouteParams params,
);

/// Definición de ruta (equivale a una entrada de `Routes`).
///
/// [shell] envuelve la vista en `Layout`. Con [redirectTo] la ruta solo redirige (admite `:param`).
class AppRoute {
  const AppRoute(
    this.pattern, {
    required AppRouteBuilder this.builder,
    this.guards = const [],
    this.shell = false,
    this.data = const {},
  }) : redirectTo = null;

  const AppRoute.redirect(this.pattern, String this.redirectTo)
    : builder = null,
      guards = const [],
      shell = false,
      data = const {};

  final String pattern;
  final AppRouteBuilder? builder;
  final String? redirectTo;
  final List<Guard> guards;
  final bool shell;
  final Map<String, Object?> data;
}
