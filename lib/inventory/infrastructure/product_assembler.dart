import '../../shared/infrastructure/base_assembler.dart';
import '../domain/model/fuel_product_entity.dart';
import 'product_response.dart';

class ProductAssembler
    implements BaseAssembler<FuelProduct, ProductResource, ProductsResponse> {
  @override
  ProductResource resourceFromJson(Map<String, dynamic> json) =>
      ProductResource.fromJson(json);

  @override
  List<FuelProduct> toEntitiesFromResponse(ProductsResponse response) => [
    for (final r in response) toEntityFromResource(r),
  ];

  @override
  FuelProduct toEntityFromResource(ProductResource resource) =>
      FuelProduct.fromJson(resource.toJson());

  @override
  ProductResource toResourceFromEntity(FuelProduct entity) =>
      ProductResource.fromJson(entity.toJson());
}
