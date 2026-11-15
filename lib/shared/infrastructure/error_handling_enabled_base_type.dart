import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Error tipado de la capa de infraestructura.
///
/// [status] es `0` cuando no hubo respuesta (red). [body] es el JSON de error del backend, si lo hay.
class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.body});

  final String message;
  final int? status;
  final Map<String, dynamic>? body;

  /// Código de error del backend (`body.code`), si existe.
  String get code => '${body?['code'] ?? ''}';

  @override
  String toString() => message;
}

/// Clase base con el manejo centralizado de errores HTTP de FuelGuard.
abstract class ErrorHandlingEnabledBaseType {
  /// Convierte [error] en un [ApiException] con una clave de traducción o texto del backend.
  ///
  /// [localized] devuelve siempre claves de traducción (sin texto ni detalles del backend).
  ApiException handleError(
    Object error,
    String operation, [
    bool localized = false,
  ]) {
    final status = error is ApiException ? (error.status ?? 0) : 0;
    final body = error is ApiException ? error.body : null;
    final fallback = status == 0
        ? 'errors.network'
        : status >= 500
        ? 'errors.server'
        : const [400, 401, 403, 404, 409, 422].contains(status)
        ? 'errors.http-$status'
        : 'errors.generic';
    final bodyMessage = body?['message'];
    final message = localized || status == 0 || status >= 500
        ? fallback
        : (bodyMessage is String ? bodyMessage : fallback);
    final rawDetails = body?['details'];
    final details =
        !localized &&
            status < 500 &&
            rawDetails is String &&
            rawDetails != message
        ? rawDetails
        : '';
    debugPrint('[FuelGuard API Error] $operation: HTTP $status');
    return ApiException(
      details.isEmpty ? message : '$message: $details',
      status: status,
      body: body,
    );
  }

  /// Ejecuta [call], decodifica el JSON de la respuesta (o `null` si viene vacía) y lanza
  /// [ApiException] ante un fallo. Con [operation] el error pasa por [handleError]; sin él se
  /// conserva el status y el cuerpo originales (útil para `displayAuthError`).
  Future<dynamic> execute(
    Future<http.Response> Function() call, {
    String? operation,
    bool localized = false,
  }) async {
    final ApiException failure;
    try {
      final response = await call();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.trim().isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
      }
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        /* cuerpo no JSON */
      }
      failure = ApiException(
        'HTTP ${response.statusCode}',
        status: response.statusCode,
        body: body,
      );
    } on ApiException catch (e) {
      return Future.error(
        operation == null ? e : handleError(e, operation, localized),
      );
    } on SocketException catch (_) {
      return Future.error(_network(operation, localized));
    } on http.ClientException catch (_) {
      return Future.error(_network(operation, localized));
    } on TimeoutException catch (_) {
      return Future.error(_network(operation, localized));
    }
    return Future.error(
      operation == null ? failure : handleError(failure, operation, localized),
    );
  }

  ApiException _network(String? operation, bool localized) {
    const failure = ApiException('errors.network', status: 0);
    return operation == null
        ? failure
        : handleError(failure, operation, localized);
  }
}
