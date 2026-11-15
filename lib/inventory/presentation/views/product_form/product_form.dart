import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/inventory_store.dart';
import '../../../domain/model/fuel_product_entity.dart';
import '../../../infrastructure/inventory_api.dart';

/// Formulario de alta y edición de producto (`/fuel-products/product-form[/:id]`).
class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.productId});

  /// Id del producto a editar; `null` para crear.
  final String? productId;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  static const _units = ['LITERS', 'GALLONS'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');
  final _capacity = TextEditingController(text: '0');
  late final InventoryStore _store;
  late final IamStore _iam;
  late final int? _productId = _parseId(widget.productId);
  String? _fuelType;
  String _unit = _units.first;
  bool _active = true;
  bool _patched = false;
  bool _ready = false;

  bool get _isEdit => _productId != null;

  static int? _parseId(String? raw) {
    final id = int.tryParse(raw ?? '') ?? 0;
    return id == 0 ? null : id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _iam = app.iamStore;
    _store = InventoryStore(InventoryApi(app.httpClient))
      ..clearError()
      ..addListener(_fillFromStore);
    final id = _productId;
    if (id != null) _store.loadProductById(id);
  }

  @override
  void dispose() {
    _store.removeListener(_fillFromStore);
    _store.dispose();
    for (final c in [_name, _price, _stock, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFromStore() {
    final p = _store.selectedProduct;
    if (!_isEdit || _patched || p == null || p.id != _productId) return;
    _patched = true;
    setState(() {
      _name.text = p.name;
      _fuelType = p.fuelType;
      _price.text = '${p.pricePerUnit}';
      _unit = p.unit;
      _stock.text = '${p.availableStock}';
      _capacity.text = '${p.capacity}';
      _active = p.active;
    });
  }

  String? _required(String? value) =>
      (value ?? '').isEmpty ? context.tr('validation.required') : null;

  String? _minLength(String? value) {
    final required = _required(value);
    if (required != null) return required;
    return (value ?? '').length < 3
        ? context.tr('validation.min-length', {'n': 3})
        : null;
  }

  String? _minNumber(String? value, double min) {
    final required = _required(value);
    if (required != null) return required;
    final number = double.tryParse(value!.trim());
    if (number == null) return context.tr('validation.required');
    return number < min ? context.tr('validation.min-value', {'n': min}) : null;
  }

  void _submit() {
    if (_store.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = double.parse(_price.text.trim());
    final stock = double.parse(_stock.text.trim());
    final capacity = double.parse(_capacity.text.trim());
    final id = _productId;
    if (id != null) {
      _store.updateProduct(
        id,
        UpdateProductPayload(
          name: _name.text,
          fuelType: _fuelType!,
          pricePerUnit: price,
          unit: _unit,
          availableStock: stock,
          capacity: capacity,
          active: _active,
        ),
        _goToInventory,
      );
      return;
    }
    final providerId = _iam.providerId;
    if (providerId == null) return;
    _store.createProduct(
      CreateProductPayload(
        name: _name.text,
        fuelType: _fuelType!,
        pricePerUnit: price,
        unit: _unit,
        availableStock: stock,
        capacity: capacity,
        providerId: providerId,
        active: true,
      ),
      _goToInventory,
    );
  }

  void _goToInventory() {
    if (mounted) context.go('/fuel-products');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  context.tr(
                    _isEdit
                        ? 'product-form.edit-subtitle'
                        : 'product-form.create-subtitle',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_store.error != null) ...[
                  ErrorBanner(message: _store.error!),
                  const SizedBox(height: 16),
                ],
                ..._fields(context),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _store.isLoading ? null : _goToInventory,
                      child: Text(context.tr('product-form.cancel')),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _store.isLoading ? null : _submit,
                      child: Text(
                        context.tr(
                          _isEdit
                              ? 'product-form.update'
                              : 'product-form.create',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _fields(BuildContext context) {
    final numberType = const TextInputType.numberWithOptions(decimal: true);
    return [
      TextFormField(
        controller: _name,
        decoration: InputDecoration(
          labelText: context.tr('product-form.fields.name'),
        ),
        validator: _minLength,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('fuel-type-$_patched'),
        initialValue: _fuelType,
        decoration: InputDecoration(
          labelText: context.tr('product-form.fields.type'),
        ),
        items: [
          for (final type in fuelTypes)
            DropdownMenuItem(
              value: type,
              child: Text(context.tr('fuel-type.${type.toLowerCase()}')),
            ),
        ],
        onChanged: (value) => setState(() => _fuelType = value),
        validator: _required,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _price,
        keyboardType: numberType,
        decoration: InputDecoration(
          labelText: context.tr('product-form.fields.price'),
          prefixText: 'S/ ',
        ),
        validator: (v) => _minNumber(v, 0.01),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('unit-$_patched'),
        initialValue: _unit,
        decoration: InputDecoration(
          labelText: context.tr('product-form.fields.unit'),
        ),
        items: [
          for (final unit in _units)
            DropdownMenuItem(
              value: unit,
              child: Text(
                context.tr(unit == 'LITERS' ? 'unit.liters' : 'unit.gallons'),
              ),
            ),
        ],
        onChanged: (value) => setState(() => _unit = value ?? _unit),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _stock,
        keyboardType: numberType,
        decoration: InputDecoration(
          labelText: context.tr('product-inventory.fields.available'),
        ),
        validator: (v) => _minNumber(v, 0),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _capacity,
        keyboardType: numberType,
        decoration: InputDecoration(
          labelText: context.tr('product-form.fields.capacity'),
        ),
        validator: (v) => _minNumber(v, 0.01),
      ),
      if (_isEdit)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('product-form.fields.active')),
          value: _active,
          onChanged: (value) => setState(() => _active = value),
        ),
    ];
  }
}
