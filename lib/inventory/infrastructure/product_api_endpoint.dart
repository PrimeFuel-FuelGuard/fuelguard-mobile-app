import '../../iam/infrastructure/auth_interceptor.dart';
import '../../environments/environment.dart';
import '../../shared/infrastructure/base_api_endpoint.dart';
import '../domain/model/fuel_product_entity.dart';
import 'product_assembler.dart';
import 'product_response.dart';

class ProductApiEndpoint
    extends
        BaseApiEndpoint<
          FuelProduct,
          ProductResource,
          ProductsResponse,
          ProductAssembler
        > {
  ProductApiEndpoint(AppHttpClient http)
    : super(
        http,
        '${Environment.serverBasePath}/fuel-products',
        ProductAssembler(),
      );

  ProductsResponse _resources(dynamic json) => [
    for (final e in (json as List))
      assembler.resourceFromJson(e as Map<String, dynamic>),
  ];

  FuelProduct _one(dynamic json) => assembler.toEntityFromResource(
    assembler.resourceFromJson(json as Map<String, dynamic>),
  );

  @override
  Future<List<FuelProduct>> getAll() async => assembler.toEntitiesFromResponse(
    _resources(
      await execute(
        () => http.getJson(endpointUrl),
        operation: 'Failed to fetch products',
      ),
    ),
  );

  Future<List<FuelProduct>> getByProvider(int providerId) async =>
      assembler.toEntitiesFromResponse(
        _resources(
          await execute(
            () => http.getJson('$endpointUrl/provider/$providerId'),
            operation: 'Failed to fetch provider products',
          ),
        ),
      );

  @override
  Future<FuelProduct> getById(int id) async => _one(
    await execute(
      () => http.getJson('$endpointUrl/$id'),
      operation: 'Failed to fetch product',
    ),
  );

  Future<FuelProduct> createProduct(CreateProductPayload request) async => _one(
    await execute(
      () => http.postJson(endpointUrl, request.toJson()),
      operation: 'Failed to create product',
    ),
  );

  Future<FuelProduct> updateProduct(
    int id,
    UpdateProductPayload request,
  ) async => _one(
    await execute(
      () => http.putJson('$endpointUrl/$id', request.toJson()),
      operation: 'Failed to update product',
    ),
  );

  Future<FuelProduct> updateStock(int id, double newStock) async => _one(
    await execute(
      () => http.postJson('$endpointUrl/$id/update-stock', {
        'newStock': newStock,
      }),
      operation: 'Failed to update stock',
    ),
  );

  @override
  Future<void> delete(int id) async {
    await execute(
      () => http.deleteJson('$endpointUrl/$id'),
      operation: 'Failed to delete product',
    );
  }
}
