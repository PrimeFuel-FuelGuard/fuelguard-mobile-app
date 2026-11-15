import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/equipment_entity.dart';
import '../domain/model/provider_equipment_entity.dart';

/// Endpoints /provider/* (solo ROLE_PROVIDER). El distribuidor lo deriva el backend del token.
class ProviderEquipmentApi extends ErrorHandlingEnabledBaseType {
  ProviderEquipmentApi(this._http);

  final AppHttpClient _http;
  static const _base = '${Environment.serverBasePath}/provider';

  String _url(String path, Map<String, String> query) =>
      Uri.parse('$_base$path')
          .replace(queryParameters: query.isEmpty ? null : query)
          .toString();

  Future<List<ProviderBuyerCompany>> buyerCompanies() async => [
    for (final e in (await execute(
      () => _http.getJson('$_base/buyer-companies'),
    ) as List))
      ProviderBuyerCompany.fromJson(e as Map<String, dynamic>),
  ];

  Future<BuyerLookup> lookupBuyer(String ruc) async => BuyerLookup.fromJson(
    await execute(
      () => _http.getJson(_url('/buyer-companies/lookup', {'ruc': ruc})),
    ) as Map<String, dynamic>,
  );

  /// [body]: `NewBuyerCompany` o `{ 'buyerCompanyId': int }`.
  Future<ProviderBuyerCompany> registerBuyerCompany(Object body) async {
    final payload = body is NewBuyerCompany ? body.toJson() : body;
    return ProviderBuyerCompany.fromJson(
      await execute(() => _http.postJson('$_base/buyer-companies', payload))
          as Map<String, dynamic>,
    );
  }

  /// `buyerCompanyId` falsy (null o 0) no filtra.
  Future<List<ProviderTank>> tanks([int? buyerCompanyId]) async {
    final url = _url('/tanks', {
      if (buyerCompanyId != null && buyerCompanyId != 0)
        'buyerCompanyId': '$buyerCompanyId',
    });
    return [
      for (final e in (await execute(() => _http.getJson(url)) as List))
        ProviderTank.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<ProviderTank> tank(int id) async => ProviderTank.fromJson(
    await execute(() => _http.getJson('$_base/tanks/$id'))
        as Map<String, dynamic>,
  );

  Future<ProviderTank> registerTank(NewProviderTank body) async =>
      ProviderTank.fromJson(
        await execute(() => _http.postJson('$_base/tanks', body.toJson()))
            as Map<String, dynamic>,
      );

  Future<ProviderTank> updateTank(int id, ProviderTankUpdate body) async =>
      ProviderTank.fromJson(
        await execute(() => _http.putJson('$_base/tanks/$id', body.toJson()))
            as Map<String, dynamic>,
      );

  Future<List<ProviderTankReading>> readings(
    int id, [
    String? from,
    String? to,
  ]) async {
    final url = _url('/tanks/$id/readings', {
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    });
    return [
      for (final e in (await execute(() => _http.getJson(url)) as List))
        ProviderTankReading.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<List<RefillEpisode>> episodes(int id) async => [
    for (final e in (await execute(
      () => _http.getJson('$_base/tanks/$id/refill-episodes'),
    ) as List))
      RefillEpisode.fromJson(e as Map<String, dynamic>),
  ];
}

/// LITRE|LITERS -> unit.liters, GALLON|GALLONS -> unit.gallons (clave i18n existente).
String unitKey(String? unit) =>
    (unit?.startsWith('GALLON') ?? false) ? 'unit.gallons' : 'unit.liters';

const Map<String, String> _errorKeys = {
  'DEVICEBINDING_CONFLICT': 'provider-equipment.err-device-duplicate',
  'BUYERCOMPANY_CONFLICT': 'provider-equipment.err-ruc-duplicate',
  'PROVIDERBUYERLINK_CONFLICT': 'provider-equipment.err-already-linked',
  'BUYERCOMPANY_NOT_FOUND': 'provider-equipment.err-buyer-not-found',
  'FUELPRODUCT_NOT_FOUND': 'provider-equipment.err-product-not-found',
  'TANK_NOT_FOUND': 'provider-equipment.err-tank-not-found',
  'LOOKUP_RATE_LIMITED': 'provider-equipment.err-lookup-rate-limited',
  'VALIDATION_ERROR': 'errors.http-400',
};

/// Error de /provider/* -> clave i18n; nunca expone `details` (viene en inglés fijo).
String providerErrorKey(Object? e) {
  final status = e is ApiException ? e.status : null;
  final Object? code = e is ApiException
      ? (e.body == null ? null : e.body!['code'])
      : null;
  return _errorKeys[code] ??
      (const [400, 401, 403, 404, 409, 422].contains(status)
          ? 'errors.http-$status'
          : status == 0
          ? 'errors.network'
          : 'equipment.request-failed');
}
