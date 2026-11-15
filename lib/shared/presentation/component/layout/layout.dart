import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../infrastructure/i18n/translate_service.dart';
import '../../../infrastructure/navigation.dart';

/// Destino de navegación. Fuente única para la `NavigationBar` y la pantalla "Más".
///
/// [primaryRoles]: roles para los que es destino de la barra inferior (en el orden de la lista).
/// El resto de roles lo ven en "Más". [match] son prefijos extra que lo resaltan.
class NavOption {
  const NavOption({
    required this.label,
    required this.icon,
    required this.link,
    this.roles = const [],
    this.primaryRoles = const [],
    this.match = const [],
    this.admin = false,
  });

  final String label;
  final IconData icon;
  final String link;
  final List<String> roles;
  final List<String> primaryRoles;
  final List<String> match;
  final bool admin;

  bool isActiveFor(String path) {
    for (final prefix in [link, ...match]) {
      if (path == prefix ||
          path.startsWith('$prefix/') ||
          (match.contains(prefix) && path.startsWith(prefix))) {
        return true;
      }
    }
    return false;
  }
}

/// Orden de la lista = orden en la barra inferior y en "Más".
const List<NavOption> navOptions = [
  NavOption(
    label: 'nav.dashboard',
    icon: Icons.dashboard,
    link: '/dashboard',
    roles: ['BUYER', 'PROVIDER'],
    primaryRoles: ['BUYER', 'PROVIDER'],
  ),
  NavOption(
    label: 'nav.admin',
    icon: Icons.admin_panel_settings,
    link: '/admin',
    admin: true,
    primaryRoles: ['ADMIN'],
  ),
  NavOption(
    label: 'nav.equipment',
    icon: Icons.oil_barrel,
    link: '/tanks',
    roles: ['BUYER'],
    primaryRoles: ['BUYER'],
  ),
  NavOption(
    label: 'ordering.requests',
    icon: Icons.shopping_cart,
    link: '/ordering/request-list',
    roles: ['BUYER', 'PROVIDER'],
    primaryRoles: ['BUYER', 'PROVIDER'],
    match: ['/ordering/request-'],
  ),
  NavOption(
    label: 'fulfillment.deliveries',
    icon: Icons.local_shipping,
    link: '/fulfillment/delivery-list',
    roles: ['PROVIDER'],
    primaryRoles: ['PROVIDER'],
    match: ['/fulfillment/delivery-'],
  ),
  NavOption(
    label: 'nav.reports',
    icon: Icons.analytics,
    link: '/analytics',
    roles: ['BUYER', 'PROVIDER', 'ADMIN'],
    primaryRoles: ['ADMIN'],
  ),
  // --- Solo en "Más" ---
  NavOption(
    label: 'inventory.catalog',
    icon: Icons.local_gas_station,
    link: '/fuel-products',
    roles: ['BUYER'],
  ),
  NavOption(
    label: 'nav.clients',
    icon: Icons.groups,
    link: '/clients',
    roles: ['PROVIDER'],
  ),
  NavOption(
    label: 'inventory.product-inventory',
    icon: Icons.inventory_2,
    link: '/fuel-products',
    roles: ['PROVIDER'],
  ),
  NavOption(
    label: 'inventory.add-product',
    icon: Icons.add_box,
    link: '/fuel-products/product-form',
    roles: ['PROVIDER'],
  ),
  NavOption(
    label: 'ordering.orders',
    icon: Icons.receipt_long,
    link: '/ordering/order-list',
    roles: ['BUYER', 'PROVIDER'],
    match: ['/ordering/order-'],
  ),
  NavOption(
    label: 'payment-history.title',
    icon: Icons.history,
    link: '/ordering/payment-history',
    roles: ['BUYER'],
  ),
  NavOption(
    label: 'nav.payments',
    icon: Icons.payments,
    link: '/payments',
    roles: ['PROVIDER'],
  ),
  NavOption(
    label: 'fulfillment.vehicles',
    icon: Icons.fire_truck,
    link: '/fulfillment/tanker-list',
    roles: ['PROVIDER'],
    match: ['/fulfillment/tanker-'],
  ),
  NavOption(
    label: 'fulfillment.drivers',
    icon: Icons.badge,
    link: '/fulfillment/driver-list',
    roles: ['PROVIDER'],
    match: ['/fulfillment/driver-'],
  ),
  NavOption(
    label: 'nav.reports',
    icon: Icons.analytics,
    link: '/analytics',
    roles: ['BUYER', 'PROVIDER'],
  ),
  NavOption(
    label: 'nav.notifications',
    icon: Icons.notifications,
    link: '/notification/notification-list',
    roles: ['BUYER', 'PROVIDER', 'ADMIN'],
  ),
  NavOption(
    label: 'profile.account-settings',
    icon: Icons.manage_accounts,
    link: '/profile',
    roles: ['BUYER', 'PROVIDER', 'ADMIN'],
  ),
];

String _roleOf(IamStore iam) => iam.isAdmin ? 'ADMIN' : (iam.role ?? '');

/// Destinos de la barra inferior para el rol actual.
List<NavOption> primaryNavOptions(IamStore iam) => [
  for (final o in navOptions)
    if (o.primaryRoles.contains(_roleOf(iam))) o,
];

/// Opciones de la pantalla "Más" para el rol actual (sin las primarias).
List<NavOption> moreNavOptions(IamStore iam) {
  final role = _roleOf(iam);
  return [
    for (final o in navOptions)
      if (!o.primaryRoles.contains(role) &&
          (o.admin ? iam.isAdmin : o.roles.contains(role)))
        o,
  ];
}

/// Estructura de las pantallas autenticadas: AppBar M3 + `NavigationBar` inferior + contenido ([child]).
///
/// [currentPath] es la ruta activa (para resaltar el destino y titular la AppBar).
class Layout extends StatefulWidget {
  const Layout({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      AppScope.of(context).notificationStore.refreshUnreadCount();
    }
  }

  String get _path => widget.currentPath.split(RegExp(r'[?#]')).first;

  String _title(BuildContext context, IamStore iam) {
    if (_path == '/more') return context.tr('nav.more');
    final role = _roleOf(iam);
    NavOption? best;
    for (final o in navOptions) {
      if (!(o.primaryRoles.contains(role) ||
          (o.admin ? iam.isAdmin : o.roles.contains(role)))) {
        continue;
      }
      if (o.isActiveFor(_path) &&
          (best == null || o.link.length > best.link.length)) {
        best = o;
      }
    }
    return best == null ? 'FuelGuard' : context.tr(best.label);
  }

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context);
    final iam = config.iamStore;
    return ListenableBuilder(
      listenable: iam,
      builder: (context, _) {
        final primary = primaryNavOptions(iam);
        var selected = primary.indexWhere((o) => o.isActiveFor(_path));
        if (selected < 0) selected = primary.length; // "Más"
        return Scaffold(
          appBar: AppBar(
            title: Text(_title(context, iam)),
            actions: [
              ListenableBuilder(
                listenable: config.notificationStore,
                builder: (context, _) {
                  final unread = config.notificationStore.unreadCount;
                  return IconButton(
                    tooltip: context.tr('notification-list.title'),
                    onPressed: () =>
                        context.push('/notification/notification-list'),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  );
                },
              ),
              _UserMenu(iam: iam),
            ],
          ),
          body: widget.child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) {
              final link = i < primary.length ? primary[i].link : '/more';
              if (i != selected || _path != link) context.go(link);
            },
            destinations: [
              for (final o in primary)
                NavigationDestination(
                  icon: Icon(o.icon),
                  label: context.tr(o.label),
                ),
              NavigationDestination(
                icon: const Icon(Icons.more_horiz),
                label: context.tr('nav.more'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.iam});

  final IamStore iam;

  @override
  Widget build(BuildContext context) {
    final translate = AppScope.of(context).translateService;
    final lang = translate.getCurrentLang();
    return PopupMenuButton<String>(
      tooltip: context.tr('profile.user'),
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) {
        if (value == 'profile') context.push('/profile');
        if (value == 'logout') iam.logout();
        if (value == 'en' || value == 'es') translate.use(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            iam.session?.username ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.manage_accounts),
            title: Text(context.tr('profile.account-settings')),
          ),
        ),
        const PopupMenuDivider(),
        for (final (code, name) in const [('en', 'English'), ('es', 'Español')])
          PopupMenuItem<String>(
            value: code,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.language),
              title: Text(name),
              trailing: lang == code ? const Icon(Icons.check, size: 18) : null,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.logout),
            title: Text(context.tr('auth.logout')),
          ),
        ),
      ],
    );
  }
}
