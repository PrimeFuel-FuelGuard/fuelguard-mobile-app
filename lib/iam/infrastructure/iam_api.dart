import '../../environments/environment.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/session_entity.dart';
import 'auth_interceptor.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.roles,
    this.companyId,
    this.providerId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: (j['id'] as num).toInt(),
    username: '${j['username']}',
    roles: [for (final r in (j['roles'] as List? ?? const [])) '$r'],
    companyId: (j['companyId'] as num?)?.toInt(),
    providerId: (j['providerId'] as num?)?.toInt(),
  );

  final int id;
  final String username;
  final List<String> roles;
  final int? companyId;
  final int? providerId;
}

class BuyerCompanyProfile {
  BuyerCompanyProfile({
    this.id = 0,
    this.name = '',
    this.ruc = '',
    this.sector = '',
    this.address = '',
    this.contactEmail = '',
    this.phone = '',
  });

  factory BuyerCompanyProfile.fromJson(Map<String, dynamic> j) =>
      BuyerCompanyProfile(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: '${j['name'] ?? ''}',
        ruc: '${j['ruc'] ?? ''}',
        sector: '${j['sector'] ?? ''}',
        address: '${j['address'] ?? ''}',
        contactEmail: '${j['contactEmail'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
      );

  int id;
  String name, ruc, sector, address, contactEmail, phone;
}

class ProviderCompanyProfile {
  ProviderCompanyProfile({
    this.id = 0,
    this.name = '',
    this.ruc = '',
    this.rating,
    this.address = '',
    this.phone = '',
    List<String>? fuelTypesOffered,
    this.description = '',
  }) : fuelTypesOffered = fuelTypesOffered ?? [];

  factory ProviderCompanyProfile.fromJson(Map<String, dynamic> j) =>
      ProviderCompanyProfile(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: '${j['name'] ?? ''}',
        ruc: '${j['ruc'] ?? ''}',
        rating: (j['rating'] as num?)?.toDouble(),
        address: '${j['address'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        fuelTypesOffered: [
          for (final f in (j['fuelTypesOffered'] as List? ?? const [])) '$f',
        ],
        description: '${j['description'] ?? ''}',
      );

  int id;
  String name, ruc, address, phone, description;
  double? rating;
  List<String> fuelTypesOffered;
}

class OrganizationProfile {
  const OrganizationProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.role,
  });

  factory OrganizationProfile.fromJson(Map<String, dynamic> j) =>
      OrganizationProfile(
        id: (j['id'] as num).toInt(),
        name: '${j['name']}',
        type: '${j['type']}',
        role: '${j['role']}',
      );

  final int id;
  final String name;
  final String type;
  final String role;
}

abstract final class MembershipRole {
  static const owner = 'OWNER';
  static const admin = 'ADMIN';
  static const member = 'MEMBER';
}

class OrganizationInvitation {
  const OrganizationInvitation({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.token,
    required this.role,
    required this.status,
    this.expiresAt,
  });

  factory OrganizationInvitation.fromJson(Map<String, dynamic> j) =>
      OrganizationInvitation(
        id: (j['id'] as num).toInt(),
        organizationId: (j['organizationId'] as num).toInt(),
        email: '${j['email']}',
        token: '${j['token'] ?? ''}',
        role: '${j['role']}',
        status: '${j['status']}',
        expiresAt: j['expiresAt'] as String?,
      );

  final int id;
  final int organizationId;
  final String email;
  final String token;

  /// `OWNER` | `ADMIN` | `MEMBER`.
  final String role;

  /// `PENDING` | `ACCEPTED` | `REVOKED`.
  final String status;
  final String? expiresAt;

  OrganizationInvitation copyWith({String? token}) => OrganizationInvitation(
    id: id,
    organizationId: organizationId,
    email: email,
    token: token ?? this.token,
    role: role,
    status: status,
    expiresAt: expiresAt,
  );
}

class IamApi extends ErrorHandlingEnabledBaseType {
  IamApi(this._http);

  final AppHttpClient _http;
  static const _base = Environment.serverBasePath;
  static const _auth = '${Environment.serverBasePath}/authentication';

  Future<UserProfile> getUser(int userId) async => UserProfile.fromJson(
    await execute(() => _http.getJson('$_base/users/$userId'))
        as Map<String, dynamic>,
  );

  Future<BuyerCompanyProfile> getBuyerCompany(int companyId) async =>
      BuyerCompanyProfile.fromJson(
        await execute(() => _http.getJson('$_base/buyer-companies/$companyId'))
            as Map<String, dynamic>,
      );

  Future<BuyerCompanyProfile> updateBuyerCompany(
    int companyId,
    BuyerCompanyProfile p,
  ) async => BuyerCompanyProfile.fromJson(
    await execute(
      () => _http.putJson('$_base/buyer-companies/$companyId', {
        'name': p.name,
        'ruc': p.ruc,
        'sector': p.sector,
        'address': p.address,
        'contactEmail': p.contactEmail,
        'phone': p.phone,
      }),
    ) as Map<String, dynamic>,
  );

  Future<ProviderCompanyProfile> getProviderCompany(int providerId) async =>
      ProviderCompanyProfile.fromJson(
        await execute(
          () => _http.getJson('$_base/provider-companies/$providerId'),
        ) as Map<String, dynamic>,
      );

  /// El PUT reemplaza rating incluso si se omite: se conserva el valor leído, sin permitir editarlo.
  Future<ProviderCompanyProfile> updateProviderCompany(
    int providerId,
    ProviderCompanyProfile p,
  ) async => ProviderCompanyProfile.fromJson(
    await execute(
      () => _http.putJson('$_base/provider-companies/$providerId', {
        'name': p.name,
        'ruc': p.ruc,
        'rating': p.rating,
        'address': p.address,
        'phone': p.phone,
        'fuelTypesOffered': p.fuelTypesOffered,
        'description': p.description,
      }),
    ) as Map<String, dynamic>,
  );

  Future<List<OrganizationProfile>> getOrganizations() async {
    final json =
        await execute(() => _http.getJson('$_base/me/organizations')) as List;
    return [
      for (final o in json)
        OrganizationProfile.fromJson(o as Map<String, dynamic>),
    ];
  }

  /// [type]: `CUSTOMER` | `DISTRIBUTOR`.
  Future<OrganizationProfile> onboardOrganization(
    String name,
    String ruc,
    String type,
  ) async => OrganizationProfile.fromJson(
    await execute(
      () => _http.postJson('$_base/onboarding', {
        'name': name,
        'ruc': ruc,
        'type': type,
      }),
      operation: 'onboardOrganization',
      localized: true,
    ) as Map<String, dynamic>,
  );

  Future<OrganizationInvitation> inviteMember(
    int organizationId,
    String email,
    String role,
  ) async => OrganizationInvitation.fromJson(
    await execute(
      () => _http.postJson('$_base/organizations/$organizationId/invitations', {
        'email': email,
        'role': role,
      }),
      operation: 'inviteMember',
      localized: true,
    ) as Map<String, dynamic>,
  );

  Future<OrganizationInvitation> revokeInvitation(int invitationId) async =>
      OrganizationInvitation.fromJson(
        await execute(
          () => _http.deleteJson('$_base/invitations/$invitationId'),
          operation: 'revokeInvitation',
          localized: true,
        ) as Map<String, dynamic>,
      );

  Future<OrganizationInvitation> acceptInvitation(String token) async =>
      OrganizationInvitation.fromJson(
        await execute(
          () => _http.postJson(
            '$_base/invitations/${Uri.encodeComponent(token)}/accept',
            null,
          ),
          operation: 'acceptInvitation',
          localized: true,
        ) as Map<String, dynamic>,
      );

  Future<Session> signIn(String username, String password) async =>
      Session.fromJson(
        await execute(
          () => _http.postJson('$_auth/sign-in', {
            'username': username,
            'password': password,
          }),
        ) as Map<String, dynamic>,
      );

  Future<void> signUp(SignUpForm form) async {
    final payload = form.role == 'BUYER'
        ? {
            'username': form.username,
            'password': form.password,
            'roles': ['ROLE_BUYER'],
            'buyerCompany': {
              'name': form.name,
              'ruc': form.ruc,
              'sector': form.sector,
              'address': form.address,
              'contactEmail': form.username,
              'phone': form.phone,
            },
          }
        : {
            'username': form.username,
            'password': form.password,
            'roles': ['ROLE_PROVIDER'],
            'providerCompany': {
              'name': form.name,
              'ruc': form.ruc,
              'address': form.address,
              'phone': form.phone,
              'fuelTypesOffered': form.fuelTypesOffered,
              'description': form.description ?? '',
            },
          };
    await execute(() => _http.postJson('$_auth/sign-up', payload));
  }

  Future<void> requestPasswordReset(String email) async {
    await execute(
      () => _http.postJson('$_auth/password-reset/request', {'email': email}),
    );
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    await execute(
      () => _http.postJson('$_auth/password-reset/confirm', {
        'token': token,
        'newPassword': newPassword,
      }),
    );
  }
}
