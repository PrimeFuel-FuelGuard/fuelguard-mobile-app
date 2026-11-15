import '../../shared/infrastructure/base_assembler.dart';
import '../domain/model/driver_entity.dart';
import 'driver_response.dart';

/// Assembler para transformar conductores entre capas (DriverResource ↔ Driver).
class DriverAssembler
    implements BaseAssembler<Driver, DriverResource, List<DriverResource>> {
  @override
  DriverResource resourceFromJson(Map<String, dynamic> json) =>
      DriverResource.fromJson(json);

  @override
  List<Driver> toEntitiesFromResponse(List<DriverResource> response) => [
    for (final r in response) toEntityFromResource(r),
  ];

  @override
  Driver toEntityFromResource(DriverResource resource) => Driver(
    id: resource.id,
    providerId: resource.providerId,
    userId: resource.userId,
    active: resource.active,
    firstName: resource.firstName,
    lastName: resource.lastName,
    licenseNumber: resource.licenseNumber,
    phoneNumber: resource.phoneNumber,
    email: resource.email,
    status: resource.status,
    createdAt: '',
  );

  @override
  DriverResource toResourceFromEntity(Driver entity) => DriverResource(
    id: entity.id,
    providerId: entity.providerId,
    userId: entity.userId,
    firstName: entity.firstName,
    lastName: entity.lastName,
    licenseNumber: entity.licenseNumber,
    phoneNumber: entity.phoneNumber,
    email: entity.email,
    status: entity.status,
    active: entity.active,
  );
}
