import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../shared/infrastructure/i18n/translate_service.dart';
import '../../shared/presentation/component/status_chip/status_chip.dart';

/// Tono de la etiqueta de estado de cisternas, conductores y entregas.
StatusTone statusTone(String status) => switch (status) {
  'AVAILABLE' || 'COMPLETED' => StatusTone.success,
  'IN_ROUTE' || 'ASSIGNED' || 'STARTED' || 'ARRIVED' => StatusTone.info,
  'DELIVERING' => StatusTone.info,
  'MAINTENANCE' || 'SUSPENDED' => StatusTone.pending,
  'FAILED' || 'CANCELLED' => StatusTone.danger,
  _ => StatusTone.neutral,
};

/// Aviso breve tras una acción; [key] es una clave de traducción.
void showNotice(BuildContext context, String key) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.tr(key))));
}

/// Confirmación con `AlertDialog`; [message] es una clave de traducción.
Future<bool> confirmAction(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('confirm.title')),
      content: Text(context.tr(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('confirm.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.tr('confirm.confirm')),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Fila etiqueta/valor dentro de una ficha de detalle.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Filtro "Todas / Disponibles" de las listas de cisternas y conductores.
class AvailabilityFilter extends StatelessWidget {
  const AvailabilityFilter({
    super.key,
    required this.availableOnly,
    required this.onChanged,
  });

  final bool availableOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(context.tr('tanker-list.show-all')),
        ),
        ButtonSegment(
          value: true,
          label: Text(context.tr('tanker-list.show-available')),
        ),
      ],
      selected: {availableOnly},
      onSelectionChanged: (s) => onChanged(s.first),
    ),
  );
}

/// Resultado de elegibilidad de una fila (etiqueta ya traducida) o su error (clave de traducción).
class EligibilityLine extends StatelessWidget {
  const EligibilityLine({super.key, this.label, this.reason, this.error});

  final String? label;
  final String? reason;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (error != null && error!.isNotEmpty) {
      return Text(
        context.tr(error!),
        style: TextStyle(color: theme.colorScheme.error),
      );
    }
    if (label == null) return const SizedBox.shrink();
    return Text('$label · $reason', style: theme.textTheme.bodySmall);
  }
}

/// Fecha de hoy en Lima (UTC-5, sin horario de verano) como `yyyy-MM-dd`.
String limaToday() =>
    isoDate(DateTime.now().toUtc().subtract(const Duration(hours: 5)));

/// Fecha como `yyyy-MM-dd`.
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Identificador UUID v4 para `commandId` de la asignación.
String newCommandId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
