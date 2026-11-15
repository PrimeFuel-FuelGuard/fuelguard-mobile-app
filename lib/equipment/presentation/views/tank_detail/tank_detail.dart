import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/infrastructure/iam_api.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/equipment_store.dart';
import '../../../domain/model/equipment_entity.dart';
import '../../../infrastructure/equipment_api.dart';
import '../../../infrastructure/provider_equipment_api.dart';
import '../../equipment_ui.dart';
import 'refill_policy_form.dart';

/// Detalle de un tanque del comprador: nivel, política de reposición y episodios (`/tanks/:id`).
class TankDetail extends StatefulWidget {
  const TankDetail({super.key, this.rawId});

  final String? rawId;

  @override
  State<TankDetail> createState() => _TankDetailState();
}

class _TankDetailState extends State<TankDetail> {
  late final EquipmentStore _store;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = EquipmentStore(
      EquipmentApi(app.httpClient),
      app.iamStore,
      IamApi(app.httpClient),
    );
    final id = int.tryParse(widget.rawId ?? '');
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
      final tank = _store.tank;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_store.error != null) ErrorBanner(message: _store.error!),
          tank == null
              ? (_store.error == null ? const LoadingView() : const SizedBox())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    SectionCard(
                      title: tank.name,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Text(
                            '${formatNumber(tank.currentLevel)} / '
                            '${formatNumber(tank.capacity)} '
                            '${context.tr(unitKey(tank.unit))}',
                          ),
                          LevelBar(
                            percent: levelPercentOf(
                              tank.currentLevel,
                              tank.capacity,
                            ),
                          ),
                          Text(
                            '${context.tr('equipment.level-source')}: '
                            '${tank.levelSource}',
                          ),
                          Text(context.tr('equipment.device-pending')),
                        ],
                      ),
                    ),
                    RefillPolicyForm(store: _store),
                    SectionCard(
                      title: context.tr('equipment.episodes'),
                      child: _store.episodes.isEmpty
                          ? EmptyState(
                              message: context.tr('equipment.no-episodes'),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final e in _store.episodes)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(_episodeLine(context, e)),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
        ],
      );
    },
  );

  String _episodeLine(BuildContext context, RefillEpisode e) {
    final request = e.requestEmitted
        ? ' · ${context.tr('equipment.request-emitted')}'
        : '';
    return '${e.status} · ${formatDateTime(e.openedAt)} · '
        '${e.openedLevelPercent}% → ${e.targetLevel} ${e.unit}$request';
  }
}
