import 'package:material_ui/material_ui.dart';

import '../../../../analytics/infrastructure/analytics_api.dart';
import '../../../../app_config.dart';
import '../../../../equipment/infrastructure/provider_equipment_api.dart';
import '../../../../fulfillment/infrastructure/fulfillment_api.dart';
import '../../../../ordering/infrastructure/ordering_api.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/kpi_card/kpi_card.dart';
import '../../../application/dashboard_store.dart';
import 'dashboard_panels.dart';

/// Resumen operativo (`/dashboard`): comprador o proveedor según el rol.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final DashboardStore _store;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    final http = app.httpClient;
    _store = DashboardStore(
      AnalyticsApi(http),
      OrderingApi(http),
      ProviderEquipmentApi(http),
      FulfillmentApi(http),
      app.iamStore,
    );
    _store.refresh();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final buyer = _store.isBuyer;
      final showBody = !buyer || _store.buyer != null;
      return RefreshIndicator(
        onRefresh: _store.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(isBuyer: buyer),
            const SizedBox(height: 12),
            _QuickActions(isBuyer: buyer),
            const SizedBox(height: 16),
            if (_store.loading) const LinearProgressIndicator(),
            if (_store.error)
              ErrorBanner(message: 'analytics.error', onRetry: _store.load),
            if (showBody) ...[
              const SizedBox(height: 16),
              _KpiGrid(store: _store),
              const SizedBox(height: 16),
              if (!buyer) ...[
                ProviderPanels(store: _store),
                const SizedBox(height: 16),
              ],
              OrderPanels(store: _store),
            ],
          ],
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.isBuyer});

  final bool isBuyer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            isBuyer ? 'analytics.buyer-title' : 'analytics.provider-title',
          ),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr(
            isBuyer
                ? 'analytics.buyer-subtitle'
                : 'analytics.provider-subtitle',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isBuyer});

  final bool isBuyer;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (isBuyer)
        FilledButton.icon(
          onPressed: () => context.push('/ordering/request-form'),
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(context.tr('analytics.new-request')),
        )
      else
        FilledButton.tonalIcon(
          onPressed: () => context.go('/ordering/order-list'),
          icon: const Icon(Icons.receipt_long),
          label: Text(context.tr('analytics.all-orders')),
        ),
      OutlinedButton.icon(
        onPressed: () => context.go('/analytics'),
        icon: const Icon(Icons.analytics_outlined),
        label: Text(context.tr('analytics.open-analytics')),
      ),
    ],
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.1,
    children: [
      for (final kpi in store.kpis)
        KpiCard(
          label: context.tr(kpi.label),
          value: kpi.money ? formatMoney(kpi.value) : formatNumber(kpi.value),
          icon: _kpiIcon(kpi.label),
        ),
    ],
  );
}

IconData _kpiIcon(String key) => switch (key) {
  'analytics.total-spent' ||
  'analytics.total-revenue' => Icons.payments_outlined,
  'analytics.pending-payments' ||
  'analytics.pending-orders' => Icons.hourglass_bottom,
  'analytics.completed-payments' ||
  'analytics.confirmed-orders' => Icons.check_circle_outline,
  'analytics.cancelled-orders' => Icons.cancel_outlined,
  'analytics.fuel-sold' => Icons.local_gas_station_outlined,
  _ => Icons.receipt_long_outlined,
};
