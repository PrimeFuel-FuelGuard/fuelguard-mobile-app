import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/infrastructure/inventory_api.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/provider_equipment_store.dart';
import '../../../domain/model/provider_equipment_entity.dart';
import '../../../infrastructure/provider_equipment_api.dart';
import '../../equipment_ui.dart';

/// Detalle de un comprador del distribuidor: sitios y tanques con su dispositivo (`/clients/:buyerId`).
class ProviderClientDetail extends StatefulWidget {
  const ProviderClientDetail({super.key, this.rawBuyerId});

  final String? rawBuyerId;

  @override
  State<ProviderClientDetail> createState() => _ProviderClientDetailState();
}

class _ProviderClientDetailState extends State<ProviderClientDetail> {
  late final ProviderEquipmentStore _store;
  bool _ready = false;
  int? _buyerId;

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
    _buyerId = int.tryParse(widget.rawBuyerId ?? '');
    final id = _buyerId;
    if (id != null) _store.loadClient(id);
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
      final id = _buyerId;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (id == null)
            EmptyState(
              message: context.tr('provider-equipment.detail.not-found'),
            )
          else ...[
            _buyerSection(context, id),
            const SizedBox(height: 12),
            _tanksSection(context, id),
          ],
        ],
      );
    },
  );

  Widget _buyerSection(BuildContext context, int id) {
    final client = _store.client;
    final buyer = client.data;
    if (client.error) {
      return ErrorBanner(
        message: 'provider-equipment.clients.error',
        onRetry: () => _store.loadClient(id),
      );
    }
    if (buyer == null) {
      return client.loading
          ? const LinearProgressIndicator()
          : EmptyState(
              message: context.tr('provider-equipment.detail.not-found'),
            );
    }
    return SectionCard(
      title: buyer.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            '${context.tr('provider-equipment.clients.ruc')}: ${buyer.ruc ?? '-'}',
          ),
          Text(
            '${context.tr('provider-equipment.clients.sector')}: '
            '${buyer.sector ?? '-'}',
          ),
          Text(
            context.tr('provider-equipment.detail.sites'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (buyer.sites.isEmpty)
            Text(context.tr('provider-equipment.detail.no-sites'))
          else
            for (final site in buyer.sites)
              Text(
                '${site.name}${site.address == null ? '' : ' · ${site.address}'}',
              ),
        ],
      ),
    );
  }

  Widget _tanksSection(BuildContext context, int id) {
    final tanks = _store.clientTanks;
    return SectionCard(
      title: context.tr('provider-equipment.detail.tanks'),
      trailing: TextButton.icon(
        onPressed: () => context.push('/clients/$id/tanks/new'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('provider-equipment.detail.add-tank')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (tanks.loading) const LinearProgressIndicator(),
          if (tanks.error)
            ErrorBanner(
              message: 'provider-equipment.detail.tanks-error',
              onRetry: () => _store.loadClientTanks(id),
            )
          else if (!tanks.loading && tanks.data.isEmpty)
            EmptyState(
              message: context.tr('provider-equipment.detail.no-tanks'),
            ),
          for (final tank in tanks.data) _TankTile(tank: tank, buyerId: id),
        ],
      ),
    );
  }
}

class _TankTile extends StatelessWidget {
  const _TankTile({required this.tank, required this.buyerId});

  final ProviderTank tank;
  final int buyerId;

  @override
  Widget build(BuildContext context) {
    final t = tank;
    final device = t.devices.isEmpty
        ? context.tr('provider-equipment.detail.no-device')
        : t.devices.map((d) => '${d.deviceId} (${d.channel})').join(', ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/clients/tank/${t.id}'),
                    child: Text(
                      t.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                if (t.critical)
                  Text(
                    context.tr('provider-equipment.detail.critical'),
                    style: TextStyle(color: FgColors.danger),
                  ),
                IconButton(
                  tooltip: context.tr('provider-equipment.detail.edit'),
                  onPressed: () =>
                      context.push('/clients/$buyerId/tanks/${t.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Text(
              '${context.tr('provider-equipment.detail.device')}: $device',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${context.tr('provider-equipment.detail.threshold')}: '
              '${t.lowLevelPercent} %',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            LevelBar(percent: t.levelPercent),
          ],
        ),
      ),
    );
  }
}
