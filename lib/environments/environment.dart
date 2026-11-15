/// Configuración de entorno (equivale a `environments/environment.ts`).
abstract final class Environment {
  static const production = true;

  /// URL base del API.
  static const serverBasePath = 'https://fuelguard.137-131-253-18.sslip.io/api';

  // Ordering (Solicitudes y Órdenes)
  static const orderingRequestsEndpointPath = '/replenishment-requests';
  static const orderingOrdersEndpointPath = '/fuel-orders';

  // Fulfillment (Entregas)
  static const fulfillmentDeliveriesEndpointPath = '/deliveries';

  /// Modo demo (bypass): las peticiones HTTP se resuelven en memoria. Persistido en prefs `fuelguard.demo`.
  static bool demoMode = false;
}
