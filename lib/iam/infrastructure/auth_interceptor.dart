import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../environments/environment.dart';
import '../../shared/infrastructure/demo/demo_handlers.dart';
import '../../shared/infrastructure/demo/demo_http_client.dart';
import '../../shared/infrastructure/i18n/translate_service.dart';
import '../application/iam_store.dart';

/// Un 401 no implica sesión caducada (el backend también lo usa en denegaciones de permiso):
/// solo se cierra si el `exp` del JWT ya pasó.
bool _isExpired(String? token) {
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(token!.split('.')[1]))),
    );
    final exp = (payload as Map<String, dynamic>)['exp'];
    return exp is num && exp * 1000 <= DateTime.now().millisecondsSinceEpoch;
  } catch (_) {
    return false;
  }
}

/// Cliente HTTP único de la app (equivale a `authInterceptor`): añade `Accept-Language` y el
/// Bearer (solo al API y no en `/authentication/`), cierra sesión ante 401 con JWT vencido y
/// resuelve en memoria cuando `Environment.demoMode` está activo.
class AppHttpClient extends http.BaseClient {
  AppHttpClient(this._translate, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final TranslateService _translate;
  final http.Client _inner;
  final DemoHttpClient _demo = DemoHttpClient(demoHandlers);

  /// Se asigna tras crear el `IamStore` (evita la dependencia circular).
  IamStore? iam;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<http.Response> getJson(String url) => get(Uri.parse(url));

  Future<http.Response> postJson(String url, Object? body) => post(
    Uri.parse(url),
    headers: _jsonHeaders,
    body: body == null ? null : jsonEncode(body),
  );

  Future<http.Response> putJson(String url, Object? body) => put(
    Uri.parse(url),
    headers: _jsonHeaders,
    body: body == null ? null : jsonEncode(body),
  );

  Future<http.Response> patchJson(String url, Object? body) => patch(
    Uri.parse(url),
    headers: _jsonHeaders,
    body: body == null ? null : jsonEncode(body),
  );

  Future<http.Response> deleteJson(String url) => delete(Uri.parse(url));

  bool _isApiRequest(Uri destination) {
    final api = Uri.parse(Environment.serverBasePath);
    final basePath = api.path.replaceFirst(RegExp(r'/$'), '');
    return destination.scheme == api.scheme &&
        destination.host == api.host &&
        destination.port == api.port &&
        (destination.path == basePath ||
            destination.path.startsWith('$basePath/'));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = iam?.session?.token;
    request.headers['Accept-Language'] = _translate.getCurrentLang();
    if (token != null &&
        _isApiRequest(request.url) &&
        !request.url.path.contains('/authentication/')) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = Environment.demoMode
        ? await _demo.send(request)
        : await _inner.send(request);
    if (response.statusCode >= 400) {
      _logHttpError(request.method, request.url, response.statusCode);
      if (response.statusCode == 401 &&
          iam?.session?.token == token &&
          _isExpired(token)) {
        iam?.logout();
      }
    }
    return response;
  }

  /// Punto único de log de errores HTTP. Nunca registra cabeceras, cuerpo ni tokens de la URL.
  void _logHttpError(String method, Uri url, int status) {
    final safe = url.path.replaceAll(
      RegExp(r'/invitations/[^/]+/accept'),
      '/invitations/:token/accept',
    );
    debugPrint('[FuelGuard HTTP $status] $method $safe');
  }
}
