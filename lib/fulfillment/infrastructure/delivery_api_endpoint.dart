import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/provider_delivery_entity.dart';

class DeliveryApiEndpoint extends ErrorHandlingEnabledBaseType {
  DeliveryApiEndpoint(this._http);

  final AppHttpClient _http;
  final String endpointUrl =
      '${Environment.serverBasePath}${Environment.fulfillmentDeliveriesEndpointPath}';

  String _url(String path, Map<String, String> query) =>
      Uri.parse('$endpointUrl$path')
          .replace(queryParameters: query.isEmpty ? null : query)
          .toString();

  /// Entregas del distribuidor del token; `date` (yyyy-MM-dd) filtra por scheduledDate.
  Future<List<ProviderDelivery>> list([String? date]) async {
    final url = _url('', {if (date != null && date.isNotEmpty) 'date': date});
    final json = await execute(
      () => _http.getJson(url),
      operation: 'Failed to load deliveries',
      localized: true,
    );
    return [
      for (final e in (json as List))
        ProviderDelivery.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<DeliveryRecommendation> recommendation(
    int orderId, [
    String? windowStart,
    String? windowEnd,
  ]) async {
    final hasWindow =
        windowStart != null &&
        windowStart.isNotEmpty &&
        windowEnd != null &&
        windowEnd.isNotEmpty;
    final url = _url('/recommendation', {
      'orderId': '$orderId',
      if (hasWindow) 'windowStart': windowStart,
      if (hasWindow) 'windowEnd': windowEnd,
    });
    return DeliveryRecommendation.fromJson(
      await execute(
        () => _http.getJson(url),
        operation: 'Failed to load delivery recommendation',
        localized: true,
      ) as Map<String, dynamic>,
    );
  }

  Future<List<ValveObservation>> valveObservations(int id) async {
    final json = await execute(
      () => _http.getJson('$endpointUrl/$id/valve-observations'),
      operation: 'Failed to load valve observations $id',
      localized: true,
    );
    return [
      for (final e in (json as List))
        ValveObservation.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<dynamic> detail(int id) =>
      execute(() => _http.getJson('$endpointUrl/$id'));
  Future<dynamic> tracking(int id) =>
      execute(() => _http.getJson('$endpointUrl/$id/tracking'));
  Future<List<dynamic>> samples(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/tracking/samples'))
          as List);
  Future<List<dynamic>> transitions(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/transitions'))
          as List);
  Future<List<dynamic>> timeline(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/timeline')) as List);
  Future<dynamic> command(
    int id,
    String action, [
    Map<String, dynamic> body = const {},
  ]) => execute(() => _http.postJson('$endpointUrl/$id/$action', body));
  Future<dynamic> geofence(int id, Map<String, dynamic> body) =>
      execute(() => _http.postJson('$endpointUrl/$id/geofence-policies', body));
  Future<dynamic> assign(Map<String, dynamic> body) =>
      execute(() => _http.postJson(endpointUrl, body));
}
