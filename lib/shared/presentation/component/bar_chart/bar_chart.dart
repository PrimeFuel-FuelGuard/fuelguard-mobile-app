import 'package:material_ui/material_ui.dart';

/// Gráfico de barras horizontales hecho con `Container`s. Etiquetas ya traducidas.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data, this.format});

  final List<(String label, double value)> data;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = data.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    String fmt(double v) => format != null
        ? format!(v)
        : (v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : v.toStringAsFixed(2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final (label, value) in data)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(fmt(value), style: theme.textTheme.labelLarge),
                ],
              ),
              LayoutBuilder(
                builder: (context, c) {
                  final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Container(
                        height: 10,
                        width: c.maxWidth * ratio,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
