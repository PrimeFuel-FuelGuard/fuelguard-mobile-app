import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/infrastructure/inventory_api.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../../shared/presentation/component/bar_chart/bar_chart.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/provider_equipment_store.dart';
import '../../../domain/model/provider_equipment_entity.dart';
import '../../../infrastructure/provider_equipment_api.dart';
import '../../equipment_ui.dart';

const _staleAfter = Duration(hours: 1);
const _chartPoints = 24;

/// Detalle de tanque del distribuidor: nivel, lecturas del dispositivo y episodios (`/clients/tank/:id`).
class ProviderTankDetail extends StatefulWidget {
  const ProviderTankDetail({super.key, this.rawId});

  final String? rawId;

  @override
  State<ProviderTankDetail> createState() => _ProviderTankDetailState();
}

class _ProviderTankDetailState extends State<ProviderTankDetail> {
  late final ProviderEquipmentStore _store;
  bool _ready = false;
  int? _id;

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
    _id = int.tryParse(widget.rawId ?? '');
    final id = _id;
    if (id != null) _store.loadTankDetail(id);
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
      return RefreshIndicator(
        onRefresh: () =>
            id == null ? Future.value() : _store.loadTankDetail(id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (id == null)
              EmptyState(
                message: context.tr('provider-equipment.tank-detail.not-found'),
              )
            else ...[
              _tankSection(context),
              const SizedBox(height: 12),
              _readingsSection(context, id),
              const SizedBox(height: 12),
              _episodesSection(context, id),
            ],
          ],
        ),
      );
    },
  );

  Widget _tankSection(BuildContext context) {
    final tank = _store.tank;
    final data = tank.data;
    if (tank.error) {
      return ErrorBanner(
        message: 'provider-equipment.clients.error',
        onRetry: () => _store.loadTank(_id!),
      );
    }
    if (data == null) {
      return tank.loading
          ? const LinearProgressIndicator()
          : EmptyState(
              message: context.tr('provider-equipment.tank-detail.not-found'),
            );
    }
    return SectionCard(
      title: data.name,
      trailing: IconButton(
        tooltip: context.tr('provider-equipment.detail.edit'),
        onPressed: () => context.push(
          '/clients/${data.buyerCompanyId}/tanks/${data.id}/edit',
        ),
        icon: const Icon(Icons.edit_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            '${context.tr('provider-equipment.detail.level')}: '
            '${formatNumber(data.currentLevel)} / ${formatNumber(data.capacity)} '
            '${context.tr(unitKey(data.unit))}',
          ),
          LevelBar(percent: data.levelPercent),
          Text(
            '${context.tr('provider-equipment.detail.device')}: '
            '${data.devices.map((d) => '${d.deviceId} (${d.channel})').join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _ageLine(context, data),
        ],
      ),
    );
  }

  Widget _ageLine(BuildContext context, ProviderTank tank) {
    final readings = _store.readings.data;
    final last = readings.isEmpty ? null : readings.last;
    if (last == null) {
      return Text(context.tr('provider-equipment.tank-detail.no-readings'));
    }
    final captured = DateTime.tryParse(last.capturedAt);
    final age = captured == null
        ? Duration.zero
        : DateTime.now().difference(captured);
    final stale = age > _staleAfter;
    final minutes = age.inMinutes < 0 ? 0 : age.inMinutes;
    return Text(
      '${context.tr('provider-equipment.tank-detail.last-reading')}: '
      '${context.tr('provider-equipment.tank-detail.age', {'minutes': minutes})}'
      '${stale ? ' · ${context.tr('provider-equipment.tank-detail.stale')}' : ''}',
      style: TextStyle(color: stale ? FgColors.warning : null),
    );
  }

  Widget _readingsSection(BuildContext context, int id) {
    final readings = _store.readings;
    final rows = readings.data;
    final recent = rows.length > _chartPoints
        ? rows.sublist(rows.length - _chartPoints)
        : rows;
    return SectionCard(
      title: context.tr('provider-equipment.tank-detail.readings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (readings.loading) const LinearProgressIndicator(),
          if (readings.error)
            ErrorBanner(
              message: 'provider-equipment.tank-detail.readings-error',
              onRetry: () => _store.loadReadings(id),
            )
          else if (!readings.loading && rows.isEmpty)
            EmptyState(
              message: context.tr('provider-equipment.tank-detail.no-readings'),
            )
          else if (rows.isNotEmpty) ...[
            SimpleBarChart(
              data: [for (final r in recent) (_hour(r.capturedAt), r.level)],
              format: (v) => formatNumber(v, 0),
            ),
            for (final r in rows.reversed.take(10))
              Text(
                '${formatDateTime(r.capturedAt)} · ${formatNumber(r.level, 1)} · '
                '${r.quality}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }

  Widget _episodesSection(BuildContext context, int id) {
    final episodes = _store.episodes;
    return SectionCard(
      title: context.tr('provider-equipment.tank-detail.episodes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (episodes.loading) const LinearProgressIndicator(),
          if (episodes.error)
            ErrorBanner(
              message: 'provider-equipment.tank-detail.episodes-error',
              onRetry: () => _store.loadEpisodes(id),
            )
          else if (!episodes.loading && episodes.data.isEmpty)
            EmptyState(
              message: context.tr('provider-equipment.tank-detail.no-episodes'),
            )
          else
            for (final e in episodes.data)
              Text(
                '${e.status} · ${formatDateTime(e.openedAt)} · '
                '${formatNumber(e.openedLevelPercent, 1)} % → '
                '${formatNumber(e.targetLevel, 0)} ${e.unit}'
                '${e.requestEmitted ? ' · ${context.tr('provider-equipment.tank-detail.request')}' : ''}',
              ),
        ],
      ),
    );
  }

  String _hour(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }
}
