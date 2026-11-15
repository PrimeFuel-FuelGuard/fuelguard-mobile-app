import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/bar_chart/bar_chart.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/kpi_card/kpi_card.dart';
import '../../../../shared/presentation/component/section_card/section_card.dart';
import '../../../application/analytics_store.dart';
import '../../../domain/sales_trend.dart';
import '../../../infrastructure/analytics_api.dart';

/// Análisis por rol (`/analytics`): comprador (gasto), proveedor (ventas) y administrador (plataforma).
class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  late final AnalyticsStore _store;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = AnalyticsStore(AnalyticsApi(app.httpClient), app.iamStore);
    _store.load();
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
      final kind = _store.kind;
      final muted = Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      return RefreshIndicator(
        onRefresh: _store.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.tr('analytics.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(context.tr('analytics.subtitle-${kind.name}'), style: muted),
            const SizedBox(height: 16),
            if (kind != AnalyticsKind.admin) ...[
              _RangeRow(store: _store),
              const SizedBox(height: 12),
            ],
            if (_store.loading) const LinearProgressIndicator(),
            if (_store.error) ...[
              ErrorBanner(message: 'analytics.error', onRetry: _store.load),
              const SizedBox(height: 12),
            ],
            if (_store.kpis.isNotEmpty) ...[
              _KpiGrid(kpis: _store.kpis),
              const SizedBox(height: 16),
            ],
            if (kind == AnalyticsKind.provider && _store.provider != null) ...[
              _TrendCard(store: _store),
              const SizedBox(height: 16),
            ],
            if (kind != AnalyticsKind.admin &&
                (_store.buyer != null || _store.provider != null))
              _MonthlyCard(store: _store),
          ],
        ),
      );
    },
  );
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.store});

  final AnalyticsStore store;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      Expanded(
        child: _DatePickerButton(
          label: context.tr('analytics.from'),
          date: store.from,
          first: DateTime(2020),
          last: store.to,
          onPicked: store.setFrom,
        ),
      ),
      Expanded(
        child: _DatePickerButton(
          label: context.tr('analytics.to'),
          date: store.to,
          first: store.from,
          last: DateTime(2100),
          onPicked: store.setTo,
        ),
      ),
    ],
  );
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.first,
    required this.last,
    required this.onPicked,
  });

  final String label;
  final DateTime date;
  final DateTime first;
  final DateTime last;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: first,
        lastDate: last,
      );
      if (picked != null) onPicked(picked);
    },
    icon: const Icon(Icons.calendar_today, size: 18),
    label: Text('$label: ${formatDate(date)}'),
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<AnalyticsKpi> kpis;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.4,
    children: [
      for (final kpi in kpis)
        KpiCard(
          label: context.tr(kpi.label),
          value: kpi.money ? formatMoney(kpi.value) : formatNumber(kpi.value),
        ),
    ],
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.store});

  final AnalyticsStore store;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: context.tr('analytics.sales-trend'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final g in TrendGranularity.values)
              ButtonSegment(
                value: g,
                label: Text(context.tr('analytics.view-$g')),
              ),
          ],
          selected: {store.granularity},
          onSelectionChanged: (s) => store.setGranularity(s.first),
        ),
        if (store.hasSales)
          SimpleBarChart(
            data: [for (final p in store.trend) (p.date, p.litres)],
            format: (v) => formatNumber(v),
          )
        else
          Text(context.tr('analytics.no-sales')),
      ],
    ),
  );
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.store});

  final AnalyticsStore store;

  @override
  Widget build(BuildContext context) {
    final isBuyer = store.kind == AnalyticsKind.buyer;
    final months = store.monthly;
    return SectionCard(
      title: context.tr(
        isBuyer ? 'analytics.monthly-spending' : 'analytics.monthly-revenue',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            context.tr('analytics.series-note'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (months.isEmpty)
            Text(context.tr('analytics.no-range-data'))
          else ...[
            SimpleBarChart(
              data: [for (final m in months) (m.month, m.amount)],
              format: formatMoney,
            ),
            const Divider(),
            for (final (i, row) in store.topMonths.indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                title: Text(row.month),
                trailing: Text(formatMoney(row.amount)),
              ),
          ],
        ],
      ),
    );
  }
}
