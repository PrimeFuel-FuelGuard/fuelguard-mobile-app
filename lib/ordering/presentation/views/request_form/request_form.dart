import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../equipment/infrastructure/equipment_api.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/request_form_store.dart';
import '../../../domain/model/request_entity.dart';
import '../../../infrastructure/ordering_api.dart';

/// Nueva solicitud manual: distribuidor, producto de su catálogo, cantidad, fecha y dirección.
class RequestForm extends StatefulWidget {
  const RequestForm({super.key});

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  late final RequestFormStore _store;
  bool _ready = false;
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _address = TextEditingController();
  int? _siteId;
  int? _tankId;
  int? _providerId;
  int? _productId;
  String _unit = 'LITERS';
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = RequestFormStore(
      OrderingApi(app.httpClient),
      EquipmentApi(app.httpClient),
      app.iamStore,
    )..load();
  }

  @override
  void dispose() {
    _store.dispose();
    _quantity.dispose();
    _address.dispose();
    super.dispose();
  }

  String get _isoDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final sent = await _store.submit(
      CreateRequest(
        customerAccountId: _store.customerAccountId!,
        tankId: _tankId,
        providerId: _providerId!,
        fuelProductId: _productId!,
        quantity: double.parse(_quantity.text),
        unit: _unit,
        deliveryAddress: _address.text.trim(),
        deliveryDate: _isoDate,
      ),
    );
    if (sent && mounted) context.go('/ordering/request-list');
  }

  String? _required(Object? value) =>
      value == null ? context.tr('validation.required') : null;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.tr('request-form.create-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_store.loadError.isNotEmpty)
              ErrorBanner(message: _store.loadError),
            if (_store.error != null) ErrorBanner(message: _store.error!),
            _select<int?>(
              label: 'request-form.site',
              value: _siteId,
              items: {null: '—', for (final s in _store.sites) s.id: s.name},
              onChanged: (id) {
                setState(() => _siteId = id);
                final address = _store.addressOfSite(id);
                if (address != null) _address.text = address;
              },
            ),
            _select<int?>(
              label: 'request-form.tank',
              value: _tankId,
              items: {
                null: context.tr('request-form.no-tank'),
                for (final t in _store.tanks) t.id: t.name,
              },
              onChanged: (id) => setState(() => _tankId = id),
            ),
            _select<int?>(
              label: 'request-form.provider',
              value: _providerId,
              items: {for (final p in _store.providers) p.id: p.name},
              validator: _required,
              onChanged: (id) {
                setState(() {
                  _providerId = id;
                  _productId = null;
                });
                _store.selectProvider(id);
              },
            ),
            if (_store.productsLoading)
              Text(context.tr('request-form.products-loading')),
            if (_store.productError.isNotEmpty)
              ErrorBanner(
                message: _store.productError,
                onRetry: _store.productError == 'request-form.products-error'
                    ? () => _store.selectProvider(_providerId)
                    : null,
              ),
            if (_store.catalogAlert.isNotEmpty)
              Text(context.tr(_store.catalogAlert)),
            _select<int?>(
              label: 'request-form.product',
              value: _productId,
              items: {
                for (final p in _store.products)
                  p.id: '${p.name} (${p.fuelType})',
              },
              validator: _required,
              onChanged: (id) => setState(() => _productId = id),
            ),
            _field(
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('request-form.quantity'),
                ),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) < 1
                    ? context.tr('validation.min-value', {'n': 1})
                    : null,
              ),
            ),
            _select<String>(
              label: 'request-form.unit',
              value: _unit,
              items: const {'LITERS': 'LITERS', 'GALLONS': 'GALLONS'},
              onChanged: (u) => setState(() => _unit = u ?? 'LITERS'),
            ),
            _field(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(context.tr('request-form.delivery-date')),
                subtitle: Text(_isoDate),
                onTap: _pickDate,
              ),
            ),
            _field(
              TextFormField(
                controller: _address,
                maxLength: 255,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('request-form.delivery-address'),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? context.tr('validation.required')
                    : null,
              ),
            ),
            FilledButton(
              onPressed: _store.canSubmit ? _submit : null,
              child: Text(context.tr('request-form.create')),
            ),
            TextButton(
              onPressed: () => context.go('/ordering/request-list'),
              child: Text(context.tr('request-form.cancel')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

  Widget _select<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    FormFieldValidator<T>? validator,
  }) => _field(
    DropdownButtonFormField<T>(
      initialValue: items.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.tr(label)),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      validator: validator,
      onChanged: onChanged,
    ),
  );
}
