import 'dart:convert';

import '../route_match.dart';

/// Petición interceptada en modo demo. [path] es relativo al API (`/users/1`), sin query.
class DemoRequest {
  DemoRequest({
    required this.method,
    required this.path,
    required this.query,
    this.body,
    this.headers = const {},
  }) : segments = path.split('/').where((e) => e.isNotEmpty).toList();

  final String method;
  final String path;
  final List<String> segments;
  final Map<String, String> query;

  /// JSON decodificado del cuerpo (o `null`).
  final Object? body;

  /// Cabeceras de la petición (claves en minúscula).
  final Map<String, String> headers;

  /// Id del usuario demo (`uid` del JWT del Bearer), o `null` sin sesión.
  int? get userId {
    final auth = headers['authorization'];
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    try {
      final payload = auth.substring(7).split('.')[1];
      final map = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      ) as Map<String, dynamic>;
      return (map['uid'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Cuerpo como mapa (vacío si no es objeto).
  Map<String, dynamic> get json => body is Map<String, dynamic>
      ? body as Map<String, dynamic>
      : <String, dynamic>{};

  /// Si coincide método y patrón (`/orders/:id`) devuelve los parámetros; si no, `null`.
  Map<String, String>? match(String method, String pattern) =>
      this.method.toUpperCase() == method.toUpperCase()
      ? matchPath(pattern, path)
      : null;
}

class DemoResponse {
  const DemoResponse(this.status, this.body);

  /// Respuesta JSON (`status` 200 por defecto).
  factory DemoResponse.json(Object? obj, [int status = 200]) =>
      DemoResponse(status, obj);

  /// Sin contenido (204).
  factory DemoResponse.empty([int status = 204]) => DemoResponse(status, null);

  /// Error con `{"message": ..}`.
  factory DemoResponse.error(int status, String message) =>
      DemoResponse(status, {'message': message});

  final int status;
  final Object? body;

  String get encoded => body == null ? '' : jsonEncode(body);
}

/// Manejador de datos demo de un contexto. Devuelve `null` si no atiende la petición.
abstract class DemoHandler {
  Future<DemoResponse?> handle(DemoRequest r);
}
