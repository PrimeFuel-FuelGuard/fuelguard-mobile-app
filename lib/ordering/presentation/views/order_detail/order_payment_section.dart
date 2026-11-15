import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/ordering_store.dart';
import '../../../domain/model/order_entity.dart';
import '../../../infrastructure/ordering_api.dart';

/// Pago de una orden: el comprador lo registra (`PENDING_PAYMENT`) y completa con la referencia.
class OrderPaymentSection extends StatefulWidget {
  const OrderPaymentSection({
    super.key,
    required this.store,
    required this.order,
    required this.isBuyer,
  });

  final OrderingStore store;
  final Order order;
  final bool isBuyer;

  @override
  State<OrderPaymentSection> createState() => _OrderPaymentSectionState();
}

class _OrderPaymentSectionState extends State<OrderPaymentSection> {
  final _reference = TextEditingController();
  String _method = PaymentMethod.bankTransfer;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final order = widget.order;
    final payment = store.payment;
    return SectionCard(
      title: context.tr('order-detail.payment'),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (store.paymentLoading)
              const Center(child: CircularProgressIndicator()),
            if (payment != null) ...[
              _line(
                context,
                'order-detail.payment-status',
                context.tr('payment-status.${payment.status.toLowerCase()}'),
              ),
              _line(
                context,
                'order-detail.payment-method',
                context.tr(
                  'order-detail.method-${payment.paymentMethod.toLowerCase()}',
                ),
              ),
              _line(
                context,
                'order-detail.payment-amount',
                formatMoney(payment.amount),
              ),
              if (payment.paidAt != null)
                _line(
                  context,
                  'order-detail.paid-at',
                  formatDateTime(payment.paidAt),
                ),
              if (payment.transactionReference != null)
                _line(
                  context,
                  'order-detail.transaction-reference',
                  payment.transactionReference!,
                ),
              if (widget.isBuyer && payment.status == PaymentStatus.pending)
                _completeForm(context, order),
            ] else if (!store.paymentLoading &&
                widget.isBuyer &&
                order.status == OrderStatus.pendingPayment)
              _paymentForm(context, order),
            if (store.paymentError.isNotEmpty)
              Text(
                context.tr(store.paymentError),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (store.paymentReadError)
              OutlinedButton(
                onPressed: store.paying || store.paymentLoading || store.loading
                    ? null
                    : store.retryPayment,
                child: Text(context.tr('request-list.retry')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) =>
      Text('${context.tr(label)}: $value');

  Widget _paymentForm(BuildContext context, Order order) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _method,
          decoration: InputDecoration(
            labelText: context.tr('order-detail.payment-method'),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final method in PaymentMethod.values)
              DropdownMenuItem(
                value: method,
                child: Text(
                  context.tr('order-detail.method-${method.toLowerCase()}'),
                ),
              ),
          ],
          onChanged: (value) => setState(() => _method = value ?? _method),
        ),
        FilledButton(
          onPressed: store.paying || store.paymentReadError || store.loading
              ? null
              : () => store.payOrder(order, _method),
          child: Text(context.tr('order-detail.submit-payment')),
        ),
      ],
    );
  }

  Widget _completeForm(BuildContext context, Order order) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TextField(
          controller: _reference,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: context.tr('order-detail.transaction-reference'),
            border: const OutlineInputBorder(),
          ),
        ),
        FilledButton(
          onPressed: store.paying || _reference.text.trim().isEmpty
              ? null
              : () => store.completePayment(order.id, _reference.text),
          child: Text(context.tr('order-detail.complete-payment')),
        ),
      ],
    );
  }
}
