import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';

/// Datos demo de IAM: usuarios, empresas, organizaciones, invitaciones y autenticación.
class IamDemoHandler implements DemoHandler {
  // Usuarios: id -> {username, roles, companyId, providerId}
  final Map<int, Map<String, dynamic>> _users = {
    DemoWorld.buyerUserId: {
      'id': DemoWorld.buyerUserId,
      'username': DemoWorld.buyerUsername,
      'roles': ['ROLE_BUYER'],
      'companyId': DemoWorld.buyerCompanyId,
      'providerId': null,
    },
    DemoWorld.providerUserId: {
      'id': DemoWorld.providerUserId,
      'username': DemoWorld.providerUsername,
      'roles': ['ROLE_PROVIDER'],
      'companyId': null,
      'providerId': DemoWorld.providerId,
    },
    DemoWorld.adminUserId: {
      'id': DemoWorld.adminUserId,
      'username': DemoWorld.adminUsername,
      'roles': ['ROLE_ADMIN'],
      'companyId': null,
      'providerId': null,
    },
  };

  final Map<int, Map<String, dynamic>> _buyerCompanies = {
    DemoWorld.buyerCompanyId: {
      'id': DemoWorld.buyerCompanyId,
      'name': DemoWorld.buyerCompanyName,
      'ruc': DemoWorld.buyerCompanyRuc,
      'sector': DemoWorld.buyerCompanySector,
      'address': DemoWorld.buyerCompanyAddress,
      'contactEmail': DemoWorld.buyerCompanyEmail,
      'phone': DemoWorld.buyerCompanyPhone,
    },
    DemoWorld.buyer2CompanyId: {
      'id': DemoWorld.buyer2CompanyId,
      'name': DemoWorld.buyer2CompanyName,
      'ruc': DemoWorld.buyer2CompanyRuc,
      'sector': DemoWorld.buyer2CompanySector,
      'address': DemoWorld.buyer2CompanyAddress,
      'contactEmail': DemoWorld.buyer2CompanyEmail,
      'phone': DemoWorld.buyer2CompanyPhone,
    },
  };

  final Map<int, Map<String, dynamic>> _providerCompanies = {
    DemoWorld.providerId: {
      'id': DemoWorld.providerId,
      'name': DemoWorld.providerName,
      'ruc': DemoWorld.providerRuc,
      'rating': 4.7,
      'address': DemoWorld.providerAddress,
      'phone': DemoWorld.providerPhone,
      'fuelTypesOffered': ['DIESEL', 'GASOLINE_90', 'GASOLINE_95', 'GLP'],
      'description': 'Distribución mayorista de combustibles para minería, agroindustria y transporte en el sur del Perú.',
    },
    DemoWorld.provider21Id: {
      'id': DemoWorld.provider21Id,
      'name': DemoWorld.provider21Name,
      'ruc': '20601234567',
      'rating': 4.3,
      'address': 'Av. Argentina 2310, Callao',
      'phone': '+51 1 452 8800',
      'fuelTypesOffered': ['DIESEL', 'GASOLINE_97'],
      'description': 'Logística de combustibles líquidos con flota propia.',
    },
    DemoWorld.provider22Id: {
      'id': DemoWorld.provider22Id,
      'name': DemoWorld.provider22Name,
      'ruc': '20559876543',
      'rating': 4.1,
      'address': 'Jr. Comercio 118, Tacna',
      'phone': '+51 52 424 100',
      'fuelTypesOffered': ['GASOLINE_84', 'GASOLINE_90'],
      'description': 'Red de grifos y suministro en la costa sur.',
    },
  };

  // Organizaciones: id -> {id, name, type}; membresías: userId -> [{orgId, role}]
  final Map<int, Map<String, dynamic>> _organizations = {
    DemoWorld.buyerOrganizationId: {
      'id': DemoWorld.buyerOrganizationId,
      'name': DemoWorld.buyerCompanyName,
      'type': 'CUSTOMER',
    },
    DemoWorld.providerOrganizationId: {
      'id': DemoWorld.providerOrganizationId,
      'name': DemoWorld.providerName,
      'type': 'DISTRIBUTOR',
    },
  };
  final Map<int, List<Map<String, dynamic>>> _memberships = {
    DemoWorld.buyerUserId: [
      {
        'organizationId': DemoWorld.buyerOrganizationId,
        'role': DemoWorld.organizationRole,
      },
    ],
    DemoWorld.providerUserId: [
      {
        'organizationId': DemoWorld.providerOrganizationId,
        'role': DemoWorld.organizationRole,
      },
    ],
  };

  final List<Map<String, dynamic>> _invitations = [
    {
      'id': 1,
      'organizationId': DemoWorld.providerOrganizationId,
      'email': 'invitado@petrosur.pe',
      'token': 'INVITE-DEMO-2026',
      'role': 'MEMBER',
      'status': 'PENDING',
      'expiresAt': DateTime.utc(2099, 1, 1).toIso8601String(),
    },
  ];

  int _nextUserId = 4;
  int _nextBuyerCompanyId = 12;
  int _nextProviderCompanyId = 23;
  int _nextOrganizationId = 30;
  int _nextInvitationId = 2;
  int _tokenSeq = 1;

  Map<String, dynamic> _sessionJson(Map<String, dynamic> user) {
    final id = user['id'] as int;
    final username = '${user['username']}';
    return {
      'id': id,
      'username': username,
      'token': DemoWorld.fakeJwt(id, username),
      'roles': user['roles'],
      'companyId': user['companyId'],
      'providerId': user['providerId'],
      'memberships': _memberships[id] ?? const [],
    };
  }

  Map<String, dynamic>? _userByName(String username) {
    for (final u in _users.values) {
      if ('${u['username']}'.toLowerCase() == username.toLowerCase()) return u;
    }
    return null;
  }

  Map<String, dynamic> _orgJson(int orgId, String role) => {
    ..._organizations[orgId]!,
    'role': role,
  };

  Map<String, dynamic> _find(
    List<Map<String, dynamic>> list,
    bool Function(Map<String, dynamic>) test,
  ) => list.firstWhere(test, orElse: () => const {});

  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    // Autenticación
    if (r.match('POST', '/authentication/sign-in') != null) {
      final user = _userByName('${r.json['username'] ?? ''}');
      if (user == null) return DemoResponse.error(401, 'Bad credentials');
      return DemoResponse.json(_sessionJson(user));
    }
    if (r.match('POST', '/authentication/sign-up') != null) {
      final username = '${r.json['username'] ?? ''}';
      if (_userByName(username) != null) {
        return DemoResponse.json({
          'code': 'USER_CONFLICT',
          'message': 'User already exists',
        }, 409);
      }
      final roles = [
        for (final x in (r.json['roles'] as List? ?? const [])) '$x',
      ];
      final id = _nextUserId++;
      final user = <String, dynamic>{
        'id': id,
        'username': username,
        'roles': roles,
        'companyId': null,
        'providerId': null,
      };
      final buyer = r.json['buyerCompany'];
      final provider = r.json['providerCompany'];
      if (buyer is Map<String, dynamic>) {
        final companyId = _nextBuyerCompanyId++;
        _buyerCompanies[companyId] = {'id': companyId, ...buyer};
        user['companyId'] = companyId;
      } else if (provider is Map<String, dynamic>) {
        final companyId = _nextProviderCompanyId++;
        _providerCompanies[companyId] = {
          'id': companyId,
          'rating': null,
          ...provider,
        };
        user['providerId'] = companyId;
      }
      _users[id] = user;
      final orgId = _nextOrganizationId++;
      final company = (buyer ?? provider) as Map<String, dynamic>?;
      _organizations[orgId] = {
        'id': orgId,
        'name': company?['name'] ?? username,
        'type': buyer != null ? 'CUSTOMER' : 'DISTRIBUTOR',
      };
      _memberships[id] = [
        {'organizationId': orgId, 'role': 'OWNER'},
      ];
      return DemoResponse.json({
        'id': id,
        'username': username,
        'roles': roles,
      }, 201);
    }
    if (r.match('POST', '/authentication/password-reset/request') != null ||
        r.match('POST', '/authentication/password-reset/confirm') != null) {
      return DemoResponse.empty();
    }

    // Usuarios y empresas
    var m = r.match('GET', '/users/:id');
    if (m != null) {
      final user = _users[int.tryParse(m['id']!)];
      return user == null
          ? DemoResponse.error(404, 'User not found')
          : DemoResponse.json(user);
    }
    m = r.match('GET', '/buyer-companies/:id');
    if (m != null) {
      final c = _buyerCompanies[int.tryParse(m['id']!)];
      return c == null
          ? DemoResponse.error(404, 'Company not found')
          : DemoResponse.json(c);
    }
    m = r.match('PUT', '/buyer-companies/:id');
    if (m != null) {
      final id = int.tryParse(m['id']!);
      final c = _buyerCompanies[id];
      if (c == null) return DemoResponse.error(404, 'Company not found');
      for (final k in const [
        'name',
        'ruc',
        'sector',
        'address',
        'contactEmail',
        'phone',
      ]) {
        if (r.json.containsKey(k)) c[k] = r.json[k];
      }
      return DemoResponse.json(c);
    }
    m = r.match('GET', '/provider-companies/:id');
    if (m != null) {
      final c = _providerCompanies[int.tryParse(m['id']!)];
      return c == null
          ? DemoResponse.error(404, 'Company not found')
          : DemoResponse.json(c);
    }
    m = r.match('PUT', '/provider-companies/:id');
    if (m != null) {
      final c = _providerCompanies[int.tryParse(m['id']!)];
      if (c == null) return DemoResponse.error(404, 'Company not found');
      for (final k in const [
        'name',
        'ruc',
        'rating',
        'address',
        'phone',
        'fuelTypesOffered',
        'description',
      ]) {
        if (r.json.containsKey(k)) c[k] = r.json[k];
      }
      return DemoResponse.json(c);
    }

    // Organizaciones
    if (r.match('GET', '/me/organizations') != null) {
      final memberships = _memberships[r.userId] ?? const [];
      return DemoResponse.json([
        for (final x in memberships)
          _orgJson(x['organizationId'] as int, '${x['role']}'),
      ]);
    }
    if (r.match('POST', '/onboarding') != null) {
      final userId = r.userId;
      if (userId == null) return DemoResponse.error(401, 'Unauthorized');
      final name = '${r.json['name'] ?? ''}'.trim();
      final ruc = '${r.json['ruc'] ?? ''}'.trim();
      if (name.isEmpty || ruc.isEmpty) {
        return DemoResponse.error(400, 'Invalid organization');
      }
      final id = _nextOrganizationId++;
      _organizations[id] = {
        'id': id,
        'name': name,
        'type': '${r.json['type'] ?? 'CUSTOMER'}',
      };
      (_memberships[userId] ??= []).add({
        'organizationId': id,
        'role': 'OWNER',
      });
      return DemoResponse.json(_orgJson(id, 'OWNER'), 201);
    }
    m = r.match('POST', '/organizations/:id/invitations');
    if (m != null) {
      final orgId = int.tryParse(m['id']!);
      if (orgId == null || !_organizations.containsKey(orgId)) {
        return DemoResponse.error(404, 'Organization not found');
      }
      final invitation = <String, dynamic>{
        'id': _nextInvitationId++,
        'organizationId': orgId,
        'email': '${r.json['email'] ?? ''}',
        'token':
            'INVITE-${orgId}0${_tokenSeq++}-${DateTime.now().millisecondsSinceEpoch}',
        'role': '${r.json['role'] ?? 'MEMBER'}',
        'status': 'PENDING',
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 7))
            .toIso8601String(),
      };
      _invitations.add(invitation);
      return DemoResponse.json(invitation, 201);
    }
    m = r.match('DELETE', '/invitations/:id');
    if (m != null) {
      final inv = _find(_invitations, (i) => '${i['id']}' == m!['id']);
      if (inv.isEmpty) return DemoResponse.error(404, 'Invitation not found');
      if (inv['status'] != 'PENDING') {
        return DemoResponse.error(422, 'Invitation is not pending');
      }
      inv['status'] = 'REVOKED';
      return DemoResponse.json(inv);
    }
    m = r.match('POST', '/invitations/:token/accept');
    if (m != null) {
      final userId = r.userId;
      if (userId == null) return DemoResponse.error(401, 'Unauthorized');
      final inv = _find(_invitations, (i) => i['token'] == m!['token']);
      if (inv.isEmpty) return DemoResponse.error(404, 'Invitation not found');
      if (inv['status'] != 'PENDING') {
        return DemoResponse.error(422, 'Invitation is not pending');
      }
      final orgId = inv['organizationId'] as int;
      final memberships = _memberships[userId] ??= [];
      if (memberships.any((x) => x['organizationId'] == orgId)) {
        return DemoResponse.error(409, 'Already a member');
      }
      memberships.add({'organizationId': orgId, 'role': inv['role']});
      inv['status'] = 'ACCEPTED';
      return DemoResponse.json({...inv, 'token': ''});
    }
    return null;
  }
}
