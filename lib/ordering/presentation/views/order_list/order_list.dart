import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/ordering_store.dart';
import '../../../domain/model/order_entity.dart';
import '../../../infrastructure/ordering_api.dart';

/// Órdenes con búsqueda por número y filtro de estado; los filtros omiten los estados sin órdenes.
class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  late final OrderingStore _store;
  bool _ready = false;
  String _search = '';
  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = OrderingStore(OrderingApi(app.httpClient), app.iamStore)
      ..loadOrders()
      ..loadNames();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  List<Order> get _visible => _store.orders
      .where(
        (order) =>
            (_search.trim().isEmpty ||
                '${order.id}'.contains(_search.trim())) &&
            (_status.isEmpty || order.status == _status),
      )
      .toList();

  void _clear() => setState(() {
    _search = '';
    _status = '';
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => RefreshIndicator(
      onRefresh: () async {
        _store.loadOrders();
        _store.loadNames();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_store.error != null) ...[
            ErrorBanner(message: _store.error!, onRetry: _store.loadOrders),
            const SizedBox(height: 12),
          ],
          _filters(context),
          const SizedBox(height: 12),
          ..._body(context),
        ],
      ),
    ),
  );

  Widget _filters(BuildContext context) {
    final counts = {
      for (final status in OrderStatus.values)
        status: _store.orders.where((o) => o.status == status).length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            labelText: context.tr('order-list.search-id'),
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(
                '${context.tr('order-list.all-statuses')} ${_store.orders.length}',
              ),
              selected: _status.isEmpty,
              onSelected: (_) => setState(() => _status = ''),
            ),
            for (final entry in counts.entries)
              if (entry.value > 0)
                FilterChip(
                  label: Text(
                    '${context.tr('order-status.${entry.key.toLowerCase()}')} ${entry.value}',
                  ),
                  selected: _status == entry.key,
                  onSelected: (_) => setState(
                    () => _status = _status == entry.key ? '' : entry.key,
                  ),
                ),
          ],
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context) {
    if (_store.loading && _store.orders.isEmpty) return const [LoadingView()];
    final rows = _visible;
    if (rows.isEmpty) {
      final empty = _store.orders.isEmpty;
      return [
        EmptyState(
          icon: empty ? Icons.inbox_outlined : Icons.search_off,
          message: context.tr(
            empty ? 'order-list.empty' : 'order-list.no-match',
          ),
          action: empty
              ? null
              : TextButton(
                  onPressed: _clear,
                  child: Text(context.tr('order-list.clear')),
                ),
        ),
      ];
    }
    return [
      for (final order in rows)
        Card(
          child: ListTile(
            onTap: () => context.push('/ordering/order-detail/${order.id}'),
            title: Text(
              '#${order.id} · ${_store.productNames[order.fuelProductId] ?? '#${order.fuelProductId}'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_store.providerNames[order.providerId] ?? '#${order.providerId}'}\n'
              '${formatNumber(order.requestedQuantity)} · ${formatMoney(order.totalPrice)}',
            ),
            isThreeLine: true,
            trailing: StatusChip(
              label: context.tr('order-status.${order.status.toLowerCase()}'),
              status: order.status,
            ),
          ),
        ),
    ];
  }
}
