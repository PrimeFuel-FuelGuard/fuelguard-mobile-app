import '../../shared/infrastructure/base_response.dart';

/// Resource DTO para conductores: estructura de respuesta del backend.
class DriverResource implements BaseResource {
  const DriverResource({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.active,
  });

  factory DriverResource.fromJson(Map<String, dynamic> json) => DriverResource(
    id: (json['id'] as num).toInt(),
    providerId: (json['providerId'] as num).toInt(),
    userId: (json['userId'] as num?)?.toInt(),
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    licenseNumber: json['licenseNumber'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
    status: json['status'] as String,
    active: json['active'] as bool,
  );

  @override
  final int id;
  final int providerId;
  final int? userId;
  final String firstName;
  final String lastName;
  final String licenseNumber;
  final String phoneNumber;
  final String email;

  /// `DriverStatus`.
  final String status;
  final bool active;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'licenseNumber': licenseNumber,
    'phoneNumber': phoneNumber,
    'email': email,
    'status': status,
    'active': active,
  };
}

/// Resultado de elegibilidad `{ outcome, reason }` de conductores y cisternas.
class EligibilityResult {
  const EligibilityResult({required this.outcome, required this.reason});

  factory EligibilityResult.fromJson(Map<String, dynamic> json) =>
      EligibilityResult(
        outcome: json['outcome'] as String,
        reason: json['reason'] as String,
      );

  final String outcome;
  final String reason;

  Map<String, dynamic> toJson() => {'outcome': outcome, 'reason': reason};
}
