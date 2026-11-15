import '../../shared/infrastructure/base_assembler.dart';
import '../domain/model/tanker_entity.dart';
import 'tanker_response.dart';

class TankerAssembler
    implements BaseAssembler<Tanker, TankerResource, List<TankerResource>> {
  @override
  TankerResource resourceFromJson(Map<String, dynamic> json) =>
      TankerResource.fromJson(json);

  @override
  List<Tanker> toEntitiesFromResponse(List<TankerResource> response) => [
    for (final r in response) toEntityFromResource(r),
  ];

  @override
  Tanker toEntityFromResource(TankerResource resource) => Tanker(
    id: resource.id,
    providerId: resource.providerId,
    active: resource.active,
    licensePlate: resource.licensePlate,
    model: resource.model,
    brand: resource.brand,
    capacity: resource.capacity,
    unit: resource.unit,
    status: resource.status,
    createdAt: '',
  );

  @override
  TankerResource toResourceFromEntity(Tanker entity) => TankerResource(
    id: entity.id,
    providerId: entity.providerId,
    licensePlate: entity.licensePlate,
    brand: entity.brand,
    model: entity.model,
    capacity: entity.capacity,
    unit: entity.unit,
    status: entity.status,
    active: entity.active,
  );
}
