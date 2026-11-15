import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../environments/environment.dart';
import 'demo_handler.dart';

/// Cliente HTTP en memoria: el primer [DemoHandler] que responda gana; si ninguno, 404.
class DemoHttpClient {
  DemoHttpClient(
    this.handlers, {
    this.latency = const Duration(milliseconds: 250),
  });

  final List<DemoHandler> handlers;
  final Duration latency;

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(latency);
    final base = Uri.parse(Environment.serverBasePath).path
        .replaceFirst(RegExp(r'/$'), '');
    var path = request.url.path;
    if (path.startsWith(base)) path = path.substring(base.length);
    Object? body;
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        body = jsonDecode(request.body);
      } catch (_) {
        /* cuerpo no JSON */
      }
    }
    final demoRequest = DemoRequest(
      method: request.method,
      path: path,
      query: request.url.queryParameters,
      body: body,
      headers: {
        for (final e in request.headers.entries) e.key.toLowerCase(): e.value,
      },
    );
    DemoResponse? response;
    for (final handler in handlers) {
      response = await handler.handle(demoRequest);
      if (response != null) break;
    }
    response ??= DemoResponse.error(404, 'Not found (demo)');
    final bytes = utf8.encode(response.encoded);
    return http.StreamedResponse(
      Stream.value(bytes),
      response.status,
      contentLength: bytes.length,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
