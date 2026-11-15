import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../application/ordering_store.dart';
import '../../../domain/model/request_entity.dart';
import '../../../infrastructure/ordering_api.dart';
import '../../ordering_feedback.dart';
import 'request_card.dart';

/// Devuelve las claves de los campos obligatorios ausentes o inválidos; vacío si la solicitud está completa.
List<String> missingRequestFields(Request request) => [
  if (request.organizationId < 1) 'organization',
  if (!RequestStatus.values.contains(request.status)) 'status',
  if (request.customerAccountId < 1) 'customer',
  if (request.fuelProductId < 1) 'product',
  if (request.providerId < 1) 'provider',
  if (!request.quantity.isFinite || request.quantity <= 0) 'quantity',
  if (request.unit.trim().isEmpty) 'unit',
  if (!request.unitPrice.isFinite || request.unitPrice < 0) 'price',
  if (request.deliveryAddress.trim().isEmpty) 'address',
  if (!_isIsoDate(request.deliveryDate)) 'date',
];

bool _isIsoDate(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
    DateTime.tryParse(value) != null;

/// Solicitudes con filtros. El comprador crea y consulta; el distribuidor acepta o rechaza las pendientes.
class RequestList extends StatefulWidget {
  const RequestList({super.key});

  @override
  State<RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<RequestList>
    with NoticeSnackBars<RequestList> {
  late final OrderingStore _store;
  late final IamStore _iam;
  bool _ready = false;
  String _search = '';
  String _status = '';
  bool _incompleteOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _iam = app.iamStore;
    _store = OrderingStore(OrderingApi(app.httpClient), _iam)
      ..loadRequests()
      ..loadNames();
    _store.addListener(() => showNotice(_store.notice));
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  List<Request> get _visible {
    final query = _search.trim().toLowerCase();
    final rows = _store.requests
        .where(
          (row) =>
              (_status.isEmpty || row.status == _status) &&
              (!_incompleteOnly || missingRequestFields(row).isNotEmpty) &&
              (query.isEmpty || _searchable(row).contains(query)),
        )
        .toList();
    return rows..sort((a, b) => b.id.compareTo(a.id));
  }

  String _searchable(Request row) => [
    row.id,
    row.customerAccountId,
    row.deliveryAddress,
    _store.productNames[row.fuelProductId],
    _store.providerNames[row.providerId],
  ].join(' ').toLowerCase();

  void _clearFilters() => setState(() {
    _search = '';
    _status = '';
    _incompleteOnly = false;
  });

  Future<void> _accept(Request row) async {
    final confirmed = await confirmAction(
      context,
      message: context.tr('request-list.confirm-accept'),
      confirmLabel: context.tr('request-list.confirm-decision'),
    );
    if (confirmed) _store.acceptRequest(row.id);
  }

  Future<void> _reject(Request row) async {
    final reason = await askText(
      context,
      title: context.tr('request-list.confirm-reject'),
      label: context.tr('request-list.reason'),
      confirmLabel: context.tr('request-list.confirm-decision'),
    );
    if (reason != null) _store.rejectRequest(row.id, reason);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final provider = _store.isProvider;
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: provider
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/ordering/request-form'),
                icon: const Icon(Icons.add),
                label: Text(context.tr('request-list.new')),
              ),
        body: RefreshIndicator(
          onRefresh: () async {
            _store.loadRequests();
            _store.loadNames();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                context.tr(
                  provider
                      ? 'request-list.inbox-subtitle'
                      : 'request-list.buyer-subtitle',
                ),
              ),
              const SizedBox(height: 12),
              if (_store.error != null) ...[
                ErrorBanner(
                  message: _store.error!,
                  onRetry: _store.loadRequests,
                ),
                const SizedBox(height: 12),
              ],
              _filters(context),
              const SizedBox(height: 12),
              ..._body(context, provider),
            ],
          ),
        ),
      );
    },
  );

  Widget _filters(BuildContext context) {
    final rows = _store.requests;
    final incomplete = rows
        .where((r) => missingRequestFields(r).isNotEmpty)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            hintText: context.tr('request-list.search'),
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
                '${context.tr('request-list.all-statuses')} ${rows.length}',
              ),
              selected: _status.isEmpty,
              onSelected: (_) => setState(() => _status = ''),
            ),
            for (final status in RequestStatus.values)
              FilterChip(
                label: Text(
                  '${context.tr('request-status.${status.toLowerCase()}')} '
                  '${rows.where((r) => r.status == status).length}',
                ),
                selected: _status == status,
                onSelected: (_) =>
                    setState(() => _status = _status == status ? '' : status),
              ),
            FilterChip(
              label: Text(
                '${context.tr('request-list.incomplete-only')} $incomplete',
              ),
              selected: _incompleteOnly,
              onSelected: (value) => setState(() => _incompleteOnly = value),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, bool provider) {
    if (_store.loading && _store.requests.isEmpty) {
      return const [LoadingView()];
    }
    final rows = _visible;
    if (rows.isEmpty) {
      if (_store.requests.isEmpty) {
        return [
          EmptyState(
            message:
                '${context.tr('request-list.empty')}\n'
                '${context.tr(provider ? 'request-list.empty-inbox-hint' : 'request-list.empty-buyer-hint')}',
            icon: Icons.inbox_outlined,
          ),
        ];
      }
      return [
        EmptyState(
          icon: Icons.search_off,
          message:
              '${context.tr('request-list.no-match')}\n'
              '${context.tr('request-list.no-match-hint')}',
          action: TextButton(
            onPressed: _clearFilters,
            child: Text(context.tr('request-list.clear')),
          ),
        ),
      ];
    }
    return [
      for (final row in rows)
        RequestCard(
          request: row,
          title: provider
              ? '${context.tr('request-list.customer')} #${row.customerAccountId}'
              : _store.providerNames[row.providerId] ??
                    '${context.tr('request-list.provider')} #${row.providerId}',
          product:
              _store.productNames[row.fuelProductId] ??
              '${context.tr('request-list.product')} #${row.fuelProductId}',
          missing: missingRequestFields(row),
          onOpen: () => context.push('/ordering/request-detail/${row.id}'),
          onAccept: provider && _canDecide(row) ? () => _accept(row) : null,
          onReject: provider && _canDecide(row) ? () => _reject(row) : null,
        ),
    ];
  }

  bool _canDecide(Request row) =>
      row.status == RequestStatus.pending &&
      row.providerId == _iam.providerId &&
      !_store.loading;
}
