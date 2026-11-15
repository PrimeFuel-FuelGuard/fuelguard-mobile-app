import 'package:material_ui/material_ui.dart';

import '../../shared/infrastructure/i18n/translate_service.dart';
import '../../shared/presentation/theme/app_theme.dart';

/// Nivel del tanque en porcentaje (0–100) según capacidad.
double levelPercentOf(double current, double capacity) =>
    capacity > 0 ? (current / capacity * 100).clamp(0, 100).toDouble() : 0;

/// Color del nivel: menos de 25 % peligro, menos de 50 % aviso, resto éxito.
Color levelColor(double percent) => percent < 25
    ? FgColors.danger
    : percent < 50
    ? FgColors.warning
    : FgColors.success;

/// Barra de nivel con porcentaje y color por umbral.
class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 4,
    children: [
      LinearProgressIndicator(
        value: percent / 100,
        color: levelColor(percent),
        backgroundColor: FgColors.border,
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
      Text(
        '${percent.round()} %',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// Aviso breve tras una acción; [key] es una clave de traducción.
void showNotice(BuildContext context, String key) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.tr(key))));
}

/// Clave de traducción del tipo de combustible (`fuel-type.diesel`).
String fuelTypeKey(String? type) => 'fuel-type.${(type ?? '').toLowerCase()}';

/// Desplegable controlado con etiqueta (value/onChanged, sin estado interno de formulario).
class EquipmentDropdown<T> extends StatelessWidget {
  const EquipmentDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.error,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      errorText: error == null ? null : context.tr(error!),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
