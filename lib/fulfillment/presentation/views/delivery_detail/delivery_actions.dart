import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../application/fulfillment_store.dart';
import '../../fulfillment_ui.dart';

/// Transiciones disponibles según el estado físico; cada una pide su confirmación.
class DeliveryActions extends StatelessWidget {
  const DeliveryActions({super.key, required this.store, required this.id});

  final FulfillmentStore store;
  final int id;

  static const _actions = [
    ('start', 'fulfillment.start'),
    ('arrive', 'fulfillment.arrive'),
    ('complete', 'fulfillment.complete'),
    ('fail', 'fulfillment.fail'),
    ('cancel', 'fulfillment.cancel-delivery'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (action, label) in _actions)
        if (store.canCommand(action))
          FilledButton.tonal(
            onPressed: store.commandBusy
                ? null
                : () => _run(context, action, label),
            child: Text(context.tr(label)),
          ),
    ],
  );

  Future<void> _run(BuildContext context, String action, String label) async {
    switch (action) {
      case 'fail' || 'cancel':
        final reason = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ReasonSheet(label: label),
        );
        if (reason == null) return;
        await store.deliveryCommand(id, action, reason: reason);
      case 'complete':
        final volume = await showDialog<double>(
          context: context,
          builder: (_) => const _VolumeDialog(),
        );
        if (volume == null) return;
        await store.deliveryCommand(id, action, deliveredVolume: volume);
      default:
        if (!context.mounted || !await confirmAction(context, label)) return;
        await store.deliveryCommand(id, action);
    }
  }
}

/// Motivo obligatorio para marcar como fallida o cancelar la entrega.
class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.label});

  final String label;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _reason.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.tr('fulfillment.reason'),
            ),
            onChanged: (_) => setState(() {}),
          ),
          FilledButton(
            onPressed: text.isEmpty
                ? null
                : () => Navigator.of(context).pop(text),
            child: Text(context.tr(widget.label)),
          ),
        ],
      ),
    );
  }
}

/// Volumen entregado (> 0) para completar la entrega.
class _VolumeDialog extends StatefulWidget {
  const _VolumeDialog();

  @override
  State<_VolumeDialog> createState() => _VolumeDialogState();
}

class _VolumeDialogState extends State<_VolumeDialog> {
  final _volume = TextEditingController();

  @override
  void dispose() {
    _volume.dispose();
    super.dispose();
  }

  double? get _parsed =>
      double.tryParse(_volume.text.trim().replaceAll(',', '.'));

  bool get _valid {
    final v = _parsed;
    return v != null && v.isFinite && v > 0;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('confirm.title')),
    content: TextField(
      controller: _volume,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: context.tr('fulfillment.delivered-volume'),
      ),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('confirm.cancel')),
      ),
      FilledButton(
        onPressed: _valid ? () => Navigator.of(context).pop(_parsed) : null,
        child: Text(context.tr('fulfillment.complete')),
      ),
    ],
  );
}
