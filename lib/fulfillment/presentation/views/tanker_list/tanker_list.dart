import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/tanker_entity.dart';
import '../../../infrastructure/fulfillment_api.dart';
import '../../fulfillment_ui.dart';

/// Flota de cisternas del distribuidor (`/fulfillment/tanker-list`).
class TankerList extends StatefulWidget {
  const TankerList({super.key});

  @override
  State<TankerList> createState() => _TankerListState();
}

class _TankerListState extends State<TankerList> {
  late final FulfillmentStore _store;
  bool _ready = false;
  bool _availableOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient))..loadTankers();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() =>
      _availableOnly ? _store.loadAvailableTankers() : _store.loadTankers();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/fulfillment/tanker-form'),
      icon: const Icon(Icons.add),
      label: Text(context.tr('tanker-list.add-button')),
    ),
    body: ListenableBuilder(
      listenable: _store,
      builder: (context, _) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(context.tr('tanker-list.subtitle')),
            const SizedBox(height: 12),
            AvailabilityFilter(
              availableOnly: _availableOnly,
              onChanged: (value) {
                setState(() => _availableOnly = value);
                _load();
              },
            ),
            const SizedBox(height: 12),
            if (_store.isLoading) const LinearProgressIndicator(),
            if (_store.error != null)
              ErrorBanner(message: _store.error!, onRetry: _load),
            if (_store.tankerList.isEmpty && !_store.isLoading)
              EmptyState(
                message: context.tr('tanker-list.empty'),
                icon: Icons.local_shipping_outlined,
              )
            else
              for (final tanker in _store.tankerList)
                _TankerCard(tanker: tanker, store: _store),
          ],
        ),
      ),
    ),
  );
}

class _TankerCard extends StatelessWidget {
  const _TankerCard({required this.tanker, required this.store});

  final Tanker tanker;
  final FulfillmentStore store;

  @override
  Widget build(BuildContext context) {
    final t = tanker;
    final loading = store.tankerEligibilityLoading[t.id] == true;
    final result = store.tankerEligibility[t.id];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
              title: Text(
                t.licensePlate,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${t.brand} ${t.model} · '
                '${formatNumber(t.capacity)} ${context.tr(_unitKey(t.unit))}',
              ),
              trailing: StatusChip(
                label: context.tr('vehicle-status.${t.status.toLowerCase()}'),
                tone: statusTone(t.status),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: loading
                      ? null
                      : () => store.checkTankerEligibility(t.id),
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(context.tr('tanker-list.eligibility')),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.tr('tanker-list.edit-tooltip'),
                  onPressed: () =>
                      context.push('/fulfillment/tanker-form/${t.id}'),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz),
                  itemBuilder: (_) => [
                    for (final status in TankerStatus.values)
                      PopupMenuItem(
                        value: status,
                        child: Text(
                          context.tr('vehicle-status.${status.toLowerCase()}'),
                        ),
                      ),
                  ],
                  onSelected: (status) => _changeStatus(context, status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: EligibilityLine(
                label: result == null
                    ? null
                    : context.tr('eligibility.outcomes.${result.outcome}'),
                reason: result?.reason,
                error: store.tankerEligibilityError[t.id],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, String status) async {
    final deactivating = status == TankerStatus.inactive;
    if (deactivating && !await confirmAction(context, 'confirm.deactivate')) {
      return;
    }
    await store.updateTankerStatus(tanker.id, status);
    if (context.mounted && store.successMsg != null) {
      showNotice(context, store.successMsg!);
    }
  }

  static String _unitKey(String unit) =>
      unit.startsWith('GALLON') ? 'unit.gallons' : 'unit.liters';
}
