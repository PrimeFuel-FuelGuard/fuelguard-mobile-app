/// Roles de la aplicación derivados de `roles` de la sesión.
abstract final class UserRole {
  static const buyer = 'BUYER';
  static const provider = 'PROVIDER';
  static const admin = 'ADMIN';
}

class Membership {
  const Membership({required this.organizationId, required this.role});

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
    organizationId: (json['organizationId'] as num).toInt(),
    role: '${json['role']}',
  );

  final int organizationId;
  final String role;

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'role': role,
  };
}

class Session {
  const Session({
    required this.id,
    required this.username,
    required this.token,
    required this.roles,
    this.companyId,
    this.providerId,
    this.memberships = const [],
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: (json['id'] as num).toInt(),
    username: '${json['username']}',
    token: '${json['token']}',
    roles: [for (final r in (json['roles'] as List)) '$r'],
    companyId: (json['companyId'] as num?)?.toInt(),
    providerId: (json['providerId'] as num?)?.toInt(),
    memberships: [
      for (final m in (json['memberships'] as List? ?? const []))
        Membership.fromJson(m as Map<String, dynamic>),
    ],
  );

  final int id;
  final String username;
  final String token;
  final List<String> roles;
  final int? companyId;
  final int? providerId;
  final List<Membership> memberships;

  Session copyWith({List<Membership>? memberships}) => Session(
    id: id,
    username: username,
    token: token,
    roles: roles,
    companyId: companyId,
    providerId: providerId,
    memberships: memberships ?? this.memberships,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'token': token,
    'roles': roles,
    'companyId': companyId,
    'providerId': providerId,
    'memberships': [for (final m in memberships) m.toJson()],
  };
}

class SignUpForm {
  const SignUpForm({
    required this.role,
    required this.username,
    required this.password,
    required this.name,
    required this.ruc,
    required this.address,
    required this.phone,
    this.sector,
    this.fuelTypesOffered,
    this.description,
  });

  /// `BUYER` o `PROVIDER`.
  final String role;
  final String username;
  final String password;
  final String name;
  final String ruc;
  final String address;
  final String phone;
  final String? sector;
  final List<String>? fuelTypesOffered;
  final String? description;
}

/// Rol efectivo de la sesión (`PROVIDER` > `BUYER` > `ADMIN`), o `null`.
String? sessionRole(Session? session) {
  if (session == null) return null;
  if (session.roles.contains('ROLE_PROVIDER')) return UserRole.provider;
  if (session.roles.contains('ROLE_BUYER')) return UserRole.buyer;
  if (session.roles.contains('ROLE_ADMIN')) return UserRole.admin;
  return null;
}
