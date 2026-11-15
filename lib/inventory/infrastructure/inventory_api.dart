import '../../environments/environment.dart';
import '../../equipment/domain/model/equipment_entity.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/fuel_product_entity.dart';
import 'product_api_endpoint.dart';

class InventoryApi extends ErrorHandlingEnabledBaseType {
  InventoryApi(this._http) : _endpoint = ProductApiEndpoint(_http);

  final AppHttpClient _http;
  final ProductApiEndpoint _endpoint;

  Future<List<FuelProduct>> getAllProducts() => _endpoint.getAll();

  Future<List<IdName>> getProviders() async => [
    for (final e in (await execute(
      () => _http.getJson('${Environment.serverBasePath}/provider-companies'),
    ) as List))
      IdName.fromJson(e as Map<String, dynamic>),
  ];

  Future<List<FuelProduct>> getProductsByProvider(int providerId) =>
      _endpoint.getByProvider(providerId);
  Future<FuelProduct> getProductById(int id) => _endpoint.getById(id);
  Future<FuelProduct> createProduct(CreateProductPayload payload) =>
      _endpoint.createProduct(payload);
  Future<FuelProduct> updateProduct(int id, UpdateProductPayload payload) =>
      _endpoint.updateProduct(id, payload);
  Future<FuelProduct> updateStock(int id, double stock) =>
      _endpoint.updateStock(id, stock);
  Future<void> deleteProduct(int id) => _endpoint.delete(id);
}
