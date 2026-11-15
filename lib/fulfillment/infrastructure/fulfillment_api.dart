import '../../iam/infrastructure/auth_interceptor.dart';
import '../domain/model/driver_entity.dart';
import '../domain/model/provider_delivery_entity.dart';
import '../domain/model/tanker_entity.dart';
import 'delivery_api_endpoint.dart';
import 'driver_api_endpoint.dart';
import 'driver_response.dart';
import 'tanker_api_endpoint.dart';

/// API gateway del bounded context Fulfillment.
///
/// Agrega TankerApiEndpoint, DriverApiEndpoint y DeliveryApiEndpoint. El distribuidor lo deriva el
/// backend del token, por eso ningún método recibe providerId.
class FulfillmentApi {
  FulfillmentApi(AppHttpClient http)
    : _tankerEndpoint = TankerApiEndpoint(http),
      _driverEndpoint = DriverApiEndpoint(http),
      _deliveryEndpoint = DeliveryApiEndpoint(http);

  final TankerApiEndpoint _tankerEndpoint;
  final DriverApiEndpoint _driverEndpoint;
  final DeliveryApiEndpoint _deliveryEndpoint;

  // ── Tankers ──
  Future<List<Tanker>> getTankers() => _tankerEndpoint.list();
  Future<List<Tanker>> getEligibleTankers() => _tankerEndpoint.list(true);
  Future<Tanker> getTankerById(int id) => _tankerEndpoint.get(id);
  Future<Tanker> registerTanker(TankerInput request) =>
      _tankerEndpoint.save(request.toJson());

  /// [request] equivale a `Partial<TankerInput>`.
  Future<Tanker> updateTanker(int id, Map<String, dynamic> request) =>
      _tankerEndpoint.save(request, id);

  /// `request.status` es `Pick<Tanker, 'status'>`.
  Future<Tanker> updateTankerStatus(int id, String status) =>
      _tankerEndpoint.setActive(id, status != 'INACTIVE');
  Future<EligibilityResult> checkTankerEligibility(int id) =>
      _tankerEndpoint.eligibility(id);

  // ── Drivers ──
  Future<List<Driver>> getDrivers() => _driverEndpoint.list();
  Future<List<Driver>> getEligibleDrivers() => _driverEndpoint.list(true);
  Future<Driver> getDriverById(int id) => _driverEndpoint.get(id);
  Future<Driver> registerDriver(DriverInput request) =>
      _driverEndpoint.save(request.toJson());

  /// [request] equivale a `Partial<Omit<Driver, 'id' | 'providerId' | 'createdAt'>>`.
  Future<Driver> updateDriver(int id, Map<String, dynamic> request) =>
      _driverEndpoint.save(request, id);

  /// `request.status` es `Pick<Driver, 'status'>`.
  Future<Driver> updateDriverStatus(int id, String status) =>
      _driverEndpoint.setActive(id, status != 'INACTIVE');
  Future<EligibilityResult> checkDriverEligibility(int id) =>
      _driverEndpoint.eligibility(id);

  // ── Deliveries ──
  Future<List<ProviderDelivery>> deliveries([String? date]) =>
      _deliveryEndpoint.list(date);
  Future<DeliveryRecommendation> recommendation(
    int orderId, [
    String? windowStart,
    String? windowEnd,
  ]) => _deliveryEndpoint.recommendation(orderId, windowStart, windowEnd);
  Future<List<ValveObservation>> valveObservations(int id) =>
      _deliveryEndpoint.valveObservations(id);
  Future<dynamic> delivery(int id) => _deliveryEndpoint.detail(id);
  Future<dynamic> tracking(int id) => _deliveryEndpoint.tracking(id);
  Future<List<dynamic>> trackingSamples(int id) =>
      _deliveryEndpoint.samples(id);
  Future<List<dynamic>> deliveryTransitions(int id) =>
      _deliveryEndpoint.transitions(id);
  Future<List<dynamic>> deliveryTimeline(int id) =>
      _deliveryEndpoint.timeline(id);
  Future<dynamic> deliveryCommand(
    int id,
    String action, [
    Map<String, dynamic> body = const {},
  ]) => _deliveryEndpoint.command(id, action, body);
  Future<dynamic> createGeofence(int id, Map<String, dynamic> body) =>
      _deliveryEndpoint.geofence(id, body);
  Future<dynamic> assignDelivery(Map<String, dynamic> body) =>
      _deliveryEndpoint.assign(body);
}
