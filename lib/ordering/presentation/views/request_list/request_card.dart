import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../domain/model/request_entity.dart';

/// Tarjeta de una solicitud con su estado y, si aplica, los botones de aceptar y rechazar.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.title,
    required this.product,
    required this.missing,
    required this.onOpen,
    this.onAccept,
    this.onReject,
  });

  final Request request;
  final String title;
  final String product;
  final List<String> missing;
  final VoidCallback onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final unit = request.unit;
    final statusKey = RequestStatus.values.contains(request.status)
        ? request.status.toLowerCase()
        : 'unknown';
    return Card(
      child: Column(
        children: [
          ListTile(
            onTap: onOpen,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '$product\n'
              '${formatNumber(request.quantity)} $unit · '
              '${formatMoney(request.unitPrice)} / $unit\n'
              '${formatDate(request.deliveryDate)} · '
              '${request.deliveryAddress.isEmpty ? '—' : request.deliveryAddress}',
            ),
            isThreeLine: true,
            trailing: StatusChip(
              label: context.tr('request-status.$statusKey'),
              status: request.status,
            ),
          ),
          if (missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${context.tr('request-list.incomplete')}: '
                '${missing.map((field) => context.tr('request-list.missing.$field')).join(', ')}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (onAccept != null || onReject != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      child: Text(context.tr('request-list.reject-by-id')),
                    ),
                  if (onAccept != null)
                    FilledButton(
                      onPressed: missing.isEmpty ? onAccept : null,
                      child: Text(context.tr('request-list.accept-by-id')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
