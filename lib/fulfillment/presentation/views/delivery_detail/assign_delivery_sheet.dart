import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/provider_delivery_entity.dart';
import '../../fulfillment_ui.dart';

/// Hoja modal para asignar cisterna y conductor al pedido. Devuelve el id de la entrega creada.
Future<int?> showAssignDeliverySheet(
  BuildContext context, {
  required FulfillmentStore store,
  required int orderId,
  required String? scheduledDate,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _AssignSheet(
    store: store,
    orderId: orderId,
    scheduledDate: scheduledDate,
  ),
);

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({
    required this.store,
    required this.orderId,
    required this.scheduledDate,
  });

  final FulfillmentStore store;
  final int orderId;
  final String? scheduledDate;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  final _commandId = newCommandId();
  int? _driverId;
  int? _tankerId;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    widget.store
      ..loadAvailableDrivers()
      ..loadAvailableTankers()
      ..loadRecommendation(widget.orderId);
  }

  bool get _windowValid {
    final s = _start;
    final e = _end;
    return s != null && e != null && s.isBefore(e);
  }

  Future<void> _pickWindow({required bool start}) async {
    final initial = (start ? _start : _end) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
    if (_windowValid) {
      widget.store.loadRecommendation(
        widget.orderId,
        _start!.toUtc().toIso8601String(),
        _end!.toUtc().toIso8601String(),
      );
    }
  }

  void _useRecommendation(DeliveryRecommendation rec) {
    final store = widget.store;
    final driverListed = store.driverList.any((d) => d.id == rec.driverId);
    final tankerListed = store.tankerList.any((t) => t.id == rec.tankerId);
    if (!rec.recommended || !driverListed || !tankerListed) return;
    setState(() {
      _driverId = rec.driverId;
      _tankerId = rec.tankerId;
      _start = DateTime.parse(rec.windowStart).toLocal();
      _end = DateTime.parse(rec.windowEnd).toLocal();
    });
  }

  Future<void> _submit() async {
    final id = await widget.store.assignDelivery({
      'commandId': _commandId,
      'orderId': widget.orderId,
      'driverId': _driverId,
      'tankerId': _tankerId,
      'windowStart': _start!.toUtc().toIso8601String(),
      'windowEnd': _end!.toUtc().toIso8601String(),
      'scheduledDate': widget.scheduledDate,
    });
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final busy = store.isLoading;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                context.tr('fulfillment.assign'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _RecommendationBox(store: store, onUse: _useRecommendation),
              _Pick(
                label: context.tr('fulfillment.driver'),
                value: _driverId,
                items: [
                  for (final d in store.driverList)
                    (d.id, '${d.firstName} ${d.lastName}'),
                ],
                onChanged: (v) => setState(() => _driverId = v),
              ),
              _Pick(
                label: context.tr('fulfillment.tanker'),
                value: _tankerId,
                items: [
                  for (final t in store.tankerList)
                    (t.id, '${t.licensePlate} · ${t.brand} ${t.model}'),
                ],
                onChanged: (v) => setState(() => _tankerId = v),
              ),
              _WindowTile(
                label: context.tr('fulfillment.window-start'),
                value: _start,
                onTap: () => _pickWindow(start: true),
              ),
              _WindowTile(
                label: context.tr('fulfillment.window-end'),
                value: _end,
                onTap: () => _pickWindow(start: false),
              ),
              if (store.error != null) ErrorBanner(message: store.error!),
              FilledButton(
                onPressed:
                    _driverId != null &&
                        _tankerId != null &&
                        _windowValid &&
                        !busy
                    ? _submit
                    : null,
                child: Text(context.tr('fulfillment.submit-assignment')),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RecommendationBox extends StatelessWidget {
  const _RecommendationBox({required this.store, required this.onUse});

  final FulfillmentStore store;
  final ValueChanged<DeliveryRecommendation> onUse;

  @override
  Widget build(BuildContext context) {
    final rec = store.recommendation;
    if (store.recommendationLoading) {
      return Text(context.tr('fulfillment.recommendation.loading'));
    }
    if (store.recommendationError != null) {
      return ErrorBanner(message: store.recommendationError!);
    }
    if (rec == null) return const SizedBox.shrink();
    if (!rec.recommended) {
      return Text(
        context.tr('fulfillment.recommendation.reason.${rec.reason ?? ''}'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('fulfillment.recommendation.title')}: '
          '${rec.driverName ?? '-'} · ${rec.licensePlate ?? '-'}',
        ),
        Text(
          context.tr('fulfillment.recommendation.criterion'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: () => onUse(rec),
          child: Text(context.tr('fulfillment.recommendation.use')),
        ),
      ],
    );
  }
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<(int, String)> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: items.any((i) => i.$1 == value) ? value : null,
        isExpanded: true,
        hint: Text(context.tr('fulfillment.delivery-list.any')),
        items: [
          for (final (id, text) in items)
            DropdownMenuItem(value: id, child: Text(text)),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

class _WindowTile extends StatelessWidget {
  const _WindowTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value == null ? '—' : formatDateTime(value)),
    trailing: const Icon(Icons.edit_calendar_outlined),
    onTap: onTap,
  );
}
