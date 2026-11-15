import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/analytics_entity.dart';

class AnalyticsApi extends ErrorHandlingEnabledBaseType {
  AnalyticsApi(this._http);

  final AppHttpClient _http;
  static const _base = '${Environment.serverBasePath}/analytics';

  Future<ProviderAnalytics> getProviderAnalytics(
    int providerId, [
    String? from,
    String? to,
  ]) async {
    final query = <String, String>{
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final uri = Uri.parse('$_base/providers/$providerId')
        .replace(queryParameters: query.isEmpty ? null : query);
    return ProviderAnalytics.fromJson(
      await execute(() => _http.getJson(uri.toString()))
          as Map<String, dynamic>,
    );
  }

  Future<PlatformSummary> getPlatformSummary() async =>
      PlatformSummary.fromJson(
        await execute(() => _http.getJson('$_base/platform'))
            as Map<String, dynamic>,
      );

  Future<BuyerAnalytics> getBuyerAnalytics(int companyId) async =>
      BuyerAnalytics.fromJson(
        await execute(() => _http.getJson('$_base/buyers/$companyId'))
            as Map<String, dynamic>,
      );
}
