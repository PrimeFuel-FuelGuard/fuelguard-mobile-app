import 'package:flutter_test/flutter_test.dart';
import 'package:fuelguard_mobile_app/fulfillment/domain/model/provider_delivery_entity.dart';

/// Respuesta de `GET /api/deliveries` según `provider-deliveries.md` del backend.
Map<String, dynamic> _json() => {
  'id': 58,
  'orderId': 91,
  'status': 'DISPATCHED',
  'physicalState': 'ASSIGNED',
  'driver': {'id': 8, 'firstName': 'Ana', 'lastName': 'Díaz'},
  'tanker': {'id': 12, 'licensePlate': 'ABC-123'},
  'scheduledDate': '2026-10-02',
  'windowStart': '2026-10-02T13:00:00Z',
  'windowEnd': '2026-10-02T15:00:00Z',
  'buyerCompanyId': 4,
  'buyerCompanyName': 'Comprador SAC',
  'customerAccountId': 7,
  'siteId': 10,
  'deliveryAddress': 'Planta Lima',
  'requestedVolume': 800.0,
  'unit': 'LITRE',
  'deliveredVolume': null,
};

void main() {
  group('ProviderDelivery', () {
    test('lee la respuesta documentada del backend', () {
      final d = ProviderDelivery.fromJson(_json());

      expect(d.id, 58);
      expect(d.orderId, 91);
      expect(d.status, 'DISPATCHED');
      expect(d.physicalState, DeliveryPhysicalState.assigned);
      expect(d.driver?.firstName, 'Ana');
      expect(d.tanker?.licensePlate, 'ABC-123');
      expect(d.requestedVolume, 800.0);
      expect(d.deliveredVolume, isNull);
    });

    test('toJson devuelve el mismo contenido que se leyó', () {
      expect(ProviderDelivery.fromJson(_json()).toJson(), _json());
    });

    test('acepta enteros donde el modelo espera decimales', () {
      final d = ProviderDelivery.fromJson({..._json(), 'requestedVolume': 800});

      expect(d.requestedVolume, 800.0);
    });

    test('los datos heredados ausentes quedan en null', () {
      final d = ProviderDelivery.fromJson({
        'id': 1,
        'orderId': 2,
        'status': 'DISPATCHED',
        'physicalState': 'ASSIGNED',
      });

      expect(d.driver, isNull);
      expect(d.tanker, isNull);
      expect(d.windowStart, isNull);
      expect(d.buyerCompanyName, isNull);
      expect(d.requestedVolume, isNull);
    });

    test('copyWith cambia solo estado y volumen entregado', () {
      final d = ProviderDelivery.fromJson(_json()).copyWith(
        physicalState: DeliveryPhysicalState.completed,
        deliveredVolume: 790.5,
      );

      expect(d.physicalState, DeliveryPhysicalState.completed);
      expect(d.deliveredVolume, 790.5);
      expect(d.status, 'DISPATCHED');
      expect(d.orderId, 91);
    });
  });

  test('DeliveryPhysicalState lista los siete estados del ciclo', () {
    expect(DeliveryPhysicalState.values, [
      'ASSIGNED',
      'STARTED',
      'ARRIVED',
      'DELIVERING',
      'COMPLETED',
      'FAILED',
      'CANCELLED',
    ]);
  });

  group('ValveObservation', () {
    test('lee y escribe una observación', () {
      final json = {
        'id': 3,
        'state': 'OPEN',
        'unauthorized': true,
        'commandId': null,
        'recordedAt': '2026-10-02T14:00:00Z',
      };

      final v = ValveObservation.fromJson(json);

      expect(v.state, ValveState.open);
      expect(v.unauthorized, isTrue);
      expect(v.commandId, isNull);
      expect(v.toJson(), json);
    });
  });

  group('DeliveryRecommendation', () {
    test('lee una recomendación con cisterna y conductor', () {
      final json = {
        'orderId': 91,
        'recommended': true,
        'reason': null,
        'driverId': 8,
        'driverName': 'Ana Díaz',
        'tankerId': 12,
        'licensePlate': 'ABC-123',
        'tankerCapacityLitres': 30000.0,
        'requestedVolumeLitres': 22712.0,
        'windowStart': '2026-10-02T13:00:00Z',
        'windowEnd': '2026-10-02T15:00:00Z',
        'criterion': 'MIN_SUFFICIENT_CAPACITY',
      };

      final r = DeliveryRecommendation.fromJson(json);

      expect(r.recommended, isTrue);
      expect(r.driverName, 'Ana Díaz');
      expect(r.tankerCapacityLitres, 30000.0);
      expect(r.toJson(), json);
    });

    test('sin recomendación trae el motivo y no trae recursos', () {
      final r = DeliveryRecommendation.fromJson({
        'orderId': 91,
        'recommended': false,
        'reason': 'NO_ELIGIBLE_DRIVER',
        'requestedVolumeLitres': 22712,
        'windowStart': '2026-10-02T13:00:00Z',
        'windowEnd': '2026-10-02T15:00:00Z',
        'criterion': 'MIN_SUFFICIENT_CAPACITY',
      });

      expect(r.recommended, isFalse);
      expect(r.reason, 'NO_ELIGIBLE_DRIVER');
      expect(r.driverId, isNull);
      expect(r.tankerId, isNull);
      expect(r.requestedVolumeLitres, 22712.0);
    });
  });
}
