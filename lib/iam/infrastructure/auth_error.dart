import '../../shared/infrastructure/error_handling_enabled_base_type.dart';

/// Convierte un error de autenticación en una clave de traducción (o texto útil del backend).
String displayAuthError(Object? error, [String? operation]) {
  final status = error is ApiException ? (error.status ?? 0) : 0;
  final body = error is ApiException ? error.body : null;
  final code = '${body?['code'] ?? ''}'.toUpperCase();
  if (status == 0) return 'auth.error.connection';
  if (status >= 500) return 'auth.error.server';
  if (status == 429) return 'auth.error.too-many-attempts';
  if (operation == 'sign-in' && const [400, 401, 404].contains(status)) {
    return 'auth.error.credentials';
  }
  if (code.contains('USER') && code.contains('CONFLICT')) {
    return 'auth.error.user-conflict';
  }
  if (code.contains('BUYER') &&
      code.contains('COMPANY') &&
      code.contains('CONFLICT')) {
    return 'auth.error.buyer-conflict';
  }
  if (code.contains('PROVIDER') &&
      code.contains('COMPANY') &&
      code.contains('CONFLICT')) {
    return 'auth.error.provider-conflict';
  }
  if (code == 'ORGANIZATION_CONFLICT') return 'auth.error.ruc-conflict';
  if (operation == 'sign-up' && status == 404) {
    return 'auth.error.registration-unavailable';
  }
  if (status == 403) return 'auth.error.forbidden';
  final message = body?['message'];
  // Los flujos de autenticación usan mensajes propios, no códigos o textos genéricos del servidor.
  if (operation == null &&
      message is String &&
      message.trim().isNotEmpty &&
      !RegExp(
        r'unknown error|http failure|internal server error',
        caseSensitive: false,
      ).hasMatch(message)) {
    return message;
  }
  return const [400, 422].contains(status)
      ? 'auth.error.bad-request'
      : status == 401
      ? 'auth.error.unauthorized'
      : status == 409
      ? 'auth.error.conflict'
      : 'auth.error.generic';
}
