import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../application/inventory_store.dart';
import '../../../domain/model/fuel_product_entity.dart';
import '../../../infrastructure/inventory_api.dart';
import 'product_inventory_widgets.dart';

/// Catálogo de productos: comprador (catálogo filtrable por proveedor) y proveedor (su inventario).
class ProductInventory extends StatefulWidget {
  const ProductInventory({super.key});

  @override
  State<ProductInventory> createState() => _ProductInventoryState();
}

class _ProductInventoryState extends State<ProductInventory> {
  late final InventoryStore _store;
  late final IamStore _iam;
  bool _ready = false;
  int? _providerFilter;

  bool get _isProvider => _iam.isProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _iam = app.iamStore;
    _store = InventoryStore(InventoryApi(app.httpClient));
    if (_iam.isBuyer) _store.loadProviders();
    _load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() =>
      _store.loadAllProducts(_isProvider ? _iam.providerId : null);

  List<FuelProduct> _visibleProducts() => [
    for (final p in _store.productList)
      if (_providerFilter == null || p.providerId == _providerFilter) p,
  ];

  String _providerName(BuildContext context, int id) =>
      _store.providerNames[id] ??
      '${context.tr('product-inventory.fields.provider')} #$id';

  Future<void> _editStock(FuelProduct product) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StockSheet(product: product),
    );
    if (value != null) _store.updateStock(product.id, value);
  }

  Future<void> _confirmDelete(FuelProduct product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('confirm.title')),
        content: Text(dialogContext.tr('confirm.product')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('confirm.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('confirm.confirm')),
          ),
        ],
      ),
    );
    if (ok ?? false) _store.deleteProduct(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final products = _visibleProducts();
        final providerIds = {
          for (final p in _store.productList) p.providerId,
        }.toList()..sort();
        return Column(
          children: [
            if (_store.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ErrorBanner(message: _store.error!),
              ),
            if (!_isProvider && providerIds.length > 1)
              _ProviderFilters(
                selected: _providerFilter,
                labels: {
                  for (final id in providerIds) id: _providerName(context, id),
                },
                onSelected: (id) => setState(() => _providerFilter = id),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _content(context, products),
              ),
            ),
          ],
        );
      },
    );
    if (!_isProvider) return body;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fuel-products/product-form'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('inventory.add-product')),
      ),
      body: body,
    );
  }

  Widget _content(BuildContext context, List<FuelProduct> products) {
    if (products.isEmpty) {
      return ListView(
        children: [
          if (_store.isLoading)
            const LoadingView()
          else
            EmptyState(
              message: context.tr('product-inventory.empty'),
              icon: Icons.local_gas_station_outlined,
            ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final product = products[i];
        return ProductCard(
          product: product,
          providerLabel: _isProvider
              ? null
              : _providerName(context, product.providerId),
          onStock: _isProvider ? () => _editStock(product) : null,
          onEdit: _isProvider
              ? () => context.push('/fuel-products/product-form/${product.id}')
              : null,
          onDelete: _isProvider ? () => _confirmDelete(product) : null,
        );
      },
    );
  }
}

class _ProviderFilters extends StatelessWidget {
  const _ProviderFilters({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final int? selected;
  final Map<int, String> labels;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Row(
      spacing: 8,
      children: [
        FilterChip(
          label: Text(context.tr('product-inventory.show-all')),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final entry in labels.entries)
          FilterChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onSelected(entry.key),
          ),
      ],
    ),
  );
}
