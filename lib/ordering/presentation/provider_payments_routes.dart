import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/provider_payments/provider_payments.dart';

/// Pagos del distribuidor: `/payments` (authGuard + providerGuard).
final List<AppRoute> providerPaymentRoutes = [
  AppRoute(
    '/payments',
    guards: [authGuard, providerGuard],
    shell: true,
    builder: (c, p) => const ProviderPayments(),
  ),
];
