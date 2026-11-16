# Fulfillment: entregas, seguimiento y geocerca en la app móvil

Este documento resume qué parte de los endpoints de entregas del backend (`fuelguard-platform`, carpeta `docs/api-ledger`) consume la app móvil, dónde está en el código y qué diferencias hay entre lo que documenta el backend y lo que muestra la app. No cambia ningún comportamiento de la app.

Fuentes del backend: `T01-A-rest-ledger.md`, `provider-deliveries.md` y `delivery-tracking.md`.

## Qué consume la app

Todas las llamadas salen de `DeliveryApiEndpoint` (`lib/fulfillment/infrastructure/delivery_api_endpoint.dart`), pasan por `FulfillmentApi` y las usa `FulfillmentStore` (`lib/fulfillment/application/fulfillment_store.dart`). La URL base es `Environment.serverBasePath` más `/deliveries`.

| Método del endpoint | Ruta del backend | Dónde se muestra |
|---|---|---|
| `list` | `GET /api/deliveries?date=` | Lista de entregas |
| `recommendation` | `GET /api/deliveries/recommendation` | Hoja de asignación |
| `assign` | `POST /api/deliveries` | Hoja de asignación |
| `detail` | `GET /api/deliveries/{id}` | Tarjeta de estado |
| `transitions` | `GET /api/deliveries/{id}/transitions` | Lista de transiciones |
| `timeline` | `GET /api/deliveries/{id}/timeline` | Cronología |
| `tracking` | `GET /api/deliveries/{id}/tracking` | Tarjeta de seguimiento |
| `samples` | `GET /api/deliveries/{id}/tracking/samples` | Lista de muestras |
| `valveObservations` | `GET /api/deliveries/{id}/valve-observations` | Tarjeta de válvula |
| `command` | `POST /api/deliveries/{id}/{start, arrive, complete, fail, cancel}` | Botones de acciones |
| `geofence` | `POST /api/deliveries/{id}/geofence-policies` | Formulario de geocerca |

Rutas del ledger que la app móvil no usa:

- `POST /api/deliveries/{id}/transport-evidence`: el backend la reserva al conductor asignado y la app solo tiene los roles comprador, distribuidor y administrador. El administrador solo exporta y borra evidencia (`admin_api.dart`).
- `POST /api/deliveries/{id}/assign` y `POST /api/deliveries/{id}/valve-observations`.

## Pruebas

Los tests de esta parte están en `test/fulfillment/`:

- `fulfillment_store_test.dart`: reglas de `canCommand`, validaciones y cuerpo de `deliveryCommand`, mapeo de errores de `saveGeofence`, secciones del detalle, descarte de respuestas viejas en `loadDeliveries`, conflicto 409 de `assignDelivery` y de `loadRecommendation`.
- `provider_delivery_entity_test.dart`: lectura y escritura de `ProviderDelivery`, `ValveObservation` y `DeliveryRecommendation` con el ejemplo de `provider-deliveries.md`.

Usan una API falsa en memoria, sin red ni dependencias nuevas. Se ejecutan con `flutter test`.

## Diferencias para decidir en equipo

Son observaciones comprobadas en el código y en los documentos del backend. Ninguna se corrigió.

1. **Geocerca: una sola frente a versionada.** La UI dice que una entrega admite una sola geocerca y que no se puede editar (`fulfillment.geofence-once`), y muestra un 409 como "ya existe" (`fulfillment.geofence-exists`). El backend documenta que cada POST crea una versión nueva (`policyVersion` empieza en 1 y suma 1) y que el 409 (`GEOFENCEPOLICY_CONFLICT`) ocurre solo ante una escritura concurrente. El modo demo responde 409 si ya existe una geocerca y no devuelve `policyVersion` ni `providerId`.
2. **Seguimiento sin datos.** El backend responde 404 en `GET /tracking` cuando la entrega todavía no recibió evidencia. `FulfillmentStore` toma cualquier error de esa carga como sección fallida, así que contra el backend real la tarjeta mostraría el mensaje de error y no "Aún no hay datos de seguimiento". El modo demo devuelve un objeto vacío y no reproduce el caso.
3. **Campos de muestras que la vista no muestra.** `latestAdvanced`, `receivedAt` y `accuracyMeters` llegan en `tracking/samples` pero la lista solo imprime hora, tipo, posición, hito, volumen y unidad.
4. **Evidencia de transporte.** Sin app de conductor, el flujo `POST /transport-evidence` no tiene cliente en este repositorio.

## Qué no se verificó

No se ejecutó ningún endpoint contra un entorno desplegado. Las rutas y los códigos de error salen de los documentos del backend y del código de la app. El detalle de `provider-recommendation.md` y `provider-valve-observations.md` no se revisó.
