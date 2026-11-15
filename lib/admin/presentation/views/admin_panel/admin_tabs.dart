import 'package:material_ui/material_ui.dart';

import '../../../../ordering/infrastructure/ordering_api.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../infrastructure/admin_api.dart';

/// Pestaña de usuarios: búsqueda por nombre y promoción a administrador.
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({
    super.key,
    required this.users,
    required this.search,
    required this.onSearch,
    required this.onPromote,
  });

  final List<AdminUser> users;
  final TextEditingController search;
  final VoidCallback onSearch;
  final ValueChanged<AdminUser> onPromote;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      TextField(
        controller: search,
        onChanged: (_) => onSearch(),
        decoration: InputDecoration(
          labelText: context.tr('admin.users.search'),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      if (users.isEmpty)
        EmptyState(
          message: context.tr('admin.users.empty'),
          icon: Icons.people_outline,
        ),
      for (final user in users)
        Card(
          child: ListTile(
            isThreeLine: true,
            leading: CircleAvatar(child: Text('${user.id}')),
            title: Text(user.username),
            subtitle: Text(
              [
                user.roles.join(', '),
                '${context.tr('admin.users.company')}: ${user.companyId ?? '—'}',
                '${context.tr('admin.users.provider')}: ${user.providerId ?? '—'}',
              ].join('\n'),
            ),
            trailing: user.roles.contains('ROLE_ADMIN')
                ? StatusChip(
                    label: context.tr('admin.users.is-admin'),
                    tone: StatusTone.success,
                  )
                : TextButton(
                    onPressed: () => onPromote(user),
                    child: Text(context.tr('admin.users.promote')),
                  ),
          ),
        ),
    ],
  );
}

/// Pestaña de métricas de API con selector de versión.
class AdminMetricsTab extends StatelessWidget {
  const AdminMetricsTab({
    super.key,
    required this.metrics,
    required this.version,
    required this.onVersion,
  });

  final List<ApiMetric> metrics;
  final String version;
  final ValueChanged<String> onVersion;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'v1', label: Text('v1')),
            ButtonSegment(value: 'v2', label: Text('v2')),
          ],
          selected: {version},
          onSelectionChanged: (s) => onVersion(s.first),
        ),
      ),
      const SizedBox(height: 12),
      if (metrics.isEmpty)
        EmptyState(
          message: context.tr('admin.metrics.empty'),
          icon: Icons.query_stats,
        ),
      for (final m in metrics)
        Card(
          child: ListTile(
            isThreeLine: true,
            title: Text(
              m.routeKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            subtitle: Text(
              [
                m.handler,
                '${context.tr('admin.metrics.last-seen')}: '
                    '${m.lastSeen == null ? '—' : formatDateTime(m.lastSeen)}',
                '${context.tr('admin.metrics.callers')}: ${m.distinctCallers}',
              ].join('\n'),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${m.count}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  context.tr('admin.metrics.count'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Pestaña de pagos con filtro por estado.
class AdminPaymentsTab extends StatelessWidget {
  const AdminPaymentsTab({
    super.key,
    required this.payments,
    required this.status,
    required this.onStatus,
  });

  final List<Payment> payments;
  final String status;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final statuses = {for (final p in payments) p.status}.toList()..sort();
    final shown = [
      for (final p in payments)
        if (status.isEmpty || p.status == status) p,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(context.tr('admin.payments.all')),
              selected: status.isEmpty,
              onSelected: (_) => onStatus(''),
            ),
            for (final s in statuses)
              FilterChip(
                label: Text(s),
                selected: status == s,
                onSelected: (_) => onStatus(s),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          EmptyState(
            message: context.tr('admin.payments.empty'),
            icon: Icons.payments_outlined,
          ),
        for (final p in shown)
          Card(
            child: ListTile(
              isThreeLine: true,
              title: Text(
                '#${p.id} · ${context.tr('admin.payments.order')} #${p.orderId}',
              ),
              subtitle: Text(
                [
                  '${context.tr('admin.payments.company')}: ${p.companyId} · '
                      '${p.paymentMethod}',
                  '${context.tr('admin.payments.reference')}: '
                      '${p.transactionReference ?? '—'}',
                  '${context.tr('admin.payments.paid-at')}: '
                      '${formatDateTime(p.paidAt)}',
                ].join('\n'),
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(p.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  StatusChip(label: p.status, status: p.status),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pestaña de evidencias de transporte: exportar o eliminar por id de entrega.
class AdminEvidenceTab extends StatelessWidget {
  const AdminEvidenceTab({
    super.key,
    required this.deliveryId,
    required this.busy,
    required this.onChanged,
    required this.onExport,
    required this.onDelete,
  });

  final TextEditingController deliveryId;
  final bool busy;
  final VoidCallback onChanged;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final valid = RegExp(r'^\d+$').hasMatch(deliveryId.text.trim());
    final enabled = valid && !busy;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: deliveryId,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: context.tr('admin.evidence.delivery-id'),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: enabled ? onExport : null,
          icon: const Icon(Icons.download),
          label: Text(context.tr('admin.evidence.export')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onDelete : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(context.tr('admin.evidence.delete')),
        ),
      ],
    );
  }
}
