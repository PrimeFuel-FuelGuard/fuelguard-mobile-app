import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/ordering_store.dart';
import '../../../domain/model/request_entity.dart';
import '../../../infrastructure/ordering_api.dart';
import '../../ordering_feedback.dart';

/// Detalle de una solicitud: el comprador puede cancelarla y el distribuidor dueño aceptarla o rechazarla.
class RequestDetail extends StatefulWidget {
  const RequestDetail({super.key, required this.id});

  final int id;

  @override
  State<RequestDetail> createState() => _RequestDetailState();
}

class _RequestDetailState extends State<RequestDetail>
    with NoticeSnackBars<RequestDetail> {
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
      ..loadRequest(widget.id);
    _store.addListener(() => showNotice(_store.notice));
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Request? get _request {
    for (final row in _store.requests) {
      if (row.id == widget.id) return row;
    }
    return null;
  }

  Future<void> _cancel(Request request) async {
    final confirmed = await confirmAction(
      context,
      message: context.tr('request-detail.confirm-cancel'),
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.cancelRequest(request.id);
  }

  Future<void> _accept(Request request) async {
    final confirmed = await confirmAction(
      context,
      message: context.tr('request-detail.confirm-accept'),
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (confirmed) _store.acceptRequest(request.id);
  }

  Future<void> _reject(Request request) async {
    final reason = await askText(
      context,
      title: context.tr('request-detail.confirm-reject'),
      label: context.tr('request-list.reason'),
      confirmLabel: context.tr('confirm.confirm'),
    );
    if (reason != null) _store.rejectRequest(request.id, reason);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final request = _request;
      return RefreshIndicator(
        onRefresh: () async => _store.loadRequest(widget.id),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_store.error != null) ...[
              ErrorBanner(
                message: _store.error!,
                onRetry: () => _store.loadRequest(widget.id),
              ),
              const SizedBox(height: 12),
            ],
            if (request == null && _store.loading) const LoadingView(),
            if (request != null) ...[
              _RequestSummary(request: request, store: _store),
              if (request.status == RequestStatus.pending && !_store.loading)
                _actions(context, request),
            ],
          ],
        ),
      );
    },
  );

  Widget _actions(BuildContext context, Request request) {
    final buyer = _iam.isBuyer;
    final owner = _iam.isProvider && _iam.providerId == request.providerId;
    if (!buyer && !owner) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (buyer)
            OutlinedButton(
              onPressed: () => _cancel(request),
              child: Text(context.tr('request-list.cancel')),
            ),
          if (owner) ...[
            OutlinedButton(
              onPressed: () => _reject(request),
              child: Text(context.tr('request-detail.reject')),
            ),
            FilledButton(
              onPressed: () => _accept(request),
              child: Text(context.tr('request-detail.accept')),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.request, required this.store});

  final Request request;
  final OrderingStore store;

  @override
  Widget build(BuildContext context) {
    final statusKey = request.status.toLowerCase();
    return SectionCard(
      title: '${context.tr('request-detail.title')} #${request.id}',
      trailing: StatusChip(
        label: context.tr('request-status.$statusKey'),
        status: request.status,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _Field(
            label: context.tr('request-detail.organization'),
            value: '#${request.organizationId}',
          ),
          _Field(
            label: context.tr('request-detail.customer'),
            value: '#${request.customerAccountId}',
          ),
          _Field(
            label: context.tr('request-detail.tank'),
            value: request.tankId == null ? '—' : '#${request.tankId}',
          ),
          _Field(
            label: context.tr('request-list.provider'),
            value:
                store.providerNames[request.providerId] ??
                '#${request.providerId}',
          ),
          _Field(
            label: context.tr('request-list.product'),
            value:
                store.productNames[request.fuelProductId] ??
                '#${request.fuelProductId}',
          ),
          _Field(
            label: context.tr('request-list.quantity'),
            value: formatNumber(request.quantity, 3),
          ),
          _Field(
            label: context.tr('request-detail.unit'),
            value: context.tr(_unitKey(request.unit)),
          ),
          _Field(
            label: context.tr('request-list.unit-price'),
            value: formatMoney(request.unitPrice),
          ),
          _Field(
            label: context.tr('request-detail.source'),
            value: context.tr(
              request.source == RequestSource.automatic
                  ? 'request-list.automatic'
                  : 'request-detail.manual',
            ),
          ),
          if (request.rejectionReason != null)
            _Field(
              label: context.tr('request-list.rejection-reason'),
              value: request.rejectionReason!,
            ),
          _Field(
            label: context.tr('request-list.order'),
            value: request.orderId == null ? '—' : '#${request.orderId}',
            onTap: request.orderId == null
                ? null
                : () =>
                      context.push('/ordering/order-detail/${request.orderId}'),
          ),
          _Field(
            label: context.tr('request-list.address'),
            value: request.deliveryAddress.isEmpty
                ? '—'
                : request.deliveryAddress,
          ),
          _Field(
            label: context.tr('request-list.delivery-date'),
            value: formatDate(request.deliveryDate),
          ),
          _Field(
            label: context.tr('request-detail.version'),
            value: '${request.version}',
          ),
        ],
      ),
    );
  }

  static String _unitKey(String unit) => switch (unit) {
    'LITRE' || 'LITERS' => 'unit.liters',
    'GALLON' || 'GALLONS' => 'unit.gallons',
    _ => unit,
  };
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onTap == null ? null : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
