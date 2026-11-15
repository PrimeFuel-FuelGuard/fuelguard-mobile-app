import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/fulfillment_store.dart';
import '../../fulfillment_ui.dart';

/// Estado físico, partes y fechas de la entrega.
class DeliveryStatusCard extends StatelessWidget {
  const DeliveryStatusCard({
    super.key,
    required this.store,
    required this.delivery,
  });

  final FulfillmentStore store;
  final Map<String, dynamic> delivery;

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final state = '${d['physicalState']}';
    String value(String key) => d[key] == null ? '—' : '${d[key]}';
    return SectionCard(
      title:
          '${context.tr('fulfillment.physical-state')}: '
          '${context.tr('delivery-status.${state.toLowerCase()}')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(
            label: context.tr('fulfillment.driver'),
            value: store.driverName.isEmpty
                ? '#${value('driverId')}'
                : store.driverName,
          ),
          InfoRow(
            label: context.tr('fulfillment.tanker'),
            value: store.tankerName.isEmpty
                ? '#${value('vehicleId')}'
                : store.tankerName,
          ),
          InfoRow(
            label: context.tr('fulfillment.order'),
            value: '#${value('orderId')}',
          ),
          InfoRow(
            label: context.tr('fulfillment.requested-volume'),
            value: value('requestedVolume'),
          ),
          InfoRow(
            label: context.tr('fulfillment.delivered-volume'),
            value: value('deliveredVolume'),
          ),
          if (d['notes'] != null)
            InfoRow(
              label: context.tr('fulfillment.notes'),
              value: value('notes'),
            ),
          const Divider(),
          for (final (key, label) in const [
            ('dispatchedAt', 'fulfillment.dispatched-at'),
            ('startedAt', 'fulfillment.started-at'),
            ('arrivedAt', 'fulfillment.arrived-at'),
            ('deliveringAt', 'fulfillment.delivering-at'),
            ('deliveredAt', 'fulfillment.delivered-at'),
          ])
            InfoRow(label: context.tr(label), value: formatDateTime(d[key])),
        ],
      ),
    );
  }
}

/// Última posición y carga reportadas por el seguimiento.
class DeliveryTrackingCard extends StatelessWidget {
  const DeliveryTrackingCard({super.key, required this.store});

  final FulfillmentStore store;

  @override
  Widget build(BuildContext context) {
    final t = store.tracking;
    final failed = store.sectionFailed(DeliverySection.tracking);
    return SectionCard(
      title: context.tr('fulfillment.tracking'),
      child: t != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: context.tr('fulfillment.position'),
                  value: t['lastLatitude'] == null
                      ? '—'
                      : '${t['lastLatitude']}, ${t['lastLongitude']}',
                ),
                InfoRow(
                  label: context.tr('fulfillment.accuracy'),
                  value: t['lastAccuracyMeters'] == null
                      ? '—'
                      : '${t['lastAccuracyMeters']} m',
                ),
                InfoRow(
                  label: context.tr('fulfillment.last-position-at'),
                  value: formatDateTime(t['lastPositionAt']),
                ),
                InfoRow(
                  label: context.tr('fulfillment.load-state'),
                  value: context.tr(
                    t['loaded'] == true
                        ? 'fulfillment.loaded'
                        : 'fulfillment.not-loaded',
                  ),
                ),
                InfoRow(
                  label: context.tr('fulfillment.load-milestone'),
                  value: '${t['lastLoadMilestone'] ?? '—'}',
                ),
                InfoRow(
                  label: context.tr('fulfillment.load-volume'),
                  value: t['lastLoadVolume'] == null
                      ? '—'
                      : '${t['lastLoadVolume']} ${t['lastLoadUnit'] ?? ''}',
                ),
              ],
            )
          : Text(
              context.tr(
                failed
                    ? 'fulfillment.section-error'
                    : 'fulfillment.no-tracking',
              ),
            ),
    );
  }
}

/// Observaciones de válvula; las no autorizadas se marcan en rojo.
class DeliveryValveCard extends StatelessWidget {
  const DeliveryValveCard({super.key, required this.store, required this.id});

  final FulfillmentStore store;
  final int id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final observations = store.valve;
    return SectionCard(
      title: context.tr('fulfillment.valve.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.sectionFailed(DeliverySection.valve))
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('fulfillment.valve.error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => store.loadValve(id),
                  child: Text(context.tr('fulfillment.valve.retry')),
                ),
              ],
            )
          else if (observations != null) ...[
            if (observations.isEmpty)
              Text(context.tr('fulfillment.valve.none')),
            for (final v in observations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${formatDateTime(v.recordedAt)} · '
                  '${context.tr('fulfillment.valve.${v.state.toLowerCase()}')}'
                  '${v.commandId == null ? '' : ' · ${v.commandId}'}'
                  '${v.unauthorized ? '\n${context.tr('fulfillment.valve.unauthorized')}' : ''}',
                  style: v.unauthorized
                      ? TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
              ),
            if (observations.isNotEmpty)
              Text(
                context.tr('fulfillment.valve.hint'),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

/// Lista cronológica de texto (transiciones, cronología o muestras).
class DeliveryLinesCard extends StatelessWidget {
  const DeliveryLinesCard({
    super.key,
    required this.title,
    required this.failed,
    required this.lines,
  });

  final String title;
  final bool failed;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: context.tr(title),
    child: failed
        ? Text(
            context.tr('fulfillment.section-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
            ],
          ),
  );
}
