import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../domain/model/fuel_product_entity.dart';

/// Tarjeta de producto del catálogo; las acciones de proveedor solo se muestran si se pasan.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.providerLabel,
    this.onStock,
    this.onEdit,
    this.onDelete,
  });

  final FuelProduct product;
  final String? providerLabel;
  final VoidCallback? onStock;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            leading: const CircleAvatar(child: Icon(Icons.local_gas_station)),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                context.tr('fuel-type.${p.fuelType.toLowerCase()}'),
                '${formatMoney(p.pricePerUnit)} / ${p.unit}',
                '${context.tr('product-inventory.fields.available')}: '
                    '${formatNumber(p.availableStock)} ${p.unit}',
                ?providerLabel,
              ].join('\n'),
            ),
            trailing: StatusChip(
              label: context.tr(p.active ? 'status.active' : 'status.inactive'),
              tone: p.active ? StatusTone.success : StatusTone.neutral,
            ),
          ),
          if (onStock != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onStock,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(context.tr('product-inventory.update-stock')),
                ),
                IconButton(
                  tooltip: context.tr('product-inventory.edit-tooltip'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: context.tr('product-inventory.delete-tooltip'),
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class StockSheet extends StatefulWidget {
  const StockSheet({super.key, required this.product});

  final FuelProduct product;

  @override
  State<StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<StockSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _value = TextEditingController(
    text: '${widget.product.availableStock}',
  );

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String? _validate(String? raw) {
    final value = double.tryParse((raw ?? '').trim());
    if (value == null) return context.tr('validation.required');
    if (!value.isFinite || value < 0) {
      return context.tr('validation.min-value', {'n': 0});
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(double.parse(_value.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(p.name, style: Theme.of(context).textTheme.titleMedium),
            TextFormField(
              controller: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.tr('product-inventory.stock-input'),
                suffixText: p.unit,
                helperText:
                    '${context.tr('product-form.fields.capacity')}: '
                    '${formatNumber(p.capacity)}',
              ),
              validator: _validate,
            ),
            FilledButton(
              onPressed: _submit,
              child: Text(context.tr('product-inventory.update-stock')),
            ),
          ],
        ),
      ),
    );
  }
}
