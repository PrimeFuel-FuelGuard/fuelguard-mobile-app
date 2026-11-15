import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/provider_delivery_entity.dart';
import '../../../infrastructure/fulfillment_api.dart';
import '../../fulfillment_ui.dart';

/// Entregas del distribuidor filtradas por fecha (`/fulfillment/delivery-list`).
class DeliveryList extends StatefulWidget {
  const DeliveryList({super.key});

  @override
  State<DeliveryList> createState() => _DeliveryListState();
}

class _DeliveryListState extends State<DeliveryList> {
  late final FulfillmentStore _store;
  bool _ready = false;

  /// `yyyy-MM-dd`; `null` muestra todas las fechas.
  String? _date = limaToday();
  String? _state;
  String? _driverId;
  String? _tankerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient))
      ..loadDeliveries(_date);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() => _store.loadDeliveries(_date);

  void _setDate(String? date) {
    setState(() {
      _date = date;
      _clearFilters();
    });
    _load();
  }

  void _clearFilters() {
    _state = null;
    _driverId = null;
    _tankerId = null;
  }

  Future<void> _pickDate() async {
    final current = _date == null ? null : DateTime.tryParse(_date!);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) _setDate(isoDate(picked));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final all = _store.deliveries;
      final rows = all.where(_matches).toList();
      final hasFilters =
          _state != null || _driverId != null || _tankerId != null;
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              _date == null
                  ? context.tr('fulfillment.delivery-list.subtitle-all')
                  : context.tr('fulfillment.delivery-list.subtitle-date', {
                      'date': formatDate(_date),
                    }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _date == null
                          ? context.tr('fulfillment.delivery-list.date')
                          : formatDate(_date),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _setDate(_date == null ? limaToday() : null),
                  child: Text(
                    context.tr(
                      _date == null
                          ? 'fulfillment.delivery-list.today'
                          : 'fulfillment.delivery-list.all',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown(
                  label: context.tr('fulfillment.delivery-list.state'),
                  value: _state,
                  items: [
                    for (final s in _unique(all.map((d) => d.physicalState)))
                      (s, context.tr('delivery-status.${s.toLowerCase()}')),
                  ],
                  onChanged: (v) => setState(() => _state = v),
                ),
                _FilterDropdown(
                  label: context.tr('fulfillment.driver'),
                  value: _driverId,
                  items: [
                    for (final d in _uniqueDrivers(all)) ('${d.$1}', d.$2),
                  ],
                  onChanged: (v) => setState(() => _driverId = v),
                ),
                _FilterDropdown(
                  label: context.tr('fulfillment.tanker'),
                  value: _tankerId,
                  items: [
                    for (final t in _uniqueTankers(all)) ('${t.$1}', t.$2),
                  ],
                  onChanged: (v) => setState(() => _tankerId = v),
                ),
                if (hasFilters)
                  TextButton(
                    onPressed: () => setState(_clearFilters),
                    child: Text(
                      context.tr('fulfillment.delivery-list.clear-filters'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_store.isLoading) const LinearProgressIndicator(),
            if (_store.error != null)
              ErrorBanner(message: _store.error!, onRetry: _load),
            if (!_store.isLoading && _store.error == null)
              if (all.isEmpty)
                EmptyState(
                  message: context.tr('fulfillment.delivery-list.empty'),
                  icon: Icons.local_shipping_outlined,
                )
              else if (rows.isEmpty)
                EmptyState(
                  message: context.tr(
                    'fulfillment.delivery-list.filtered-empty',
                  ),
                  icon: Icons.filter_alt_off_outlined,
                )
              else
                for (final delivery in rows) _DeliveryCard(delivery: delivery),
          ],
        ),
      );
    },
  );

  bool _matches(ProviderDelivery d) =>
      (_state == null || d.physicalState == _state) &&
      (_driverId == null || '${d.driver?.id}' == _driverId) &&
      (_tankerId == null || '${d.tanker?.id}' == _tankerId);

  static List<String> _unique(Iterable<String> values) => {...values}.toList();

  static List<(int, String)> _uniqueDrivers(List<ProviderDelivery> all) => {
    for (final d in all)
      if (d.driver case final driver?)
        driver.id: (driver.id, '${driver.firstName} ${driver.lastName}'),
  }.values.toList();

  static List<(int, String)> _uniqueTankers(List<ProviderDelivery> all) => {
    for (final d in all)
      if (d.tanker case final tanker?)
        tanker.id: (tanker.id, tanker.licensePlate),
  }.values.toList();
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, isDense: true),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(context.tr('fulfillment.delivery-list.any')),
            ),
            for (final (id, text) in items)
              DropdownMenuItem(value: id, child: Text(text)),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final ProviderDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final driver = d.driver == null
        ? '-'
        : '${d.driver!.firstName} ${d.driver!.lastName}';
    final volume = d.requestedVolume == null
        ? '-'
        : '${formatNumber(d.requestedVolume!)} '
              '${context.tr(d.unit?.startsWith('GALLON') == true ? 'unit.gallons' : 'unit.liters')}';
    return Card(
      child: ListTile(
        onTap: () => context.push('/fulfillment/delivery-detail/${d.id}'),
        leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
        title: Text(
          '${context.tr('fulfillment.delivery')} #${d.id} · '
          '${context.tr('fulfillment.order')} #${d.orderId}',
        ),
        subtitle: Text(
          '$driver · ${d.tanker?.licensePlate ?? '-'}\n'
          '${d.buyerCompanyName ?? '-'} · $volume\n'
          '${formatDateTime(d.windowStart)}',
        ),
        isThreeLine: true,
        trailing: StatusChip(
          label: context.tr('delivery-status.${d.physicalState.toLowerCase()}'),
          tone: statusTone(d.physicalState),
        ),
      ),
    );
  }
}
