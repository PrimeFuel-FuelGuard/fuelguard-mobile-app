import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/infrastructure/inventory_api.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/provider_equipment_store.dart';
import '../../../infrastructure/provider_equipment_api.dart';

final _rucPattern = RegExp(r'^\d{11}$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Alta de comprador: busca por RUC y vincula, o crea si no existe (`/clients/new`).
class ProviderBuyerForm extends StatefulWidget {
  const ProviderBuyerForm({super.key});

  @override
  State<ProviderBuyerForm> createState() => _ProviderBuyerFormState();
}

class _ProviderBuyerFormState extends State<ProviderBuyerForm> {
  late final ProviderEquipmentStore _store;
  bool _ready = false;
  final _ruc = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _createRuc = TextEditingController();
  final _sector = TextEditingController();
  final _address = TextEditingController();
  final _contactEmail = TextEditingController();
  final _phone = TextEditingController();
  final _siteName = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = ProviderEquipmentStore(
      ProviderEquipmentApi(app.httpClient),
      InventoryApi(app.httpClient),
      app.iamStore,
    );
    _store.addListener(_prefillRuc);
  }

  @override
  void dispose() {
    for (final c in [
      _ruc,
      _name,
      _createRuc,
      _sector,
      _address,
      _contactEmail,
      _phone,
      _siteName,
    ]) {
      c.dispose();
    }
    _store.removeListener(_prefillRuc);
    _store.dispose();
    super.dispose();
  }

  /// Al pasar al alta, la RUC buscada queda prellenada.
  void _prefillRuc() {
    if (_store.createStep && _createRuc.text.isEmpty) {
      _createRuc.text = _ruc.text.trim();
    }
  }

  bool get _rucValid => _rucPattern.hasMatch(_ruc.text.trim());

  Future<void> _link() async {
    final linked = await _store.linkBuyer();
    if (linked != null && mounted) context.go('/clients/${linked.id}');
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, String>{};
    for (final (key, controller) in [
      ('name', _name),
      ('ruc', _createRuc),
      ('sector', _sector),
      ('address', _address),
      ('contactEmail', _contactEmail),
      ('phone', _phone),
      ('siteName', _siteName),
    ]) {
      final value = controller.text.trim();
      if (value.isNotEmpty) body[key] = value;
    }
    final created = await _store.createBuyer(body);
    if (created != null && mounted) context.go('/clients/${created.id}');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr('provider-equipment.buyer-form.title'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(context.tr('provider-equipment.buyer-form.subtitle')),
        const SizedBox(height: 16),
        if (_store.createStep) _createForm(context) else _lookup(context),
      ],
    ),
  );

  Widget _lookup(BuildContext context) {
    final found = _store.found;
    final waiting = _store.waitSeconds > 0;
    final rucError = _ruc.text.isEmpty || _rucValid
        ? null
        : context.tr('provider-equipment.buyer-form.ruc-invalid');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TextField(
          controller: _ruc,
          keyboardType: TextInputType.number,
          maxLength: 11,
          decoration: InputDecoration(
            labelText: context.tr('provider-equipment.buyer-form.ruc'),
            helperText: context.tr('provider-equipment.buyer-form.lookup-hint'),
            errorText: rucError,
          ),
          onChanged: (_) {
            _store.resetLookup();
            setState(() {});
          },
        ),
        FilledButton.icon(
          onPressed: !_rucValid || waiting || _store.searching
              ? null
              : () => _store.lookupBuyer(_ruc.text.trim()),
          icon: const Icon(Icons.search),
          label: Text(context.tr('provider-equipment.buyer-form.search')),
        ),
        if (waiting)
          Text(
            context.tr('provider-equipment.buyer-form.wait', {
              'seconds': _store.waitSeconds,
            }),
          ),
        if (_store.lookupError != null)
          ErrorBanner(message: _store.lookupError!),
        if (found != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    context.tr('provider-equipment.buyer-form.found'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(found.name),
                  Text('RUC ${found.ruc}'),
                  if (_store.buyerError != null)
                    ErrorBanner(message: _store.buyerError!),
                  FilledButton(
                    onPressed: _store.saving ? null : _link,
                    child: Text(
                      context.tr('provider-equipment.buyer-form.link'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _createForm(BuildContext context) {
    String? nameRequired(String? v) => (v ?? '').trim().isEmpty
        ? context.tr('provider-equipment.buyer-form.name-required')
        : null;
    String? rucValidator(String? v) => _rucPattern.hasMatch((v ?? '').trim())
        ? null
        : context.tr('provider-equipment.buyer-form.ruc-invalid');
    String? email(String? v) {
      final text = (v ?? '').trim();
      return text.isEmpty || _emailPattern.hasMatch(text)
          ? null
          : context.tr('provider-equipment.buyer-form.email-invalid');
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextButton(
            onPressed: _store.saving ? null : _store.backToLookup,
            child: Text(context.tr('provider-equipment.buyer-form.back')),
          ),
          _field(
            _name,
            'provider-equipment.buyer-form.name',
            nameRequired,
            150,
          ),
          _field(
            _createRuc,
            'provider-equipment.buyer-form.ruc',
            rucValidator,
            11,
          ),
          _field(_sector, 'provider-equipment.buyer-form.sector', null, 80),
          _field(_address, 'provider-equipment.buyer-form.address', null, 200),
          _field(
            _contactEmail,
            'provider-equipment.buyer-form.contact-email',
            email,
            160,
          ),
          _field(_phone, 'provider-equipment.buyer-form.phone', null, 30),
          _field(
            _siteName,
            'provider-equipment.buyer-form.site-name',
            null,
            150,
          ),
          if (_store.buyerError != null)
            ErrorBanner(message: _store.buyerError!),
          FilledButton(
            onPressed: _store.saving ? null : _create,
            child: Text(context.tr('provider-equipment.buyer-form.submit')),
          ),
          TextButton(
            onPressed: _store.saving ? null : () => context.go('/clients'),
            child: Text(context.tr('provider-equipment.buyer-form.cancel')),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator,
    int maxLength,
  ) => TextFormField(
    controller: controller,
    maxLength: maxLength,
    decoration: InputDecoration(labelText: context.tr(label)),
    validator: validator,
  );
}
