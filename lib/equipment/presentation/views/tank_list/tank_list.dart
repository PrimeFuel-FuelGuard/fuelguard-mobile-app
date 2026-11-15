import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/infrastructure/iam_api.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/equipment_store.dart';
import '../../../domain/model/equipment_entity.dart';
import '../../../infrastructure/equipment_api.dart';
import '../../../infrastructure/provider_equipment_api.dart';
import '../../equipment_ui.dart';

/// Tanques de la empresa compradora con su nivel (`/tanks`).
class TankList extends StatefulWidget {
  const TankList({super.key});

  @override
  State<TankList> createState() => _TankListState();
}

class _TankListState extends State<TankList> {
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
    )..load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => RefreshIndicator(
      onRefresh: _store.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_store.loading) const LinearProgressIndicator(),
          if (_store.error != null)
            ErrorBanner(message: _store.error!, onRetry: _store.load),
          if (!_store.loading && _store.tanks.isEmpty && _store.error == null)
            EmptyState(
              message: context.tr('equipment.no-tanks'),
              icon: Icons.propane_tank_outlined,
            ),
          for (final tank in _store.tanks) _TankCard(tank: tank),
        ],
      ),
    ),
  );
}

class _TankCard extends StatelessWidget {
  const _TankCard({required this.tank});

  final Tank tank;

  @override
  Widget build(BuildContext context) {
    final percent = levelPercentOf(tank.currentLevel, tank.capacity);
    final unit = context.tr(unitKey(tank.unit));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/tanks/${tank.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tank.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    tank.fuelType == null
                        ? '—'
                        : context.tr(fuelTypeKey(tank.fuelType)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              Text(
                '${context.tr('equipment.current-level')}: '
                '${formatNumber(tank.currentLevel)} / '
                '${formatNumber(tank.capacity)} $unit',
              ),
              LevelBar(percent: percent),
            ],
          ),
        ),
      ),
    );
  }
}
