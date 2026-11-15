import '../../iam/infrastructure/auth_guard.dart';
import '../../shared/infrastructure/app_route.dart';
import 'views/product_form/product_form.dart';
import 'views/product_inventory/product_inventory.dart';

/// Rutas de `/fuel-products`; el formulario exige providerGuard.
const List<Guard> _guards = [authGuard, supportedRoleGuard];

final List<AppRoute> fuelProductRoutes = [
  AppRoute(
    '/fuel-products',
    guards: _guards,
    shell: true,
    builder: (c, p) => const ProductInventory(),
  ),
  AppRoute(
    '/fuel-products/product-form',
    guards: [..._guards, providerGuard],
    shell: true,
    builder: (c, p) => const ProductForm(),
  ),
  AppRoute(
    '/fuel-products/product-form/:id',
    guards: [..._guards, providerGuard],
    shell: true,
    builder: (c, p) => ProductForm(productId: p.path['id']),
  ),
];
