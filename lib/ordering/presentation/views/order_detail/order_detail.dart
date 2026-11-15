import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/ordering_store.dart';
import '../../../domain/model/order_entity.dart';
import '../../../infrastructure/ordering_api.dart';
import '../../ordering_feedback.dart';
import 'order_payment_section.dart';

/// Detalle de una orden: el comprador confirma o cancela y registra el pago; el distribuidor puede cancelar.
class OrderDetail extends StatefulWidget {
  const OrderDetail({super.key, required this.id});

  final int id;

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  late final OrderingStore _store;
  late final IamStore _iam;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _iam = app.iamStore;
    _store = OrderingStore(OrderingApi(app.httpClient), _iam)
      ..loadNames()
      ..openOrder(widget.id);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _confirm(Order order) async {
    final confirmed = await confirmAction(
      context,
      message: '${context.tr('order-detail.confirm')} #${order.id}',
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.confirmOrder(order.id);
  }

  Future<void> _cancel(Order order) async {
    final confirmed = await confirmAction(
      context,
      message: '${context.tr('order-detail.cancel')} #${order.id}',
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.cancelOrder(order.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final order = _store.order;
      return RefreshIndicator(
        onRefresh: () async => _store.openOrder(widget.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_store.error != null) ...[
              ErrorBanner(
                message: _store.error!,
                onRetry: () => _store.openOrder(widget.id),
              ),
              const SizedBox(height: 12),
            ],
            if (order == null && _store.loading) const LoadingView(),
            if (order == null && !_store.loading)
              EmptyState(
                message: context.tr('order-detail.not-found'),
                icon: Icons.search_off,
              ),
            if (order != null) ..._content(context, order),
          ],
        ),
      );
    },
  );

  List<Widget> _content(BuildContext context, Order order) {
    final buyer = _iam.isBuyer;
    final busy = _store.loading || _store.paying;
    final showPayment = const [
      OrderStatus.pendingPayment,
      OrderStatus.paid,
      OrderStatus.inProgress,
      OrderStatus.delivered,
    ].contains(order.status);
    return [
      SectionCard(
        title: '#${order.id}',
        trailing: StatusChip(
          label: context.tr('order-status.${order.status.toLowerCase()}'),
          status: order.status,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            _Field(
              label: context.tr('order-detail.request-id'),
              value: order.requestId == null ? '—' : '#${order.requestId}',
            ),
            _Field(
              label: context.tr('order-detail.client'),
              value: _store.companyName ?? '#${order.companyId}',
            ),
            _Field(
              label: context.tr('order-detail.provider'),
              value:
                  _store.providerNames[order.providerId] ??
                  '#${order.providerId}',
            ),
            _Field(
              label: context.tr('order-detail.product'),
              value:
                  _store.productNames[order.fuelProductId] ??
                  '#${order.fuelProductId}',
            ),
            _Field(
              label: context.tr('order-detail.quantity'),
              value: formatNumber(order.requestedQuantity),
            ),
            _Field(
              label: context.tr('order-detail.total'),
              value: formatMoney(order.totalPrice),
            ),
            _Field(
              label: context.tr('order-detail.address'),
              value: order.deliveryAddress.isEmpty
                  ? '—'
                  : order.deliveryAddress,
            ),
            if (order.scheduledDate != null)
              _Field(
                label: context.tr('order-detail.scheduled-date'),
                value: formatDate(order.scheduledDate),
              ),
          ],
        ),
      ),
      if (_canConfirm(order) || _canCancel(order))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_canCancel(order))
                OutlinedButton(
                  onPressed: busy ? null : () => _cancel(order),
                  child: Text(context.tr('order-detail.cancel')),
                ),
              if (_canConfirm(order))
                FilledButton(
                  onPressed: busy ? null : () => _confirm(order),
                  child: Text(context.tr('order-detail.confirm')),
                ),
            ],
          ),
        ),
      if (showPayment) ...[
        const SizedBox(height: 12),
        OrderPaymentSection(store: _store, order: order, isBuyer: buyer),
      ],
    ];
  }

  bool _canConfirm(Order order) =>
      _iam.isBuyer && order.status == OrderStatus.pending;

  bool _canCancel(Order order) =>
      (order.status == OrderStatus.pending ||
          order.status == OrderStatus.confirmed) &&
      (_iam.isBuyer || _iam.isProvider);
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}
