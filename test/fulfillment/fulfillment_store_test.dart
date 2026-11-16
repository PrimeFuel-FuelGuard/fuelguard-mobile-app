import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuelguard_mobile_app/fulfillment/application/fulfillment_store.dart';
import 'package:fuelguard_mobile_app/fulfillment/domain/model/driver_entity.dart';
import 'package:fuelguard_mobile_app/fulfillment/domain/model/provider_delivery_entity.dart';
import 'package:fuelguard_mobile_app/fulfillment/domain/model/tanker_entity.dart';
import 'package:fuelguard_mobile_app/fulfillment/infrastructure/fulfillment_api.dart';
import 'package:fuelguard_mobile_app/shared/infrastructure/error_handling_enabled_base_type.dart';

/// API falsa: solo implementa lo que usa `FulfillmentStore` en estos tests.
class _FakeApi implements FulfillmentApi {
  String physicalState = 'ASSIGNED';
  int detailCalls = 0;
  int availableDriverCalls = 0;
  int availableTankerCalls = 0;
  final commands = <(int, String, Map<String, dynamic>)>[];
  final geofences = <(int, Map<String, dynamic>)>[];
  Object? commandError;
  Object? geofenceError;
  Object? trackingError;
  Object? assignError;
  Object? recommendationError;
  Map<String, dynamic> assignResult = {'deliveryId': 77};
  Future<List<ProviderDelivery>> Function(String? date)? deliveriesHandler;

  @override
  Future<List<ProviderDelivery>> deliveries([String? date]) =>
      deliveriesHandler!(date);

  @override
  Future<dynamic> delivery(int id) async {
    detailCalls++;
    return {
      'id': id,
      'orderId': 5,
      'driverId': 1,
      'vehicleId': 2,
      'physicalState': physicalState,
    };
  }

  @override
  Future<dynamic> tracking(int id) async {
    if (trackingError != null) throw trackingError!;
    return {'deliveryId': id, 'loaded': false};
  }

  @override
  Future<List<dynamic>> trackingSamples(int id) async => [];

  @override
  Future<List<dynamic>> deliveryTransitions(int id) async => [];

  @override
  Future<List<dynamic>> deliveryTimeline(int id) async => [];

  @override
  Future<List<ValveObservation>> valveObservations(int id) async => [];

  @override
  Future<Driver> getDriverById(int id) =>
      Future.error(const ApiException('sin conductor'));

  @override
  Future<Tanker> getTankerById(int id) =>
      Future.error(const ApiException('sin cisterna'));

  @override
  Future<dynamic> deliveryCommand(
    int id,
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    if (commandError != null) throw commandError!;
    commands.add((id, action, body));
    return null;
  }

  @override
  Future<dynamic> createGeofence(int id, Map<String, dynamic> body) async {
    if (geofenceError != null) throw geofenceError!;
    geofences.add((id, body));
    return {'id': 1, 'deliveryId': id, ...body, 'policyVersion': 1};
  }

  @override
  Future<dynamic> assignDelivery(Map<String, dynamic> body) async {
    if (assignError != null) throw assignError!;
    return assignResult;
  }

  @override
  Future<List<Driver>> getEligibleDrivers() async {
    availableDriverCalls++;
    return [];
  }

  @override
  Future<List<Tanker>> getEligibleTankers() async {
    availableTankerCalls++;
    return [];
  }

  @override
  Future<DeliveryRecommendation> recommendation(
    int orderId, [
    String? windowStart,
    String? windowEnd,
  ]) async {
    if (recommendationError != null) throw recommendationError!;
    return DeliveryRecommendation.fromJson({
      'orderId': orderId,
      'recommended': true,
      'requestedVolumeLitres': 1000,
      'windowStart': '2026-11-15T08:00:00-05:00',
      'windowEnd': '2026-11-15T12:00:00-05:00',
      'criterion': 'MIN_SUFFICIENT_CAPACITY',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _deliveryJson(int id) => {
  'id': id,
  'orderId': 5,
  'status': 'DISPATCHED',
  'physicalState': 'ASSIGNED',
};

void main() {
  late _FakeApi api;
  late FulfillmentStore store;

  setUp(() {
    api = _FakeApi();
    store = FulfillmentStore(api);
  });

  tearDown(() => store.dispose());

  // Las tuplas con mapas no se comparan por contenido, por eso se revisa campo a campo.
  void expectCommands(List<(int, String, Map<String, dynamic>)> expected) {
    expect(api.commands.length, expected.length);
    for (var i = 0; i < expected.length; i++) {
      expect(api.commands[i].$1, expected[i].$1);
      expect(api.commands[i].$2, expected[i].$2);
      expect(api.commands[i].$3, expected[i].$3);
    }
  }

  Future<List<String>> allowedActions(String state) async {
    api.physicalState = state;
    await store.reloadDelivery(1);
    return [
      for (final a in const ['start', 'arrive', 'complete', 'fail', 'cancel'])
        if (store.canCommand(a)) a,
    ];
  }

  group('canCommand', () {
    test('sin entrega cargada no permite ninguna acción', () {
      expect(store.canCommand('start'), isFalse);
      expect(store.canCommand('cancel'), isFalse);
    });

    test('depende del estado físico', () async {
      expect(await allowedActions('ASSIGNED'), ['start', 'fail', 'cancel']);
      expect(await allowedActions('STARTED'), ['arrive', 'fail', 'cancel']);
      expect(await allowedActions('ARRIVED'), ['complete', 'fail', 'cancel']);
      expect(await allowedActions('DELIVERING'), [
        'complete',
        'fail',
        'cancel',
      ]);
    });

    test('los estados finales no permiten acciones', () async {
      expect(await allowedActions('COMPLETED'), isEmpty);
      expect(await allowedActions('FAILED'), isEmpty);
      expect(await allowedActions('CANCELLED'), isEmpty);
    });

    test('una acción desconocida nunca se permite', () async {
      api.physicalState = 'ASSIGNED';
      await store.reloadDelivery(1);
      expect(store.canCommand('reopen'), isFalse);
    });
  });

  group('deliveryCommand', () {
    test('start envía cuerpo vacío y recarga el detalle', () async {
      api.physicalState = 'ASSIGNED';
      await store.reloadDelivery(1);
      final before = api.detailCalls;

      await store.deliveryCommand(1, 'start');

      expectCommands([(1, 'start', <String, dynamic>{})]);
      expect(api.detailCalls, before + 1);
      expect(store.commandBusy, isFalse);
      expect(store.error, isNull);
    });

    test('complete envía deliveredVolume', () async {
      api.physicalState = 'ARRIVED';
      await store.reloadDelivery(1);

      await store.deliveryCommand(1, 'complete', deliveredVolume: 12.5);

      expectCommands([
        (1, 'complete', <String, dynamic>{'deliveredVolume': 12.5}),
      ]);
    });

    test('complete sin volumen válido no llama al backend', () async {
      api.physicalState = 'ARRIVED';
      await store.reloadDelivery(1);

      await store.deliveryCommand(1, 'complete');
      await store.deliveryCommand(1, 'complete', deliveredVolume: 0);
      await store.deliveryCommand(1, 'complete', deliveredVolume: -3);
      await store.deliveryCommand(1, 'complete', deliveredVolume: double.nan);
      await store.deliveryCommand(
        1,
        'complete',
        deliveredVolume: double.infinity,
      );

      expect(api.commands, isEmpty);
    });

    test('fail y cancel exigen motivo y lo envían', () async {
      api.physicalState = 'STARTED';
      await store.reloadDelivery(1);

      await store.deliveryCommand(1, 'fail', reason: '   ');
      await store.deliveryCommand(1, 'cancel');
      expect(api.commands, isEmpty);

      await store.deliveryCommand(1, 'fail', reason: 'Camino cortado');
      expectCommands([
        (1, 'fail', <String, dynamic>{'reason': 'Camino cortado'}),
      ]);
    });

    test('una acción no permitida en el estado actual se ignora', () async {
      api.physicalState = 'COMPLETED';
      await store.reloadDelivery(1);

      await store.deliveryCommand(1, 'start');

      expect(api.commands, isEmpty);
    });

    test('si el backend falla deja el error y libera el botón', () async {
      api.physicalState = 'ASSIGNED';
      await store.reloadDelivery(1);
      api.commandError = const ApiException('boom', status: 409);

      await store.deliveryCommand(1, 'start');

      expect(store.error, 'fulfillment.command-failed');
      expect(store.commandBusy, isFalse);
    });
  });

  group('saveGeofence', () {
    test('envía el cuerpo documentado y avisa el éxito', () async {
      await store.saveGeofence(
        9,
        latitude: -12.04,
        longitude: -77.03,
        radiusMeters: 500,
      );

      expect(api.geofences.length, 1);
      expect(api.geofences.single.$1, 9);
      expect(api.geofences.single.$2, <String, dynamic>{
        'centerLatitude': -12.04,
        'centerLongitude': -77.03,
        'radiusMeters': 500.0,
      });
      expect(store.successMsg, 'fulfillment.geofence-saved');
      expect(store.error, isNull);
      expect(store.geofenceBusy, isFalse);
    });

    test('un 409 se muestra como geocerca existente', () async {
      api.geofenceError = const ApiException('conflict', status: 409);

      await store.saveGeofence(9, latitude: 0, longitude: 0, radiusMeters: 100);

      expect(store.error, 'fulfillment.geofence-exists');
      expect(store.successMsg, isNull);
      expect(store.geofenceBusy, isFalse);
    });

    test('cualquier otro error es un fallo genérico de geocerca', () async {
      api.geofenceError = const ApiException('forbidden', status: 403);

      await store.saveGeofence(9, latitude: 0, longitude: 0, radiusMeters: 100);

      expect(store.error, 'fulfillment.geofence-failed');
    });
  });

  group('seguimiento', () {
    test('un 404 en tracking marca solo esa sección como fallida', () async {
      api.trackingError = const ApiException('sin seguimiento', status: 404);

      await store.reloadDelivery(1);

      expect(store.sectionFailed(DeliverySection.tracking), isTrue);
      expect(store.sectionFailed(DeliverySection.detail), isFalse);
      expect(store.sectionFailed(DeliverySection.samples), isFalse);
      expect(store.tracking, isNull);
      expect(store.delivery, isNotNull);
    });

    test('con seguimiento disponible la sección carga sin fallos', () async {
      await store.reloadDelivery(1);

      expect(store.sectionFailed(DeliverySection.tracking), isFalse);
      expect(store.tracking, {'deliveryId': 1, 'loaded': false});
      expect(store.valve, isEmpty);
    });
  });

  group('loadDeliveries', () {
    test('descarta la respuesta de una petición anterior', () async {
      final byDate = <String?, Completer<List<ProviderDelivery>>>{
        '2026-11-01': Completer(),
        '2026-11-02': Completer(),
      };
      api.deliveriesHandler = (date) => byDate[date]!.future;

      final first = store.loadDeliveries('2026-11-01');
      final second = store.loadDeliveries('2026-11-02');
      byDate['2026-11-02']!.complete([
        ProviderDelivery.fromJson(_deliveryJson(2)),
      ]);
      await second;
      byDate['2026-11-01']!.complete([
        ProviderDelivery.fromJson(_deliveryJson(1)),
      ]);
      await first;

      expect([for (final d in store.deliveries) d.id], [2]);
      expect(store.isLoading, isFalse);
    });

    test('si falla deja la lista vacía y el error', () async {
      api.deliveriesHandler = (_) =>
          Future.error(const ApiException('errors.network', status: 0));

      await store.loadDeliveries();

      expect(store.deliveries, isEmpty);
      expect(store.error, 'errors.network');
      expect(store.isLoading, isFalse);
    });
  });

  group('assignDelivery', () {
    test('devuelve el id de la entrega creada', () async {
      expect(await store.assignDelivery({'orderId': 5}), 77);
      expect(store.error, isNull);
    });

    test('un 409 recarga disponibilidad y avisa el conflicto', () async {
      api.assignError = const ApiException('conflict', status: 409);

      expect(await store.assignDelivery({'orderId': 5}), isNull);

      expect(store.error, 'fulfillment.assignment.conflict');
      expect(api.availableDriverCalls, 1);
      expect(api.availableTankerCalls, 1);
    });

    test('otro error no recarga y avisa el fallo', () async {
      api.assignError = const ApiException('boom', status: 500);

      expect(await store.assignDelivery({'orderId': 5}), isNull);

      expect(store.error, 'fulfillment.assignment-failed');
      expect(api.availableDriverCalls, 0);
      expect(api.availableTankerCalls, 0);
    });
  });

  group('loadRecommendation', () {
    test('carga la sugerencia', () async {
      await store.loadRecommendation(5);

      expect(store.recommendation?.orderId, 5);
      expect(store.recommendationError, isNull);
      expect(store.recommendationLoading, isFalse);
    });

    test('un 409 usa la clave de conflicto', () async {
      api.recommendationError = const ApiException('conflict', status: 409);

      await store.loadRecommendation(5);

      expect(store.recommendation, isNull);
      expect(store.recommendationError, 'fulfillment.recommendation.conflict');
    });

    test('otro error usa el mensaje de la excepción', () async {
      api.recommendationError = const ApiException(
        'errors.server',
        status: 500,
      );

      await store.loadRecommendation(5);

      expect(store.recommendationError, 'errors.server');
    });
  });
}
