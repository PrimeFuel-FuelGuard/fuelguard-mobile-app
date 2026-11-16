import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/provider_delivery_entity.dart';

/// Endpoint REST de entregas del backend (`/api/deliveries`).
///
/// Las rutas de `provider-deliveries.md` requieren JWT con `ROLE_PROVIDER`; las de seguimiento
/// también admiten al conductor asignado. El backend deriva el distribuidor del token, por eso
/// ningún método envía `providerId`. Las rutas y sus códigos de error están en
/// `docs/api-ledger` del repositorio `fuelguard-platform`: `T01-A-rest-ledger.md`,
/// `provider-deliveries.md` y `delivery-tracking.md`.
///
/// Los métodos que devuelven `dynamic` o `List<dynamic>` entregan el JSON sin tipar; el
/// `FulfillmentStore` los guarda como mapas y las vistas leen sus claves.
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
  ///
  /// `GET /api/deliveries?date=`. Sin `date` devuelve todas las entregas propias. El backend
  /// responde 403 si falta el rol o la identidad de distribuidor, y 400 ante una fecha inválida.
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

  /// Sugerencia de conductor y cisterna para un pedido.
  ///
  /// `GET /api/deliveries/recommendation?orderId=&windowStart=&windowEnd=`. La ventana se envía
  /// solo si llegan ambos extremos. Detalle en `provider-recommendation.md` del backend.
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

  /// Observaciones de válvula de la entrega.
  ///
  /// `GET /api/deliveries/{id}/valve-observations`. Detalle en
  /// `provider-valve-observations.md` del backend.
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

  /// Detalle de una entrega: `GET /api/deliveries/{id}`.
  Future<dynamic> detail(int id) =>
      execute(() => _http.getJson('$endpointUrl/$id'));

  /// Último estado de seguimiento: `GET /api/deliveries/{id}/tracking`.
  ///
  /// Puede consultarlo el distribuidor propietario o el conductor asignado. Devuelve la última
  /// posición (`lastLatitude`, `lastLongitude`, `lastAccuracyMeters`, `lastPositionAt`) y el
  /// último hito de carga (`loaded`, `lastLoadMilestone`, `lastLoadVolume`, `lastLoadUnit`).
  /// Responde 404 cuando la entrega todavía no recibió ninguna evidencia, y 403 si el usuario
  /// no es ninguno de los dos.
  Future<dynamic> tracking(int id) =>
      execute(() => _http.getJson('$endpointUrl/$id/tracking'));

  /// Historial de muestras de seguimiento: `GET /api/deliveries/{id}/tracking/samples`.
  ///
  /// Cada muestra es de tipo `POSITION` o `LOAD`. Salen ordenadas por `recordedAt` (hora del
  /// dispositivo), no por orden de llegada, y `latestAdvanced` indica si esa muestra movió el
  /// último estado al llegar. Puede ser una lista vacía.
  Future<List<dynamic>> samples(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/tracking/samples'))
          as List);

  /// Transiciones del estado físico: `GET /api/deliveries/{id}/transitions`.
  Future<List<dynamic>> transitions(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/transitions'))
          as List);

  /// Cronología de eventos de la entrega: `GET /api/deliveries/{id}/timeline`.
  Future<List<dynamic>> timeline(int id) async =>
      (await execute(() => _http.getJson('$endpointUrl/$id/timeline')) as List);

  /// Transición del ciclo de vida: `POST /api/deliveries/{id}/{action}`.
  ///
  /// `action` es `start`, `arrive`, `complete`, `fail` o `cancel`. La app envía
  /// `{deliveredVolume}` en `complete` y `{reason}` en `fail` y `cancel`; `start` y `arrive`
  /// van con cuerpo vacío `{}`. Los estados desde los que se permite cada acción están en
  /// `FulfillmentStore.canCommand`.
  Future<dynamic> command(
    int id,
    String action, [
    Map<String, dynamic> body = const {},
  ]) => execute(() => _http.postJson('$endpointUrl/$id/$action', body));

  /// Crea una versión de la geocerca: `POST /api/deliveries/{id}/geofence-policies`.
  ///
  /// Cuerpo `{centerLatitude, centerLongitude, radiusMeters}`: latitud entre -90 y 90,
  /// longitud entre -180 y 180 y radio mayor que cero, en metros. Solo el distribuidor
  /// propietario puede crearla (403 si no, 404 si la entrega no existe). El backend guarda
  /// versiones (`policyVersion` empieza en 1 y suma 1 por cada POST) y responde 409
  /// (`GEOFENCEPOLICY_CONFLICT`) solo ante una escritura concurrente.
  Future<dynamic> geofence(int id, Map<String, dynamic> body) =>
      execute(() => _http.postJson('$endpointUrl/$id/geofence-policies', body));

  /// Asigna conductor y cisterna a un pedido: `POST /api/deliveries`.
  ///
  /// La app lee `deliveryId` de la respuesta y trata un 409 como conflicto de disponibilidad
  /// (ver `FulfillmentStore.assignDelivery`). El ledger también lista
  /// `POST /api/deliveries/{id}/assign`, que esta app no usa.
  Future<dynamic> assign(Map<String, dynamic> body) =>
      execute(() => _http.postJson(endpointUrl, body));
}
