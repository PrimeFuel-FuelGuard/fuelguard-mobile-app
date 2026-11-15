import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/ordering_store.dart';
import '../../../infrastructure/ordering_api.dart';
import '../../ordering_feedback.dart';

/// Historial de pagos del comprador. Los pendientes van primero y luego los más recientes.
class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory>
    with NoticeSnackBars<PaymentHistory> {
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
      ..loadPayments();
    _store.addListener(() => showNotice(_store.notice));
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  List<Payment> get _visible {
    final rows = _store.payments
        .where((payment) => _status.isEmpty || payment.status == _status)
        .toList();
    rows.sort((a, b) {
      final pending = _rank(b) - _rank(a);
      if (pending != 0) return pending;
      final paid = _paidAt(b).compareTo(_paidAt(a));
      return paid != 0 ? paid : b.id.compareTo(a.id);
    });
    return rows;
  }

  int _rank(Payment payment) => payment.status == PaymentStatus.pending ? 1 : 0;

  int _paidAt(Payment payment) =>
      DateTime.tryParse(payment.paidAt ?? '')?.millisecondsSinceEpoch ?? 0;

  Future<void> _refund(Payment payment) async {
    final confirmed = await confirmAction(
      context,
      message:
          '${context.tr('fulfillment.order')} #${payment.orderId} · '
          '${formatMoney(payment.amount)}\n'
          '${context.tr('payment-history.refund-confirmation')}',
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.refundPayment(payment);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => RefreshIndicator(
      onRefresh: () async => _store.loadPayments(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(context.tr('payment-history.all')),
                selected: _status.isEmpty,
                onSelected: (_) => setState(() => _status = ''),
              ),
              for (final status in PaymentStatus.values)
                FilterChip(
                  label: Text(
                    context.tr('payment-status.${status.toLowerCase()}'),
                  ),
                  selected: _status == status,
                  onSelected: (_) =>
                      setState(() => _status = _status == status ? '' : status),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_store.error != null)
            ErrorBanner(message: _store.error!, onRetry: _store.loadPayments),
          if (_store.refundError.isNotEmpty)
            ErrorBanner(message: _store.refundError),
          ..._body(context),
        ],
      ),
    ),
  );

  List<Widget> _body(BuildContext context) {
    if (_store.loading && _store.payments.isEmpty) return const [LoadingView()];
    final rows = _visible;
    if (rows.isEmpty) {
      return [
        EmptyState(
          icon: Icons.payments_outlined,
          message: context.tr(
            _store.payments.isEmpty
                ? 'payment-history.empty'
                : 'payment-history.no-match',
          ),
        ),
      ];
    }
    return [
      for (final payment in rows)
        Card(
          child: Column(
            children: [
              ListTile(
                onTap: () =>
                    context.push('/ordering/order-detail/${payment.orderId}'),
                title: Text(
                  '${context.tr('fulfillment.order')} #${payment.orderId} · '
                  '${formatMoney(payment.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${context.tr('order-detail.method-${payment.paymentMethod.toLowerCase()}')}\n'
                  '${payment.paidAt == null ? context.tr('payment-history.no-date') : formatDateTime(payment.paidAt)} · '
                  '${payment.transactionReference ?? '—'}',
                ),
                isThreeLine: true,
                trailing: StatusChip(
                  label: context.tr(
                    'payment-status.${payment.status.toLowerCase()}',
                  ),
                  status: payment.status,
                ),
              ),
              if (payment.status == PaymentStatus.completed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _refundButton(context, payment),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _refundButton(BuildContext context, Payment payment) {
    final refunding = _store.refundingId == payment.id;
    return OutlinedButton.icon(
      onPressed: _store.refundingId != null ? null : () => _refund(payment),
      icon: refunding
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.undo),
      label: Text(
        context.tr(
          refunding ? 'payment-history.refunding' : 'payment-history.refund',
        ),
      ),
    );
  }
}
