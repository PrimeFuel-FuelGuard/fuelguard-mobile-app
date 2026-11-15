import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/fulfillment_store.dart';
import '../../../domain/model/driver_entity.dart';
import '../../../infrastructure/fulfillment_api.dart';
import '../../fulfillment_ui.dart';

/// Conductores autorizados del distribuidor (`/fulfillment/driver-list`).
class DriverList extends StatefulWidget {
  const DriverList({super.key});

  @override
  State<DriverList> createState() => _DriverListState();
}

class _DriverListState extends State<DriverList> {
  late final FulfillmentStore _store;
  bool _ready = false;
  bool _availableOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = FulfillmentStore(FulfillmentApi(app.httpClient))..loadDrivers();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() =>
      _availableOnly ? _store.loadAvailableDrivers() : _store.loadDrivers();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/fulfillment/driver-form'),
      icon: const Icon(Icons.add),
      label: Text(context.tr('driver-list.add-button')),
    ),
    body: ListenableBuilder(
      listenable: _store,
      builder: (context, _) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(context.tr('driver-list.subtitle')),
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
            if (_store.driverList.isEmpty && !_store.isLoading)
              EmptyState(
                message: context.tr('driver-list.empty'),
                icon: Icons.person_search_outlined,
              )
            else
              for (final driver in _store.driverList)
                _DriverCard(driver: driver, store: _store),
          ],
        ),
      ),
    ),
  );
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.store});

  final Driver driver;
  final FulfillmentStore store;

  @override
  Widget build(BuildContext context) {
    final d = driver;
    final loading = store.driverEligibilityLoading[d.id] == true;
    final result = store.driverEligibility[d.id];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                '${d.firstName} ${d.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${d.licenseNumber} · ${d.phoneNumber}\n${d.email}',
              ),
              isThreeLine: true,
              trailing: StatusChip(
                label: context.tr('driver-status.${d.status.toLowerCase()}'),
                tone: statusTone(d.status),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: loading
                      ? null
                      : () => store.checkDriverEligibility(d.id),
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(context.tr('driver-list.eligibility')),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.tr('driver-list.edit-tooltip'),
                  onPressed: () =>
                      context.push('/fulfillment/driver-form/${d.id}'),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz),
                  itemBuilder: (_) => [
                    for (final status in DriverStatus.values)
                      PopupMenuItem(
                        value: status,
                        child: Text(
                          context.tr('driver-status.${status.toLowerCase()}'),
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
                    : _outcomeLabel(context, result.outcome),
                reason: result?.reason,
                error: store.driverEligibilityError[d.id],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _outcomeLabel(BuildContext context, String outcome) =>
      outcome == 'BUSY'
      ? context.tr('eligibility.driver-busy')
      : context.tr('eligibility.outcomes.$outcome');

  Future<void> _changeStatus(BuildContext context, String status) async {
    final deactivating = status == DriverStatus.inactive;
    if (deactivating && !await confirmAction(context, 'confirm.deactivate')) {
      return;
    }
    await store.updateDriverStatus(driver.id, status);
    if (context.mounted && store.successMsg != null) {
      showNotice(context, store.successMsg!);
    }
  }
}
