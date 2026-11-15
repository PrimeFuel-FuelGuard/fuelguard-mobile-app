import 'dart:convert';

import '../../../iam/domain/model/session_entity.dart';

/// Mundo demo compartido: constantes que deben usar todos los [DemoHandler].
abstract final class DemoWorld {
  // Contraseña aceptada para cualquier usuario demo (en realidad cualquiera sirve).
  static const password = 'demo1234';

  // Usuarios
  static const buyerUserId = 1;
  static const buyerUsername = 'compras@mineraandina.pe';
  static const providerUserId = 2;
  static const providerUsername = 'ventas@petrosur.pe';
  static const adminUserId = 3;
  static const adminUsername = 'admin@fuelguard.app';

  // Empresa compradora principal
  static const buyerCompanyId = 10;
  static const buyerCompanyName = 'Minera Andina S.A.C.';
  static const buyerCompanyRuc = '20512345678';
  static const buyerCompanySector = 'Minería';
  static const buyerCompanyAddress = 'Av. Los Álamos 450, Arequipa';
  static const buyerCompanyPhone = '+51 54 238 910';
  static const buyerCompanyEmail = buyerUsername;

  // Segunda empresa compradora (cliente del proveedor 20)
  static const buyer2CompanyId = 11;
  static const buyer2CompanyName = 'Agroindustrial Costa Verde';
  static const buyer2CompanyRuc = '20587654321';
  static const buyer2CompanySector = 'Agroindustria';
  static const buyer2CompanyAddress = 'Km 12 Panamericana Sur, Ica';
  static const buyer2CompanyPhone = '+51 56 231 450';
  static const buyer2CompanyEmail = 'logistica@costaverde.pe';

  // Proveedores
  static const providerId = 20;
  static const providerName = 'PetroSur Distribuciones S.A.';
  static const providerRuc = '20698765432';
  static const providerAddress = 'Av. Industrial 1200, Arequipa';
  static const providerPhone = '+51 54 271 330';
  static const provider21Id = 21;
  static const provider21Name = 'Andes Fuel Logistics';
  static const provider22Id = 22;
  static const provider22Name = 'Grifos del Pacífico';

  // Organizaciones (membresías)
  static const buyerOrganizationId = 10;
  static const providerOrganizationId = 20;
  static const organizationRole = 'OWNER';

  // Rangos de IDs: [min, max]
  static const productIdRange = (100, 119);
  static const tankIdRange = (200, 219);
  static const requestIdRange = (300, 349);
  static const orderIdRange = (400, 449);
  static const paymentIdRange = (500, 549);
  static const deliveryIdRange = (600, 649);
  static const tankerIdRange = (700, 719);
  static const driverIdRange = (800, 819);
  static const notificationIdRange = (900, 949);

  // Productos del proveedor 20
  static const productDieselId = 100;
  static const productDieselName = 'Diesel B5 S50';
  static const productGasohol90Id = 101;
  static const productGasohol90Name = 'Gasohol 90';
  static const productGasohol95Id = 102;
  static const productGasohol95Name = 'Gasohol 95';
  static const productGlpId = 103;
  static const productGlpName = 'GLP Granel';
  // Productos del proveedor 21
  static const product21DieselId = 110;
  static const product21DieselName = 'Diesel B5';
  static const product21Gasohol97Id = 111;
  static const product21Gasohol97Name = 'Gasohol 97';

  // Tanques de la empresa 10
  static const tankMainId = 200;
  static const tankMainName = 'Tanque Principal Planta';
  static const tankMainCapacity = 20000;
  static const tankMainLevelPercent = 62;
  static const tankFleetId = 201;
  static const tankFleetName = 'Tanque Flota Volquetes';
  static const tankFleetCapacity = 10000;
  static const tankFleetLevelPercent = 18; // nivel bajo: dispara alerta
  static const tankCampId = 202;
  static const tankCampName = 'Generador Campamento';
  static const tankCampCapacity = 5000;
  static const tankCampLevelPercent = 85;
  // Tanques de la empresa 11
  static const tank2aId = 210;
  static const tank2bId = 211;

  /// JWT falso con `exp` en el año 2099.
  static String fakeJwt(int userId, String username) {
    String enc(Map<String, Object?> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    return '${enc({'alg': 'none', 'typ': 'JWT'})}.${enc({'sub': username, 'uid': userId, 'exp': 4070908800})}.demo';
  }

  static Session buyerSession() => Session(
    id: buyerUserId,
    username: buyerUsername,
    token: fakeJwt(buyerUserId, buyerUsername),
    roles: const ['ROLE_BUYER'],
    companyId: buyerCompanyId,
    providerId: null,
    memberships: const [
      Membership(organizationId: buyerOrganizationId, role: organizationRole),
    ],
  );

  static Session providerSession() => Session(
    id: providerUserId,
    username: providerUsername,
    token: fakeJwt(providerUserId, providerUsername),
    roles: const ['ROLE_PROVIDER'],
    companyId: null,
    providerId: providerId,
    memberships: const [
      Membership(
        organizationId: providerOrganizationId,
        role: organizationRole,
      ),
    ],
  );

  static Session adminSession() => Session(
    id: adminUserId,
    username: adminUsername,
    token: fakeJwt(adminUserId, adminUsername),
    roles: const ['ROLE_ADMIN'],
    companyId: null,
    providerId: null,
    memberships: const [],
  );

  /// Sesión demo para `BUYER`, `PROVIDER` o `ADMIN`.
  static Session sessionFor(String role) => switch (role) {
    'PROVIDER' => providerSession(),
    'ADMIN' => adminSession(),
    _ => buyerSession(),
  };
}
