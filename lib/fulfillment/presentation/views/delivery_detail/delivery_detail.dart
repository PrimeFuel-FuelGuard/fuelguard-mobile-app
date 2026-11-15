import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/fulfillment_store.dart';
import '../../../infrastructure/fulfillment_api.dart';
import 'assign_delivery_sheet.dart';
import 'delivery_actions.dart';
import 'delivery_detail_sections.dart';
import 'geofence_form.dart';

/// Detalle de una entrega (`/fulfillment/delivery-detail/:id`). [rawId] es el segmento `:id`.
class DeliveryDetail extends StatefulWidget {
  const DeliveryDetail({super.key, this.rawId});

  final String? rawId;

  @override
  State<DeliveryDetail> createState() => _DeliveryDetailState();
}

class _DeliveryDetailState extends State<DeliveryDetail> {
  late final FulfillmentStore _store;
  bool _ready = false;
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient));
    _id = int.tryParse(widget.rawId ?? '');
    final id = _id;
    if (id != null) _store.reloadDelivery(id);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    final id = _id;
    return id == null ? Future.value() : _store.reloadDelivery(id);
  }

  Future<void> _assign(Map<String, dynamic> delivery) async {
    final newId = await showAssignDeliverySheet(
      context,
      store: _store,
      orderId: (delivery['orderId'] as num).toInt(),
      scheduledDate: delivery['scheduledDate'] as String?,
    );
    if (newId != null && mounted) {
      context.replace('/fulfillment/delivery-detail/$newId');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final id = _id;
      if (id == null) {
        return ErrorBanner(message: 'fulfillment.delivery-load-failed');
      }
      final delivery = _store.delivery;
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (delivery == null)
              _store.sectionFailed(DeliverySection.detail)
                  ? ErrorBanner(
                      message: 'fulfillment.delivery-load-failed',
                      onRetry: _reload,
                    )
                  : LoadingView(
                      message: context.tr('fulfillment.delivery-loading'),
                    )
            else
              _DeliveryBody(
                store: _store,
                id: id,
                delivery: delivery,
                onAssign: () => _assign(delivery),
              ),
          ],
        ),
      );
    },
  );
}

class _DeliveryBody extends StatelessWidget {
  const _DeliveryBody({
    required this.store,
    required this.id,
    required this.delivery,
    required this.onAssign,
  });

  final FulfillmentStore store;
  final int id;
  final Map<String, dynamic> delivery;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (store.error != null) ErrorBanner(message: store.error!),
      DeliveryStatusCard(store: store, delivery: delivery),
      SectionCard(
        title: context.tr('fulfillment.dispatch'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            DeliveryActions(store: store, id: id),
            OutlinedButton.icon(
              onPressed: store.commandBusy ? null : onAssign,
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(context.tr('fulfillment.assign')),
            ),
          ],
        ),
      ),
      DeliveryTrackingCard(store: store),
      DeliveryValveCard(store: store, id: id),
      GeofenceForm(store: store, id: id),
      DeliveryLinesCard(
        title: 'fulfillment.transitions',
        failed: store.sectionFailed(DeliverySection.transitions),
        lines: [for (final t in store.transitions) _transitionLine(context, t)],
      ),
      DeliveryLinesCard(
        title: 'fulfillment.timeline',
        failed: store.sectionFailed(DeliverySection.timeline),
        lines: [for (final item in store.timeline) _timelineLine(item)],
      ),
      DeliveryLinesCard(
        title: 'fulfillment.samples',
        failed: store.sectionFailed(DeliverySection.samples),
        lines: [for (final s in store.samples) _sampleLine(s)],
      ),
    ],
  );

  String _transitionLine(BuildContext context, Map<String, dynamic> t) {
    final from = t['fromState'];
    final fromLabel = from == null
        ? '—'
        : context.tr('delivery-status.${from.toString().toLowerCase()}');
    final toLabel = context.tr(
      'delivery-status.${t['toState'].toString().toLowerCase()}',
    );
    return '${formatDateTime(t['occurredAt'])} · $fromLabel → $toLabel '
        '· v${t['aggregateVersion']}';
  }

  String _timelineLine(Map<String, dynamic> item) =>
      '${formatDateTime(item['occurredAt'])} · ${item['type']} · '
      '${item['summary']}';

  String _sampleLine(Map<String, dynamic> s) =>
      '${formatDateTime(s['recordedAt'])} · ${s['kind']} · '
      '${s['latitude']}, ${s['longitude']} · '
      '${s['milestone']} ${s['volume'] ?? ''} ${s['unit'] ?? ''}';
}
