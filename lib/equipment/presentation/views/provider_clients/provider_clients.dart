import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/infrastructure/inventory_api.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/provider_equipment_store.dart';
import '../../../domain/model/provider_equipment_entity.dart';
import '../../../infrastructure/provider_equipment_api.dart';

/// Compradores del distribuidor con su resumen de tanques y pedidos (`/clients`).
class ProviderClients extends StatefulWidget {
  const ProviderClients({super.key});

  @override
  State<ProviderClients> createState() => _ProviderClientsState();
}

class _ProviderClientsState extends State<ProviderClients> {
  late final ProviderEquipmentStore _store;
  bool _ready = false;
  String _search = '';

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
    )..loadBuyers();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  List<ProviderBuyerCompany> _rows(List<ProviderBuyerCompany> all) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final b in all)
        if (b.name.toLowerCase().contains(q) || (b.ruc ?? '').contains(q)) b,
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/clients/new'),
      icon: const Icon(Icons.person_add_alt_1_outlined),
      label: Text(context.tr('provider-equipment.clients.register')),
    ),
    body: ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final buyers = _store.buyers;
        final rows = _rows(buyers.data);
        return RefreshIndicator(
          onRefresh: _store.loadBuyers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (buyers.loading) const LinearProgressIndicator(),
              if (buyers.error)
                ErrorBanner(
                  message: 'provider-equipment.clients.error',
                  onRetry: _store.loadBuyers,
                )
              else if (!buyers.loading && buyers.data.isEmpty)
                EmptyState(
                  message: context.tr('provider-equipment.clients.empty'),
                  icon: Icons.business_outlined,
                )
              else if (buyers.data.isNotEmpty) ...[
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    labelText: context.tr('provider-equipment.clients.search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  EmptyState(
                    message: context.tr(
                      'provider-equipment.clients.search-none',
                    ),
                    icon: Icons.search_off,
                  )
                else
                  for (final b in rows) _ClientCard(buyer: b),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.buyer});

  final ProviderBuyerCompany buyer;

  @override
  Widget build(BuildContext context) {
    final b = buyer;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/clients/${b.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(b.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${context.tr('provider-equipment.clients.ruc')}: '
                '${b.ruc ?? '-'} · '
                '${context.tr('provider-equipment.clients.sector')}: '
                '${b.sector ?? '-'}',
              ),
              Text(
                '${context.tr('provider-equipment.clients.tanks')}: ${b.tankCount} · '
                '${context.tr('provider-equipment.clients.critical')}: '
                '${b.criticalTankCount} · '
                '${context.tr('provider-equipment.clients.sites')}: ${b.sites.length}',
              ),
              Text(
                '${context.tr('provider-equipment.clients.active-orders')}: '
                '${b.activeOrderCount} · '
                '${context.tr('provider-equipment.clients.historical-orders')}: '
                '${b.historicalOrderCount}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
