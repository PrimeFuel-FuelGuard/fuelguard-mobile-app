import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/fulfillment_store.dart';
import '../../fulfillment_ui.dart';

/// Geocerca de la entrega: una sola, con rangos de latitud, longitud y radio.
class GeofenceForm extends StatefulWidget {
  const GeofenceForm({super.key, required this.store, required this.id});

  final FulfillmentStore store;
  final int id;

  @override
  State<GeofenceForm> createState() => _GeofenceFormState();
}

class _GeofenceFormState extends State<GeofenceForm> {
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radius = TextEditingController();

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    super.dispose();
  }

  static double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double? get _lat => _parse(_latitude);
  double? get _lng => _parse(_longitude);
  double? get _rad => _parse(_radius);

  bool get _latInvalid {
    final v = _lat;
    return v != null && (!v.isFinite || v < -90 || v > 90);
  }

  bool get _lngInvalid {
    final v = _lng;
    return v != null && (!v.isFinite || v < -180 || v > 180);
  }

  bool get _radInvalid {
    final v = _rad;
    return v != null && (!v.isFinite || v <= 0);
  }

  bool get _valid =>
      _lat != null &&
      _lng != null &&
      _rad != null &&
      !_latInvalid &&
      !_lngInvalid &&
      !_radInvalid;

  Future<void> _save() async {
    await widget.store.saveGeofence(
      widget.id,
      latitude: _lat!,
      longitude: _lng!,
      radiusMeters: _rad!,
    );
    if (!mounted) return;
    final notice = widget.store.successMsg;
    if (notice != null) showNotice(context, notice);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.store.geofenceBusy;
    return SectionCard(
      title: context.tr('fulfillment.geofence'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _field(
            context,
            _latitude,
            'fulfillment.latitude',
            _latInvalid ? 'fulfillment.latitude-range' : null,
          ),
          _field(
            context,
            _longitude,
            'fulfillment.longitude',
            _lngInvalid ? 'fulfillment.longitude-range' : null,
          ),
          _field(
            context,
            _radius,
            'fulfillment.radius',
            _radInvalid ? 'fulfillment.radius-positive' : null,
          ),
          Text(
            context.tr('fulfillment.geofence-once'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          FilledButton(
            onPressed: _valid && !busy ? _save : null,
            child: Text(context.tr('fulfillment.save-geofence')),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
    String? error,
  ) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    decoration: InputDecoration(
      labelText: context.tr(label),
      errorText: error == null ? null : context.tr(error),
    ),
    onChanged: (_) => setState(() {}),
  );
}
