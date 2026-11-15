import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/ordering_store.dart';
import '../../../infrastructure/ordering_api.dart';
import '../../ordering_feedback.dart';

/// Pagos de los pedidos del distribuidor, filtrables por estado: confirma pagos pendientes y reembolsa completados.
class ProviderPayments extends StatefulWidget {
  const ProviderPayments({super.key});

  @override
  State<ProviderPayments> createState() => _ProviderPaymentsState();
}

class _ProviderPaymentsState extends State<ProviderPayments>
    with NoticeSnackBars<ProviderPayments> {
  late final OrderingStore _store;
  bool _ready = false;
  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = OrderingStore(OrderingApi(app.httpClient), app.iamStore)
      ..loadProviderPayments();
    _store.addListener(() => showNotice(_store.notice));
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _setStatus(String value) {
    setState(() => _status = value);
    _store.loadProviderPayments(status: value);
  }

  Future<void> _complete(ProviderPayment payment) async {
    final reference = await askText(
      context,
      title: context.tr('provider-payments.complete-title'),
      label: context.tr('provider-payments.reference'),
      confirmLabel: context.tr('provider-payments.complete'),
      message:
          '${context.tr('provider-payments.order')} #${payment.orderId} · '
          '${formatNumber(payment.amount, 2)}',
      maxLength: null,
    );
    if (reference != null) _store.completeProviderPayment(payment, reference);
  }

  Future<void> _refund(ProviderPayment payment) async {
    final confirmed = await confirmAction(
      context,
      message:
          '${context.tr('provider-payments.order')} #${payment.orderId} · '
          '${formatNumber(payment.amount, 2)}\n'
          '${context.tr('provider-payments.refund-confirmation')}',
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.refundProviderPayment(payment);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => RefreshIndicator(
      onRefresh: () async => _store.loadProviderPayments(status: _status),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(context.tr('provider-payments.all')),
                selected: _status.isEmpty,
                onSelected: (_) => _setStatus(''),
              ),
              for (final status in PaymentStatus.values)
                FilterChip(
                  label: Text(
                    context.tr('payment-status.${status.toLowerCase()}'),
                  ),
                  selected: _status == status,
                  onSelected: (_) =>
                      _setStatus(_status == status ? '' : status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('provider-payments.currency-hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_store.error != null)
            ErrorBanner(
              message: _store.error!,
              onRetry: () => _store.loadProviderPayments(status: _status),
            ),
          if (_store.providerActionError.isNotEmpty)
            ErrorBanner(message: _store.providerActionError),
          ..._body(context),
        ],
      ),
    ),
  );

  List<Widget> _body(BuildContext context) {
    final rows = _store.providerPayments;
    if (_store.loading && rows.isEmpty) return const [LoadingView()];
    if (rows.isEmpty && _store.error == null) {
      return [
        EmptyState(
          icon: Icons.payments_outlined,
          message: context.tr('provider-payments.empty'),
        ),
      ];
    }
    return [for (final payment in rows) _paymentCard(context, payment)];
  }

  Widget _paymentCard(BuildContext context, ProviderPayment payment) {
    final busy = _store.busyProviderPaymentId;
    final working = busy == payment.id;
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${context.tr('provider-payments.order')} #${payment.orderId} · '
              '${payment.buyerName ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${formatNumber(payment.amount, 2)} '
              '(${context.tr(payment.currency ?? 'provider-payments.currency-unknown')})\n'
              '${context.tr('order-detail.method-${payment.paymentMethod.toLowerCase()}')} · '
              '${formatDateTime(payment.createdAt)}\n'
              '${context.tr('provider-payments.paid')}: '
              '${payment.paidAt == null ? context.tr('provider-payments.no-date') : formatDateTime(payment.paidAt)}',
            ),
            isThreeLine: true,
            trailing: StatusChip(
              label: context.tr(
                'payment-status.${payment.status.toLowerCase()}',
              ),
              status: payment.status,
            ),
          ),
          if (payment.status == PaymentStatus.pending ||
              payment.status == PaymentStatus.completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: busy != null
                      ? null
                      : () => payment.status == PaymentStatus.pending
                            ? _complete(payment)
                            : _refund(payment),
                  child: Text(_actionLabel(context, payment, working)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _actionLabel(
    BuildContext context,
    ProviderPayment payment,
    bool working,
  ) {
    if (payment.status == PaymentStatus.pending) {
      return context.tr(
        working ? 'provider-payments.completing' : 'provider-payments.complete',
      );
    }
    return context.tr(
      working ? 'provider-payments.refunding' : 'provider-payments.refund',
    );
  }
}
