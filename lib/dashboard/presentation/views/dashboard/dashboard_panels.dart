import 'package:material_ui/material_ui.dart';

import '../../../../analytics/domain/sales_trend.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/bar_chart/bar_chart.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/dashboard_store.dart';

/// Paneles del proveedor: tendencia de ventas, solicitudes pendientes, tanques críticos y entregas de hoy.
class ProviderPanels extends StatelessWidget {
  const ProviderPanels({super.key, required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      _trend(context),
      _requests(context),
      _tanks(context),
      _deliveries(context),
    ],
  );

  Widget _trend(BuildContext context) => SectionCard(
    title: context.tr('analytics.sales-trend'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final g in TrendGranularity.values)
              ButtonSegment(
                value: g,
                label: Text(context.tr('analytics.view-$g')),
              ),
          ],
          selected: {store.granularity},
          onSelectionChanged: (s) => store.setGranularity(s.first),
        ),
        if (store.hasSales)
          SimpleBarChart(
            data: [for (final p in store.trend) (p.date, p.litres)],
            format: (v) => formatNumber(v),
          )
        else
          Text(context.tr('analytics.no-sales'), style: _mutedStyle(context)),
      ],
    ),
  );

  Widget _requests(BuildContext context) => SectionCard(
    title:
        '${context.tr('analytics.pending-requests')} '
        '(${store.pendingRequests.length})',
    child: _CardBody(
      loading: store.inboxLoading,
      failed: store.inboxError,
      failedKey: 'analytics.inbox-error',
      onRetry: store.loadInbox,
      emptyKey: 'analytics.no-pending-requests',
      items: [
        for (final r in store.pendingRequests.take(5))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('#${r.id} · ${formatNumber(r.quantity)} ${r.unit}'),
            trailing: Text(formatDate(r.deliveryDate)),
            onTap: () => context.push('/ordering/request-detail/${r.id}'),
          ),
      ],
      footer: TextButton(
        onPressed: () => context.go('/ordering/request-list'),
        child: Text(context.tr('analytics.all-requests')),
      ),
    ),
  );

  Widget _tanks(BuildContext context) {
    final tanks = store.criticalTanks;
    return SectionCard(
      title: context.tr('analytics.critical-tanks'),
      child: _CardBody(
        loading: tanks.loading,
        failed: tanks.error,
        failedKey: 'analytics.critical-tanks-error',
        onRetry: store.loadCriticalTanks,
        emptyKey: 'analytics.no-critical-tanks',
        items: [
          for (final t in tanks.data)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t.name),
              trailing: StatusChip(
                label: '${formatNumber(t.levelPercent)} %',
                tone: StatusTone.danger,
              ),
              onTap: () => context.push('/clients/tank/${t.id}'),
            ),
        ],
      ),
    );
  }

  Widget _deliveries(BuildContext context) {
    final deliveries = store.todayDeliveries;
    return SectionCard(
      title:
          '${context.tr('analytics.today-deliveries')} '
          '(${deliveries.data.length})',
      child: _CardBody(
        loading: deliveries.loading,
        failed: deliveries.error,
        failedKey: 'analytics.today-deliveries-error',
        onRetry: store.loadTodayDeliveries,
        emptyKey: 'analytics.no-today-deliveries',
        items: [
          for (final d in deliveries.data.take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('#${d.id} · ${d.buyerCompanyName ?? '-'}'),
              trailing: StatusChip(
                label: context.tr(
                  'delivery-status.${d.physicalState.toLowerCase()}',
                ),
                status: d.physicalState,
              ),
              onTap: () => context.push('/fulfillment/delivery-detail/${d.id}'),
            ),
        ],
        footer: TextButton(
          onPressed: () => context.go('/fulfillment/delivery-list'),
          child: Text(context.tr('analytics.all-deliveries')),
        ),
      ),
    );
  }
}

/// Paneles comunes: pedidos por estado y últimos pedidos.
class OrderPanels extends StatelessWidget {
  const OrderPanels({super.key, required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [_statusCard(context), _recentCard(context)],
  );

  Widget _statusCard(BuildContext context) => SectionCard(
    title: context.tr('analytics.orders-by-status'),
    child: _CardBody(
      loading: store.ordersLoading,
      failed: store.ordersError,
      failedKey: 'analytics.orders-error',
      onRetry: store.loadOrders,
      emptyKey: 'analytics.no-orders',
      items: [
        for (final (status, count) in store.statusCounts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('order-status.${status.toLowerCase()}'),
                    style: count == 0 ? _mutedStyle(context) : null,
                  ),
                ),
                Text(
                  formatNumber(count),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _recentCard(BuildContext context) => SectionCard(
    title: context.tr('analytics.recent-orders'),
    child: _CardBody(
      loading: store.ordersLoading,
      failed: store.ordersError,
      failedKey: 'analytics.orders-error',
      onRetry: store.loadOrders,
      emptyKey: 'analytics.no-orders',
      items: [
        for (final o in store.recentOrders)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('#${o.id}'),
            subtitle: Text(
              o.scheduledDate == null
                  ? formatMoney(o.totalPrice)
                  : '${formatMoney(o.totalPrice)} · '
                        '${formatDate(o.scheduledDate)}',
            ),
            trailing: StatusChip(
              label: context.tr('order-status.${o.status.toLowerCase()}'),
              status: o.status,
            ),
            onTap: () => context.push('/ordering/order-detail/${o.id}'),
          ),
      ],
      footer: TextButton(
        onPressed: () => context.go('/ordering/order-list'),
        child: Text(context.tr('analytics.all-orders')),
      ),
    ),
  );
}

TextStyle? _mutedStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// Cuerpo de tarjeta con estados de carga, error (con reintento), vacío y contenido.
class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.loading,
    required this.failed,
    required this.failedKey,
    required this.onRetry,
    required this.emptyKey,
    required this.items,
    this.footer,
  });

  final bool loading;
  final bool failed;
  final String failedKey;
  final VoidCallback onRetry;
  final String emptyKey;
  final List<Widget> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text(
        context.tr('analytics.card-loading'),
        style: _mutedStyle(context),
      );
    }
    if (failed) {
      return Row(
        children: [
          Expanded(child: Text(context.tr(failedKey))),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('analytics.card-retry')),
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return Text(context.tr(emptyKey), style: _mutedStyle(context));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...items, ?footer],
    );
  }
}
