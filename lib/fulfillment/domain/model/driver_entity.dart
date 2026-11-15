import '../../../shared/domain/model/base_entity.dart';

/// Estado del conductor.
abstract final class DriverStatus {
  static const available = 'AVAILABLE';
  static const assigned = 'ASSIGNED';
  static const suspended = 'SUSPENDED';
  static const inactive = 'INACTIVE';
  static const values = [available, assigned, suspended, inactive];
}

/// Entidad de dominio que representa un conductor autorizado para realizar entregas.
class Driver implements BaseEntity {
  const Driver({
    required this.id,
    required this.providerId,
    this.userId,
    this.active = true,
    required this.firstName,
    required this.lastName,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: (json['id'] as num).toInt(),
    providerId: (json['providerId'] as num).toInt(),
    userId: (json['userId'] as num?)?.toInt(),
    active: json['active'] as bool? ?? true,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    licenseNumber: json['licenseNumber'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
    status: json['status'] as String,
    createdAt: json['createdAt'] as String? ?? '',
  );

  @override
  final int id;
  final int providerId;
  final int? userId;
  final bool active;
  final String firstName;
  final String lastName;
  final String licenseNumber;
  final String phoneNumber;
  final String email;

  /// `DriverStatus`.
  final String status;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'userId': userId,
    'active': active,
    'firstName': firstName,
    'lastName': lastName,
    'licenseNumber': licenseNumber,
    'phoneNumber': phoneNumber,
    'email': email,
    'status': status,
    'createdAt': createdAt,
  };

  Driver copyWith({
    int? userId,
    bool? active,
    String? firstName,
    String? lastName,
    String? licenseNumber,
    String? phoneNumber,
    String? email,
    String? status,
    String? createdAt,
  }) => Driver(
    id: id,
    providerId: providerId,
    userId: userId ?? this.userId,
    active: active ?? this.active,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// `Omit<Driver, 'id' | 'providerId' | 'createdAt'>`: datos para registrar un conductor.
class DriverInput {
  const DriverInput({
    this.userId,
    this.active = true,
    required this.firstName,
    required this.lastName,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.email,
    required this.status,
  });

  final int? userId;
  final bool active;
  final String firstName;
  final String lastName;
  final String licenseNumber;
  final String phoneNumber;
  final String email;
  final String status;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'active': active,
    'firstName': firstName,
    'lastName': lastName,
    'licenseNumber': licenseNumber,
    'phoneNumber': phoneNumber,
    'email': email,
    'status': status,
  };
}
