import '../application/iam_store.dart';

/// Requiere sesión; si no, redirige a `/login?returnUrl=<url>`.
String? authGuard(IamStore iam, String url) => iam.isAuthenticated
    ? null
    : '/login?returnUrl=${Uri.encodeQueryComponent(url)}';

String? _roleGuard(IamStore iam, bool allowed) =>
    allowed ? null : (iam.isAuthenticated ? '/access-denied' : '/login');

String? buyerGuard(IamStore iam, String url) => _roleGuard(iam, iam.isBuyer);

String? providerGuard(IamStore iam, String url) =>
    _roleGuard(iam, iam.isProvider);

String? adminGuard(IamStore iam, String url) => _roleGuard(iam, iam.isAdmin);

/// Analytics: comprador, proveedor o administrador (el admin solo ve el resumen de plataforma).
String? analyticsGuard(IamStore iam, String url) =>
    iam.isBuyer || iam.isProvider || iam.isAdmin ? null : '/access-denied';

String? supportedRoleGuard(IamStore iam, String url) =>
    iam.role == 'BUYER' || iam.role == 'PROVIDER' ? null : '/access-denied';
