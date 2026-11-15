import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../application/admin_store.dart';
import '../../../infrastructure/admin_api.dart';
import 'admin_tabs.dart';

/// Panel de administración (`/admin`): usuarios, métricas de API, pagos y evidencias de transporte.
class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late final AdminStore _store;
  final _search = TextEditingController();
  final _deliveryId = TextEditingController();
  final _confirmId = TextEditingController();
  bool _ready = false;
  String _version = 'v1';
  String _paymentStatus = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = AdminStore(AdminApi(app.httpClient));
    _store.addListener(_onStoreChange);
    _store.loadUsers();
    _store.loadMetrics(_version);
    _store.loadPayments();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChange);
    _store.dispose();
    for (final c in [_search, _deliveryId, _confirmId]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onStoreChange() {
    final notice = _store.notice;
    if (notice == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(notice))));
    _store.clearNotice();
  }

  int? get _deliveryNumber => int.tryParse(_deliveryId.text.trim());

  List<AdminUser> get _filteredUsers {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final u in _store.users)
        if (u.username.toLowerCase().contains(query)) u,
    ];
  }

  void _setVersion(String version) {
    setState(() => _version = version);
    _store.loadMetrics(version);
  }

  Future<void> _askPromote(AdminUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          dialogContext.tr('admin.users.confirm-title', {
            'username': user.username,
          }),
        ),
        content: Text(dialogContext.tr('admin.users.confirm-message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('admin.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('admin.users.promote')),
          ),
        ],
      ),
    );
    if (ok ?? false) _store.promote(user);
  }

  void _export() {
    final id = _deliveryNumber;
    if (id != null) _store.exportEvidence(id, _showEvidence);
  }

  void _showEvidence(TransportEvidence evidence) {
    if (!mounted) return;
    final json = const JsonEncoder.withIndent('  ').convert(evidence.toJson());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              sheetContext.tr('admin.evidence.export'),
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askDelete() async {
    final id = _deliveryNumber;
    if (id == null) return;
    final typed = _deliveryId.text.trim();
    _confirmId.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialog) {
          final matches = _confirmId.text.trim() == typed;
          return AlertDialog(
            title: Text(
              dialogContext.tr('admin.evidence.confirm-title', {'id': typed}),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(dialogContext.tr('admin.evidence.confirm-message')),
                TextField(
                  controller: _confirmId,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialog(() {}),
                  decoration: InputDecoration(
                    labelText: dialogContext.tr('admin.evidence.delivery-id'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.tr('admin.cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(builderContext).colorScheme.error,
                ),
                onPressed: matches
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(dialogContext.tr('admin.evidence.confirm-delete')),
              ),
            ],
          );
        },
      ),
    );
    if (ok ?? false) _store.deleteEvidence(id);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: ListenableBuilder(
      listenable: _store,
      builder: (context, _) => Column(
        children: [
          if (_store.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ErrorBanner(message: _store.error!),
            ),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.tr('admin.users.tab')),
              Tab(text: context.tr('admin.metrics.tab')),
              Tab(text: context.tr('admin.payments.tab')),
              Tab(text: context.tr('admin.evidence.tab')),
            ],
          ),
          if (_store.loading) const LinearProgressIndicator(),
          Expanded(
            child: TabBarView(
              children: [
                AdminUsersTab(
                  users: _filteredUsers,
                  search: _search,
                  onSearch: () => setState(() {}),
                  onPromote: _askPromote,
                ),
                AdminMetricsTab(
                  metrics: _store.metrics,
                  version: _version,
                  onVersion: _setVersion,
                ),
                AdminPaymentsTab(
                  payments: _store.payments,
                  status: _paymentStatus,
                  onStatus: (s) => setState(() => _paymentStatus = s),
                ),
                AdminEvidenceTab(
                  deliveryId: _deliveryId,
                  busy: _store.loading,
                  onChanged: () => setState(() {}),
                  onExport: _export,
                  onDelete: _askDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
