import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/infrastructure/inventory_api.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../application/provider_equipment_store.dart';
import '../../../domain/model/provider_equipment_entity.dart';
import '../../../infrastructure/provider_equipment_api.dart';
import '../../equipment_ui.dart';

/// Alta o edición de tanque con su dispositivo IoT (`/clients/:buyerId/tanks/new` y `.../:tankId/edit`).
/// En edición solo se envían los campos cambiados; dispositivo y canal siempre juntos.
class ProviderTankForm extends StatefulWidget {
  const ProviderTankForm({super.key, this.rawBuyerId, this.rawTankId});

  final String? rawBuyerId;
  final String? rawTankId;

  @override
  State<ProviderTankForm> createState() => _ProviderTankFormState();
}

class _ProviderTankFormState extends State<ProviderTankForm> {
  late final ProviderEquipmentStore _store;
  bool _ready = false;
  bool _submitted = false;
  int? _buyerId;
  int? _tankId;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _capacity = TextEditingController();
  final _initialLevel = TextEditingController();
  final _low = TextEditingController(text: '20');
  final _device = TextEditingController();
  final _channel = TextEditingController(text: 'level');
  int? _siteId;
  int? _productId;
  String _unit = ProviderUnit.litre;
  bool _auto = true;
  bool _formInitialized = false;

  bool get _editing => _tankId != null;

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
    )..addListener(_onStore);
    _buyerId = int.tryParse(widget.rawBuyerId ?? '');
    _tankId = int.tryParse(widget.rawTankId ?? '');
    final buyer = _buyerId;
    if (buyer != null) _store.loadTankForm(buyer, _tankId);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    for (final c in [
      _name,
      _capacity,
      _initialLevel,
      _low,
      _device,
      _channel,
    ]) {
      c.dispose();
    }
    _store.dispose();
    super.dispose();
  }

  /// Rellena el formulario una vez cargados comprador, productos y (al editar) el tanque.
  void _onStore() {
    if (_formInitialized || _store.formLoading || _store.formLoadError) return;
    _formInitialized = true;
    final original = _store.original;
    final buyer = _store.formBuyer;
    setState(() {
      if (original != null) {
        final device = original.devices.firstOrNull;
        _name.text = original.name;
        _capacity.text = '${original.capacity}';
        _initialLevel.text = '${original.currentLevel}';
        _low.text = '${original.lowLevelPercent}';
        _device.text = device?.deviceId ?? '';
        _channel.text = device?.channel ?? 'level';
        _siteId = original.siteId;
        _productId = original.fuelProductId;
        _unit = original.unit;
      } else if (buyer != null && buyer.sites.length == 1) {
        _siteId = buyer.sites.first.id;
      }
    });
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty
      ? context.tr('provider-equipment.tank-form.required')
      : null;

  String? _number(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null || !n.isFinite || n < min || n > max) {
      return context.tr('provider-equipment.tank-form.range');
    }
    return null;
  }

  String? _initialLevelError() {
    final level = double.tryParse(
      _initialLevel.text.trim().replaceAll(',', '.'),
    );
    final capacity = double.tryParse(
      _capacity.text.trim().replaceAll(',', '.'),
    );
    if (level != null && capacity != null && level > capacity) {
      return context.tr('provider-equipment.tank-form.range');
    }
    return _number(_initialLevel.text, 0, double.infinity);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _store.formSaving) return;
    final buyer = _store.formBuyer;
    final products = _store.formProducts;
    final original = _store.original;
    final site = buyer?.sites.where((s) => s.id == _siteId).firstOrNull;
    final unchangedProduct = _editing && _productId == original?.fuelProductId;
    final productKnown = products.any((p) => p.id == _productId);
    if ((!_editing && site == null) || (!unchangedProduct && !productKnown)) {
      return;
    }
    final name = _name.text.trim();
    final device = _device.text.trim();
    final channel = _channel.text.trim();
    final low = double.parse(_low.text.trim().replaceAll(',', '.'));
    final ok = !_editing
        ? await _store.createTank(
            NewProviderTank(
              buyerCompanyId: _buyerId!,
              customerAccountId: site!.customerAccountId,
              siteId: site.id,
              name: name,
              fuelProductId: _productId!,
              capacity: double.parse(
                _capacity.text.trim().replaceAll(',', '.'),
              ),
              unit: _unit,
              initialLevel: double.parse(
                _initialLevel.text.trim().replaceAll(',', '.'),
              ),
              lowLevelPercent: low,
              deviceId: device,
              channel: channel,
              autoGenerateEnabled: _auto,
            ),
          )
        : await _store.updateTank(
            _tankId!,
            _changes(original!, device, channel, low),
          );
    if (ok && mounted) context.go('/clients/$_buyerId');
  }

  ProviderTankUpdate _changes(
    ProviderTank original,
    String device,
    String channel,
    double low,
  ) {
    final deviceChanged =
        device != (original.devices.firstOrNull?.deviceId ?? '') ||
        channel != (original.devices.firstOrNull?.channel ?? '');
    return ProviderTankUpdate(
      fuelProductId: _productId != original.fuelProductId ? _productId : null,
      lowLevelPercent: low != original.lowLevelPercent ? low : null,
      deviceId: deviceChanged ? device : null,
      channel: deviceChanged ? channel : null,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      if (_store.formLoading) return const LoadingView();
      if (_store.formLoadError) {
        return ErrorBanner(
          message: 'provider-equipment.tank-form.loading-error',
        );
      }
      final buyer = _store.formBuyer;
      return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.tr(
                _editing
                    ? 'provider-equipment.detail.edit'
                    : 'provider-equipment.detail.add-tank',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (buyer != null) Text(buyer.name),
            const SizedBox(height: 12),
            _fields(context, buyer),
            const SizedBox(height: 12),
            if (_store.tankFormError != null)
              ErrorBanner(message: _store.tankFormError!),
            FilledButton(
              onPressed: _store.formSaving ? null : _submit,
              child: Text(context.tr('provider-equipment.tank-form.submit')),
            ),
            TextButton(
              onPressed: () => context.go('/clients/$_buyerId'),
              child: Text(context.tr('provider-equipment.tank-form.cancel')),
            ),
          ],
        ),
      );
    },
  );

  Widget _fields(BuildContext context, ProviderBuyerCompany? buyer) {
    final lock = _editing;
    final products = _store.formProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (!lock)
          EquipmentDropdown<int>(
            label: context.tr('provider-equipment.tank-form.site'),
            value: _siteId,
            error: _submitted && _siteId == null
                ? 'provider-equipment.tank-form.required'
                : null,
            onChanged: (v) => setState(() => _siteId = v),
            items: [
              for (final s in buyer?.sites ?? const <ProviderSite>[])
                DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
          ),
        TextFormField(
          controller: _name,
          enabled: !lock,
          maxLength: 150,
          decoration: InputDecoration(
            labelText: context.tr('provider-equipment.tank-form.name'),
          ),
          validator: _required,
        ),
        EquipmentDropdown<int>(
          label: context.tr('provider-equipment.tank-form.product'),
          value: products.any((p) => p.id == _productId) ? _productId : null,
          error: products.isEmpty
              ? 'provider-equipment.tank-form.no-products'
              : _submitted && _productId == null
              ? 'provider-equipment.tank-form.required'
              : null,
          onChanged: (v) => setState(() => _productId = v),
          items: [
            for (final p in products)
              DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.name} (${context.tr(fuelTypeKey(p.fuelType))})',
                ),
              ),
          ],
        ),
        if (!lock) ...[
          TextFormField(
            controller: _capacity,
            enabled: !lock,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('provider-equipment.tank-form.capacity'),
            ),
            validator: (v) => _number(v, 0.01, double.infinity),
          ),
          EquipmentDropdown<String>(
            label: context.tr('provider-equipment.tank-form.unit'),
            value: _unit,
            onChanged: (v) => setState(() => _unit = v ?? _unit),
            items: [
              DropdownMenuItem(
                value: ProviderUnit.litre,
                child: Text(context.tr('unit.liters')),
              ),
              DropdownMenuItem(
                value: ProviderUnit.gallon,
                child: Text(context.tr('unit.gallons')),
              ),
            ],
          ),
          TextFormField(
            controller: _initialLevel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr(
                'provider-equipment.tank-form.initial-level',
              ),
            ),
            validator: (_) => _initialLevelError(),
          ),
        ],
        TextFormField(
          controller: _low,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.tr('provider-equipment.tank-form.low-level'),
            helperText: context.tr(
              'provider-equipment.tank-form.low-level-hint',
            ),
          ),
          validator: (v) => _number(v, 1, 90),
        ),
        TextFormField(
          controller: _device,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: context.tr('provider-equipment.tank-form.device-id'),
          ),
          validator: _required,
        ),
        TextFormField(
          controller: _channel,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: context.tr('provider-equipment.tank-form.channel'),
          ),
          validator: _required,
        ),
        if (!lock)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.tr('provider-equipment.tank-form.auto-generate'),
            ),
            value: _auto,
            onChanged: (v) => setState(() => _auto = v),
          ),
      ],
    );
  }
}
