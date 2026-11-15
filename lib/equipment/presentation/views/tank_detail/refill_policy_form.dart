import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/equipment_store.dart';
import '../../../domain/model/equipment_entity.dart';
import '../../equipment_ui.dart';

/// Política de reposición del tanque: umbral, histéresis, objetivo, proveedor, producto y
/// generación automática. Reglas de RefillThresholds y RefillPolicy del backend.
class RefillPolicyForm extends StatefulWidget {
  const RefillPolicyForm({super.key, required this.store});

  final EquipmentStore store;

  @override
  State<RefillPolicyForm> createState() => _RefillPolicyFormState();
}

class _RefillPolicyFormState extends State<RefillPolicyForm> {
  bool _ready = false;
  double? _low;
  double? _hyst;
  double? _target;
  int? _providerId;
  int? _productId;
  bool _auto = false;

  void _initDraft(RefillPolicy p) {
    _ready = true;
    _low = p.lowLevelPercent;
    _hyst = p.hysteresisPercent;
    _target = p.targetLevelPercent;
    _providerId = p.providerId;
    _productId = p.fuelProductId;
    _auto = p.autoGenerateEnabled;
  }

  String? get _lowError {
    final v = _low;
    if (v == null) return 'validation.required';
    return v <= 0 || v >= 100 ? 'equipment.err-low-range' : null;
  }

  String? get _hystError {
    final h = _hyst;
    if (h == null) return 'validation.required';
    if (h <= 0) return 'equipment.err-hysteresis-positive';
    final l = _low;
    return l != null && l + h > 100
        ? 'equipment.err-low-plus-hysteresis'
        : null;
  }

  String? get _targetError {
    final v = _target;
    if (v == null) return 'validation.required';
    return v <= 0 || v > 100 ? 'equipment.err-target-range' : null;
  }

  bool get _invalid =>
      _lowError != null || _hystError != null || _targetError != null;

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _onProvider(int? id) {
    setState(() {
      _providerId = id;
      _productId = null;
      _auto = false;
    });
    widget.store.selectProvider(id);
  }

  void _onProduct(int? id) {
    setState(() {
      _productId = id;
      if (id == null) _auto = false;
    });
    widget.store.editPolicy();
  }

  Future<void> _save() => widget.store.savePolicy(
    RefillPolicy(
      lowLevelPercent: _low!,
      hysteresisPercent: _hyst!,
      targetLevelPercent: _target!,
      providerId: _providerId,
      fuelProductId: _productId,
      autoGenerateEnabled: _auto,
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final policy = store.policy;
      if (!store.policyReady || policy == null) {
        return SectionCard(
          title: context.tr('equipment.policy'),
          child: LoadingView(message: context.tr('equipment.loading')),
        );
      }
      if (!_ready) _initDraft(policy);
      final busy = store.savingPolicy;
      final providerSet = _providerId != null;
      final productSet = _productId != null;
      return SectionCard(
        title: context.tr('equipment.policy'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _number(
              'low',
              'equipment.low-level',
              _low,
              _lowError,
              (v) => _low = v,
            ),
            _number(
              'hyst',
              'equipment.hysteresis',
              _hyst,
              _hystError,
              (v) => _hyst = v,
            ),
            _number(
              'target',
              'equipment.target-level',
              _target,
              _targetError,
              (v) => _target = v,
            ),
            EquipmentDropdown<int?>(
              label: context.tr('equipment.provider'),
              value: store.providers.any((p) => p.id == _providerId)
                  ? _providerId
                  : null,
              onChanged: busy ? null : _onProvider,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.tr('equipment.not-set')),
                ),
                for (final p in store.providers)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
            ),
            EquipmentDropdown<int?>(
              label: context.tr('equipment.product'),
              value: store.products.any((p) => p.id == _productId)
                  ? _productId
                  : null,
              onChanged: busy || !providerSet ? null : _onProduct,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.tr('equipment.not-set')),
                ),
                for (final p in store.products)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.name} (${context.tr(fuelTypeKey(p.fuelType))})',
                    ),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('equipment.auto-generate')),
              value: _auto,
              onChanged: busy || !providerSet || !productSet
                  ? null
                  : (v) {
                      setState(() => _auto = v);
                      store.editPolicy();
                    },
            ),
            if (!providerSet || !productSet)
              Text(
                context.tr('equipment.auto-needs-both'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            FilledButton(
              onPressed: store.tank == null || _invalid || busy ? null : _save,
              child: Text(context.tr('equipment.save-policy')),
            ),
            if (store.policySaved) Text(context.tr('equipment.policy-saved')),
          ],
        ),
      );
    },
  );

  Widget _number(
    String key,
    String label,
    double? value,
    String? error,
    ValueChanged<double?> onChanged,
  ) => TextFormField(
    key: ValueKey('policy-$key'),
    initialValue: value?.toString(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: context.tr(label),
      errorText: error == null ? null : context.tr(error),
    ),
    onChanged: (text) {
      setState(() => onChanged(_parse(text)));
      widget.store.editPolicy();
    },
  );
}
