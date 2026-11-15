import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/tanker_entity.dart';
import '../../../infrastructure/fulfillment_api.dart';
import '../../fulfillment_ui.dart';

/// Alta y edición de cisterna (`/fulfillment/tanker-form[/:id]`). [rawId] es el segmento `:id`.
class TankerForm extends StatefulWidget {
  const TankerForm({super.key, this.rawId});

  final String? rawId;

  @override
  State<TankerForm> createState() => _TankerFormState();
}

class _TankerFormState extends State<TankerForm> {
  late final FulfillmentStore _store;
  bool _ready = false;
  bool _invalidId = false;
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final raw = widget.rawId;
    final parsed = int.tryParse(raw ?? '');
    _invalidId = raw != null && (parsed == null || parsed <= 0);
    _id = _invalidId ? null : parsed;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient));
    final id = _id;
    if (id != null) _store.loadTankerById(id);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final id = _id;
      final tanker = _store.selectedTanker;
      final loaded = id == null || tanker?.id == id;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.tr(
              id == null ? 'tanker-form.title' : 'tanker-form.edit-title',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              id == null ? 'tanker-form.subtitle' : 'tanker-form.edit-subtitle',
            ),
          ),
          const SizedBox(height: 16),
          if (_invalidId)
            ErrorBanner(message: 'tanker-form.invalid-id')
          else if (_store.error != null)
            ErrorBanner(
              message: _store.error!,
              onRetry: id == null ? null : () => _store.loadTankerById(id),
            ),
          if (!_invalidId && !loaded && _store.error == null)
            LoadingView(message: context.tr('tanker-form.loading'))
          else if (!_invalidId && loaded)
            _TankerFields(
              key: ValueKey('tanker-${id ?? 'new'}'),
              store: _store,
              tanker: id == null ? null : tanker,
            ),
        ],
      );
    },
  );
}

class _TankerFields extends StatefulWidget {
  const _TankerFields({super.key, required this.store, this.tanker});

  final FulfillmentStore store;
  final Tanker? tanker;

  @override
  State<_TankerFields> createState() => _TankerFieldsState();
}

class _TankerFieldsState extends State<_TankerFields> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};

  Tanker? get _tanker => widget.tanker;

  String? _required(String? value, {int? max}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return context.tr('validation.required');
    if (max != null && text.length > max) {
      return context.tr('validation.max-length', {'n': max});
    }
    return null;
  }

  String? _capacity(String? value) {
    final required = _required(value);
    if (required != null) return required;
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || !number.isFinite || number <= 0
        ? context.tr('validation.positive')
        : null;
  }

  void _submit() {
    final form = _formKey.currentState!;
    if (widget.store.isLoading || !form.validate()) return;
    form.save();
    final capacity = double.parse(_values['capacity']!.replaceAll(',', '.'));
    final request = {
      'licensePlate': _values['licensePlate'],
      'brand': _values['brand'],
      'model': _values['model'],
      'capacity': capacity,
      'unit': _values['unit'],
      'status': _values['status'],
    };
    void done() {
      showNotice(context, widget.store.successMsg ?? 'errors.generic');
      context.go('/fulfillment/tanker-list');
    }

    final id = _tanker?.id;
    if (id == null) {
      widget.store.registerTanker(
        TankerInput(
          licensePlate: _values['licensePlate']!,
          brand: _values['brand']!,
          model: _values['model']!,
          capacity: capacity,
          unit: _values['unit']!,
          status: _values['status']!,
        ),
        done,
      );
    } else {
      widget.store.updateTanker(id, request, done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanker = _tanker;
    final theme = Theme.of(context);
    final saving = widget.store.isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            context.tr('tanker-form.identity-title'),
            style: theme.textTheme.titleMedium,
          ),
          Text(context.tr('tanker-form.identity-help')),
          TextFormField(
            initialValue: tanker?.licensePlate,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.license-plate'),
              hintText: context.tr('tanker-form.placeholders.license-plate'),
              helperText: context.tr('tanker-form.plate-help'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (v) => _required(v, max: 20),
            onSaved: (v) => _values['licensePlate'] = v!.trim(),
          ),
          TextFormField(
            initialValue: tanker?.brand,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.brand'),
              hintText: context.tr('tanker-form.placeholders.brand'),
            ),
            validator: (v) => _required(v, max: 80),
            onSaved: (v) => _values['brand'] = v!.trim(),
          ),
          TextFormField(
            initialValue: tanker?.model,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.model'),
              hintText: context.tr('tanker-form.placeholders.model'),
            ),
            validator: (v) => _required(v, max: 80),
            onSaved: (v) => _values['model'] = v!.trim(),
          ),
          Text(
            context.tr('tanker-form.capacity-title'),
            style: theme.textTheme.titleMedium,
          ),
          Text(context.tr('tanker-form.capacity-help')),
          TextFormField(
            initialValue: tanker == null ? null : '${tanker.capacity}',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.capacity'),
              hintText: context.tr('tanker-form.placeholders.capacity'),
              prefixIcon: const Icon(Icons.local_gas_station_outlined),
            ),
            validator: _capacity,
            onSaved: (v) => _values['capacity'] = v!.trim(),
          ),
          DropdownButtonFormField<String>(
            initialValue: tanker?.unit ?? 'LITERS',
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.unit'),
              helperText: context.tr('tanker-form.unit-help'),
            ),
            items: [
              for (final unit in const ['LITERS', 'GALLONS'])
                DropdownMenuItem(
                  value: unit,
                  child: Text(
                    context.tr(
                      unit == 'LITERS' ? 'unit.liters' : 'unit.gallons',
                    ),
                  ),
                ),
            ],
            onSaved: (v) => _values['unit'] = v!,
          ),
          DropdownButtonFormField<String>(
            initialValue: tanker?.status ?? TankerStatus.available,
            decoration: InputDecoration(
              labelText: context.tr('tanker-form.fields.status'),
              helperText: context.tr('tanker-form.status-help'),
            ),
            items: [
              for (final status in TankerStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(
                    context.tr('vehicle-status.${status.toLowerCase()}'),
                  ),
                ),
            ],
            onSaved: (v) => _values['status'] = v!,
          ),
          if (tanker != null)
            Text(
              context.tr(
                tanker.active
                    ? 'tanker-form.active-record'
                    : 'tanker-form.inactive-record',
              ),
              style: theme.textTheme.bodySmall,
            ),
          FilledButton.icon(
            onPressed: saving ? null : _submit,
            icon: Icon(tanker == null ? Icons.add : Icons.save_outlined),
            label: Text(
              context.tr(
                saving
                    ? 'tanker-form.saving'
                    : tanker == null
                    ? 'tanker-form.register'
                    : 'tanker-form.save',
              ),
            ),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () => context.go('/fulfillment/tanker-list'),
            child: Text(context.tr('tanker-form.cancel')),
          ),
        ],
      ),
    );
  }
}
