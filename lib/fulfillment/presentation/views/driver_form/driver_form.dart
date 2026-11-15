import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/driver_entity.dart';
import '../../../infrastructure/fulfillment_api.dart';
import '../../fulfillment_ui.dart';

/// Alta y edición de conductor (`/fulfillment/driver-form[/:id]`). [rawId] es el segmento `:id`.
class DriverForm extends StatefulWidget {
  const DriverForm({super.key, this.rawId});

  final String? rawId;

  @override
  State<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  late final FulfillmentStore _store;
  bool _ready = false;
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient));
    _store.clearMessages();
    _id = int.tryParse(widget.rawId ?? '');
    final id = _id;
    if (id != null) _store.loadDriverById(id);
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
      final driver = _store.selectedDriver;
      final loaded = id == null || driver?.id == id;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.tr(
              id == null ? 'driver-form.title' : 'driver-form.edit-title',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              id == null ? 'driver-form.subtitle' : 'driver-form.edit-subtitle',
            ),
          ),
          const SizedBox(height: 16),
          if (_store.error != null)
            ErrorBanner(
              message: _store.error!,
              onRetry: id == null ? null : () => _store.loadDriverById(id),
            ),
          if (!loaded && _store.error == null)
            const LoadingView()
          else if (loaded)
            _DriverFields(
              key: ValueKey('driver-${id ?? 'new'}'),
              store: _store,
              driver: id == null ? null : driver,
            ),
        ],
      );
    },
  );
}

class _DriverFields extends StatefulWidget {
  const _DriverFields({super.key, required this.store, this.driver});

  final FulfillmentStore store;
  final Driver? driver;

  @override
  State<_DriverFields> createState() => _DriverFieldsState();
}

class _DriverFieldsState extends State<_DriverFields> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9]{9,15}$');

  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};

  String? _required(String? value, {int min = 1, int max = 255}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return context.tr('validation.required');
    if (text.length < min) {
      return context.tr('validation.min-length', {'n': min});
    }
    if (text.length > max) {
      return context.tr('validation.max-length', {'n': max});
    }
    return null;
  }

  String? _phone(String? value) {
    final required = _required(value, max: 30);
    if (required != null) return required;
    return _phonePattern.hasMatch((value ?? '').trim())
        ? null
        : context.tr('validation.phone');
  }

  String? _email(String? value) {
    final required = _required(value, max: 160);
    if (required != null) return required;
    return _emailPattern.hasMatch((value ?? '').trim())
        ? null
        : context.tr('validation.email');
  }

  void _submit() {
    final form = _formKey.currentState!;
    if (widget.store.isLoading || !form.validate()) return;
    form.save();
    final userId = int.tryParse(_values['userId'] ?? '');
    final driver = widget.driver;
    void done() {
      showNotice(context, widget.store.successMsg ?? 'errors.generic');
      context.go('/fulfillment/driver-list');
    }

    if (driver == null) {
      widget.store.registerDriver(
        DriverInput(
          userId: userId,
          firstName: _values['firstName']!,
          lastName: _values['lastName']!,
          licenseNumber: _values['licenseNumber']!,
          phoneNumber: _values['phoneNumber']!,
          email: _values['email']!,
          status: DriverStatus.available,
        ),
        done,
      );
    } else {
      widget.store.updateDriver(driver.id, {
        'userId': userId,
        'status': _values['status'],
        'firstName': _values['firstName'],
        'lastName': _values['lastName'],
        'licenseNumber': _values['licenseNumber'],
        'phoneNumber': _values['phoneNumber'],
        'email': _values['email'],
      }, done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final saving = widget.store.isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          TextFormField(
            initialValue: driver?.userId?.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr('driver-form.fields.user-id'),
            ),
            onSaved: (v) => _values['userId'] = v ?? '',
          ),
          _nameField(
            context,
            key: 'firstName',
            label: 'driver-form.fields.first-name',
            hint: 'driver-form.placeholders.first-name',
            initial: driver?.firstName,
            min: 2,
            max: 80,
          ),
          _nameField(
            context,
            key: 'lastName',
            label: 'driver-form.fields.last-name',
            hint: 'driver-form.placeholders.last-name',
            initial: driver?.lastName,
            min: 2,
            max: 80,
          ),
          TextFormField(
            initialValue: driver?.licenseNumber,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: context.tr('driver-form.fields.license-number'),
              hintText: context.tr('driver-form.placeholders.license-number'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (v) => _required(v, min: 8, max: 60),
            onSaved: (v) => _values['licenseNumber'] = v!.trim(),
          ),
          TextFormField(
            initialValue: driver?.phoneNumber,
            maxLength: 30,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.tr('driver-form.fields.phone'),
              hintText: context.tr('driver-form.placeholders.phone'),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: _phone,
            onSaved: (v) => _values['phoneNumber'] = v!.trim(),
          ),
          TextFormField(
            initialValue: driver?.email,
            maxLength: 160,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr('driver-form.fields.email'),
              hintText: context.tr('driver-form.placeholders.email'),
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: _email,
            onSaved: (v) => _values['email'] = v!.trim(),
          ),
          if (driver != null)
            DropdownButtonFormField<String>(
              initialValue: driver.status,
              decoration: InputDecoration(
                labelText: context.tr('driver-form.fields.status'),
              ),
              items: [
                for (final status in DriverStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(
                      context.tr('driver-status.${status.toLowerCase()}'),
                    ),
                  ),
              ],
              onSaved: (v) => _values['status'] = v!,
            ),
          FilledButton.icon(
            onPressed: saving ? null : _submit,
            icon: Icon(driver == null ? Icons.add : Icons.save_outlined),
            label: Text(
              context.tr(
                driver == null ? 'driver-form.register' : 'driver-form.save',
              ),
            ),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () => context.go('/fulfillment/driver-list'),
            child: Text(context.tr('driver-form.cancel')),
          ),
        ],
      ),
    );
  }

  Widget _nameField(
    BuildContext context, {
    required String key,
    required String label,
    required String hint,
    required String? initial,
    required int min,
    required int max,
  }) => TextFormField(
    initialValue: initial,
    maxLength: max,
    decoration: InputDecoration(
      labelText: context.tr(label),
      hintText: context.tr(hint),
      prefixIcon: const Icon(Icons.person_outline),
    ),
    validator: (v) => _required(v, min: min, max: max),
    onSaved: (v) => _values[key] = v!.trim(),
  );
}
